'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:54 pm'!

OrderSpec subclass: #RealUpOrder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(RealUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!RealUpOrder methodsFor: 'accessing'!

{Arrangement} arrange: region {XnRegion}

	| stepper {Stepper} array {PtrArray} |
	region isFinite ifFalse: [Heaper BLAST: #MustBeFinite].
	stepper := (region cast: RealRegion) stepper.
	array := stepper stepMany cast: PtrArray.
	stepper atEnd ifFalse: [self unimplemented].
	^ExplicitArrangement make: array!

{CoordinateSpace} coordinateSpace
	
	^RealSpace make! !

!RealUpOrder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^#cat.U.RealUpOrder hashForEqual + 1!

{BooleanVar} follows: x {Position} with: y {Position}
	
	MarkM thingToDo. "128 bit values"
	^(x cast: RealPos) asIEEE64 >= (y cast: RealPos) asIEEE64!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: RealUpOrder!

{BooleanVar} isFullOrder: keys {XnRegion default: NULL}
	
	^true!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}

	before cast: RealRegion into: [ :br |
		br isBoundedBelow ifFalse:
			[^true].
		after cast: RealRegion into: [ :ar |
			^ar isBoundedBelow not
				and: [self follows: ar lowerBound with: br lowerBound]]].
	^false "fodder"! !

!RealUpOrder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RealUpOrder class
	instanceVariableNames: ''!

(RealUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!RealUpOrder class methodsFor: 'creation'!

{OrderSpec} make

	^self create! !