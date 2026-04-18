'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:10 pm'!

Stepper subclass: #MergeStepper
	instanceVariableNames: '
		myA {Stepper of: Position}
		myB {Stepper of: Position}
		myOrder {OrderSpec}
		myValue {Position | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
MergeStepper comment:
'A Stepper for doing a merge-sort like ordered interleaving of two other steppers.  It is assumed that the other two steppers are constructed so that their values are also produced in order according to the same OrderSpec.  A tree of these operates much like a heap as found in heapsort.'!

(MergeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!MergeStepper methodsFor: 'operations'!

{Stepper} copy

	myValue == NULL ifTrue:
		[^Stepper emptyStepper].
	^MergeStepper
		create: myA copy
		with: myB copy
		with: myOrder
		with: myValue!

{Heaper wimpy} fetch
	
	^myValue!

{BooleanVar} hasValue
	
	^myValue ~~ NULL!

{void} step
	
	| a {Position} b {Position} |
	a := myA fetch cast: Position.
	b := myB fetch cast: Position.
	a == NULL ifTrue:
		[b == NULL ifTrue:
			[myValue := NULL]
		ifFalse:
			[myValue := b.
			myB step]]
	ifFalse:
		[b == NULL ifTrue:
			[myValue := a.
			myA step]
		ifFalse:
			[(myOrder follows: a with: b) ifTrue:
				[myValue := b.
				myB step.
				(a isEqual: b) ifTrue:
					[myA step]]
			ifFalse:
				[myValue := a.
				myA step.
				(a isEqual: b) ifTrue:
					[myB step]]]]! !

!MergeStepper methodsFor: 'private: creation'!

create: a {Stepper of: Position} 
	with: b {Stepper of: Position} 
	with: order {OrderSpec} 
	with: value {Position | NULL}
	
	super create.
	myA := a.
	myB := b.
	myOrder := order.
	myValue := value.
	value == NULL ifTrue:
		[self step]! !

!MergeStepper methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myA _ receiver receiveHeaper.
	myB _ receiver receiveHeaper.
	myOrder _ receiver receiveHeaper.
	myValue _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myA.
	xmtr sendHeaper: myB.
	xmtr sendHeaper: myOrder.
	xmtr sendHeaper: myValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MergeStepper class
	instanceVariableNames: ''!

(MergeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!MergeStepper class methodsFor: 'pseudoconstructors'!

{Stepper} make: a {Stepper of: Position} 
	with: b {Stepper of: Position} 
	with: order {OrderSpec}
	
	^self create: a with: b with: order with: NULL! !