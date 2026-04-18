'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:58 pm'!

OrderSpec subclass: #SequenceUpOrder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(SequenceUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SequenceUpOrder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} follows: x {Position} with: y {Position}

	^((x cast: Sequence) secretNumbers
		compare: (y cast: Sequence) secretNumbers) >= Int32Zero!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: SequenceUpOrder!

{BooleanVar} isFullOrder: keys {XnRegion unused default: NULL}

	^true!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}
	
	| first {SequenceRegion} second {SequenceRegion} |
	first _ before cast: SequenceRegion.
	second _ after cast: SequenceRegion.
	first isBoundedBelow ifFalse: [^true].
	second isBoundedBelow ifFalse: [^false].
	^(((first secretTransitions fetch: Int32Zero) cast: SequenceEdge)
		isGE: ((second secretTransitions fetch: Int32Zero) cast: SequenceEdge)) not! !

!SequenceUpOrder methodsFor: 'accessing'!

{Arrangement} arrange: region {XnRegion}

	| stepper {Stepper} array {PtrArray} |
	region isFinite ifFalse: [Heaper BLAST: #MustBeFinite].
	stepper := (region cast: SequenceRegion) stepper.
	array := stepper stepMany cast: PtrArray.
	stepper atEnd ifFalse: [self unimplemented].
	^ExplicitArrangement make: array!

{CoordinateSpace} coordinateSpace

	^SequenceSpace make! !

!SequenceUpOrder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceUpOrder class
	instanceVariableNames: ''!

(SequenceUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SequenceUpOrder class methodsFor: 'pseudo constructors'!

{OrderSpec} make

	^self create! !