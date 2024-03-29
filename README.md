# DoubleEnded

**A Double ended mutable list for Julia**

This package provides a DoubleEnded mutable list.
It is provided to be used in conjunction with the singly linked immutable list,
provided in ImmutableList.jl.

This package contains the defintion
along with various utility methods to get the head and the tail in constant time.

## MutableList

`MutableList` is a single linked and double ended list.
* Usage:
```julia
  lst1::List = nil
  dLst1::DoubleEnded.MutableList = DoubleEnded.fromList(lst1) #Creates an empty double ended list
  dLst2::DoubleEnded.MutableList = DoubleEnded.empty #Same as above
  #Creates a double ended list from the immutable list (1,2,3)
  dLst2::DoubleEnded.MutableList = DoubleEnded.fromList(ImmutableList.list(1,2,3))
```
* Utility functions:
```julia

"""
  Creates a new Mutable list with one element, first of type T.
"""
new

"""
  Converts an Immutable list, lst into an MutableList.
"""
fromList

"""
  Creates a new empty MutableList
"""
empty

"""
  Returns the length of the MutableList, delst
"""
length

"""
  Pops and returns the first element of the MutableList, delst.
"""
pop_front
"""
  Returns the current back cell of the MutableList, delst.
"""
currentBackCell

"""
  Prepends an element elt at the front of the MutableList delst.
"""
push_front

"""
  Prepends the immutable list lst at the front of the MutableList, delst.
"""
push_list_front

"""
  Pushes an element elt at the back of the mutable list delst.
"""
push_back

"""
  Appends the ImmutableList lst at the back of the MutableList delst.
"""
push_list_back

"""
  Returns an immutable List and clears the MutableList
"""
toListAndClear

"""
  Returns an Immutable list without changing the MutableList.
"""
toListNoCopyNoClear

"""
  Resets the MutableList.
"""
clear

"""
  This function takes a higher order function(inMapFunc) and one argument(ArgT1).
  It applies these function to each element in the list mutating it and by doing so updating
  the list.
"""
mapNoCopy_1

"""
  This functions folds a MutableList, delst using inMapFunc together with the extra argument arg.
"""
mapFoldNoCopy
```
