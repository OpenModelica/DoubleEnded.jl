#= /*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
* c/o Linköpings universitet, Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
* THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
* RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL VERSION 3,
* ACCORDING TO RECIPIENTS CHOICE.
*
* The OpenModelica software and the OSMC (Open Source Modelica Consortium)
* Public License (OSMC-PL) are obtained from OSMC, either from the above
* address, from the URLs:
* http://www.openmodelica.org or
* https://github.com/OpenModelica/ or
* http://www.ida.liu.se/projects/OpenModelica,
* and in the OpenModelica distribution.
*
* GNU AGPL version 3 is obtained from:
* https://www.gnu.org/licenses/licenses.html#GPL
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
*
*/ =#

"""
  Author: John Tinnerholm

  Mirrors the MetaModelica record:

      uniontype MutableList<T>
        record LIST
          Mutable<Integer> length;
          Mutable<list<T>> front;
          Mutable<list<T>> back;
        end LIST;
      end MutableList;

  `front` and `back` hold actual `ImmutableList` cons cells. `back` points to
  the LAST cell, so `push_back` is O(1) via `listSetRest` (in-place tail
  update of the last cell). `nil` is the empty value, shared with the rest
  of the OM.jl runtime.
"""
module DoubleEnded

using ExportAll
using ImmutableList
using ImmutableList.Unsafe: listSetFirst, listSetRest

mutable struct MutableList{T}
  length::Int
  front::Union{Nil, Cons{T}}
  back::Union{Nil, Cons{T}}
end

MutableList{T}() where {T} = MutableList{T}(0, nil, nil)

"""
  Creates a new MutableList with one element of type T.
"""
function new(first::T) where {T}
  local cell = Cons{T}(first, nil)
  MutableList{T}(1, cell, cell)
end

"""
  Converts an ImmutableList into a MutableList. The returned MutableList
  shares cells with the input list; mutating the MutableList may therefore
  mutate the source list. (Same convention as the MetaModelica original.)
"""
function fromList(::Nil)
  MutableList{Any}()
end

function fromList(lst::Cons{T}) where {T}
  local mlst = MutableList{T}()
  for e in lst
    push_back(mlst, e)
  end
  mlst
end

"""
  Creates a new empty MutableList. The dummy element fixes the element
  type T at the call site.
"""
function empty(dummy::T) where {T}
  MutableList{T}()
end

empty() = MutableList{Any}()

"""
  Returns the length of the MutableList.
"""
Base.length(delst::MutableList) = delst.length

"""
  Pops and returns the first element of the MutableList.
"""
function pop_front(delst::MutableList{T}) where {T}
  delst.front isa Nil && throw(ArgumentError("pop_front on empty MutableList"))
  local cell = delst.front::Cons{T}
  local popped = cell.head
  delst.front = cell.tail
  if delst.front isa Nil
    delst.back = nil
  end
  delst.length -= 1
  popped
end

"""
  Returns the current back cell of the MutableList, or `nil` if empty.
"""
currentBackCell(delst::MutableList) = delst.back

"""
  Prepends an element at the front of the MutableList.
"""
function push_front(delst::MutableList{T}, elt) where {T}
  local cell = Cons{T}(convert(T, elt), delst.front)
  delst.front = cell
  if delst.back isa Nil
    delst.back = cell
  end
  delst.length += 1
  delst
end

"""
  Prepends the immutable list lst at the front of the MutableList.
"""
function push_list_front(delst::MutableList, lst::List)
  for e in listReverse(lst)
    push_front(delst, e)
  end
  delst
end

"""
  Pushes an element at the back of the MutableList in O(1).
  Mutates the previous back cell's tail to point to the new cell.
"""
function push_back(delst::MutableList{T}, elt) where {T}
  local newCell = Cons{T}(convert(T, elt), nil)
  if delst.back isa Nil
    delst.front = newCell
  else
    listSetRest(delst.back::Cons{T}, newCell)
  end
  delst.back = newCell
  delst.length += 1
  delst
end

"""
  Appends the ImmutableList lst at the back of the MutableList.
"""
function push_list_back(delst::MutableList, lst::List)
  for e in lst
    push_back(delst, e)
  end
  delst
end

"""
  Returns the contents as an ImmutableList and clears the MutableList.
  When `prependToList` is non-empty the result is the MutableList contents
  followed by `prependToList`; this splice is O(1) via `listSetRest` on the
  back cell.
"""
function toListAndClear(delst::MutableList{T};
                        prependToList::Union{Nil, Cons{T}} = nil) where {T}
  if delst.length == 0
    clear(delst)
    return prependToList
  end
  if !(prependToList isa Nil)
    listSetRest(delst.back::Cons{T}, prependToList)
  end
  local result = delst.front
  clear(delst)
  result
end

"""
  Returns an ImmutableList view of the contents without copying or
  clearing the MutableList. Subsequent mutations of the MutableList are
  visible through the returned list.
"""
function toListNoCopyNoClear(delst::MutableList)
  delst.front
end

"""
  Resets the MutableList to empty.
"""
function clear(delst::MutableList)
  delst.front = nil
  delst.back = nil
  delst.length = 0
  delst
end

"""
  Applies inMapFunc(elt, inArg1) to each element in delst, mutating in place.
"""
function mapNoCopy_1(delst::MutableList{T}, inMapFunc::Function, inArg1) where {T}
  local cur = delst.front
  while !(cur isa Nil)
    local cell = cur::Cons{T}
    listSetFirst(cell, convert(T, inMapFunc(cell.head, inArg1)))
    cur = cell.tail
  end
  delst
end

"""
  Folds delst in place with inMapFunc(elt, acc) -> (newElt, newAcc).
  Returns the final accumulator.
"""
function mapFoldNoCopy(delst::MutableList{T}, inMapFunc::Function, arg) where {T}
  local cur = delst.front
  local argo = arg
  while !(cur isa Nil)
    local cell = cur::Cons{T}
    local newHead, newAcc = inMapFunc(cell.head, argo)
    listSetFirst(cell, convert(T, newHead))
    argo = newAcc
    cur = cell.tail
  end
  argo
end

"""
  Iterate over the elements of a MutableList in order.
"""
Base.iterate(delst::MutableList) = _iter(delst.front)
Base.iterate(::MutableList, state) = _iter(state)
Base.eltype(::Type{MutableList{T}}) where {T} = T
Base.IteratorSize(::Type{<:MutableList}) = Base.HasLength()

@inline _iter(::Nil) = nothing
@inline _iter(cell::Cons) = (cell.head, cell.tail)

@exportAll

end #= DoubleEnded =#
