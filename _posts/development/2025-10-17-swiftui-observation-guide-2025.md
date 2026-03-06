---
title: "The SwiftUI Observation Guide: Observable, Bindable, and Friends (2025)"
date: 2025-10-17 12:00:00 +0900
tags: [swiftui, observation, swift, ios]
---


**Tested with:**

* **Xcode:** 26.0.1 (17A400)
* **Swift:** 6.2

**Minimum platforms for Observation APIs:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+, visionOS 1.0+. ([Apple Developer][1])

**Overview:**
Swift’s **Observation** framework gives SwiftUI precise, fast change tracking with simple code. Instead of `ObservableObject` + `@Published` + Combine, you put `@Observable` on your model type, read its properties in views, and SwiftUI updates only the views that actually used those properties. Less boilerplate; better performance. ([Apple Developer][2])

**What you’ll learn**

* What `@Observable` is and how it compares to `ObservableObject`.
* How change tracking works (in plain English).
* Step-by-step setup in **Xcode 26.0.1** with **Swift 6.2**.
* Core patterns: reading values, two-way binding with `@Bindable`, ignoring properties, computed/derived state, ownership & lifetime, and concurrency.
* Common UI patterns with full, runnable examples.
* A migration guide from `ObservableObject`/`@Published`.
* Performance tips, pitfalls, and tests.
* Advanced composition & Combine interop.
* A small, complete “Habit Tracker” mini-app.
* A quick cheat sheet + FAQ.

---

## Table of Contents

* [1. What is `@Observable`?](#1-what-is-observable)
* [2. Getting Started](#2-getting-started)
* [3. Core Concepts](#3-core-concepts)
* [4. Common UI Patterns](#4-common-ui-patterns)
* [5. Migration Guide](#5-migration-guide)
* [6. Performance & Pitfalls](#6-performance--pitfalls)
* [7. Advanced Topics](#7-advanced-topics)
* [8. Mini App (end-to-end)](#8-mini-app-end-to-end)
* [9. FAQ & Troubleshooting](#9-faq--troubleshooting)
* [10. Cheat Sheet](#10-cheat-sheet)
* [References](#references)

---

## 1. What is `@Observable`?

### The problem it solves

With the old approach (`ObservableObject` + `@Published`), **any** change often forced a whole view hierarchy that observed that object to refresh. It worked, but it could be chatty and boilerplate-heavy. `@Observable` is a **macro** that teaches your type how to track reads/writes to its properties at a fine-grained level. SwiftUI then re-renders **only** views that actually used the changed properties. ([Apple Developer][2])

### Where it fits vs. `ObservableObject` / `@Published` / Combine

* **Then:** `ObservableObject` protocol, `@Published` on fields, and Combine under the hood.
* **Now:** mark your model with **`@Observable`**, read properties in the view, and use **`@Bindable`** when you need bindings. Combine is still great for streams, networking, and interop, but **Observation** is the default for SwiftUI app state. ([Apple Developer][3])

### How change tracking works (plain English)

* When SwiftUI renders a view, it **records** which `@Observable` properties were read.
* If one of those properties changes later, SwiftUI **invalidates** only the views that read it.
* Computed properties are fine: if a computed getter reads `firstName` and `lastName`, changing either will re-render views that read the computed value. ([Apple Developer][2])

---

## 2. Getting Started

### Project setup (Xcode 26.0.1, Swift 6.2)

1. Create a **SwiftUI App** project in **Xcode 26.0.1**.
2. Set your **Deployment Target** to **iOS 17** (or macOS 14, etc.) to use Observation APIs.
3. Add `import Observation` in files that declare or use `@Observable`.
   (Observation ships with the platform SDK; no extra package needed.) ([Apple Developer][1])

### Hello, `@Observable` (runnable)

```swift
import SwiftUI
import Observation

@available(iOS 17.0, macOS 14.0, *)
@Observable
final class CounterModel {
    var count = 0
}

@available(iOS 17.0, macOS 14.0, *)
struct ContentView: View {
    // Own the model at the view's root
    @State private var model = CounterModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(model.count)")
                .font(.largeTitle)
            Button("Increment") { model.count += 1 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

**What’s happening here?**
`@Observable` makes `CounterModel` track reads/writes. The view reads `model.count`. When you tap the button, the write to `count` invalidates only the text that used it, so the UI updates.

---

## 3. Core Concepts

### 3.1 Defining an observable model (recommended patterns)

```swift
import Observation

@available(iOS 17.0, *)
@Observable
final class Profile {
    var firstName = ""
    var lastName  = ""
    var age       = 0

    // Computed/derived property
    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }
}
```

**What’s happening here?**
This is a plain Swift class with stored and computed properties. No `@Published`. The macro synthesizes the observation plumbing. Computed properties work because their getters read stored properties, which are tracked. ([Apple Developer][4])

---

### 3.2 Reading values in SwiftUI views

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
struct ProfileCard: View {
    @State private var profile = Profile()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profile.fullName).font(.title2)
            Text("Age \(profile.age)")
        }
        .padding()
        .task {
            // Simulate data load
            try? await Task.sleep(for: .seconds(1))
            profile.firstName = "Lee"
            profile.lastName  = "Na-na"
            profile.age       = 27
        }
    }
}
```

**What’s happening here?**
The view reads `fullName` and `age`. When those underlying fields change, SwiftUI re-renders this view. No Combine required. ([Apple Developer][2])

---

### 3.3 Two-way binding with `@Bindable`

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
@Observable
final class Settings {
    var username = ""
    var sendNotifications = true
}

@available(iOS 17.0, *)
struct SettingsForm: View {
    @State private var settings = Settings()

    var body: some View {
        // Create local bindings to an @Observable model
        @Bindable var settings = settings

        Form {
            TextField("Username", text: $settings.username)
            Toggle("Notifications", isOn: $settings.sendNotifications)
        }
    }
}
```

**What’s happening here?**
`@Bindable` lets a view expose **`Binding`**s for properties of an `@Observable` model so form controls can edit them. This replaces the old `@ObservedObject` + `$object.property` dance. ([Apple Developer][5])

---

### 3.4 Ignore properties with `@ObservationIgnored`

```swift
import Observation

@available(iOS 17.0, *)
@Observable
final class ImageLoader {
    var url: URL?
    @ObservationIgnored var cacheKey: String? // expensive/ephemeral
    @ObservationIgnored var logger = Logger() // non-UI concern
}
```

**What’s happening here?**
Mark fields you **don’t** want to trigger updates. Use this for caches, helpers, loggers, or heavy blobs. If code can access a property but UI shouldn’t react to it, ignore it. ([Apple Developer][6])

---

### 3.5 Computed properties & derived state

```swift
import Observation

@available(iOS 17.0, *)
@Observable
final class Cart {
    var items: [Double] = [] // prices

    var subtotal: Double { items.reduce(0, +) }
    var tax: Double { subtotal * 0.1 }
    var total: Double { subtotal + tax }
}
```

**What’s happening here?**
Views can read `total`. Changing `items` causes `subtotal`, then `total` to change, and only views that read those values will redraw. That’s the benefit of per-property tracking. ([Apple Developer][2])

---

### 3.6 Ownership & lifetime patterns

**Root ownership:** Hold your `@Observable` in `@State` at feature roots. Pass it down directly or via the SwiftUI **Environment**:

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
@Observable final class Library { var books: [String] = [] }

@available(iOS 17.0, *)
struct RootView: View {
    @State private var library = Library()

    var body: some View {
        BooksList()
            .environment(library) // inject observable instance
    }
}

@available(iOS 17.0, *)
struct BooksList: View {
    @Environment(Library.self) private var library

    var body: some View {
        List(library.books, id: \.self, rowContent: Text.init)
    }
}
```

**Why?**
With Observation, you inject models using `environment(_:)` and read them with `@Environment(MyModel.self)`, not `@EnvironmentObject`. This keeps types explicit and avoids Combine. ([Apple Developer][7])

---

### 3.7 Concurrency notes (`@MainActor`)

* `@Observable` itself **doesn’t** force thread affinity. SwiftUI expects UI state changes on the **main actor**. If your model is mutated from async/background work, make the type or mutating methods `@MainActor`. ([Swift Forums][8])

```swift
import Observation

@available(iOS 17.0, *)
@MainActor
@Observable
final class Feed {
    var items: [String] = []

    func refresh() async {
        let loaded = await fetch()
        items = loaded
    }
}
```

**What’s happening here?**
Annotating the type `@MainActor` keeps reads/writes synchronized with the UI thread. That’s the safest default for view models that drive SwiftUI. ([Apple Developer][9])

---

## 4. Common UI Patterns

> All examples target **iOS 17+** and compile in **Xcode 26.0.1 / Swift 6.2**.

### 4.1 Forms with live validation

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
@Observable
final class Account {
    var email = ""
    var password = ""

    var isValid: Bool {
        email.contains("@") && password.count >= 8
    }
}

@available(iOS 17.0, *)
struct AccountForm: View {
    @State private var account = Account()

    var body: some View {
        @Bindable var account = account
        Form {
            TextField("Email", text: $account.email)
                .keyboardType(.emailAddress)
            SecureField("Password (8+)", text: $account.password)
            Button("Create Account") { /* submit */ }
                .disabled(!account.isValid)
        }
    }
}
```

**What’s happening here?**
`isValid` is computed. Edits to `email` or `password` recompute it and toggle the button automatically.

---

### 4.2 Lists with add/remove/edit (nested models)

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
@Observable
final class Todo: Identifiable {
    let id = UUID()
    var title: String
    var done: Bool = false
    init(title: String) { self.title = title }
}

@available(iOS 17.0, *)
@Observable
final class TodoStore {
    var items: [Todo] = []
    func add(_ title: String) { items.append(Todo(title: title)) }
    func remove(at offsets: IndexSet) { items.remove(atOffsets: offsets) }
}

@available(iOS 17.0, *)
struct TodoListView: View {
    @State private var store = TodoStore()
    @State private var newTitle = ""

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New to-do", text: $newTitle)
                        Button("Add") {
                            guard !newTitle.isEmpty else { return }
                            store.add(newTitle); newTitle = ""
                        }
                    }
                }
                Section {
                    ForEach(store.items) { todo in
                        NavigationLink(todo.title) {
                            TodoDetail(todo: todo)
                        }
                    }
                    .onDelete(perform: store.remove)
                }
            }
            .navigationTitle("To-Dos")
        }
    }
}

@available(iOS 17.0, *)
struct TodoDetail: View {
    // Two-way edits on a nested observable
    @Bindable var todo: Todo

    var body: some View {
        Form {
            TextField("Title", text: $todo.title)
            Toggle("Done", isOn: $todo.done)
        }
        .navigationTitle("Edit")
    }
}
```

**What’s happening here?**
Each `Todo` is `@Observable`. Editing a detail view updates just the corresponding row because SwiftUI tracked reads to that specific item. ([Apple Developer][2])

---

### 4.3 Search + filtering + sorting

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
@Observable
final class PeopleStore {
    var all: [String] = []
    var query = ""
    var ascending = true

    var filtered: [String] {
        let f = query.isEmpty ? all : all.filter { $0.localizedCaseInsensitiveContains(query) }
        return ascending ? f.sorted() : f.sorted().reversed()
    }
}

@available(iOS 17.0, *)
struct PeopleView: View {
    @State private var store = PeopleStore()

    var body: some View {
        @Bindable var store = store
        VStack {
            TextField("Search", text: $store.query)
                .textFieldStyle(.roundedBorder)
            Picker("Sort", selection: $store.ascending) {
                Text("A→Z").tag(true); Text("Z→A").tag(false)
            }.pickerStyle(.segmented)
            List(store.filtered, id: \.self, rowContent: Text.init)
        }
        .padding()
        .task { store.all = ["Kim", "Choi", "Park", "Lee", "Jung"] }
    }
}
```

**What’s happening here?**
`filtered` derives from `all`, `query`, and `ascending`. The list recomputes when any of those change—no manual invalidation.

---

### 4.4 Master–detail navigation

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
struct MasterDetailView: View {
    @State private var store = TodoStore()

    var body: some View {
        NavigationSplitView {
            List(store.items) { todo in
                NavigationLink(todo.title, value: todo.id)
            }
            .navigationTitle("All")
        } detail: {
            DetailRouter(store: store)
        }
        .navigationDestination(for: UUID.self) { id in
            if let todo = store.items.first(where: { $0.id == id }) {
                TodoDetail(todo: todo)
            }
        }
        .task { store.items = [Todo(title: "Read"), Todo(title: "Walk")] }
    }
}

@available(iOS 17.0, *)
struct DetailRouter: View {
    let store: TodoStore
    var body: some View {
        Text("Select an item")
            .foregroundStyle(.secondary)
    }
}
```

**What’s happening here?**
We keep a single `TodoStore` and navigate by IDs. When a `Todo` changes, only the detail that used it refreshes.

---

### 4.5 Two-way binding inside reusable components

```swift
import SwiftUI

@available(iOS 17.0, *)
struct LabeledToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
    }
}
```

**What’s happening here?**
Reusable views still take `@Binding`. Upstream, you can pass `$settings.sendNotifications` made available via `@Bindable`.

---

### 4.6 Simple persistence with `@AppStorage` (JSON blob)

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
@Observable
final class NotesStore: Codable {
    var notes: [String] = []
}

@available(iOS 17.0, *)
struct NotesView: View {
    @AppStorage("notes.json") private var raw = Data()
    @State private var store = NotesStore()
    @State private var text = ""

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 12) {
            HStack {
                TextField("New note", text: $text)
                Button("Add") { guard !text.isEmpty else { return }; store.notes.append(text); text = "" }
            }
            List(store.notes, id: \.self, rowContent: Text.init)
            Button("Save") { raw = (try? JSONEncoder().encode(store)) ?? Data() }
            Button("Load") { if let s = try? JSONDecoder().decode(NotesStore.self, from: raw) { store = s } }
        }
        .padding()
    }
}
```

**What’s happening here?**
We serialize the whole model to `Data` inside `@AppStorage`. For production, prefer files or `SwiftData/CoreData`, but this is a minimal, runnable example.

---

## 5. Migration Guide

### 5.1 Before → After (step-by-step)

**Before (Combine):**

```swift
import Combine

final class Player: ObservableObject {
    @Published var name = ""
    @Published var score = 0
}
```

**After (Observation):**

```swift
import Observation

@Observable
final class Player {
    var name = ""
    var score = 0
}
```

**Views:**

* Replace `@StateObject var player = Player()` **with** `@State var player = Player()`.
* Replace `@ObservedObject var player: Player` **with** `let player: Player` (or pass in and mark local `@Bindable`).
* Replace `@EnvironmentObject var player: Player` **with** `@Environment(Player.self) var player` and inject using `.environment(player)` on an ancestor. ([Apple Developer][3])

**Why `@State`?**
For `@Observable` models, SwiftUI owns lifecycle with `@State` (instead of `@StateObject`). That’s the intended pattern after migration. ([Apple Developer][3])

### 5.2 Mixed codebases

You can migrate gradually: SwiftUI supports both models during transition. Start with one type, swap its usage, and proceed feature by feature. ([Apple Developer][3])

---

## 6. Performance & Pitfalls

* **Observed vs. not observed:** Views only update if they previously *read* a property that changed. If the view didn’t read it, no update. Use previews/logging to verify what’s read. ([Apple Developer][2])
* **Large collections:** Mutating array elements (e.g., toggling a `Todo.done`) is fine; if the UI read those fields, it updates. For huge lists, keep models small and derived computations cheap.
* **Avoid unintended updates:** Mark caches, helpers, timers, and dependency objects as `@ObservationIgnored`. ([Apple Developer][6])
* **Concurrency:** `@Observable` is **BYO synchronization**. For UI state, prefer `@MainActor` or funnel mutations to the main actor. ([Swift Forums][8])
* **Testing observation:** Use `withObservationTracking(_:, onChange:)` to assert that a change triggers invalidation. (Re-establish tracking if you expect multiple notifications.) ([Apple Developer][10])

**Example test (XCTest):**

```swift
import XCTest
import Observation

@Observable final class Counter { var value = 0 }

final class ObservationTests: XCTestCase {
    func testCounterNotifies() {
        let counter = Counter()
        var didChange = false

        _ = withObservationTracking({ _ = counter.value }) {
            didChange = true
        }

        XCTAssertFalse(didChange)
        counter.value += 1
        // Spin the runloop to allow the change handler to fire.
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        XCTAssertTrue(didChange)
    }
}
```

**What’s happening here?**
We track reads of `counter.value`. Changing it calls `onChange` once. Re-establish tracking if you need subsequent notifications. ([Apple Developer][10])

---

## 7. Advanced Topics

### 7.1 Derived models / composition

You can build “derived” view models that read other `@Observable` models. As long as the derived computed properties read source properties, views update when sources change. (Same idea as selectors/derived state in other frameworks.) ([Apple Developer][2])

### 7.2 Modularization & sharing across features

Inject shared models via `environment(_:)` at your app or feature root. Downstream views fetch them with `@Environment(MyType.self)`. This avoids singletons and keeps modules testable. ([Apple Developer][11])

### 7.3 Interop with Combine

Still using Combine publishers? No problem. Keep them at the edges (networking, timers), and write results into your `@Observable` model on the main actor so SwiftUI updates correctly. If you need to observe an `@Observable` outside SwiftUI, bridge with `withObservationTracking` or wrap it as an `AsyncStream` for `async` sequences. ([Apple Developer][10])

---

## 8. Mini App (end-to-end): **Habit Tracker**

**Files:**

**HabitModels.swift**

```swift
import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
final class Habit: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String
    var isComplete: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, notes: String = "", isComplete: Bool = false, createdAt: Date = .now) {
        self.id = id; self.title = title; self.notes = notes; self.isComplete = isComplete; self.createdAt = createdAt
    }
}

@available(iOS 17.0, *)
@Observable
final class HabitStore: Codable {
    var habits: [Habit] = []
    var search = ""
    var showCompleted = true
    var sortNewestFirst = true

    var filtered: [Habit] {
        var list = habits.filter { showCompleted || !$0.isComplete }
        if !search.isEmpty { list = list.filter { $0.title.localizedCaseInsensitiveContains(search) } }
        return sortNewestFirst ? list.sorted { $0.createdAt > $1.createdAt }
                               : list.sorted { $0.createdAt < $1.createdAt }
    }

    func add(title: String) { habits.append(Habit(title: title)) }
    func remove(at offsets: IndexSet) { habits.remove(atOffsets: offsets) }
    func toggle(_ habit: Habit) { habit.isComplete.toggle() }
}
```

**Storage.swift** (very small JSON persistence)

```swift
import Foundation

struct Storage {
    static func save<T: Codable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }
    static func load<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("habits.json")
    }
}
```

**HabitViews.swift**

```swift
import SwiftUI
import Observation

@available(iOS 17.0, *)
struct HabitListView: View {
    @State private var store = HabitStore()
    @State private var newTitle = ""

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New habit", text: $newTitle)
                        Button("Add") { guard !newTitle.isEmpty else { return }; store.add(title: newTitle); newTitle = "" }
                    }
                }
                Section {
                    ForEach(store.filtered) { habit in
                        NavigationLink(habit.title) { HabitDetailView(habit: habit) }
                            .swipeActions {
                                Button { store.toggle(habit) } label: { Text(habit.isComplete ? "Undo" : "Done") }
                                .tint(.green)
                            }
                    }.onDelete(perform: store.remove)
                }
            }
            .searchable(text: $store.search)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle("Show Completed", isOn: $store.showCompleted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("Newest First", isOn: $store.sortNewestFirst)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Load")   { if let s = try? Storage.load(HabitStore.self, from: Storage.fileURL) { store = s } }
                    Button("Save")   { try? Storage.save(store, to: Storage.fileURL) }
                }
            }
            .navigationTitle("Habits")
        }
    }
}

@available(iOS 17.0, *)
struct HabitDetailView: View {
    @Bindable var habit: Habit

    var body: some View {
        Form {
            TextField("Title", text: $habit.title)
            TextField("Notes", text: $habit.notes, axis: .vertical)
                .lineLimit(3...6)
            Toggle("Completed", isOn: $habit.isComplete)
            LabeledContent("Created") { Text(habit.createdAt.formatted()) }
        }
        .navigationTitle("Edit")
    }
}
```

**App.swift**

```swift
import SwiftUI

@main
struct HabitApp: App {
    var body: some Scene {
        WindowGroup { HabitListView() }
    }
}
```

**What’s happening here?**

* `HabitStore` is the single source of truth (owned in `@State` at the list root).
* Children read or edit `Habit` instances using `@Bindable`.
* Search/filter/sort are derived properties.
* JSON persistence is minimal but shows how to save/load the **whole** observed graph.

---

## 9. FAQ & Troubleshooting

**“Why didn’t my view update?”**
Because the view must have *read* the property that changed during a previous render. Make sure the UI actually references the property, or bind directly via `@Bindable`. ([Apple Developer][2])

**“Should I use `@State`, `@StateObject`, or store my `@Observable` another way?”**
Use **`@State`** to own an `@Observable` model in a view, **`@Environment(MyType.self)`** for shared models, and **`let`** when you simply pass it down. `@StateObject` is for `ObservableObject` (Combine) models. ([Apple Developer][3])

**“How do I ignore expensive properties?”**
Add `@ObservationIgnored` to skip change tracking (caches, loggers, large images, etc.). ([Apple Developer][6])

**“Do I need `@MainActor`?”**
`@Observable` doesn’t enforce threading. If the model drives UI, prefer `@MainActor` or ensure mutations occur on the main actor. ([Swift Forums][8])

**“Can I observe outside SwiftUI?”**
Yes—use `withObservationTracking(_:onChange:)` to react to property changes in plain Swift code. Re-register tracking for repeated notifications. ([Apple Developer][10])

---

## 10. Cheat Sheet

**Create a model**

```swift
@Observable final class Model { var name = "" } // import Observation
```

**Own it at a root**

```swift
@State private var model = Model()
```

**Edit in a form**

```swift
@Bindable var model = model
TextField("Name", text: $model.name)
```

**Share via Environment**

```swift
RootView().environment(model)       // inject
@Environment(Model.self) var model  // read
```

**Ignore stuff**

```swift
@ObservationIgnored var cache = Cache()
```

**Concurrency**

```swift
@MainActor @Observable final class VM { /* ... */ }
```

**Testing notifications**

```swift
withObservationTracking({ _ = model.name }) { /* called on change */ }
```

---

## References

* **Xcode & Swift versions**

  * *Xcode 26.0.1 (17A400) release note & news* (confirms current stable). ([Apple Developer][1])
  * *Xcode 26 includes Swift 6.2* (release notes). ([Apple Developer][12])
  * *Swift 6.2 Released* (official Swift.org blog). ([Swift.org][13])

* **Observation docs & sessions**

  * *Observation framework overview.* ([Apple Developer][4])
  * *`@Observable` type doc.* ([Apple Developer][14])
  * *`@Bindable` doc.* ([Apple Developer][5])
  * *`@ObservationIgnored` doc.* ([Apple Developer][6])
  * *Migrating from `ObservableObject` to `@Observable`* (official guide). ([Apple Developer][3])
  * *Discover Observation in SwiftUI* (WWDC23). ([Apple Developer][2])

* **Environment integration**

  * *Use Environment with Observable types; inject with `environment(_:)`.* ([Apple Developer][11])

* **Concurrency guidance**

  * *SwiftUI + main actor behavior (WWDC25 Concurrency in SwiftUI).* ([Apple Developer][9])
  * *Threading note: `@Observable` is BYO synchronization.* ([Swift Forums][8])

* **Testing & utilities**

  * *`withObservationTracking(_:onChange:)` API.* ([Apple Developer][10])

---

### Learn more

* Apple Doc: **Managing model data in your app** (Observation in SwiftUI). ([Apple Developer][15])
* Apple Doc: **Observation module** index. ([Apple Developer][4])
* Apple Video: **Discover Observation in SwiftUI** (best deep dive). ([Apple Developer][2])

---

**You’re set!** Try dropping these snippets into a fresh **Xcode 26.0.1 / Swift 6.2** project (iOS 17+). As you edit your `@Observable` models and use `@Bindable`, watch how only the UI that depends on changed data updates—clean, fast, and easy.

[1]: https://developer.apple.com/news/releases/?id=09222025m&utm_source=chatgpt.com "Xcode 26.0.1 (17A400) - Releases - Apple Developer"
[2]: https://developer.apple.com/videos/play/wwdc2023/10149/?utm_source=chatgpt.com "Discover Observation in SwiftUI - WWDC23 - Apple Developer"
[3]: https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro?utm_source=chatgpt.com "Migrating from the Observable Object protocol to the ... - Apple Developer"
[4]: https://developer.apple.com/documentation/Observation?utm_source=chatgpt.com "Observation | Apple Developer Documentation"
[5]: https://developer.apple.com/documentation/swiftui/bindable?utm_source=chatgpt.com "Bindable | Apple Developer Documentation"
[6]: https://developer.apple.com/documentation/observation/observationignored%28%29/?utm_source=chatgpt.com "ObservationIgnored() | Apple Developer Documentation"
[7]: https://developer.apple.com/documentation/swiftui/environmentobject?utm_source=chatgpt.com "EnvironmentObject | Apple Developer Documentation"
[8]: https://forums.swift.org/t/observable-macro-conflicting-with-mainactor/67309?utm_source=chatgpt.com "@Observable macro conflicting with @MainActor - Swift Forums"
[9]: https://developer.apple.com/videos/play/wwdc2025/266/?utm_source=chatgpt.com "Explore concurrency in SwiftUI - WWDC25 - Videos - Apple Developer"
[10]: https://developer.apple.com/documentation/observation/withobservationtracking%28_%3Aonchange%3A%29?utm_source=chatgpt.com "withObservationTracking(_:onChange:) | Apple Developer Documentation"
[11]: https://developer.apple.com/documentation/swiftui/environment?utm_source=chatgpt.com "Environment | Apple Developer Documentation"
[12]: https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes?utm_source=chatgpt.com "Xcode 26 Release Notes | Apple Developer Documentation"
[13]: https://www.swift.org/blog/swift-6.2-released/?utm_source=chatgpt.com "Swift 6.2 Released | Swift.org"
[14]: https://developer.apple.com/documentation/observation/observable?utm_source=chatgpt.com "Observable | Apple Developer Documentation"
[15]: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app?utm_source=chatgpt.com "Managing model data in your app - Apple Developer"
