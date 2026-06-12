# Idiomatic Go — Reference

Worked guidance distilled from the Uber Go Style Guide, Google's Go Style Guide, Effective Go, and Go Code Review Comments. Examples are illustrative and original. When in doubt, run `gofmt`/`goimports`, `go vet`, and `staticcheck`, and match the surrounding package.

## Contents

- [Naming & style](#naming--style)
- [Control flow & declarations](#control-flow--declarations)
- [Errors](#errors)
- [Context](#context)
- [API & package design](#api--package-design)
- [Structs, interfaces & embedding](#structs-interfaces--embedding)
- [Enums, time & maps/slices](#enums-time--mapsslices)
- [Testing](#testing)

---

## Naming & style

**MixedCaps, never underscores.** Exported identifiers start uppercase, unexported lowercase. The only common underscores are in test names for grouping (`TestParse_EmptyInput`).

**Scope drives length.** A name's length should match how far it travels. A receiver or loop variable is one or two letters; a package-level exported symbol earns a full descriptive name. Short is good; cryptic is not.

**Avoid stutter.** The package name is already a prefix at the call site.

```go
// Bad — callers write http.HTTPServer
package http
type HTTPServer struct{}

// Good — callers write http.Server
package http
type Server struct{}
```

**Getters omit `Get`.** Setters keep `Set`.

```go
// Bad
func (u *User) GetName() string { return u.name }

// Good
func (u *User) Name() string     { return u.name }
func (u *User) SetName(n string) { u.name = n }
```

**Consistent, short receiver names.** Pick one and use it on every method of the type. Never `self` or `this`.

```go
// Bad — inconsistent, and "this" is not idiomatic
func (this *Client) Send() {}
func (c *Client) Close()   {}

// Good
func (c *Client) Send()  {}
func (c *Client) Close() {}
```

**Don't shadow built-ins.** Names like `error`, `string`, `len`, `copy`, `new` as variables create confusing, hard-to-grep code.

**Doc comments are full sentences that start with the name** of the thing they document. This is what `go doc` renders.

```go
// Reader reads bytes from an underlying source.
type Reader struct{ /* ... */ }

// Read fills p and returns the number of bytes read.
func (r *Reader) Read(p []byte) (int, error) { /* ... */ }
```

---

## Control flow & declarations

**Handle errors first, return early, flatten nesting.**

```go
// Bad
for _, v := range items {
    if v.Valid() {
        if err := v.Process(); err == nil {
            v.Commit()
        } else {
            return err
        }
    } else {
        log.Printf("invalid: %v", v)
    }
}

// Good
for _, v := range items {
    if !v.Valid() {
        log.Printf("invalid: %v", v)
        continue
    }
    if err := v.Process(); err != nil {
        return err
    }
    v.Commit()
}
```

**Drop the unnecessary `else`** when the `if` branch already assigns or returns.

```go
// Bad
var level int
if verbose {
    level = 10
} else {
    level = 1
}

// Good
level := 1
if verbose {
    level = 10
}
```

**Reduce variable scope.** Scope a value to the `if` when you don't need it afterward.

```go
// Good
if err := os.WriteFile(name, data, 0o644); err != nil {
    return err
}
```

But don't contort flow to do it — if you need the result later, declare it plainly above the `if` rather than nesting everything in an `else`.

**`:=` for explicit values, `var` for zero values.** Don't allocate an empty slice with `[]int{}` just to declare it — a nil slice is a valid empty slice and appends to it fine.

```go
// Bad — pointless allocation
filtered := []int{}
```

Which empty form to reach for depends on whether you know the size:

```go
// Good (size unknown / likely small) — nil, ready to append, zero allocation if nothing matches
var filtered []int
for _, v := range list {
    if v > 0 {
        filtered = append(filtered, v)
    }
}

// Better (bound known) — preallocate capacity to avoid repeated grow-and-copy
filtered := make([]int, 0, len(list))
for _, v := range list {
    if v > 0 {
        filtered = append(filtered, v)
    }
}
```

When you're filtering or mapping a slice you already hold, you know the result is at most `len(list)`, so `make([]T, 0, len(list))` is the idiomatic choice — it sizes the backing array once instead of reallocating as the slice grows. Reserve the bare `var s []T` form for when the final size is genuinely unknown or expected to stay small/empty (it costs nothing until the first append). See also [Specify capacity when you know the size](#enums-time--mapsslices).

Check emptiness with `len(s) == 0`, never `s == nil`. Return `nil`, not `[]T{}`, for empty results.

**`defer` for cleanup.** Pair acquisition with `defer` release immediately so early returns can't skip it.

```go
mu.Lock()
defer mu.Unlock()
```

---

## Errors

**Errors are values.** Return them; don't `panic` to signal ordinary failure. Panic only for the truly unrecoverable (e.g. a programming invariant violated at startup). In `main`, exit via `os.Exit`/`log.Fatal` in exactly one place; everything else returns errors.

**Choosing how to build an error:**

| Caller must match it? | Message | Use |
|---|---|---|
| No | static | `errors.New("...")` |
| No | dynamic | `fmt.Errorf("...%s", x)` |
| Yes | static | package-level `var ErrX = errors.New("...")` |
| Yes | dynamic | a custom type implementing `error` |

```go
// Matchable sentinel
var ErrNotFound = errors.New("not found")

// Matchable dynamic error
type ValidationError struct{ Field string }

func (e *ValidationError) Error() string {
    return fmt.Sprintf("invalid field %q", e.Field)
}
```

Callers match with `errors.Is` (sentinels) or `errors.As` (types):

```go
if errors.Is(err, ErrNotFound) { /* ... */ }

var verr *ValidationError
if errors.As(err, &verr) { /* use verr.Field */ }
```

**Wrap with `%w` to add context while preserving the chain.** Keep context short and drop "failed to".

```go
// Bad — vague, and "failed to" stacks up into noise
return fmt.Errorf("failed to load configuration file: %v", err)

// Good — concise, unwrappable
return fmt.Errorf("load config %q: %w", path, err)
```

Use `%v` instead of `%w` only when you intend to *hide* the wrapped error from callers (it can't be unwrapped).

**Handle each error once.** Logging *and* returning the same error duplicates it up the stack.

```go
// Bad
if err != nil {
    log.Printf("get user: %v", err)
    return err
}

// Good — caller will handle/log it
if err != nil {
    return fmt.Errorf("get user %q: %w", id, err)
}
```

Logging is the right "handling" only when you recover and degrade gracefully (e.g. best-effort metrics) and do *not* return the error.

**Error string style:** lowercase, no trailing punctuation, since they're usually wrapped mid-sentence. Name sentinel vars `ErrXxx`/`errXxx`; name custom types `XxxError`.

**Use the comma-ok form** for type assertions so a wrong type returns gracefully instead of panicking.

```go
s, ok := v.(string)
if !ok {
    return fmt.Errorf("expected string, got %T", v)
}
```

---

## Context

**First parameter, named `ctx`.**

```go
func (s *Service) Fetch(ctx context.Context, id string) (*Item, error)
```

**Don't store a *request-scoped* `Context` in a struct.** Pass it explicitly through the call chain. A stored request ctx hides lifetime and tends to get reused after it's already cancelled or for an operation it never belonged to.

```go
// Bad — which request does this ctx belong to? When is it stale?
type Worker struct{ ctx context.Context }

// Good — ctx flows in per call
func (w *Worker) Do(ctx context.Context) error
```

The exception is a **long-lived component that owns its own lifetime** (a pool, server, or daemon). Such a type legitimately holds a base context or a `cancel` func representing *its* lifecycle — that's different from stashing a caller's request ctx, and it's how graceful shutdown is built (see below). Note the standard library does store a ctx on `http.Request`, surfaced through `r.Context()` rather than a public field.

**Never pass `nil`.** Use `context.TODO()` when you don't yet have one to thread through; use `context.Background()` at the true top (in `main`, top of a request, or in tests).

**Context is for cancellation, deadlines, and request-scoped values** — not a bag for optional arguments. Honor cancellation in anything that blocks or loops, and pass the *same* `ctx` downward (optionally deriving a child with `context.WithTimeout`/`WithCancel`).

```go
func (s *Service) poll(ctx context.Context) error {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-ticker.C:
            s.flush()
        }
    }
}
```

### Cancellation is not lifecycle: graceful shutdown

A request ctx and a component's shutdown are *different signals*, and a single cancellable context can't express both. For an operation, "ctx cancelled" means **abandon the work and unwind now**. But a long-lived component like a worker pool usually has two distinct shutdown moments that one ctx conflates:

1. **Stop accepting new work** — refuse or stop enqueuing new jobs.
2. **Drain in-flight work** — let already-accepted jobs finish.

Model these as separate mechanisms: close an intake channel (or flip a flag) for (1), and a `sync.WaitGroup` for (2). A `Shutdown(ctx)` method then takes *its own* ctx that bounds **how long you'll wait for the drain** — crucially, that ctx does **not** cancel the running jobs.

```go
type Pool struct {
    jobs chan func(context.Context)
    wg   sync.WaitGroup
}

func New(workers int) *Pool {
    p := &Pool{jobs: make(chan func(context.Context))}
    p.wg.Add(workers)
    for range workers {
        go func() {
            defer p.wg.Done()
            for job := range p.jobs { // exits once jobs is closed AND drained
                job(context.Background())
            }
        }()
    }
    return p
}

// Submit enqueues work. Contract: stop calling Submit before Shutdown
// (the sender is responsible for not sending on a closed channel).
func (p *Pool) Submit(job func(context.Context)) { p.jobs <- job }

// Shutdown stops intake and waits for queued + in-flight jobs to finish,
// or until ctx fires. Cancelling ctx bounds the WAIT; it does not abort the jobs.
func (p *Pool) Shutdown(ctx context.Context) error {
    close(p.jobs) // (1) stop intake; workers drain what's already queued

    done := make(chan struct{})
    go func() { p.wg.Wait(); close(done) }() // (2) drain

    select {
    case <-done:
        return nil // graceful: everything finished
    case <-ctx.Done():
        return ctx.Err() // gave up waiting — jobs may still be running
    }
}
```

If you *also* want the option to hard-abort in-flight jobs (say, on a second Ctrl-C), give the jobs a **separate** cancellable context — one the pool owns and can cancel — and pass that to `job(jobCtx)` instead of `context.Background()`. Now you have two independent levers: cancel `jobCtx` to abort running work, and `Shutdown(ctx)` to stop intake and bound the drain. Don't try to overload a single context with both meanings; wire up the signal each caller actually needs.

---

## API & package design

**Package names: short, lowercase, singular, meaningful.** No `util`, `common`, `shared`, `helpers`, `base`. No plurals (`url`, not `urls`). The name prefixes everything inside, so choose it to avoid stutter.

**Accept interfaces, return concrete types.** Depend on the narrowest behavior you use; return the concrete type so callers keep full functionality.

```go
// Good — accepts a minimal interface, returns a concrete type
func NewScanner(r io.Reader) *Scanner { /* ... */ }
```

**Keep interfaces small, and define them where they're consumed.** One- or two-method interfaces compose best (`io.Reader`, `io.Writer`). Don't ship a broad interface next to its only implementation "just in case" — let the consumer declare exactly what it needs.

**Functional options for expandable constructors.** When a constructor has more than ~3 parameters or optional knobs you expect to grow, prefer options over a long signature or an ever-growing config struct.

```go
type Server struct {
    addr   string
    logger *log.Logger
    tls    bool
}

type Option func(*Server)

func WithLogger(l *log.Logger) Option { return func(s *Server) { s.logger = l } }
func WithTLS() Option                 { return func(s *Server) { s.tls = true } }

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{addr: addr, logger: log.Default()} // sensible defaults
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Callers pay only for what they need:
//   NewServer(":8080")
//   NewServer(":8080", WithTLS(), WithLogger(l))
```

**Verify interface compliance at compile time** when implementing a contract:

```go
var _ http.Handler = (*Handler)(nil)
```

**Avoid mutable package-level globals.** Inject dependencies (including things like `time.Now`) instead, so code stays testable and free of hidden shared state.

---

## Structs, interfaces & embedding

**Initialize with field names.**

```go
// Bad — positional, breaks silently on field reorder
u := User{"Ada", "Lovelace", true}

// Good
u := User{FirstName: "Ada", LastName: "Lovelace", Admin: true}
```

Omit zero-value fields unless naming them adds clarity. For an all-zero struct, prefer `var u User` over `u := User{}`. Use `&T{...}` rather than `new(T)` for references.

**Design useful zero values.** `var b bytes.Buffer` and `var mu sync.Mutex` are usable immediately. Don't break that property.

**Embed consciously.** Embedding promotes the inner type's exported methods *and a field by its name* into your public API, which constrains future changes. Don't embed for convenience or cosmetics.

```go
// Bad — leaks Lock/Unlock into the public API of SafeMap
type SafeMap struct {
    sync.Mutex
    data map[string]int
}

// Good — mutex is an unexported implementation detail
type SafeMap struct {
    mu   sync.Mutex
    data map[string]int
}
```

Litmus test: would you add *every* promoted method/field to the outer type by hand? If only some, use a named field and write the few delegating methods you actually want. Put embedded fields at the top of the struct, separated by a blank line. Never embed a mutex.

**Copy slices and maps at boundaries.** Storing a caller's slice/map (or returning your internal one) shares mutable state. Copy when you need isolation.

```go
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = make([]Trip, len(trips))
    copy(d.trips, trips)
}
```

---

## Enums, time & maps/slices

**Start enums at 1** (with `iota + 1`) unless the zero value is a meaningful default, so an unset value is distinguishable.

```go
type State int

const (
    StateActive State = iota + 1
    StatePaused
    StateClosed
)
```

**Use `time.Time` for instants and `time.Duration` for periods** — never bare `int` seconds/millis. When crossing a boundary that can't carry them (e.g. JSON), put the unit in the field name (`TimeoutMillis`).

```go
// Bad
func poll(delay int) // seconds? millis?

// Good
func poll(delay time.Duration)
// poll(5 * time.Second)
```

**Specify capacity when you know the size**, to cut allocations.

```go
items := make([]Item, 0, len(src))
seen  := make(map[string]struct{}, len(src))
```

Use a map literal for a fixed set; use `make` for maps built up programmatically.

---

## Testing

**Table-driven tests with subtests** keep repetitive cases readable. Convention: the slice is `tests`, each case `tt`, inputs prefixed `give`, expectations `want`.

```go
func TestSplit(t *testing.T) {
    tests := []struct {
        give     string
        wantHost string
        wantPort string
    }{
        {give: "host:80", wantHost: "host", wantPort: "80"},
        {give: ":80", wantHost: "", wantPort: "80"},
    }
    for _, tt := range tests {
        t.Run(tt.give, func(t *testing.T) {
            host, port, err := net.SplitHostPort(tt.give)
            require.NoError(t, err)
            assert.Equal(t, tt.wantHost, host)
            assert.Equal(t, tt.wantPort, port)
        })
    }
}
```

Keep table bodies flat: if a case needs branching (per-case mock setup, conditional assertions), split it into separate `Test...` functions instead. Prefer `t.Fatal`/`t.FailNow` over `panic` in tests.
