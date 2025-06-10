## Summary of `show` Method Usage in Julia

### `show(io::IO, x)`
- Used when the type is printed **inside another struct** or explicitly by code.
- Useful for **internal or nested types** (e.g., `SourceLocation`, `GrammarError`).
- Ensures nicely formatted output during **code execution** (e.g., in error handling).
- Does **not** affect REPL or notebook display directly unless called explicitly.

### `show(io::IO, ::MIME"text/plain", x)`
- Used when the type is shown **at the top level** in the **REPL**, **Jupyter**, or **Pluto**.
- Needed for **user-facing types** like `Point`, `Vec`, `ColorTypes.RGB`, etc.
- Controls how the object is printed when users directly enter it in the REPL or notebook cells.
- Also used by `string(x)` internally to produce string representations, so defining this affects how `string(x)` looks.

### Best Practice
- For **internal or error types** only used programmatically (e.g., `SourceLocation`, `GrammarError`), defining just `show(io::IO, x)` is usually sufficient.
- For **user-facing or interactive types**, define **both** methods for full compatibility:

```julia
function Base.show(io::IO, x::MyType)
    print(io, "MyType(...)")
end

function Base.show(io::IO, ::MIME"text/plain", x::MyType)
    show(io, x)  # Delegate to plain version
end
