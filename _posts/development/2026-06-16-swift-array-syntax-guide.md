---
title: "Swift Array Syntax Guide"
date: 2026-06-16 08:26:00 +0900
tags: [swift, array, coding-test, algorithms]
---

# Swift Array Syntax Guide

This guide summarizes common Swift `Array` syntax and patterns for coding tests.

---

## 1. Creating Arrays

### Empty array

```swift
var numbers: [Int] = []
var names = [String]()
```

### Array literal

```swift
let numbers = [1, 2, 3, 4, 5]
let names = ["Alice", "Bob", "Charlie"]
```

### Array from range

```swift
let digits = Array(0...9)
// [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

let zeroToNine = Array(0..<10)
// [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
```

### Repeating values

```swift
let zeros = Array(repeating: 0, count: 5)
// [0, 0, 0, 0, 0]

var visited = Array(repeating: false, count: 10)
// [false, false, false, false, false, false, false, false, false, false]
```

This pattern is very common in DFS, BFS, dynamic programming, and counting problems.

---

## 2. Accessing Elements

```swift
let nums = [10, 20, 30]

print(nums[0]) // 10
print(nums[1]) // 20
print(nums[2]) // 30
```

Swift arrays are zero-indexed.

### First and last elements

```swift
let nums = [10, 20, 30]

print(nums.first) // Optional(10)
print(nums.last)  // Optional(30)
```

`first` and `last` return optional values because the array may be empty.

```swift
if let first = nums.first {
    print(first)
}
```

---

## 3. Basic Properties

```swift
let nums = [1, 2, 3]

print(nums.count)    // 3
print(nums.isEmpty)  // false
```

Common usage:

```swift
if nums.isEmpty {
    print("No elements")
}
```

---

## 4. Adding Elements

### Append one element

```swift
var nums = [1, 2, 3]
nums.append(4)

print(nums) // [1, 2, 3, 4]
```

### Append multiple elements

```swift
var nums = [1, 2, 3]
nums.append(contentsOf: [4, 5, 6])

print(nums) // [1, 2, 3, 4, 5, 6]
```

### Insert at index

```swift
var nums = [1, 3, 4]
nums.insert(2, at: 1)

print(nums) // [1, 2, 3, 4]
```

Note: Inserting into the middle of an array is O(n).

---

## 5. Removing Elements

### Remove by index

```swift
var nums = [10, 20, 30]
let removed = nums.remove(at: 1)

print(removed) // 20
print(nums)    // [10, 30]
```

### Remove first or last

```swift
var nums = [1, 2, 3]

nums.removeFirst()
nums.removeLast()

print(nums) // [2]
```

Be careful: `removeFirst()` is O(n) for Array because remaining elements must shift.

### Remove all elements

```swift
var nums = [1, 2, 3]
nums.removeAll()

print(nums) // []
```

---

## 6. Iterating Over Arrays

### Basic for loop

```swift
let nums = [10, 20, 30]

for num in nums {
    print(num)
}
```

### Iterate with index

```swift
let nums = [10, 20, 30]

for i in 0..<nums.count {
    print(i, nums[i])
}
```

### Using enumerated()

```swift
let nums = [10, 20, 30]

for (index, value) in nums.enumerated() {
    print(index, value)
}
```

This is safer and more readable when both index and value are needed.

---

## 7. Slicing Arrays

### Prefix

```swift
let nums = [1, 2, 3, 4, 5]
let firstThree = nums.prefix(3)

print(firstThree) // [1, 2, 3]
```

### Suffix

```swift
let nums = [1, 2, 3, 4, 5]
let lastTwo = nums.suffix(2)

print(lastTwo) // [4, 5]
```

### Range slicing

```swift
let nums = [1, 2, 3, 4, 5]
let middle = nums[1...3]

print(middle) // [2, 3, 4]
```

Important: slicing creates an `ArraySlice`, not an `Array`.

```swift
let slice = nums[1...3]
let array = Array(slice)
```

Use `Array(slice)` when a real Array is required.

---

## 8. Sorting

### sorted()

Returns a new sorted array.

```swift
let nums = [3, 1, 4, 2]
let sortedNums = nums.sorted()

print(sortedNums) // [1, 2, 3, 4]
print(nums)       // [3, 1, 4, 2]
```

### sort()

Sorts the array in place.

```swift
var nums = [3, 1, 4, 2]
nums.sort()

print(nums) // [1, 2, 3, 4]
```

### Descending order

```swift
let nums = [3, 1, 4, 2]
let descending = nums.sorted(by: >)

print(descending) // [4, 3, 2, 1]
```

---

## 9. map, filter, reduce

### map

Transforms each element.

```swift
let nums = [1, 2, 3]
let doubled = nums.map { $0 * 2 }

print(doubled) // [2, 4, 6]
```

### filter

Keeps only elements that satisfy a condition.

```swift
let nums = [1, 2, 3, 4, 5]
let evens = nums.filter { $0 % 2 == 0 }

print(evens) // [2, 4]
```

### reduce

Combines all elements into one value.

```swift
let nums = [1, 2, 3, 4]
let sum = nums.reduce(0, +)

print(sum) // 10
```

Another example:

```swift
let nums = [1, 2, 3, 4]
let product = nums.reduce(1) { result, num in
    result * num
}

print(product) // 24
```

---

## 10. Searching

### contains

```swift
let nums = [1, 2, 3]

print(nums.contains(2)) // true
print(nums.contains(5)) // false
```

### firstIndex

```swift
let nums = [10, 20, 30]

if let index = nums.firstIndex(of: 20) {
    print(index) // 1
}
```

### first(where:)

```swift
let nums = [3, 7, 10, 15]

let firstEven = nums.first { $0 % 2 == 0 }
print(firstEven) // Optional(10)
```

---

## 11. Reversing

```swift
let nums = [1, 2, 3]
let reversedNums = Array(nums.reversed())

print(reversedNums) // [3, 2, 1]
```

`reversed()` does not directly return an Array, so use `Array(...)` when needed.

---

## 12. Two-Dimensional Arrays

### Create a 2D array

```swift
let rows = 3
let cols = 4

var grid = Array(
    repeating: Array(repeating: 0, count: cols),
    count: rows
)

print(grid)
// [[0, 0, 0, 0],
//  [0, 0, 0, 0],
//  [0, 0, 0, 0]]
```

### Access and update

```swift
grid[1][2] = 5
print(grid[1][2]) // 5
```

Common in grid, BFS, DFS, and dynamic programming problems.

---

## 13. Common Coding Test Patterns

### Counting with Array

Use this when values are in a small fixed range.

```swift
let nums = [1, 2, 2, 3, 3, 3]
var count = Array(repeating: 0, count: 4)

for num in nums {
    count[num] += 1
}

print(count)
// [0, 1, 2, 3]
```

### Counting with Dictionary

Use this when values can be large or negative.

```swift
let nums = [100, -3, 100, 7, -3]
var count: [Int: Int] = [:]

for num in nums {
    count[num, default: 0] += 1
}

print(count)
```

### Prefix Sum

```swift
let nums = [1, 2, 3, 4]
var prefix = Array(repeating: 0, count: nums.count + 1)

for i in 0..<nums.count {
    prefix[i + 1] = prefix[i] + nums[i]
}

// Sum from index l to r
let l = 1
let r = 3
let rangeSum = prefix[r + 1] - prefix[l]

print(rangeSum) // 2 + 3 + 4 = 9
```

### Two Pointers

```swift
let nums = [1, 2, 3, 4, 5]
var left = 0
var right = nums.count - 1

while left < right {
    print(nums[left], nums[right])
    left += 1
    right -= 1
}
```

### Move zeros to the end

```swift
func moveZeros(_ nums: [Int]) -> [Int] {
    var result: [Int] = []
    var zeroCount = 0

    for num in nums {
        if num == 0 {
            zeroCount += 1
        } else {
            result.append(num)
        }
    }

    result.append(contentsOf: Array(repeating: 0, count: zeroCount))
    return result
}

print(moveZeros([0, 1, 0, 3, 12]))
// [1, 3, 12, 0, 0]
```

---

## 14. Useful Syntax Summary

| Purpose | Syntax |
|---|---|
| Empty array | `var arr: [Int] = []` |
| Array from range | `Array(0..<10)` |
| Repeating values | `Array(repeating: 0, count: n)` |
| Add element | `arr.append(x)` |
| Add multiple elements | `arr.append(contentsOf: otherArray)` |
| Remove last | `arr.removeLast()` |
| Count | `arr.count` |
| Check empty | `arr.isEmpty` |
| Sort new array | `arr.sorted()` |
| Sort in place | `arr.sort()` |
| Reverse | `Array(arr.reversed())` |
| Transform | `arr.map { ... }` |
| Filter | `arr.filter { ... }` |
| Sum | `arr.reduce(0, +)` |
| Contains | `arr.contains(x)` |
| First index | `arr.firstIndex(of: x)` |
| Slice | `arr[l...r]` |

---

## 15. Common Mistakes

### Mistake 1: Forgetting that Array indices start at 0

```swift
let nums = [10, 20, 30]
print(nums[0]) // first element
```

### Mistake 2: Accessing an invalid index

```swift
let nums = [1, 2, 3]
// nums[3] causes a runtime error
```

Always check bounds when necessary.

```swift
if index >= 0 && index < nums.count {
    print(nums[index])
}
```

### Mistake 3: Confusing ArraySlice with Array

```swift
let nums = [1, 2, 3, 4]
let slice = nums[1...2]
let arr = Array(slice)
```

### Mistake 4: Using removeFirst() repeatedly

```swift
var queue = [1, 2, 3]
queue.removeFirst()
```

`removeFirst()` is O(n), so it can be slow if used many times.

For queue problems, prefer using an index pointer:

```swift
var queue = [1, 2, 3]
var head = 0

while head < queue.count {
    let value = queue[head]
    head += 1
    print(value)
}
```

---

## 16. Practice Problems

Try solving these using Array syntax:

1. Find duplicate numbers
2. Sum of missing digits from 0 to 9
3. Maximum profit from prices
4. Compress consecutive duplicate values
5. Prefix sum range queries
6. Move zeros to the end
7. Reverse an array
8. Rotate an array
9. Find the maximum subarray sum
10. Merge two sorted arrays

---

## 17. Recommended Memorization List

For coding tests, memorize these patterns first:

```swift
Array(0..<n)
```

```swift
Array(repeating: 0, count: n)
```

```swift
Array(repeating: false, count: n)
```

```swift
for i in 0..<arr.count { }
```

```swift
for (i, value) in arr.enumerated() { }
```

```swift
arr.map { $0 * 2 }
```

```swift
arr.filter { $0 > 0 }
```

```swift
arr.reduce(0, +)
```

```swift
arr.sorted()
```

```swift
Array(arr[l...r])
```

These are enough for many beginner and intermediate Array problems.
