'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:51 pm'!

OrderSpec subclass: #IDUpOrder
	instanceVariableNames: 'myIDSpace {IDSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(IDUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!IDUpOrder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} follows: x {Position} with: y {Position}

	x cast: ID into: [ :a | y cast: ID into: [ :b |
		Ravi thingToDo. "more efficient comparison"
		^(b backend isGE: a backend) not
			or: [(a backend isEqual: b backend)
				and: [a number >= b number]]]].
	^false "fodder"!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: IDUpOrder!

{BooleanVar} isFullOrder: keys {XnRegion default: NULL}

	^true!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}
	"Return true if some position in before is less than or equal to all positions in after."
	
	| beforeB {SequenceRegion} afterB {SequenceRegion} bound {Sequence} |
	before cast: IDRegion into: [ :beforeIDs |
	after cast: IDRegion into: [ :afterIDs |
		beforeB := beforeIDs backends.
		afterB := afterIDs backends.
		(SequenceSpace make ascending preceeds: beforeB with: afterB) ifFalse:
			[^false].
		beforeB isBoundedBelow ifFalse:
			[^true].
		bound := beforeB lowerBound.
		(bound isEqual: afterB lowerBound) ifFalse:
			[^true].
		^IntegerSpace make ascending
			preceeds: (beforeIDs iDNumbersFrom: bound)
			with: (afterIDs iDNumbersFrom: bound)]].
	^false "fodder"! !

!IDUpOrder methodsFor: 'accessing'!

{Arrangement} arrange: region {XnRegion}

	| stepper {Stepper} array {PtrArray} |
	region isFinite ifFalse: [Heaper BLAST: #MustBeFinite].
	stepper := (region cast: IDRegion) stepper.
	array := stepper stepMany cast: PtrArray.
	stepper atEnd ifFalse: [self unimplemented].
	^ExplicitArrangement make: array!

{CoordinateSpace} coordinateSpace

	^myIDSpace! !

!IDUpOrder methodsFor: 'create'!

create: space {IDSpace}

	super create.
	myIDSpace := space.! !

!IDUpOrder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myIDSpace _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myIDSpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IDUpOrder class
	instanceVariableNames: ''!

(IDUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!IDUpOrder class methodsFor: 'pseudo constructors'!

{OrderSpec} make: space {IDSpace}

	^self create: space.! !