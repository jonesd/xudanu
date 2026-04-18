'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:10 pm'!

Stepper subclass: #MergeBundlesStepper
	instanceVariableNames: '
		myA {Stepper of: FeBundle}
		myB {Stepper of: FeBundle}
		myOrder {OrderSpec}
		myValue {FeBundle | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!
MergeBundlesStepper comment:
'A Stepper for doing a merge-sort like ordered interleaving of two other steppers.  It is assumed that the other two steppers are constructed so that their values are also produced in order according to the same OrderSpec.  A tree of these operates much like a heap as found in heapsort.'!

(MergeBundlesStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!MergeBundlesStepper methodsFor: 'operations'!

{Stepper} copy

	myValue == NULL ifTrue:
		[^Stepper emptyStepper].
	^MergeBundlesStepper
		create: myA copy
		with: myB copy
		with: myOrder
		with: myValue!

{Heaper wimpy} fetch
	
	^myValue!

{BooleanVar} hasValue
	
	^myValue ~~ NULL!

{void} step
	| a {FeBundle} b {FeBundle} |
	a := myA fetch cast: FeBundle.
	b := myB fetch cast: FeBundle.
	a == NULL ifTrue: 
		[myValue := b.
		b ~~ NULL ifTrue: [myB step].
		^VOID].
	b == NULL ifTrue: 
		[myValue := a.
		myA step.
		^VOID].
	(myOrder preceeds: a region with: b region)
		ifTrue: 
			[myValue := a.
			myA step]
		ifFalse: 
			[myValue := b.
			myB step]! !

!MergeBundlesStepper methodsFor: 'private: creation'!

create: a {Stepper of: Position} 
	with: b {Stepper of: Position} 
	with: order {OrderSpec} 
	with: value {FeBundle | NULL}
	
	super create.
	myA := a.
	myB := b.
	myOrder := order.
	myValue := value.
	value == NULL ifTrue:
		[self step]! !

!MergeBundlesStepper methodsFor: 'generated:'!

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

MergeBundlesStepper class
	instanceVariableNames: ''!

(MergeBundlesStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!MergeBundlesStepper class methodsFor: 'creation'!

{Stepper} make: a {Stepper of: FeBundle} 
	with: b {Stepper of: FeBundle} 
	with: order {OrderSpec}
	
	a hasValue ifFalse: [^b].
	b hasValue ifFalse: [^a].
	^self create: a with: b with: order with: NULL! !