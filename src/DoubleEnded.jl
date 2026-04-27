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
  This package provides a DoubleEnded list with various utility methods.
"""
module DoubleEnded

import DataStructures

using ExportAll
using ImmutableList
using DataStructures: LinkedList
include("linkedListAliases.jl")

"""
  Defintion of the Double ended mutable list
"""
mutable struct MutableList{T}
  length::Int
  front::LinkedList{T}
  back::LinkedList{T}
end

"""
  Creates a new Mutable list with one element, first of type T.
"""
function new(first::T) where {T}
  lst = DataStructures.list(first)
  MutableList(1, lst, lst)
end

"""
  Converts an Immutable list, lst into an MutableList.
"""
function fromList(lst::List{T})  where {T}
  #= Rethink this, maybe =#
  if lst isa Nil
    return MutableList(0, llist(), llist())
  end
  #= Otherwise we loop =#
  local linkedLst::LinkedList = lnil()
  local cntr::Int = 0
  for i in lst
    linkedLst = lcons(i, linkedLst)
    cntr += 1
  end
  local linkedLst = reverse(linkedLst)
  local newFront = linkedLst
  local cntr2::Int = 0
  local backList::LinkedList = linkedLst
  for i in 1:cntr - 1
    backList = backList.tail
  end
  MutableList(cntr, newFront, backList)
end

"""
  Creates a new empty MutableList
"""
function empty(dummy::T)  where {T}
  MutableList(0, llist(), llist())
end

"""
  Creates a new empty MutableList
"""
function empty()
  MutableList(0, llist(), llist())
end

"""
  Returns the length of the MutableList, delst
"""
function Base.length(delst::MutableList)
  delst.length
end

"""
  Pops and returns the first element of the MutableList, delst.
"""
function pop_front(delst::MutableList{T})  where {T}
  if length==1 then
    delst.front = llist()
    delst.back = llist()
    delst.length = 0
  end
  popped_elem = delst.front.head
  delst.front = delst.front.tail
  delst.length -= 1
  popped_elem
end

"""
  Returns the current back cell of the MutableList, delst.
"""
function currentBackCell(delst::MutableList)
  delst.back
end

"""
  Prepends an element elt at the front of the MutableList delst.
"""
function push_front(delst::MutableList, elt::T)  where {T}
  if ! (delst.front isa DataStructures.Nil)
    local currentHead = delst.front.head
    delst.front = lcons(elt, lcons(currentHead, delst.front.tail))
    delst.length += 1
  else
    throw("Cannot push a list at the front of an empty list.")
  end
  return delst
end

"""
  Prepends the immutable list lst at the front of the MutableList, delst.
"""
function push_list_front(delst::MutableList, lst::List{T})  where {T}
  for e in listReverse(lst)
    push_front(delst, e)
  end
end

"""
  Pushes an element elt at the back of the mutable list delst.
"""
function push_back(delst::MutableList, elt::T)  where {T}
  local newTail = lcons(elt ,llist())
  delst.back.tail = lcons(delst.back.head, newTail)
  delst.back = newTail
  delst.length += 1
end

"""
  Appends the ImmutableList lst at the back of the MutableList delst.
"""
function push_list_back(delst::MutableList, lst::List{T})  where {T}
  for e in lst
    push_back(delst, e)
  end
end

"""
  Returns an immutable List and clears the MutableList
"""
function toListAndClear(delst::MutableList, prependToList::List{T} = nil)  where {T}
  local linkedLst::LinkedList = lnil()
  local pl = prependToList
  for i in reverse(delst.front)
    pl = i <| pl
  end
  clear(delst)
  pl
end

"""
  Returns an Immutable list without changing the MutableList.
"""
function toListNoCopyNoClear(delst::MutableList{T})  where {T}
  local res::List{T} = nil
  for i in lst:-1:1
    res = i <| res
  end
end

"""
  Resets the MutableList.
"""
function clear(delst::MutableList{T})  where {T}
  delst.back = lnil()
  delst.front = lnil()
  delst.length = 0
end

"""
  This function takes a higher order function(inMapFunc) and one argument(ArgT1).
  It applies these function to each element in the list mutating it and by doing so updating
  the list.
"""
function mapNoCopy_1(delst::MutableList, inMapFunc::Function, inArg1::ArgT1)  where {ArgT1}
  local tmp::LinkedList = delst.front
  while !(tmp isa DataStructures.Nil)
    local headValue = tmp.head
    tmp.head = inMapFunc(headValue, inArg1)
    tmp = tmp.tail
  end
end

"""
  This functions folds a MutableList. Delst using inMapFunc together with the extra argument arg.
"""
function mapFoldNoCopy(delst::MutableList{T}, inMapFunc::Function, arg::ArgT1)  where {T, ArgT1}
  local tmp::LinkedList = delst.front
  #= Our fold storage =#
  local argo = arg
  while !(tmp isa DataStructures.Nil)
    local headValue = tmp.head
    local res
    (res, argo) = inMapFunc(headValue, argo)
    #= Mutate the list element =#
    tmp.head = res
    tmp = tmp.tail
  end
  #= We return void =#
  argo
end

@exportAll

end #= DoubleEnded =#
