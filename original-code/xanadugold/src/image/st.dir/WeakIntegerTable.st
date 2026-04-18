'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:02 pm'!

ActualIntegerTable subclass: #WeakIntegerTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(WeakIntegerTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WeakIntegerTable methodsFor: 'create'!

create
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."
	super create.
	elements _ WeakPtrArray make: 8!

create.IntegerVar: size {IntegerVar} 
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."

	super create.IntegerVar: size.
	elements _ WeakPtrArray make: elemCount!

create: begin {IntegerVar} with: end {IntegerVar} 
	"Hint at the domain to be accessed (inclusive, exclusive)."

	super create: begin with: end.
	elements _ WeakPtrArray make: elemCount!

{void} enlargeAfter: toMinimum {IntegerVar}
	"Enlarge the receiver to contain more slots filled with nil."

	| newElements{PtrArray} oldElements {PtrArray wimpy} tmp {UInt4 register} newSize {UInt4} |
	newSize _ elemCount * 2.
	newSize < 4 ifTrue: [newSize _ 4].
	(newSize < (tmp _ (toMinimum - start) DOTasLong + 1)) ifTrue: [newSize _ tmp].
	newElements _ WeakPtrArray make: newSize.
	UInt40 almostTo: elemCount do: [:i {UInt4 register} | newElements at: i store: (elements fetch: i)].
	"Just for the hell of it, I make this robust for asynchronous readers..."
	oldElements _ elements.
	elements _ newElements.
	oldElements destroy.
	elemCount _ newSize.
	tally == UInt40 ifTrue: [firstElem _ elements count - 1]!

{void} enlargeBefore: toMinimum {IntegerVar} 
	"Enlarge the receiver to contain more slots filled with nil."

	| newSize {UInt4} newElements {PtrArray} oldElements {PtrArray wimpy} offset {UInt4 register} tmp {UInt4 register} stop {IntegerVar} |
	stop _ start + elemCount.
	newSize _ elemCount * 2.
	newSize < 4 ifTrue: [newSize _ 4].
	newSize < (tmp _ (stop - toMinimum) DOTasLong + 1) ifTrue: [newSize _ tmp].
	newElements _ WeakPtrArray make: newSize.
	offset _ newSize - elemCount.
	UInt40 almostTo: elemCount do: [:i {UInt4 register} | newElements at: i + offset store: (elements fetch: i)].
	oldElements _ elements.
	elements _ newElements.
	oldElements destroy.
	start _ stop - newSize.
	firstElem _ firstElem + offset.
	lastElem _ lastElem + offset.
	elemCount _ newSize! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeakIntegerTable class
	instanceVariableNames: ''!

(WeakIntegerTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WeakIntegerTable class methodsFor: 'pseudoConstructors'!

{IntegerTable} make
	^ WeakIntegerTable create.!

{IntegerTable} make.IntegerVar: someSize {IntegerVar}
	^ WeakIntegerTable create.IntegerVar: someSize! !