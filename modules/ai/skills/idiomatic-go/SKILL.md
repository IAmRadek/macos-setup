---
name: idiomatic-go
description: Write idiomatic, production-quality Go — naming and style conventions, error construction and wrapping, context propagation, and clean package/API design. Use this whenever writing, reviewing, refactoring, or critiquing Go (.go) code: new functions or packages, error handling, struct/interface design, or any time the user asks for "idiomatic", "clean", or "review my" Go, even if they don't name a style guide.
---

# Idiomatic Go

Write Go the way the standard library and the Go community write it. The goal is code that reads plainly, fails loudly at the right boundary, and exposes the smallest possible surface. When a rule below would make code worse in a specific spot, prefer clarity — but be able to say why.

## Before anything else

- **Format with `gofmt`/`goimports`.** Never hand-align or hand-order imports. Formatting is not a matter of taste in Go.
- **Code must pass `go vet`** and ideally `staticcheck`. Treat their warnings as bugs, not suggestions.
- **Match the surrounding package.** Consistency within a codebase beats any individual preference. Apply style changes at package granularity, not line by line.

## Naming & style

- Use `MixedCaps`/`mixedCaps`, never underscores (except `Test_`/`Benchmark_` grouping). Exported = capitalized.
- Keep names short in proportion to scope: loop indices are `i`, a package-level exported type earns a descriptive name. Short, clear, not cryptic.
- **Avoid stutter.** In package `http`, the type is `Server`, not `HTTPServer` — callers write `http.Server`. Likewise `bytes.Buffer`, not `bytes.BytesBuffer`.
- **No `Get` prefix on getters.** A getter for `owner` is `Owner()`, not `GetOwner()`. Setters keep `Set`.
- **Receiver names** are short (1–2 chars), consistent across all methods on a type, and never `self` or `this`.
- **Reduce nesting:** handle the error/special case first and `return`/`continue` early. Drop the `else` when the `if` already returns.
- Prefer `:=` for explicit values; use `var` for zero values. Never declare an empty slice as `xs := []int{}`.
- A **nil slice is a valid empty slice** — return `nil`, and test emptiness with `len(s) == 0`, never `s == nil`. Use bare `var xs []int` when the size is unknown; when you know the bound (e.g. filtering a slice you hold), **preallocate**: `make([]int, 0, len(src))` to avoid repeated grow-and-copy.

## Errors

- Errors are values returned and handled, not exceptions. **Don't `panic`** in library or request-path code; return an `error` and let the caller decide. Reserve panics for truly unrecoverable startup conditions.
- **Construction:** static message → `errors.New`; dynamic message → `fmt.Errorf`. If callers must *match* the error, expose a sentinel `var ErrFoo = errors.New(...)` (static) or a custom `error` type (dynamic).
- **Wrap with context using `%w`** so callers can `errors.Is`/`errors.As` through it: `fmt.Errorf("open config: %w", err)`. Use `%v` only when you deliberately want to hide the underlying error.
- **Keep context terse.** Drop "failed to" — it piles up. Want `"open config: ..."`, not `"failed to open config: failed to ..."`.
- **Handle each error once.** Log it *or* return it, not both. Logging and returning produces duplicate noise up the stack.
- **Error strings are lowercase, no trailing punctuation** (they get wrapped): `"connection refused"`, not `"Connection refused."`.
- Name sentinels `ErrXxx`/`errXxx`; name custom error types `XxxError`.

## Context

- **Pass `ctx context.Context` as the first parameter**, named `ctx`. Don't store a *request* `Context` in a struct field — thread it through calls. (A long-lived component owning its own shutdown lifecycle is the rare exception.)
- **Never pass a nil `Context`.** If unsure, pass `context.TODO()`; use `context.Background()` at the top of `main`/requests/tests.
- Context carries cancellation, deadlines, and request-scoped values *only* — not optional parameters. Respect `<-ctx.Done()` in anything long-running, and propagate the same `ctx` downward.
- **Don't conflate cancellation with lifecycle.** A cancelled ctx means "abandon and unwind." Graceful shutdown (stop accepting new work, but wait for in-flight work to drain) is a *separate* signal — model it with an intake channel + `WaitGroup`, and give `Shutdown(ctx)` its own ctx that bounds the wait without aborting running jobs. See the worker-pool example in [references/style-guide.md](references/style-guide.md).

## API & package design

- **Package names** are short, lowercase, singular, and meaningful: `url`, not `urls`, `utils`, `common`, or `helpers`. The name is a prefix at every call site, so avoid stutter with the things inside it.
- **Accept interfaces, return concrete types.** Take the narrowest interface you actually use (often one method); hand back the concrete type so callers keep full access.
- **Keep interfaces small** and define them in the *consumer* package, not alongside the implementation.
- **Design for useful zero values** (`sync.Mutex`, `bytes.Buffer` work unused). Avoid embedding that breaks the zero value or leaks a type into your public API.
- For constructors growing past ~3 params or optional config, use the **functional options** pattern (`WithLogger(...)`) instead of long parameter lists or config structs you have to keep extending.
- Verify interface compliance at compile time when it's part of the contract: `var _ http.Handler = (*Handler)(nil)`.

## Going deeper

For the full distilled guide — every rule above with Good/Bad code pairs, plus struct initialization, embedding details, table-driven tests, enums, time handling, and more — read [references/style-guide.md](references/style-guide.md). Consult it when writing non-trivial Go, reviewing a file against conventions, or when a judgment call needs the worked example and rationale.

Primary sources distilled here: the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md), Google's [Go Style Guide](https://google.github.io/styleguide/go/), [Effective Go](https://go.dev/doc/effective_go), and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments).
