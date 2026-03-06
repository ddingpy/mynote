---
title: "TypeScript 5.9 Study Guide (for JavaScript, Node.js, and React Developers)"
date: 2026-01-19 23:18:00 +0900
tags: [typescript, javascript, nodejs, react]
---


**Last verified:** 2026-01-13
**Latest stable release line shown on the TypeScript site:** **TypeScript 5.9** ([TypeScript][1])
**Latest patch listed on GitHub releases:** **5.9.3** ([GitHub][2])
**TypeScript 5.9 announcement date:** 2025-08-01 ([Microsoft for Developers][3])

> This document focuses on what’s new/important in **TypeScript 5.9**, plus the practical configuration + patterns you’ll use in **Node.js** and **React**.

---

## Table of contents

* [1. What “latest TypeScript” means](#1-what-latest-typescript-means)
* [2. Install and verify TypeScript 5.9](#2-install-and-verify-typescript-59)
* [3. The biggest change in 5.9: a new default `tsc --init`](#3-the-biggest-change-in-59-a-new-default-tsc---init)
* [4. What’s new in TypeScript 5.9](#4-whats-new-in-typescript-59)

  * [4.1 `import defer`](#41-import-defer)
  * [4.2 Stable Node 20 mode: `--module node20` / `--moduleResolution node20`](#42-stable-node-20-mode---module-node20--moduleresolution-node20)
  * [4.3 Better DOM API tooltips](#43-better-dom-api-tooltips)
  * [4.4 Better editor hovers](#44-better-editor-hovers)
  * [4.5 Performance improvements](#45-performance-improvements)
  * [4.6 Breaking-ish changes to watch for](#46-breaking-ish-changes-to-watch-for)
* [5. Modern TS config, explained (Node + React)](#5-modern-ts-config-explained-node--react)
* [6. Recommended `tsconfig.json` templates](#6-recommended-tsconfigjson-templates)

  * [6.1 Node.js (Node 20, ESM)](#61-nodejs-node-20-esm)
  * [6.2 React (bundler: Vite/Webpack/Next, etc.)](#62-react-bundler-vitewebpacknext-etc)
  * [6.3 Libraries (publish types)](#63-libraries-publish-types)
* [7. React + TypeScript patterns you’ll use constantly](#7-react--typescript-patterns-youll-use-constantly)
* [8. TypeScript type system refresher (high leverage)](#8-typescript-type-system-refresher-high-leverage)
* [9. Upgrade checklist to 5.9](#9-upgrade-checklist-to-59)
* [10. What’s coming next (6.0 and the native TypeScript 7 line)](#10-whats-coming-next-60-and-the-native-typescript-7-line)
* [11. Practice exercises](#11-practice-exercises)
* [12. References](#12-references)

---

## 1. What “latest TypeScript” means

TypeScript has:

* A **stable release line** (today that’s 5.9 on the official site). ([TypeScript][1])
* **Patch releases** within that line (GitHub currently lists 5.9.3 as the latest patch). ([GitHub][2])

Also: the TypeScript team has been working on a **new native toolchain (“TypeScript 7” line)** and describes TypeScript 6.0 as a “bridge” release, but that’s roadmap context—not what most projects call “latest stable TypeScript” today. ([Microsoft for Developers][4])

---

## 2. Install and verify TypeScript 5.9

### Install per-project (recommended)

```bash
npm install --save-dev typescript
npx tsc -v
```

This is the standard workflow for Node.js projects, and using a lockfile keeps everyone on the same TS version. ([TypeScript][5])

### Global install (okay for quick experiments)

```bash
npm install -g typescript
tsc -v
```

The TypeScript download page explicitly calls out global installs as convenient for one-offs but recommends per-project installs for reproducibility. ([TypeScript][5])

---

## 3. The biggest change in 5.9: a new default `tsc --init`

In **TypeScript 5.9**, running `tsc --init` now generates a **much smaller, more prescriptive** `tsconfig.json` by default, instead of a huge commented file. ([TypeScript][6])

Key defaults from that generated config include (summarized):

* `module: "nodenext"`
* `target: "esnext"`
* `types: []` (important!)
* `sourceMap: true`
* `declaration: true`
* `declarationMap: true`
* `noUncheckedIndexedAccess: true`
* `exactOptionalPropertyTypes: true`
* `strict: true`
* `jsx: "react-jsx"`
* `verbatimModuleSyntax: true`
* `isolatedModules: true`
* `noUncheckedSideEffectImports: true`
* `moduleDetection: "force"`
* `skipLibCheck: true` ([TypeScript][6])

### Why this matters to you (Node/React dev)

This new default pushes you toward:

* **Modern JS output** (high `target`) ([TypeScript][6])
* **Modern module semantics** (`nodenext` + explicit module detection) ([TypeScript][6])
* **Cleaner module emit rules** (`verbatimModuleSyntax`) ([TypeScript][6])
* **Bundler-friendly correctness** (`isolatedModules`) ([TypeScript][6])
* **Stricter correctness checks** (like `noUncheckedIndexedAccess`) ([TypeScript][6])

But: the new default also includes settings you *may want to change* depending on whether you’re building an **app** or a **library**—especially `declaration`/`declarationMap` and `types: []`. ([TypeScript][6])

---

## 4. What’s new in TypeScript 5.9

### 4.1 `import defer`

TypeScript 5.9 adds support for the ECMAScript **deferred module evaluation** proposal via:

```ts
import defer * as feature from "./some-feature.js";
```

Important constraints and behavior:

* **Only namespace imports** are allowed (`import defer * as …`). ([TypeScript][6])
* The module is **loaded**, but **not evaluated** until you access an export (e.g., `feature.someExport`). ([TypeScript][6])
* TypeScript **does not downlevel/transform** `import defer`. It’s intended for runtimes/tools that support it, and it only works under `--module preserve` and `--module esnext`. ([TypeScript][6])

**When it’s useful:** deferring expensive initialization or side effects until a feature is actually used (think: optional subsystems, “only on client” code, feature flags, etc.). ([TypeScript][6])

**Compare with `import()` (dynamic import):**

* `import()` is asynchronous and typically loads+evaluates the module immediately when awaited.
* `import defer` is designed to **delay evaluation until first use of an export** (even though the module is already loaded). ([TypeScript][6])

---

### 4.2 Stable Node 20 mode: `--module node20` / `--moduleResolution node20`

TypeScript 5.9 introduces **stable** Node 20 modes:

* `--module node20`
* `--moduleResolution node20`

The release notes describe `node20` as:

* Intended to model **Node.js v20**
* **Unlikely to pick up new behaviors** over time (unlike `nodenext`) ([TypeScript][6])
* `--module node20` also implies `--target es2023` unless you override it (whereas `nodenext` implies the floating `esnext`). ([TypeScript][6])

The module reference also notes `node20` includes support for **`require()` of ESM** in the appropriate interop cases. ([TypeScript][7])

**Practical guidance:**

* If your production runtime is fixed at **Node 20**, `node20` is a good “stable anchor.”
* If you want TypeScript to track the newest Node behaviors more aggressively, use `nodenext` (and accept occasional behavior shifts). ([TypeScript][6])

---

### 4.3 Better DOM API tooltips

TypeScript 5.9 includes **summary descriptions for many DOM APIs** (based on MDN documentation), improving the in-editor learning experience when you hover DOM types. ([TypeScript][6])

---

### 4.4 Better editor hovers

TypeScript 5.9 previews **expandable hovers** (a “verbosity” control with `+` / `-`) in editors like VS Code. ([TypeScript][6])

It also supports a **configurable maximum hover length** via the VS Code setting `js/ts.hover.maximumLength`, and increases the default hover length. ([TypeScript][6])

---

### 4.5 Performance improvements

Two notable optimizations called out in the 5.9 notes:

* Caching intermediate instantiations during complex type substitution (helps performance and can reduce “excessive type instantiation depth” problems in heavily-generic libraries). ([TypeScript][6])
* Faster file/directory existence checks (less allocation overhead in a hot path). ([TypeScript][6])

---

### 4.6 Breaking-ish changes to watch for

#### `lib.d.ts` changes: ArrayBuffer vs TypedArrays (including Node `Buffer`)

TypeScript 5.9 changes built-in types so that `ArrayBuffer` is **no longer a supertype** of several `TypedArray` types, including Node’s `Buffer` (which is a subtype of `Uint8Array`). This can surface new errors around `BufferSource`, `ArrayBufferLike`, etc. ([TypeScript][6])

Mitigations suggested in the release notes include:

* Update to the latest `@types/node` first.
* Use a more specific underlying buffer type (e.g., `Uint8Array<ArrayBuffer>` instead of `Uint8Array` defaulting to `ArrayBufferLike`).
* Pass `typedArray.buffer` when an API expects an `ArrayBuffer`. ([TypeScript][6])

#### Type argument inference changes

TypeScript 5.9 includes changes meant to fix “leaks” of type variables during inference. This may produce new errors in some codebases, and often the fix is to **add explicit type arguments** to generic calls. ([TypeScript][6])

---

## 5. Modern TS config, explained (Node + React)

This section explains the settings you’re most likely to see (especially if you start from `tsc --init` in 5.9).

### `types`: why `types: []` can surprise you

* By default, TypeScript includes all “visible” `@types/*` packages.
* If you specify `types`, TypeScript only includes what you list.
* Therefore `types: []` means **include no global `@types` packages**. ([TypeScript][8])

**Common consequences:**

* Node projects need `"types": ["node"]` plus `@types/node`. ([TypeScript][6])
* React projects may need `"types": ["react", "react-dom"]` (or you can remove the `types` setting and let TS auto-include visible `@types` packages). ([TypeScript][8])

### `verbatimModuleSyntax`: predictable import/export output

With `verbatimModuleSyntax`, TypeScript keeps imports/exports **without** a `type` modifier, and drops anything explicitly marked `type`. This simplifies “import elision” and makes output closer to “what you wrote.” ([TypeScript][9])

This is especially valuable when you want consistency across:

* `tsc` emit
* Babel/swc/esbuild transforms
* mixed ESM/CJS packages ([TypeScript][9])

### `isolatedModules`: bundler/transpiler compatibility

`isolatedModules` warns you about TS patterns that can’t be safely transpiled **one file at a time** (common with Babel/swc-style transforms). It doesn’t change runtime behavior; it’s a correctness guardrail. ([TypeScript][10])

### `noUncheckedSideEffectImports`: catch typos, but watch asset imports

By default, TypeScript may silently ignore unresolved **side-effect imports** (`import "x";`). With `noUncheckedSideEffectImports`, TypeScript errors if it can’t resolve them. ([TypeScript][11])

If you import assets like CSS, you’ll often solve this by adding an ambient module declaration:

```ts
// src/globals.d.ts
declare module "*.css" {}
```

That exact workaround is recommended in the option docs. ([TypeScript][11])

### `moduleDetection: "force"`: treat every file as a module

`moduleDetection` controls how TS decides whether a file is a “script” or a “module.” The `"force"` option treats every non-`.d.ts` file as a module, which avoids a lot of accidental-global-script weirdness. ([TypeScript][12])

### `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`: stricter correctness

* `noUncheckedIndexedAccess` adds `undefined` when you access properties via “maybe present” keys (like index signatures). ([TypeScript][13])
* `exactOptionalPropertyTypes` treats `prop?: T` as “either missing, or T” (not “T | undefined”), which catches subtle bugs around explicitly assigning `undefined`. ([TypeScript][14])

### `skipLibCheck`: faster builds, lower strictness for `.d.ts`

`skipLibCheck` skips type-checking of declaration files. It can speed builds and reduce friction during upgrades, at the cost of some type-system accuracy. ([TypeScript][15])

---

## 6. Recommended `tsconfig.json` templates

These are **starting points**; adjust for your runtime and toolchain.

### 6.1 Node.js (Node 20, ESM)

Use stable Node 20 semantics.

```jsonc
{
  "compilerOptions": {
    "target": "es2023",
    "module": "node20",
    "moduleResolution": "node20",

    "rootDir": "src",
    "outDir": "dist",

    "strict": true,

    // Important if you started from TS 5.9's `tsc --init` default:
    "types": ["node"],

    "sourceMap": true,

    // For an app you might not need these:
    "declaration": false,
    "declarationMap": false,

    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "moduleDetection": "force",

    "skipLibCheck": true
  },
  "include": ["src"]
}
```

Why these choices:

* `node20` is a stable mode intended to model Node 20 behavior. ([TypeScript][6])
* `types: ["node"]` is needed if you otherwise have `types: []` (the 5.9 `tsc --init` default). ([TypeScript][6])
* `verbatimModuleSyntax` and `isolatedModules` are common modern defaults and are part of the new 5.9 init template. ([TypeScript][6])

> If you *do* want `.d.ts` output (e.g., you’re building a library), flip `declaration` back to `true`. ([TypeScript][16])

---

### 6.2 React (bundler: Vite/Webpack/Next, etc.)

For most React apps, you often want TS to **type-check only** and let your bundler transpile.

```jsonc
{
  "compilerOptions": {
    "target": "esnext",
    "module": "esnext",

    // Bundler-friendly resolution rules
    "moduleResolution": "bundler",

    "jsx": "react-jsx",

    "strict": true,

    // Let the bundler emit JS
    "noEmit": true,

    // If you started from TS 5.9's init, don't forget types
    // (or remove "types" entirely to use default visibility).
    "types": ["react", "react-dom"],

    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "moduleDetection": "force",

    "skipLibCheck": true
  },
  "include": ["src"]
}
```

Notes:

* `moduleResolution: "bundler"` is documented as a mode for bundler-style projects. ([TypeScript][17])
* `jsx: "react-jsx"` is the 5.9 init default and is explained in the JSX compiler option docs. ([TypeScript][6])
* `noEmit` makes TypeScript skip output, which is ideal if Babel/swc/esbuild handles transpilation. ([TypeScript][18])
* If you keep `types`, remember it changes which `@types` packages are loaded globally. ([TypeScript][8])

---

### 6.3 Libraries (publish types)

If you publish a package, you typically want `.d.ts` output:

```jsonc
{
  "compilerOptions": {
    "target": "es2020",
    "module": "esnext",
    "moduleResolution": "bundler",

    "rootDir": "src",
    "outDir": "dist",

    "declaration": true,
    "declarationMap": true,

    "strict": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,

    "skipLibCheck": true
  },
  "include": ["src"]
}
```

* `declaration` generates `.d.ts` describing your public API. ([TypeScript][16])
* `declarationMap` helps editors jump from `.d.ts` back to original `.ts`. ([TypeScript][19])

---

## 7. React + TypeScript patterns you’ll use constantly

### Strong prop typing without ceremony

```ts
type ButtonProps =
  | { variant: "primary"; onClick: () => void }
  | { variant: "link"; href: string };

export function Button(props: ButtonProps) {
  if (props.variant === "link") {
    return <a href={props.href}>Link</a>;
  }
  return <button onClick={props.onClick}>Primary</button>;
}
```

Why this rocks:

* Discriminated unions give you *automatic narrowing* based on `variant`.
* You reduce runtime checks and avoid invalid prop combos.

### Typed event handlers

```ts
function SearchBox() {
  const onChange: React.ChangeEventHandler<HTMLInputElement> = (e) => {
    console.log(e.currentTarget.value);
  };
  return <input onChange={onChange} />;
}
```

### `useState` with correct inference

```ts
const [count, setCount] = useState(0);      // number inferred
const [user, setUser] = useState<User|null>(null);
```

### Use `noUncheckedSideEffectImports` safely with CSS/assets

If you enable `noUncheckedSideEffectImports`, set up ambient modules for assets (CSS, SVG, etc.) so `import "./styles.css"` stays type-safe. ([TypeScript][11])

---

## 8. TypeScript type system refresher (high leverage)

If you already write JS/React daily, these are the TS concepts that pay off fastest:

1. **Union types** and **narrowing**
   Use unions to model “states” and branches, and let TS narrow with `if`, `switch`, `in`, `typeof`, etc.

2. **`unknown` over `any`**
   `unknown` forces you to validate before use—ideal for API responses.

3. **Generics (with constraints)**
   Build reusable helpers:

   ```ts
   function first<T>(arr: readonly T[]): T | undefined {
     return arr[0];
   }
   ```

4. **Mapped + conditional types**
   These power a lot of modern library types (and your own schema/type helpers).

5. **`satisfies` + `as const` for “validated literals”**
   Great for config objects where you want literal types but still want validation.

---

## 9. Upgrade checklist to 5.9

1. **Upgrade TypeScript** (project devDependency) and run a full type-check. ([TypeScript][5])
2. Watch for **ArrayBuffer/TypedArray/Buffer** errors caused by `lib.d.ts` changes. ([TypeScript][6])

   * First try updating `@types/node`
   * Then consider using `typedArray.buffer` or more specific typed array parameters (as described in the release notes) ([TypeScript][6])
3. If you see new generic inference failures, add explicit type arguments where needed. ([TypeScript][6])
4. If you run `tsc --init` and copy that config into a React/Node project, double-check:

   * `types` (because `types: []` is restrictive) ([TypeScript][6])
   * whether you really want `declaration` / `declarationMap` in an app ([TypeScript][6])

---

## 10. What’s coming next (6.0 and the native TypeScript 7 line)

The TypeScript team’s roadmap update (Dec 2025) states:

* **TypeScript 6.0** will be the **last release** based on the existing TypeScript/JavaScript codebase (no 6.1 planned, though patch releases may happen). ([Microsoft for Developers][4])
* 6.0 is described as a **bridge** between the 5.9 line and 7.0. ([Microsoft for Developers][4])
* They discuss running the existing `typescript` package side-by-side with a native preview package and using `tsgo` for faster type-checking in some workflows. ([Microsoft for Developers][4])

This is mostly “keep an eye on it” information unless you’re chasing very large-project performance improvements.

---

## 11. Practice exercises

1. **Recreate the 5.9 `tsc --init` defaults**, then modify them for:

   * Node 20 backend
   * React bundler frontend ([TypeScript][6])

2. **Try `import defer`**:

   * Create a module with obvious side effects (`console.log`, expensive initialization).
   * Import it with `import defer` and confirm evaluation timing. ([TypeScript][6])

3. **Fix a Buffer/ArrayBuffer typing issue**:

   * Write a small function that accepts `ArrayBuffer`.
   * Pass a `Uint8Array` / `Buffer`, and fix it via `.buffer` or more specific typing. ([TypeScript][6])

4. **Turn on** `noUncheckedSideEffectImports` **and keep your CSS imports working**:

   * Add `declare module "*.css" {}` in a global `.d.ts`. ([TypeScript][11])

---

## 12. References

* TypeScript homepage (shows the current stable line as 5.9). ([TypeScript][1])
* TypeScript download/install instructions (npm install, npx tsc, global install notes). ([TypeScript][5])
* TypeScript 5.9 release notes (all new features + behavioral changes). ([TypeScript][6])
* TypeScript 5.8 release notes (background on Node ESM/CJS interop + erasable syntax). ([TypeScript][20])
* TSConfig reference pages used above:

  * `verbatimModuleSyntax` ([TypeScript][9])
  * `noUncheckedSideEffectImports` ([TypeScript][11])
  * `moduleDetection` ([TypeScript][12])
  * `types` ([TypeScript][8])
  * `target` ([TypeScript][21])
  * `isolatedModules` ([TypeScript][10])
  * `skipLibCheck` ([TypeScript][15])
  * `noUncheckedIndexedAccess` ([TypeScript][13])
  * `exactOptionalPropertyTypes` ([TypeScript][14])
  * `noEmit` ([TypeScript][18])
  * `declaration` ([TypeScript][16])
  * `declarationMap` ([TypeScript][19])
  * `module` option details (including Node modes) ([TypeScript][7])
  * `moduleResolution` (including bundler mode) ([TypeScript][17])
  * `jsx` ([TypeScript][22])
* GitHub releases list for the latest patch (5.9.3). ([GitHub][2])
* Roadmap update: “Progress on TypeScript 7 – December 2025” (6.0/7.0 direction). ([Microsoft for Developers][4])

---

[1]: https://www.typescriptlang.org/ "TypeScript: JavaScript With Syntax For Types."
[2]: https://github.com/Microsoft/TypeScript/releases "Releases · microsoft/TypeScript · GitHub"
[3]: https://devblogs.microsoft.com/typescript/announcing-typescript-5-9/ "Announcing TypeScript 5.9 - TypeScript"
[4]: https://devblogs.microsoft.com/typescript/progress-on-typescript-7-december-2025/ "Progress on TypeScript 7 - December 2025 - TypeScript"
[5]: https://www.typescriptlang.org/download/ "TypeScript: How to set up TypeScript"
[6]: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html "TypeScript: Documentation - TypeScript 5.9"
[7]: https://www.typescriptlang.org/tsconfig/module.html "TypeScript: TSConfig Option: module"
[8]: https://www.typescriptlang.org/tsconfig/types.html "TypeScript: TSConfig Option: types"
[9]: https://www.typescriptlang.org/tsconfig/verbatimModuleSyntax.html "TypeScript: TSConfig Option: verbatimModuleSyntax"
[10]: https://www.typescriptlang.org/tsconfig/isolatedModules.html "TypeScript: TSConfig Option: isolatedModules"
[11]: https://www.typescriptlang.org/tsconfig/noUncheckedSideEffectImports.html "TypeScript: TSConfig Option: noUncheckedSideEffectImports"
[12]: https://www.typescriptlang.org/tsconfig/moduleDetection.html "TypeScript: TSConfig Option: moduleDetection"
[13]: https://www.typescriptlang.org/tsconfig/noUncheckedIndexedAccess.html "TypeScript: TSConfig Option: noUncheckedIndexedAccess"
[14]: https://www.typescriptlang.org/tsconfig/exactOptionalPropertyTypes.html "TypeScript: TSConfig Option: exactOptionalPropertyTypes"
[15]: https://www.typescriptlang.org/tsconfig/skipLibCheck.html "TypeScript: TSConfig Option: skipLibCheck"
[16]: https://www.typescriptlang.org/tsconfig/declaration.html "TypeScript: TSConfig Option: declaration"
[17]: https://www.typescriptlang.org/tsconfig/moduleResolution.html "TypeScript: TSConfig Option: moduleResolution"
[18]: https://www.typescriptlang.org/tsconfig/noEmit.html "TypeScript: TSConfig Option: noEmit"
[19]: https://www.typescriptlang.org/tsconfig/declarationMap.html "TypeScript: TSConfig Option: declarationMap"
[20]: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html "TypeScript: Documentation - TypeScript 5.8"
[21]: https://www.typescriptlang.org/tsconfig/target.html "TypeScript: TSConfig Option: target"
[22]: https://www.typescriptlang.org/tsconfig/jsx.html "TypeScript: TSConfig Option: jsx"
