# DoubleEnded [![Tests](https://github.com/OpenModelica/DoubleEnded.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/OpenModelica/DoubleEnded.jl/actions/workflows/CI.yml)

`DoubleEnded` provides `MutableList`, a mutable double-ended list.
It stores its elements in the immutable singly linked list of
[ImmutableList.jl](https://github.com/OpenModelica/ImmutableList.jl) and keeps
pointers to the first and the last cell. Pushing and popping at the front
and pushing at the back take O(1). The length is stored, so `length` is O(1).

## Installation

The package is in the OpenModelica registry
(<https://github.com/OpenModelica/OpenModelicaRegistry>). The General registry
must also be present: ExportAll.jl and ImmutableList.jl are resolved from it.

```julia
using Pkg
Pkg.Registry.add(Pkg.RegistrySpec(url="https://github.com/OpenModelica/OpenModelicaRegistry"))
Pkg.add("DoubleEnded")
```

The development version:

```julia
using Pkg
Pkg.add(url="https://github.com/OpenModelica/DoubleEnded.jl")
```

Requirements: Julia 1.13. Dependencies: ExportAll.jl, ImmutableList.jl.

## Usage

```julia
using DoubleEnded
using ImmutableList

delst = DoubleEnded.fromList(list(1, 2, 3))   # MutableList{Int64}
DoubleEnded.push_front(delst, 0)
DoubleEnded.push_back(delst, 4)
println(length(delst))                        # 5
println(DoubleEnded.pop_front(delst))         # 0
println(collect(delst))                       # [1, 2, 3, 4]
lst = DoubleEnded.toListAndClear(delst)       # the ImmutableList 1, 2, 3, 4; delst is empty
```

## Functions

The argument names below are the ones in `src/DoubleEnded.jl`. Each function
has a docstring: `?DoubleEnded.push_back` in the REPL.

`MutableList` and all functions are exported (`@exportAll`), except `empty`:
call it as `DoubleEnded.empty`. `length` and iteration extend Base.

Constructors:

- `new(first)`: a list with the one element `first`. The element type is `typeof(first)`.
- `fromList(lst)`: a list with the elements of the ImmutableList `lst`, in order, O(n). The list does not share cells with `lst`. `fromList(nil)` returns a `MutableList{Any}`.
- `empty(dummy)`: an empty list of element type `typeof(dummy)`.
- `empty()`: an empty `MutableList{Any}`.

Queries:

- `length(delst)`: the number of elements, O(1).
- `currentBackCell(delst)`: the last cell, or `nil` if `delst` is empty.
- `toListNoCopyNoClear(delst)`: the first cell as an ImmutableList, without copying or clearing `delst`. If `delst` is non-empty, in-place changes (`push_back`, `mapNoCopy_1`, `mapFoldNoCopy`) show through the returned list. `push_front`, `pop_front` and `clear` do not. If `delst` is empty, the result is `nil` and stays `nil`.
- `for x in delst` and `collect(delst)`: iterate front to back.

Adding elements (`elt` is converted to the element type with `convert`):

- `push_front(delst, elt)`: prepends `elt`, O(1). Returns `delst`.
- `push_back(delst, elt)`: appends `elt`, O(1). Returns `delst`.
- `push_list_front(delst, lst)`: prepends the elements of the ImmutableList `lst`, O(n). Returns `delst`.
- `push_list_back(delst, lst)`: appends the elements of the ImmutableList `lst`, O(n). Returns `delst`.

Removing elements:

- `pop_front(delst)`: removes and returns the first element. Throws `ArgumentError` if `delst` is empty.
- `clear(delst)`: removes all elements. Returns `delst`.
- `toListAndClear(delst; prependToList = nil)`: returns the elements as an ImmutableList, followed by `prependToList`, and clears `delst`. The splice is O(1).

In-place maps:

- `mapNoCopy_1(delst, inMapFunc, inArg1)`: replaces each element `e` by `inMapFunc(e, inArg1)`. Returns `delst`.
- `mapFoldNoCopy(delst, inMapFunc, arg)`: starts with `acc = arg`. For each element `e`, `(newElt, newAcc) = inMapFunc(e, acc)` replaces `e` by `newElt` and sets `acc = newAcc`. Returns the final `acc`.

`_iter` is an internal helper of the iteration. It is exported by `@exportAll`
but is not part of the API.

## Tests

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

The test environment needs the `Test` standard library only. CI runs this on
Julia 1.13 (`.github/workflows/CI.yml`).

## License

The code is licensed under the GNU Affero General Public License v3 or the
OSMC Public License v1.8, at the recipient's choice (source file header). The
full texts are in `LICENSE.md`.
