'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:58 pm'!

ActualArray subclass: #MuWeakArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(MuWeakArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MuWeakArray methodsFor: 'create'!

{ScruTable} copy
	^ MuWeakArray create: (WeakPtrArray make: elements count with: elements) with: tally!

create
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."
	super create.
	elements _ WeakPtrArray make: 4.
	tally _ UInt40!

create.IntegerVar: size {IntegerVar} 
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."
	| newSize {UInt4} |
	super create.
	newSize _ (size > 4 ifTrue: [size DOTasLong] ifFalse: [4]).
	elements _ WeakPtrArray make: newSize.
	tally _ UInt40!

{void} enlarge
	"Enlarge the receiver to contain more slots filled with nil."

	| newElements {PtrArray of: Heaper} oldElements {PtrArray wimpy of: Heaper} |
	newElements _ WeakPtrArray make: (elements count * 2) with: elements.
	"Just for the hell of it, I make this robust for asynchronous readers..."
	oldElements _ elements.
	elements _ newElements.
	oldElements destroy! !