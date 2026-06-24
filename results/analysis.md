# Project Analysis — Txtmark (Java Markdown Processor)

> Analysis scope: the Java project located in `target/`. Generated 2026-06-23.

## 1. Overview

**Txtmark** is a standalone Markdown-to-HTML processor for the JVM, authored by
René Jeschke. It parses Markdown text and emits HTML, supporting both standard
Markdown (MarkdownTest 1.0 conformity) and an extended profile with extra
features. Its stated design goal is speed — historically marketed as "the
fastest markdown processor on the JVM."

| | |
|---|---|
| **Group / Artifact** | `com.github.rjeschke` / `txtmark` |
| **Version** | `0.14-SNAPSHOT` |
| **Packaging** | `jar` |
| **License** | Apache License 2.0 |
| **Upstream** | https://github.com/rjeschke/txtmark |
| **Source size** | ~7,200 LOC across 25 Java files (main + test) |

## 2. Project Structure

```
target/
├── pom.xml                     Maven build descriptor
├── README.md                   Usage, extensions, conformity, benchmarks
├── LICENSE.txt                 Apache 2.0
├── .travis.yml                 CI config (legacy)
├── bootstrap.py/txtmark.py     Bootstrapping helper script
├── src/
│   ├── main/java/com/github/rjeschke/txtmark/
│   │   ├── Processor.java      (1014) Public entry point — process() overloads
│   │   ├── Emitter.java        (1048) Core: blocks/spans → HTML
│   │   ├── Utils.java          (785)  Escaping, entity, string helpers
│   │   ├── Line.java           (600)  Line model + line-type detection
│   │   ├── Block.java          (336)  Block model (tree of blocks)
│   │   ├── Configuration.java  (279)  Builder-based config + DEFAULT presets
│   │   ├── Decorator / DefaultDecorator   Pluggable HTML tag emission
│   │   ├── HTML / HTMLElement  HTML tag knowledge tables
│   │   ├── BlockType / LineType / MarkToken / BlockEmitter / SpanEmitter
│   │   ├── LinkRef.java        Reference-link model
│   │   ├── Run.java            Simple CLI runner
│   │   └── cmd/                Richer command-line front-end
│   │       ├── CmdLineParser (691), Run, HlUtils, CodeBlockEmitter,
│   │       │   CmdArgument, TxtmarkArguments
│   └── test/
│       ├── java/.../ConformityTest.java   Runs MarkdownTest 1.0 suite
│       ├── java/.../Benchmark.java        Micro-benchmark harness
│       └── resources/.../testsuite/       .text/.html conformity pairs
└── target/                     Maven build output (classes, surefire, apidocs)
```

The package is cleanly layered: a **model** (`Line`, `Block`, `LinkRef`,
enums), a **two-phase parser** (`Processor` builds the block tree; `Emitter`
renders spans/inline), **configuration/extensibility** (`Configuration`,
`Decorator`, `BlockEmitter`, `SpanEmitter`), and **front-ends** (`Run`, `cmd/`).

## 3. Tech Stack

- **Language:** Java, targeting **Java 1.8** (`maven-compiler-plugin` source/target = 1.8).
- **Build:** Apache Maven, inheriting from `org.sonatype.oss:oss-parent:7` (Sonatype OSS publishing parent). Source-jar and Javadoc-jar plugins configured; a `release-sign-artifacts` profile wires GPG signing for releases.
- **Distribution:** Maven Central.
- **CI:** `.travis.yml` present but **legacy** — pins `openjdk7` / `oraclejdk7`, which contradicts the Java 8 compiler target and points at a now-retired Travis service.
- **No runtime dependencies** — a deliberate selling point: dropping `txtmark.jar` on the classpath is sufficient.

## 4. Dependencies

| Dependency | Version | Scope | Notes |
|---|---|---|---|
| `junit:junit` | 4.12 | test | Only declared dependency |

There are **zero runtime/compile dependencies** — the parser is fully
self-contained. This is excellent for embeddability and minimizes supply-chain
surface, but JUnit 4.12 is dated (current 4.x is 4.13.2, with known CVEs in
older releases fixed there); a bump is advisable.

## 5. Main Functionality

The public API is small and string-oriented. Typical usage:

```java
String html = Processor.process("This is ***TXTMARK***");
```

`Processor` exposes overloads accepting `String`, `Reader`, `InputStream`, and
`File`, each optionally taking a `Configuration`. Configuration is assembled via
a fluent **Builder**, with two ready-made presets — `Configuration.DEFAULT` and
`Configuration.DEFAULT_SAFE` (HTML-sanitizing "safe mode").

Notable configurable behaviors (`Configuration.Builder`): safe mode, encoding,
custom `Decorator` (controls emitted tags), custom code-block `BlockEmitter`
(enables e.g. syntax-highlighted `<pre>` blocks), special-link `SpanEmitter`,
fenced-code-block delimiter spacing, and a "panic mode".

**Extended profile** (`[$PROFILE$]: extended`) adds: lists/code-blocks ending
paragraphs, text anchors/IDs on headings & list items, auto HTML entities
(`(C)`→`&copy;`, `--`→`&ndash;`, smart quotes, etc.), intra-word underscore
suppression, superscript via `^`, abbreviations, and fenced code blocks
(```` ``` ```` / `~~~`) with meta lines for highlighting.

**Conformity:** passes the MarkdownTest 1.0 suite except two cases the author
deliberately rejects (empty image `title` attributes, and unescaped `"` inside
quote-delimited titles). The bundled `ConformityTest` passed in the recorded
surefire report (`Tests run: 1, Failures: 0`).

## 6. Code Quality

**Strengths**
- **Clear separation of concerns** and a readable two-phase (block tree →
  inline emit) architecture.
- **Thorough Javadoc** with `@since` tags tracking API evolution.
- **Extensibility done right:** behavior is injected via `Decorator` /
  `BlockEmitter` / `SpanEmitter` interfaces rather than hard-coded.
- **Builder pattern** gives an immutable, discoverable `Configuration`.
- **No external runtime dependencies** — small, embeddable, low-risk footprint.
- Apache-licensed conformity test corpus included for regression safety.

**Concerns**
- **Performance-oriented hand-written parsing:** `Emitter` (1048 LOC) and
  `Processor` (1014 LOC) are large, character-by-character `StringBuilder`
  state machines with deep `switch`/recursion (`recursiveEmitLine`,
  `checkLink`, `checkHtml`, `checkEntity`). Fast, but dense and hard to modify
  safely.
- **Thin automated test coverage relative to surface area:** essentially one
  conformity test plus a manual benchmark. No unit tests targeting individual
  emitters, edge cases, or safe-mode/XSS sanitization.
- **Visibility leakage:** `Emitter.useExtensions` is a mutable `public` field;
  several internals are package-or-public where stricter encapsulation would be
  safer.
- **Stale tooling:** Travis pins JDK 7 while the build targets Java 8;
  `oss-parent:7` and the Maven plugin versions (compiler 2.4, etc.) are old.
- **Security note:** as an HTML generator, raw (non-safe-mode) processing emits
  untrusted HTML verbatim. Callers handling user input must use
  `DEFAULT_SAFE`/safe mode — worth flagging prominently to consumers.

## 7. Build & Artifacts

The `target/target/` build directory contains a successful prior build:
compiled classes (~21 `.class` files under `target/classes`), generated
Javadoc (`apidocs/`), and surefire reports showing passing tests. Source and
Javadoc jars are produced by the configured plugins.

> Naming note: this project literally sits in a directory called `target/`, and
> Maven's own output directory is `target/` inside it — so build artifacts live
> at `target/target/`. Worth keeping in mind to avoid confusion.

## 8. Recommendations

1. **Modernize the build & CI.** Replace the abandoned Travis (`openjdk7`) with
   GitHub Actions, align the JDK matrix with the Java 8 target (or raise the
   target), and update the ancient `oss-parent:7` and Maven plugin versions.
2. **Bump JUnit** from 4.12 to 4.13.2 (or migrate to JUnit 5) to pick up bug
   and security fixes.
3. **Expand test coverage.** Add focused unit tests for the inline emitter,
   reference links, fenced code blocks, the extended profile features, and —
   importantly — **safe-mode / XSS sanitization** as explicit regression tests.
4. **Tighten encapsulation.** Make `Emitter.useExtensions` and similar internals
   non-public/`final` where possible to reduce the mutable API surface.
5. **Document the security contract.** Prominently steer consumers handling
   untrusted input toward `Configuration.DEFAULT_SAFE`.
6. **Consider modularization.** If targeting newer Java, add a
   `module-info.java`; the zero-dependency design makes this low-friction.
7. **Refresh or remove the benchmark section** in the README — the author
   already flags the numbers as obsolete; a current JMH-based benchmark would
   better support the "fast" claim.

## Summary

Txtmark is a mature, self-contained, Apache-licensed Markdown→HTML library with
a clean, extensible architecture and a performance focus. The core code is
well-structured and documented but dense in its hot paths, lightly tested, and
wrapped in dated build/CI tooling. The highest-value improvements are modern
CI/build hygiene, broader (especially security-focused) test coverage, and a
dependency refresh — none of which require architectural change.
