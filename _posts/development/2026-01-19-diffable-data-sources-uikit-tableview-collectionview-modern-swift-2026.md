---
title: "Diffable Data Sources in UIKit (UITableView + UICollectionView): Modern Swift 2026"
date: 2026-01-19 23:18:00 +0900
tags: [swift, uikit, ios, diffable-data-source]
---


Diffable Data Sources let you drive `UITableView` and `UICollectionView` from *snapshots* (a declarative “this is what the UI should show right now” state) instead of manually coordinating `insertRows`, `deleteItems`, `performBatchUpdates`, etc. Apple’s snapshot API requires **unique, `Hashable` identifiers** for sections and items. ([Apple Developer][1])

> Key idea: **your UI is a projection of a snapshot**. You build a snapshot from your current model state and apply it; the system computes the updates for you. ([Apple Developer][1])

---

## Table of contents

* [1. Core types and mental model](#1-core-types-and-mental-model)
* [2. Identifier design (most important “gotcha”)](#2-identifier-design-most-important-gotcha)
* [3. Modern “latest” apply syntax: `async` + `@MainActor`](#3-modern-latest-apply-syntax-async--mainactor)
* [4. UITableView examples](#4-uitableview-examples)

  * [4.1 Minimal table view](#41-minimal-table-view)
  * [4.2 Table with multiple sections + section headers](#42-table-with-multiple-sections--section-headers)
  * [4.3 Swipe-to-delete + snapshot-driven deletes](#43-swipe-to-delete--snapshot-driven-deletes)
  * [4.4 Updating a single row: `reconfigureItems` vs `reloadItems`](#44-updating-a-single-row-reconfigureitems-vs-reloaditems)
  * [4.5 Fast “reset” updates: `applySnapshotUsingReloadData`](#45-fast-reset-updates-applysnapshotusingreloaddata)
  * [4.6 Filtering + search](#46-filtering--search)
* [5. UICollectionView examples](#5-uicollectionview-examples)

  * [5.1 List-style collection view (modern replacement for many tables)](#51-list-style-collection-view-modern-replacement-for-many-tables)
  * [5.2 Section headers with `SupplementaryRegistration`](#52-section-headers-with-supplementaryregistration)
  * [5.3 Grid layout (compositional) + diffable](#53-grid-layout-compositional--diffable)
  * [5.4 Expandable outline / hierarchy with `NSDiffableDataSourceSectionSnapshot`](#54-expandable-outline--hierarchy-with-nsdiffabledatasourcesectionsnapshot)
  * [5.5 Reordering with `reorderingHandlers` + transactions](#55-reordering-with-reorderinghandlers--transactions)
* [6. Snapshot operations cookbook](#6-snapshot-operations-cookbook)
* [7. Concurrency + performance notes (Swift 6 era)](#7-concurrency--performance-notes-swift-6-era)
* [8. Core Data integration pattern (FRC → diffable)](#8-core-data-integration-pattern-frc--diffable)
* [9. Common pitfalls checklist](#9-common-pitfalls-checklist)

---

## 1. Core types and mental model

### The main actors

* **Data source**

  * `UITableViewDiffableDataSource<SectionID, ItemID>`
  * `UICollectionViewDiffableDataSource<SectionID, ItemID>` ([Apple Developer][2])
* **Snapshot**

  * `NSDiffableDataSourceSnapshot<SectionID, ItemID>`: the *entire* UI state ([Apple Developer][1])
* **Section snapshot (optional / advanced)**

  * `NSDiffableDataSourceSectionSnapshot<ItemID>`: per-section state, supports hierarchy/outline and independent section updates ([Apple Developer][3])

### The flow

1. Pick identifier types (`Hashable`, unique). ([Apple Developer][1])
2. Create a diffable data source with a **cell provider**.
3. Build a snapshot reflecting current model state.
4. Apply snapshot to render UI updates.

---

## 2. Identifier design (most important “gotcha”)

Apple’s snapshot docs explicitly recommend **Swift value types** (struct/enum) for identifiers; if you use a Swift class it must be an `NSObject` subclass. ([Apple Developer][1])

### Rules of thumb

✅ **Good identifiers**

* `UUID`, `Int`, `String`
* `struct ItemID: Hashable { let rawValue: UUID }`
* `enum Section: Hashable { case main, favorites }`

❌ **Risky identifiers**

* A whole mutable model (`struct Contact { var name: String ... }`) *if* its `Hashable` includes mutable properties.
* Anything where `hashValue` can change over the lifetime of an item.

### Recommended pattern: “IDs in snapshots, models in a store”

* Snapshot contains **IDs**.
* Cell provider looks up the **current model** from a dictionary/cache by ID.

Why? Because the `itemIdentifier` passed into your cell provider should be treated primarily as an identifier, and your “fresh data” should come from your own source-of-truth store (a common source of confusion when reloading). ([Stack Overflow][4])

---

## 3. Modern “latest” apply syntax: `async` + `@MainActor`

In newer SDKs, `apply` is available as an **`async`** method and annotated with **`@MainActor`**. ([Apple Developer][5])

```swift
// Modern (Swift Concurrency-friendly)
await dataSource.apply(snapshot, animatingDifferences: true)
```

There are also completion-handler variants in the API surface (useful for compatibility or when you need an explicit callback). ([Apple Developer][6])

### Important concurrency nuance (iOS 18+ era)

UIKit docs historically said you could call `apply` from a background queue if done consistently, but the API gained `@MainActor` annotations in the iOS 18 SDK and that created real-world Swift 6 friction; Jesse Squires documents the change and UIKit’s explanation. ([Jesse Squires][7])

**Practical guidance (2026):**

* Build snapshots off-thread if you want (pure data).
* **Apply snapshots on the main actor** (either by being in `@MainActor` context or using `await MainActor.run { ... }`). ([Apple Developer][5])

---

## 4. UITableView examples

> **Note:** Apple explicitly warns you shouldn’t swap out the table view’s data source after configuring a diffable data source; if you truly need a new data source, create a new table view and data source. ([Apple Developer][8])

### Shared model helpers used by table examples

```swift
import UIKit

enum Section: Hashable {
    case main
    case favorites
}

struct Contact: Identifiable, Hashable {
    let id: UUID
    var name: String
    var isFavorite: Bool

    // Stable identity: only ID participates in Hashable/Equatable.
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Contact, rhs: Contact) -> Bool { lhs.id == rhs.id }
}
```

---

### 4.1 Minimal table view

This example uses:

* `UITableViewDiffableDataSource`
* `UITableView.CellRegistration`
* `UIListContentConfiguration` (modern cell content API) ([Apple Developer][9])
* `await dataSource.apply(...)` (modern apply) ([Apple Developer][8])

```swift
@MainActor
final class ContactsTableViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // Keep a strong reference! tableView.dataSource is a weak reference in UIKit patterns.
    private var dataSource: UITableViewDiffableDataSource<Section, UUID>!

    // Source of truth store
    private var contactsByID: [UUID: Contact] = [:]
    private var orderedIDs: [UUID] = []

    private lazy var cellRegistration = UITableView.CellRegistration<UITableViewCell, Contact> { cell, _, contact in
        var content = cell.defaultContentConfiguration()
        content.text = contact.name
        content.secondaryText = contact.isFavorite ? "★ Favorite" : nil
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contacts"

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        configureDataSource()
        seedData()
        Task { await applySnapshot(animated: false) }
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, UUID>(tableView: tableView) { [weak self] tableView, indexPath, contactID in
            guard let self, let contact = self.contactsByID[contactID] else { return nil }
            // Note: cell registration item type can be the *model* (Contact),
            // even though diffable item identifier is UUID.
            return tableView.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: contact)
        }
    }

    private func seedData() {
        let contacts: [Contact] = [
            .init(id: UUID(), name: "Alicia", isFavorite: true),
            .init(id: UUID(), name: "Ben", isFavorite: false),
            .init(id: UUID(), name: "Chen", isFavorite: false),
        ]
        contactsByID = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0) })
        orderedIDs = contacts.map(\.id)
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, UUID> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(orderedIDs, toSection: .main)
        return snapshot
    }

    private func applySnapshot(animated: Bool) async {
        let snapshot = makeSnapshot()
        await dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
```

**Why the cell registration uses `Contact` while diffable uses `UUID`:** Apple notes the *registration item type doesn’t have to match the diffable item identifier type*. ([Apple Developer][10])

---

### 4.2 Table with multiple sections + section headers

There are multiple approaches for headers:

* Use the table view delegate to provide custom header views.
* Or **subclass** `UITableViewDiffableDataSource` and override `tableView(_:titleForHeaderInSection:)` (common pattern). ([Stack Overflow][11])

Here’s the subclass approach:

```swift
final class HeaderedContactsDataSource: UITableViewDiffableDataSource<Section, UUID> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionID = sectionIdentifier(for: section) else { return nil }
        switch sectionID {
        case .favorites: return "Favorites"
        case .main: return "All Contacts"
        }
    }
}
```

Then create it:

```swift
dataSource = HeaderedContactsDataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
    guard let self, let contact = self.contactsByID[id] else { return nil }
    return tableView.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: contact)
}
```

Build a snapshot that splits items:

```swift
private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, UUID> {
    var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()

    let favorites = orderedIDs.filter { contactsByID[$0]?.isFavorite == true }
    let others = orderedIDs.filter { contactsByID[$0]?.isFavorite != true }

    snapshot.appendSections([.favorites, .main])

    snapshot.appendItems(favorites, toSection: .favorites)
    snapshot.appendItems(others, toSection: .main)

    return snapshot
}
```

---

### 4.3 Swipe-to-delete + snapshot-driven deletes

For tables, it’s common to implement swipe actions in the view controller (delegate) and then update your model + apply a new snapshot.

```swift
extension ContactsTableViewController: UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        guard let id = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { return }
            self.contactsByID[id] = nil
            self.orderedIDs.removeAll { $0 == id }
            Task { await self.applySnapshot(animated: true) }
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }
}
```

---

### 4.4 Updating a single row: `reconfigureItems` vs `reloadItems`

Apple’s guidance: if you want to update the contents of existing cells without replacing them, prefer `reconfigureItems(_:)` over `reloadItems(_:)` for performance, unless you truly need a full reload. ([Apple Developer][12])

Example: toggle favorite flag for one contact.

```swift
@MainActor
func toggleFavorite(for id: UUID) async {
    guard var contact = contactsByID[id] else { return }
    contact.isFavorite.toggle()
    contactsByID[id] = contact

    var snapshot = dataSource.snapshot()
    snapshot.reconfigureItems([id]) // lightweight refresh of visible/prefetched cells
    await dataSource.apply(snapshot, animatingDifferences: true)
}
```

**When to use `reloadItems`:**

* You changed the cell type (rare / usually a smell).
* You must trigger a full reload lifecycle (`prepareForReuse`, etc.).
* You need the “replace cell” behavior rather than “reconfigure existing cell”.

Also note a common confusion: reloading doesn’t mean the identifier changed; you still use your own backing store to provide updated content. ([Stack Overflow][4])

---

### 4.5 Fast “reset” updates: `applySnapshotUsingReloadData`

`applySnapshotUsingReloadData` resets UI to match the snapshot **without computing a diff** and without animating changes. ([Apple Developer][13])

This is useful when:

* You have massive changes and don’t want animations.
* You’re switching entire datasets (e.g., changing accounts).
* You’re hitting edge cases where animated diffs get expensive.

```swift
@MainActor
func replaceAll(with contacts: [Contact]) async {
    contactsByID = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0) })
    orderedIDs = contacts.map(\.id)

    let snapshot = makeSnapshot()
    await dataSource.applySnapshotUsingReloadData(snapshot)
}
```

---

### 4.6 Filtering + search

A simple approach: keep a full list of IDs and a current filter, then build snapshot from the filtered IDs.

```swift
enum Filter {
    case all
    case favoritesOnly
    case query(String)
}

private var filter: Filter = .all

private func filteredIDs() -> [UUID] {
    switch filter {
    case .all:
        return orderedIDs
    case .favoritesOnly:
        return orderedIDs.filter { contactsByID[$0]?.isFavorite == true }
    case .query(let q):
        let lower = q.lowercased()
        return orderedIDs.filter { (contactsByID[$0]?.name.lowercased().contains(lower) ?? false) }
    }
}

private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, UUID> {
    var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
    snapshot.appendSections([.main])
    snapshot.appendItems(filteredIDs(), toSection: .main)
    return snapshot
}
```

Hook it up to a `UISearchController` and call `Task { await applySnapshot(animated: true) }` when the query changes.

---

## 5. UICollectionView examples

### 5.1 List-style collection view (modern replacement for many tables)

Using:

* `UICollectionLayoutListConfiguration` + compositional list layout
* `UICollectionView.CellRegistration`
* `UICollectionViewDiffableDataSource`

```swift
@MainActor
final class SettingsListViewController: UIViewController, UICollectionViewDelegate {

    enum Section: Hashable { case main }

    struct Setting: Hashable, Identifiable {
        let id: UUID
        var title: String
        var isOn: Bool
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func ==(l: Self, r: Self) -> Bool { l.id == r.id }
    }

    private var settingsByID: [UUID: Setting] = [:]
    private var orderedIDs: [UUID] = []

    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, UUID>!

    // IMPORTANT: create registrations outside the cell provider (Apple warns against doing so inside).
    // Doing it inside prevents reuse and can throw exceptions (iOS 15+).
    private lazy var cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Setting> { cell, _, setting in
        var content = UIListContentConfiguration.cell()
        content.text = setting.title
        cell.contentConfiguration = content

        // Use a checkmark accessory for demo
        cell.accessories = setting.isOn ? [.checkmark()] : []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"

        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        configureDataSource()
        seed()
        Task { await applySnapshot(animated: false) }
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, UUID>(collectionView: collectionView) { [weak self] collectionView, indexPath, id in
            guard let self, let setting = self.settingsByID[id] else { return nil }
            return collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: setting)
        }
    }

    private func seed() {
        let items: [Setting] = [
            .init(id: UUID(), title: "Wi‑Fi", isOn: true),
            .init(id: UUID(), title: "Bluetooth", isOn: false),
            .init(id: UUID(), title: "Airplane Mode", isOn: false),
        ]
        settingsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        orderedIDs = items.map(\.id)
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, UUID> {
        var snap = NSDiffableDataSourceSnapshot<Section, UUID>()
        snap.appendSections([.main])
        snap.appendItems(orderedIDs, toSection: .main)
        return snap
    }

    private func applySnapshot(animated: Bool) async {
        await dataSource.apply(makeSnapshot(), animatingDifferences: animated)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath),
              var setting = settingsByID[id] else { return }

        setting.isOn.toggle()
        settingsByID[id] = setting

        Task {
            var snap = dataSource.snapshot()
            snap.reconfigureItems([id])
            await dataSource.apply(snap, animatingDifferences: true)
        }
    }
}
```

---

### 5.2 Section headers with `SupplementaryRegistration`

`UICollectionViewDiffableDataSource` supports a `supplementaryViewProvider` closure for headers/footers. ([Apple Developer][14])
Modern pattern: `UICollectionView.SupplementaryRegistration` + `dequeueConfiguredReusableSupplementary`. ([Apple Developer][15])

```swift
private lazy var headerRegistration =
    UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
        elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] header, _, indexPath in
        guard let self else { return }
        let sectionID = self.dataSource.sectionIdentifier(for: indexPath.section)

        var content = UIListContentConfiguration.groupedHeader()
        content.text = (sectionID == .main) ? "General" : "Other"
        header.contentConfiguration = content
    }

private func configureHeader() {
    dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
        guard let self, kind == UICollectionView.elementKindSectionHeader else { return nil }
        return collectionView.dequeueConfiguredReusableSupplementary(using: self.headerRegistration, for: indexPath)
    }
}
```

---

### 5.3 Grid layout (compositional) + diffable

A classic “photo grid” example.

```swift
@MainActor
final class PhotoGridViewController: UIViewController {

    enum Section: Hashable { case main }

    struct Photo: Hashable, Identifiable {
        let id: UUID
        let title: String
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func ==(l: Self, r: Self) -> Bool { l.id == r.id }
    }

    private var photos: [Photo] = (0..<60).map {
        Photo(id: UUID(), title: "Photo \($0)")
    }

    private lazy var collectionView: UICollectionView = {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1.0/3.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)

        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)

        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, UUID>!

    private lazy var cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Photo> { cell, _, photo in
        var content = UIListContentConfiguration.cell()
        content.text = photo.title
        cell.contentConfiguration = content

        var bg = UIBackgroundConfiguration.listPlainCell()
        bg.cornerRadius = 12
        cell.backgroundConfiguration = bg
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Grid"

        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        configureDataSource()
        Task { await applySnapshot(animated: false) }
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, UUID>(collectionView: collectionView) { [weak self] cv, indexPath, id in
            guard let self,
                  let photo = self.photos.first(where: { $0.id == id }) else { return nil }
            return cv.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: photo)
        }
    }

    private func applySnapshot(animated: Bool) async {
        var snap = NSDiffableDataSourceSnapshot<Section, UUID>()
        snap.appendSections([.main])
        snap.appendItems(photos.map(\.id), toSection: .main)
        await dataSource.apply(snap, animatingDifferences: animated)
    }
}
```

---

### 5.4 Expandable outline / hierarchy with `NSDiffableDataSourceSectionSnapshot`

`NSDiffableDataSourceSectionSnapshot` is available for hierarchical structures (outline / expandable items). ([Apple Developer][3])

**Model:**

```swift
struct Node: Hashable, Identifiable {
    let id: UUID
    let title: String
    var children: [Node] = []

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func ==(l: Self, r: Self) -> Bool { l.id == r.id }
}
```

**Apply section snapshot to a section:**

```swift
@MainActor
func applyOutline(nodes: [Node]) async {
    // Flatten to lookup store
    var store: [UUID: Node] = [:]
    func index(_ node: Node) {
        store[node.id] = node
        node.children.forEach(index)
    }
    nodes.forEach(index)
    self.nodesByID = store

    var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<UUID>()

    func append(_ node: Node, to parent: UUID?) {
        sectionSnapshot.append([node.id], to: parent)
        for child in node.children {
            append(child, to: node.id)
        }
    }

    // Add roots
    for root in nodes { append(root, to: nil) }

    await dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true)
}
```

You can also hook into `sectionSnapshotHandlers` for expand/collapse behaviors. ([Apple Developer][16])

---

### 5.5 Reordering with `reorderingHandlers` + transactions

`UICollectionViewDiffableDataSource` supports reordering via `reorderingHandlers`. ([Apple Developer][17])
The system calls your handler after a reordering transaction so you can update your backing store. ([Apple Developer][17])

```swift
@MainActor
func enableReordering() {
    dataSource.reorderingHandlers.canReorderItem = { _ in true }

    dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
        guard let self else { return }
        // transaction.finalSnapshot / transaction.difference can be used to update your store
        // Example strategy: rebuild orderedIDs from finalSnapshot.
        let final = transaction.finalSnapshot
        self.orderedIDs = final.itemIdentifiers
    }
}
```

---

## 6. Snapshot operations cookbook

A snapshot is just a value type representing the desired state. You add/delete/move sections and items, then apply.

### Create sections + items

```swift
var snap = NSDiffableDataSourceSnapshot<Section, UUID>()
snap.appendSections([.main, .favorites])
snap.appendItems(mainIDs, toSection: .main)
snap.appendItems(favIDs, toSection: .favorites)
await dataSource.apply(snap, animatingDifferences: true)
```

### Insert items at the top of a section

```swift
var snap = dataSource.snapshot()
snap.insertItems([newID], beforeItem: snap.itemIdentifiers(inSection: .main).first!)
await dataSource.apply(snap, animatingDifferences: true)
```

### Delete items

```swift
var snap = dataSource.snapshot()
snap.deleteItems([idToDelete])
await dataSource.apply(snap, animatingDifferences: true)
```

### Move an item

```swift
var snap = dataSource.snapshot()
snap.moveItem(id, afterItem: otherID)
await dataSource.apply(snap, animatingDifferences: true)
```

### Reconfigure (lightweight refresh) vs reload

```swift
var snap = dataSource.snapshot()
snap.reconfigureItems([id]) // preferred when possible
await dataSource.apply(snap, animatingDifferences: true)
```

### “No diff, no animation” reset

```swift
await dataSource.applySnapshotUsingReloadData(fullSnapshot) //
```

---

## 7. Concurrency + performance notes (Swift 6 era)

### Apply is main-actor constrained

Modern SDK signatures show `apply` as `@MainActor` and `async`. ([Apple Developer][5])
If you were applying snapshots on background queues historically, expect Swift 6 strict concurrency to push you toward main-actor application. ([Jesse Squires][7])

### Diffing cost

Apple’s docs describe the diff as an **O(n)** operation where *n is item count*. ([Apple Developer][18])
If you have huge datasets, prefer:

* pagination / incremental loading
* stable, efficient identifiers (fast hashing/equality)
* avoid rebuilding unnecessarily-large snapshots

UIKit team guidance (as reported) suggests diffing is usually not the bottleneck compared to cell creation/layout/measurement. ([Jesse Squires][7])

### iOS 15 behavior change: `animatingDifferences: false` no longer equals “reloadData”

Historically, `animatingDifferences: false` behaved like `reloadData`, but as of iOS 15 diffing always happens; to explicitly reload without diffing use `applySnapshotUsingReloadData`. ([Jesse Squires][19])

---

## 8. Core Data integration pattern (FRC → diffable)

`NSFetchedResultsController` has a delegate method that can hand you a snapshot reference; SwiftLee shows a robust pattern for converting it to a typed snapshot, optionally reloading updated items, and applying it. ([SwiftLee][20])

A simplified outline (collection view example):

```swift
@available(iOS 13.0, *)
func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {

    guard let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<Int, NSManagedObjectID> else {
        return
    }

    var typed = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    // Optional: compute which IDs need reload (if object updated but ID unchanged)
    // typed.reloadItems(reloadIDs)

    let animate = collectionView.numberOfSections != 0
    dataSource.apply(typed, animatingDifferences: animate)
}
```

Key takeaways from the Core Data case:

* Keep your diffable data source strongly referenced. ([SwiftLee][20])
* When identifiers don’t change (e.g. `NSManagedObjectID`), you may need explicit reload/reconfigure logic for updated objects. ([SwiftLee][20])

---

## 9. Common pitfalls checklist

### ✅ Identifiers

* [ ] Section + item identifiers are **unique** and `Hashable`. ([Apple Developer][1])
* [ ] Identifiers are **stable** (hash/equality won’t change as model fields change).
* [ ] Prefer value types (struct/enum) as identifiers; class identifiers must be `NSObject` subclasses. ([Apple Developer][1])

### ✅ Data source lifecycle

* [ ] You keep a strong reference to the diffable data source (don’t rely on `tableView.dataSource` / `collectionView.dataSource`). ([SwiftLee][20])
* [ ] For table views: don’t swap out `dataSource` after configuring a diffable data source. ([Apple Developer][8])

### ✅ Cell registration

* [ ] For collection views: don’t create `UICollectionView.CellRegistration` inside the cell provider; it breaks reuse and can crash on iOS 15+. ([Apple Developer][21])

### ✅ Updating items

* [ ] Use `reconfigureItems` when you can (lighter than reload). ([Apple Developer][12])
* [ ] If you need “no diff, just reset”, use `applySnapshotUsingReloadData`. ([Apple Developer][13])

### ✅ Concurrency

* [ ] Apply snapshots on the main actor (`@MainActor`, `await MainActor.run`, etc.). ([Apple Developer][5])

---

[1]: https://developer.apple.com/documentation/uikit/nsdiffabledatasourcesnapshot-swift.struct?utm_source=chatgpt.com "NSDiffableDataSourceSnapshot | Apple Developer Documentation"
[2]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa?utm_source=chatgpt.com "UICollectionViewDiffableDataSource | Apple Developer Documentation"
[3]: https://developer.apple.com/documentation/uikit/nsdiffabledatasourcesectionsnapshot-swift.struct?utm_source=chatgpt.com "NSDiffableDataSourceSectionSnapshot - Apple Developer"
[4]: https://stackoverflow.com/questions/64081701/what-is-nsdiffabledatasourcesnapshot-reloaditems-for?utm_source=chatgpt.com "What is NSDiffableDataSourceSnapshot `reloadItems` for?"
[5]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa/apply%28_%3Aanimatingdifferences%3A%29?utm_source=chatgpt.com "apply(_:animatingDifferences:) | Apple Developer Documentation"
[6]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa/itemidentifier%28for%3A%29?utm_source=chatgpt.com "itemIdentifier (for:) | Apple Developer Documentation"
[7]: https://www.jessesquires.com/blog/2024/12/19/diffable-data-source-main-actor-inconsistency/ "UIKit DiffableDataSource API inconsistencies with Swift Concurrency annotations explained · Jesse Squires"
[8]: https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource-2euir?utm_source=chatgpt.com "UITableViewDiffableDataSource | Apple Developer Documentation"
[9]: https://developer.apple.com/documentation/uikit/uilistcontentconfiguration-swift.struct?utm_source=chatgpt.com "UIListContentConfiguration | Apple Developer Documentation"
[10]: https://developer.apple.com/documentation/uikit/updating-collection-views-using-diffable-data-sources?utm_source=chatgpt.com "Updating collection views using diffable data sources"
[11]: https://stackoverflow.com/questions/63981508/uitableview-diffable-data-source?utm_source=chatgpt.com "swift - UITableView diffable data source - Stack Overflow"
[12]: https://developer.apple.com/documentation/uikit/nsdiffabledatasourcesnapshot-swift.struct/reconfigureitems%28_%3A%29?utm_source=chatgpt.com "reconfigureItems (_:) | Apple Developer Documentation"
[13]: https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource-2euir/applysnapshotusingreloaddata%28_%3A%29?utm_source=chatgpt.com "applySnapshotUsingReloadData(_:) | Apple Developer Documentation"
[14]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa/supplementaryviewprovider-swift.typealias?utm_source=chatgpt.com "UICollectionViewDiffableDataSource.SupplementaryViewProvider | Apple ..."
[15]: https://developer.apple.com/documentation/uikit/uicollectionview/supplementaryregistration?utm_source=chatgpt.com "UICollectionView.SupplementaryRegistration - Apple Developer"
[16]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa/sectionsnapshothandlers-swift.struct?utm_source=chatgpt.com "UICollectionViewDiffableDataSource.SectionSnapshotHandlers | Apple ..."
[17]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasourcereference/reorderinghandlers?utm_source=chatgpt.com "reorderingHandlers | Apple Developer Documentation"
[18]: https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasourcereference/applysnapshot%28_%3Aanimatingdifferences%3Acompletion%3A%29?utm_source=chatgpt.com "applySnapshot(_:animatingDifferences:completion:) | Apple Developer ..."
[19]: https://www.jessesquires.com/blog/2021/07/08/diffable-data-source-behavior-changes-and-reconfiguring-cells-in-ios-15/?utm_source=chatgpt.com "Diffable data source behavior changes and reconfiguring cells in iOS 15"
[20]: https://www.avanderlee.com/swift/diffable-data-sources-core-data/ "How-to use Diffable Data Sources with Core Data - SwiftLee"
[21]: https://developer.apple.com/documentation/uikit/uicollectionview/cellregistration?utm_source=chatgpt.com "UICollectionView.CellRegistration | Apple Developer Documentation"
[22]: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa/sectionsnapshothandlers-swift.property?utm_source=chatgpt.com "sectionSnapshotHandlers | Apple Developer Documentation"
