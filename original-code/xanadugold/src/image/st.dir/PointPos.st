'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:23 pm'!

Tuple subclass: #PointPos
	instanceVariableNames: '
		myX {IntegerVar}
		myY {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(PointPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PointPos methodsFor: 'creating'!

create
	super create.
	myX _ IntegerVar0.
	myY _ IntegerVar0!

create: x {IntegerVar} with: y {IntegerVar} 
	super create.
	myX _ x.
	myY _ y! !

!PointPos methodsFor: 'Converting'!

{PointRegion} corner: aPoint{PointPos unused} 
	 self unimplemented.
	 ^NULL!

{PointRegion} extent: aPoint{PointPos unused} 
	"Answer a new region whose origin is the receiver and whose extent is aPoint. 
	This is one of the infix ways of expressing the creation of a rectangle."
self unimplemented.
^NULL
"	^ PointRegion make.XuPoint: self with: ((self convert: Dsp) of: aPoint)"!

{PointPos} transpose
	^ PointPos create: myY with: myX! !

!PointPos methodsFor: 'accessing'!

{XnRegion} asRegion

	^PointRegion make: myX with: myY with: myX + 1 with: myY + 1!

{PtrArray of: Position} coordinates

	^ (PrimSpec pointer arrayWithTwo: myX integer with: myY integer) cast: PtrArray!

{CoordinateSpace INLINE} coordinateSpace
	^PointSpace make!

{PointPos} minus: otherPoint {PointPos} 
	^PointPos create: self x - otherPoint x with: self y - otherPoint y!

{PointPos} plus: otherPoint {PointPos} 
	^PointPos create: self x + otherPoint x with: self y + otherPoint y!

{IntegerVar INLINE} x
	^myX!

{IntegerVar INLINE} y
	^myY! !

!PointPos methodsFor: 'comparing'!

{UInt32} hashForEqual

	[IntegerPos] USES.
	^myX DOTasLong + myY DOTasLong + #cat.U.IntegerPos hashForEqual!

{BooleanVar} isEqual: other {Heaper} 

	other
		cast: PointPos into: [:op |
			^myX == op x and: [myY == op y]]
		others: [^false].
	^false "fodder"! !

!PointPos methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'xP' << '(' << myX << '@' << myY << ')'! !

!PointPos methodsFor: 'smalltalk: smalltalk only'!

asSTPoint
	^ myX @ myY! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointPos class
	instanceVariableNames: ''!

(PointPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PointPos class methodsFor: 'pseudo-constructors'!

make
	"Return the origin."
	
	^PointPos create: IntegerVar0 with: IntegerVar0!

make: x {IntegerVar} with: y {IntegerVar}
	"Just create a smalltalk point for the moment."
	
	^PointPos create: x with: y! !

!PointPos class methodsFor: 'smalltalk: smalltalk pmake'!

make.Point: smalltalkPoint
	^ self make: smalltalkPoint x with: smalltalkPoint y! !