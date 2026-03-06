---
title: "Copyable vs Noncopyable in Swift: A Friendly, Step-by-Step Guide"
date: 2025-10-14 12:00:00 +0900
tags: [swift, ownership, copyable, noncopyable, concurrency]
---


## Table of Contents

1. **Big Picture (Why this matters)**
2. **What “copying” means in Swift**
   2.1 Value types (struct/enum)
   2.2 Reference types (class)
   2.3 Implicit copies vs explicit copies
3. **`Copyable` and `~Copyable` (noncopyable)**
   3.1 The idea
   3.2 Declaring a noncopyable type
   3.3 Lifetime and `deinit` for noncopyable value types
4. **Ownership when calling functions**
   4.1 `borrowing`
   4.2 `consuming`
   4.3 `inout`
   4.4 The `copy` and `consume` operators
   4.5 Quick comparison table
5. **Beginner examples (Copyable types)**
6. **Beginner → Intermediate (Declaring noncopyable)**
7. **Intermediate (borrowing vs inout vs consuming)**
8. **Intermediate → Advanced (methods, `deinit`, and enums)**
9. **Generics, extensions, and conditional conformances**
10. **Common pitfalls (and what the compiler says)**
11. **Practice problems**
    – Set A (Beginner)
    – Set B (Intermediate)
    – Set C (Advanced)
12. **Answer key (with fixes and explanations)**

---

## 1) Big Picture (Why this matters)

Swift used to quietly copy your values whenever needed. That’s easy, but sometimes **copying is wrong** (for example: a “single‑use ticket” should not be duplicated) or **too expensive** (large structs). Newer Swift lets you be **clear about ownership**: you can say “this function just borrows your value”, “this function takes it and you can’t use it again”, or “this function mutates it in place”.

**Goal of this guide:** Build a simple mental model and then practice with real code.

> **Mental model**: *Copyable* values are like photocopies of a paper. *Noncopyable* values are like your real passport — you can pass it around to check it (borrow), give it to someone (consume), or update it (inout), but you can’t clone it.

---

## 2) What “copying” means in Swift

### 2.1 Value types (struct/enum)

* Assigning or passing a struct/enum normally **copies the bits**.
* Example: `var a = Point(x: 1, y: 2); var b = a` → `b` is a **separate** value.

### 2.2 Reference types (class)

* Assigning or passing a class **copies the reference**, **not** the object.
* Example: `var a = Box(10); var b = a` → `a` and `b` **point to the same** object.

### 2.3 Implicit copies vs explicit copies

* By default, Swift **may copy implicitly** to make your code work.
* With the new ownership features, you can **turn off implicit copies** inside certain functions and **require `copy x`** to be explicit when needed.

---

## 3) `Copyable` and `~Copyable` (noncopyable)

### 3.1 The idea

* **`Copyable`** is a *marker* that says a type can be copied. Most types are `Copyable` by default.
* **`~Copyable`** means “**not** copyable”. You opt out of copying.

### 3.2 Declaring a noncopyable type

```swift
struct SingleUseTicket: ~Copyable {
    let id: Int
}
```

* You can **move** or **borrow** a `SingleUseTicket`, but you **can’t duplicate** it.

### 3.3 Lifetime and `deinit` for noncopyable value types

Because a noncopyable value has a unique identity, **structs and enums marked `~Copyable` can have a `deinit`**, which runs at the end of the value’s lifetime (similar to classes):

```swift
struct FileHandle: ~Copyable {
    let path: String
    var isOpen = true

    deinit {
        if isOpen { print("Auto‑closing \(path)") }
    }

    mutating func write(_ text: String) {
        precondition(isOpen)
        print("→ write to", path, ":", text)
    }
}
```

> Tip: You can also write **consuming methods** on noncopyable types (see §8). A consuming method takes ownership of `self` and ends its lifetime by the end of the call.

---

## 4) Ownership when calling functions

There are **three** main ways to pass a value:

### 4.1 `borrowing`

* The function **borrows** a read‑only view temporarily.
* Caller keeps ownership. Callee **can’t keep** or **consume** it.

```swift
func inspect(_ t: borrowing SingleUseTicket) {
    print("Ticket #", t.id)
    // t can’t be consumed or stored beyond this call
}
```

### 4.2 `consuming`

* The function **takes ownership**. After the call, the **caller can’t use** the value anymore.

```swift
func use(_ t: consuming SingleUseTicket) {
    // t is now owned here; caller loses it
    print("Using ticket #", t.id)
    // t’s lifetime ends by the end of this function
}

var ticket = SingleUseTicket(id: 42)
use(ticket)
// ❌ error if we try: print(ticket)  // “'ticket' used after consume”
```

### 4.3 `inout`

* The function gets **exclusive, mutable access** to the caller’s value. It **must return it** to the caller.

```swift
func punch(_ t: inout SingleUseTicket) {
    print("Punching #", t.id)
    // can mutate fields if they’re var
}

var t2 = SingleUseTicket(id: 7)
punch(&t2)   // caller still owns t2 afterwards
```

### 4.4 The `copy` and `consume` operators

* **`copy x`**: make an **explicit copy** (only for `Copyable` values). Often required inside `borrowing`/`consuming` functions when you need a duplicate.
* **`consume x`**: **move** the current value out of a local/parameter, **ending that binding’s lifetime**.

```swift
func duplicate(_ s: borrowing String) -> (String, String) {
    let a = copy s
    let b = copy s
    return (a, b)
}

var fh = FileHandle(path: "/tmp/log.txt")
let owned = consume fh
// fh is now invalid here; we moved it into `owned`
```

### 4.5 Quick comparison table

| How you pass | Callee can read? | Callee can mutate? | Callee can keep/consume? | Caller can still use after? |
| ------------ | ---------------- | ------------------ | ------------------------ | --------------------------- |
| `borrowing`  | ✅                | ❌                  | ❌                        | ✅                           |
| `inout`      | ✅                | ✅                  | ❌                        | ✅ (with mutations)          |
| `consuming`  | ✅                | ✅                  | ✅ (owns it)              | ❌                           |

---

## 5) Beginner examples (Copyable types)

### Example 5.1 – Struct copy vs class reference

```swift
struct Point { var x: Int; var y: Int }
class Box { var value: Int; init(_ v: Int) { value = v } }

var p1 = Point(x: 1, y: 2)
var p2 = p1            // copies bits
p2.x = 99
print(p1.x, p2.x)     // 1, 99

let b1 = Box(10)
let b2 = b1           // copies reference
b2.value = 99
print(b1.value, b2.value) // 99, 99 (same object)
```

### Example 5.2 – `borrowing` with explicit `copy`

```swift
func shoutTwice(_ s: borrowing String) -> String {
    // `s` isn’t implicitly copyable here
    let twice = copy s + " " + copy s
    return twice.uppercased()
}
print(shoutTwice("hello"))  // HELLO HELLO
```

---

## 6) Beginner → Intermediate (Declaring noncopyable)

### Example 6.1 – A single‑use ticket

```swift
struct SingleUseTicket: ~Copyable { let id: Int }

func scan(_ t: borrowing SingleUseTicket) {
    print("Scanning #", t.id)
}

func enter(_ t: consuming SingleUseTicket) {
    print("Welcome with #", t.id)
}

var t = SingleUseTicket(id: 101)
scan(t)      // OK (borrow)
enter(t)     // OK (consume)
// print(t)  // ❌ error: 't' used after consume
```

### Example 6.2 – Noncopyable + `deinit`

```swift
struct TempDir: ~Copyable {
    let path: String
    deinit { print("Cleaning up", path) }
}

func makeAndDrop() {
    var d = TempDir(path: "/tmp/work")
    // end of scope → runs deinit automatically
}
makeAndDrop()
```

---

## 7) Intermediate (borrowing vs inout vs consuming)

```swift
struct Counter: ~Copyable {
    var value: Int
    mutating func inc() { value += 1 }
    consuming func take() -> Int { return value }
}

func read(_ c: borrowing Counter) {
    print("peek:", c.value)     // read only
}

func bump(_ c: inout Counter) {
    c.inc()                      // mutate in place
}

func drain(_ c: consuming Counter) -> Int {
    c.take()                     // take ownership and end lifetime
}

var c = Counter(value: 0)
read(c)             // borrow
bump(&c)            // inout, c now 1
let n = drain(c)    // consume, caller loses `c`
print(n)
// print(c.value)   // ❌ error: use after consume
```

**Key differences:**

* `borrowing` → easy, safe read.
* `inout` → exclusive mutation, must give value back.
* `consuming` → moves ownership to the callee.

---

## 8) Intermediate → Advanced (methods, `deinit`, and enums)

### 8.1 Consuming methods on noncopyable types

```swift
struct Socket: ~Copyable {
    var isOpen = true
    mutating func send(_ s: String) { precondition(isOpen); print("→", s) }
    consuming func close() { print("closing"); /* end lifetime */ }
}

var s = Socket()
s.send("PING")
s.close()        // after this, `s` is gone
```

### 8.2 Pattern matching with noncopyable enums

```swift
enum Resource: ~Copyable {
    case open(Socket)
    case closed
}

func describe(_ r: consuming Resource) {
    switch consume r {              // consume for a full match
    case .open(let s): print("open")
    case .closed:       print("closed")
    }
}
```

> Note: Newer toolchains improve “borrowing switches” too, but `switch consume` is a good mental model today.

---

## 9) Generics, extensions, and conditional conformances

### 9.1 Generic algorithms that work with **copyable** inputs

```swift
// Only works for types you can duplicate
func pair<T: Copyable>(_ x: borrowing T) -> (T, T) {
    (copy x, copy x)
}
```

### 9.2 Generic functions that can accept **noncopyable** inputs

```swift
// Works for any T as long as we only *borrow* it
func logType<T>(_ x: borrowing T) { /* read-only use of x */ }
```

> If you need to *consume* a generic `T`, mark the parameter `consuming T` and make sure your algorithm doesn’t require copying. If you need duplication, constrain `T: Copyable` and use `copy`.

### 9.3 Extensions and conformances

You can extend your noncopyable types and add `consuming` or `mutating` methods. Protocol conformances for noncopyable types are available in modern Swift toolchains; check your compiler version if you hit a limitation.

```swift
protocol Closable { consuming func close() }

struct Ticket: ~Copyable { let id: Int }
extension Ticket: Closable { consuming func close() { /* ... */ } }
```

---

## 10) Common pitfalls (and what the compiler says)

1. **Trying to copy a noncopyable value**

```swift
let t = SingleUseTicket(id: 1)
let t2 = t  // ❌ error: value of noncopyable type 'SingleUseTicket' cannot be copied
```

*Fix:* pass it as `borrowing`/`inout`, or move it using `consume` / `consuming`.

2. **Using a value after it’s been consumed**

```swift
var t = SingleUseTicket(id: 2)
let moved = consume t
print(t)      // ❌ error: 't' used after consume
```

*Fix:* Only use `moved` afterwards.

3. **Forgetting ownership on function parameters**

```swift
// Needs an ownership annotation for noncopyable
func bad(_ t: SingleUseTicket) { }
//    ^ may be rejected for noncopyable; use borrowing/consuming/inout
```

*Fix:* choose one: `borrowing`, `inout`, or `consuming`.

4. **Capturing a noncopyable local in a closure** (advanced)

* Once a local escapes into a closure, you generally **can’t consume it later**. Keep noncopyable lifetimes simple: consume them **before** they escape.

5. **Switching on a noncopyable enum without `consume`**

```swift
func f(_ r: Resource) {  // if Resource is noncopyable
    // switch r   // ❌ often needs: switch consume r
}
```

*Fix:* `switch consume r` (or use a borrowing switch in newer toolchains).

6. **Trying to consume a global**

* Consuming noncopyable globals is limited. Wrap the operation in a function where the value is local and can be consumed safely.

---

## 11) Practice problems

### Set A (Beginner)

A1) Write a function `centered(_ p: borrowing Point) -> Point` that returns a **new** `Point` at `(p.x - 10, p.y - 10)` using `copy`.

A2) Turn this into a noncopyable type:

```swift
struct Token { let id: Int }
```

Make a function `redeem(_:)` that **consumes** the token.

A3) Why does this fail?

```swift
struct Badge: ~Copyable { let id: Int }
let b = Badge(id: 1)
let c = b   // ???
```

Explain what the compiler is telling you in plain words.

---

### Set B (Intermediate)

B1) Make `Counter` noncopyable and add:

```swift
mutating func add(_ n: Int)
consuming func take() -> Int
```

Write three functions: `peek(_:)` (borrowing), `bump(_:)` (inout), and `drain(_:)` (consuming) and show how calls affect the caller’s variable.

B2) Write a generic function `duplicateIfCopyable`:

```swift
func duplicateIfCopyable<T>(_: borrowing T) -> (T?, T?)
```

* If `T: Copyable`, return `(x, x)` using `copy`.
* Otherwise, return `(nil, nil)`. *(Hint: use an overload with `T: Copyable`.)*

B3) For a noncopyable enum

```swift
enum Door: ~Copyable { case open; case closed }
```

write a function that prints the state using `switch consume`.

---

### Set C (Advanced)

C1) Add a `deinit` to a noncopyable `TempFile` that prints when it cleans up. Show a timeline where `deinit` runs.

C2) Define a protocol:

```swift
protocol Closable { consuming func close() }
```

Make a noncopyable type `Socket: ~Copyable` conform and implement `close()`.

C3) Show why this code is rejected and fix it:

```swift
func pair<T>(_ x: borrowing T) -> (T, T) { (x, x) }
```

*(No copying is allowed on a borrowing parameter unless you say it.)*

---

## 12) Answer key (with fixes and explanations)

### Set A

**A1)**

```swift
struct Point { var x: Int; var y: Int }
func centered(_ p: borrowing Point) -> Point {
    var c = copy p
    c.x -= 10; c.y -= 10
    return c
}
```

*Why:* `p` is not implicitly copyable here, so we use `copy p` explicitly.

**A2)**

```swift
struct Token: ~Copyable { let id: Int }
func redeem(_ t: consuming Token) { print("Redeemed", t.id) }
```

*Why:* A noncopyable token can be **consumed** once to prevent reuse.

**A3)** The compiler says the value **can’t be copied**. Assigning `b` to `c` would duplicate a `Badge`, which is forbidden for `~Copyable` types.

---

### Set B

**B1)**

```swift
struct Counter: ~Copyable {
    var value: Int
    mutating func add(_ n: Int) { value += n }
    consuming func take() -> Int { value }
}

func peek(_ c: borrowing Counter) { print(c.value) }
func bump(_ c: inout Counter) { c.add(1) }
func drain(_ c: consuming Counter) -> Int { c.take() }

var c = Counter(value: 0)
peek(c)            // prints 0
bump(&c)           // c.value = 1
let v = drain(c)   // moves it; c is gone here
print(v)           // 1
```

**B2)**

```swift
// Fallback when T isn’t Copyable
func duplicateIfCopyable<T>(_ x: borrowing T) -> (T?, T?) { (nil, nil) }

// Overload for copyable types
func duplicateIfCopyable<T: Copyable>(_ x: borrowing T) -> (T?, T?) {
    let a = copy x
    let b = copy x
    return (a, b)
}
```

*Why:* The `Copyable`-constrained overload enables `copy`.

**B3)**

```swift
enum Door: ~Copyable { case open; case closed }
func printDoor(_ d: consuming Door) {
    switch consume d {
    case .open:   print("open")
    case .closed: print("closed")
    }
}
```

---

### Set C

**C1)**

```swift
struct TempFile: ~Copyable {
    let path: String
    deinit { print("Removing", path) }
}

func demo() {
    var f = TempFile(path: "/tmp/demo.txt")
    // do work
} // leaving scope → prints "Removing /tmp/demo.txt"
```

**C2)**

```swift
protocol Closable { consuming func close() }
struct Socket: ~Copyable {
    var isOpen = true
    consuming func close() { if isOpen { print("closed"); } }
}
extension Socket: Closable {}
```

**C3)**

```swift
// Original (rejected):
// func pair<T>(_ x: borrowing T) -> (T, T) { (x, x) }

// Fix for copyable types:
func pair<T: Copyable>(_ x: borrowing T) -> (T, T) { (copy x, copy x) }
```

*Why:* A `borrowing` parameter isn’t implicitly copyable; use `copy`, and only if `T` is `Copyable`.

---

## Final tips

* Start with **`borrowing`** for read‑only helpers.
* Use **`inout`** when a function needs to **mutate and return** the same value.
* Use **`consuming`** to **move** ownership (single‑use, cleanup-on-drop types).
* Reach for **`~Copyable`** when duplication would be **unsafe** or **meaningless**.
* If the compiler complains about copying: think “Do I need `copy`? Or do I need to redesign to borrow/consume instead?”
