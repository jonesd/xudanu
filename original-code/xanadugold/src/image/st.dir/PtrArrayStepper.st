'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:10 pm'!

TableStepper subclass: #PtrArrayStepper
	instanceVariableNames: '
		myArray {PtrArray of: Heaper}
		myIndex {Int32}
		myPastEnd {Int32}
		myStep {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
PtrArrayStepper comment:
'A Stepper for stepping over the elements of a PtrArray in ascending or descending order.  This is a TableStepper even though it is stepping over a PtrArray instead of a table.  Should probably eventually be generalized to PrimArrays. NOT.A.TYPE'!

(PtrArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PtrArrayStepper methodsFor: 'operations'!

{Stepper} copy
	
	^PtrArrayStepper create: (myArray copy cast: PtrArray) with: myIndex with: myPastEnd with: myStep!

{Heaper wimpy} fetch
	
	myIndex >= myPastEnd ifTrue:
		[^NULL].
	^myArray fetch: myIndex!

{BooleanVar} hasValue
	
	^myIndex < myPastEnd!

{void} step
	myIndex _ myIndex + myStep! !

!PtrArrayStepper methodsFor: 'special'!

{IntegerVar} index
	
	myIndex >= myPastEnd ifTrue:
		[Heaper BLAST: #EmptyStepper].
	^myIndex!

{Position} position
	
	myIndex >= myPastEnd ifTrue:
		[Heaper BLAST: #EmptyStepper].
	^myIndex integer! !

!PtrArrayStepper methodsFor: 'private: creation'!

create: array {PtrArray} with: start {Int32} with: pastEnd {Int32} with: step {Int32}

	super create.
	myArray := array.
	myIndex := start.
	myPastEnd := pastEnd.
	myStep := step! !

!PtrArrayStepper methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myArray _ receiver receiveHeaper.
	myIndex _ receiver receiveInt32.
	myPastEnd _ receiver receiveInt32.
	myStep _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myArray.
	xmtr sendInt32: myIndex.
	xmtr sendInt32: myPastEnd.
	xmtr sendInt32: myStep.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PtrArrayStepper class
	instanceVariableNames: ''!

(PtrArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PtrArrayStepper class methodsFor: 'creation'!

{TableStepper} ascending: array {PtrArray}
	"Note: this being a low level operation, and there being no lightweight form of immutable or lazily copied PtrArray, it is my caller's responsibility to pass me a PtrArray which will in fact not be changed during the life of this stepper.  This is an unchecked an uncheckable precondition on my clients."
	 
	^self create: array with: Int32Zero with: array count with: 1!

{TableStepper} descending: array {PtrArray}
	"Note: this being a low level operation, and there being no lightweight form of immutable or lazily copied PtrArray, it is my caller's responsibility to pass me a PtrArray which will in fact not be changed during the life of this stepper.  This is an unchecked an uncheckable precondition on my clients."
	
	^self create: array with: array count - 1 with: -1 with: -1! !