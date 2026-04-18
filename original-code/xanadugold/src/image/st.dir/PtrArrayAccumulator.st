'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:30 pm'!

Accumulator subclass: #PtrArrayAccumulator
	instanceVariableNames: '
		myValues {PtrArray}
		myN {UInt4}
		myValuesGiven {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-aspire'!
PtrArrayAccumulator comment:
'To save array copies, this class will hand out its internal array if the size is right.  If it does so it remembers so that if new elements are introduced, a copy can be made for further use.'!

(PtrArrayAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!PtrArrayAccumulator methodsFor: 'operations'!

{Accumulator} copy

	^PtrArrayAccumulator create: (myValues copy cast: PtrArray) with: myN!

{void} step: x {Heaper}

	myN + 1 < myValues count ifFalse:
		[myValues := (myValues copyGrow: myValues count+1) cast: PtrArray].
	myValues at: myN store: x.
	myN := myN + 1.!

{Heaper} value

	myValues count == myN
		ifTrue: [
			myValuesGiven := true.
			^ myValues]
		ifFalse: [
			^myValues copy: myN]! !

!PtrArrayAccumulator methodsFor: 'create'!

create
	super create.
	myValues := PtrArray nulls: 2.
	myN := UInt32Zero.
	myValuesGiven := false!

create: count {UInt32}
	super create.
	myValues := PtrArray nulls: count.
	myN := UInt32Zero.
	myValuesGiven := false!

create: values {PtrArray} with: n {UInt32}
	super create.
	myValues := values.
	myN := n.
	myValuesGiven := false! !