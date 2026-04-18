'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:55 pm'!

OrderSpec subclass: #IntegerUpOrder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(IntegerUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!IntegerUpOrder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^#cat.U.IntegerUpOrder hashForEqual + 1!

{BooleanVar} follows: x {Position} with: y {Position}

	^(x cast: IntegerPos) asIntegerVar >= (y cast: IntegerPos) asIntegerVar!

{BooleanVar} followsInt: x {IntegerVar} with: y {IntegerVar}
	"See discussion in XuInteger class comment about boxed vs unboxed integers"

	^ x >= y!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: IntegerUpOrder!

{BooleanVar} isFullOrder: keys {XnRegion unused default: NULL}
	
	^true!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}
	"Return true if some position in before is less than or equal to all positions in after."
	
	| first {IntegerRegion} second {IntegerRegion} |
	first _ before cast: IntegerRegion.
	second _ after cast: IntegerRegion.
	first isBoundedBelow ifFalse: [^true].
	second isBoundedBelow ifFalse: [^false].
	^first start <= second start! !

!IntegerUpOrder methodsFor: 'accessing'!

{Arrangement} arrange: region {XnRegion}
	^IntegerArrangement make: region with: self.!

{XnRegion} chooseMany: region {XnRegion} with: n {IntegerVar}
	"Return the first n positions in the region according to my ordering."
	
	^(self arrange: region) keysOf: Int32Zero with: n DOTasLong!

{Position} chooseOne: region {XnRegion}
	"Return the first position in the region according to my ordering."
	
	^IntegerPos make: (region cast: IntegerRegion) start!

{CoordinateSpace} coordinateSpace
	
	^IntegerSpace make! !

!IntegerUpOrder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerUpOrder class
	instanceVariableNames: ''!

(IntegerUpOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!IntegerUpOrder class methodsFor: 'pseudoconstructors'!

{OrderSpec} make

	^self create! !