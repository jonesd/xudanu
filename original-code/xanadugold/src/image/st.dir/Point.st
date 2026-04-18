'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:43 pm'!

ArithmeticValue subclass: #Point
	instanceVariableNames: 'x y '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Primitives'!
Point comment:
'Class Point represents an x-y pair of numbers usually designating a location on the screen.

Instance Variables:
	x	<Integer> usually x coordinate
	y	<Integer> usually y coordinate'!


!Point methodsFor: 'accessing'!

x
	"Answer the x coordinate."

	^x!

x: xInteger 
	"Set the x coordinate."

	x _ xInteger!

y
	"Answer the y coordinate."

	^y!

y: yInteger 
	"Set the y coordinate."

	y _ yInteger! !

!Point methodsFor: 'comparing'!

< aPoint 
	"Answer whether the receiver is 'above and to the left' of the 
	argument, aPoint."

	| p |
	p _ aPoint asPoint.
	^x < p x and: [y < p y]!

<= aPoint 
	"Answer whether the receiver is 'neither below nor to the right' of aPoint."

	| p |
	p _ aPoint asPoint.
	^x <= p x and: [y <= p y]!

> aPoint 
	"Answer whether the receiver is 'below and to the right' of aPoint."

	| p |
	p _ aPoint asPoint.
	^x > p x and: [y > p y]!

>= aPoint 
	"Answer whether the receiver is 'neither above nor to the left' of aPoint."

	| p |
	p _ aPoint asPoint.
	^x >= p x and: [y >= p y]!

hash
	"Answer a SmallInteger unique to the receiver."

	^(x hash bitShift: 2) bitXor: y hash!

max: aPoint 
	"Answer the lower right corner of the rectangle uniquely defined  
	by the receiver and aPoint."

	| p |
	p _ aPoint asPoint.
	^Point
		x: (x max: p x)
		y: (y max: p y)!

min: aPoint 
	"Answer the upper left corner of the rectangle uniquely defined 
	by the receiver and aPoint."

	| p |
	p _ aPoint asPoint.
	^Point 
		x: (x min: p x)
		y: (y min: p y)! !

!Point methodsFor: 'arithmetic'!

* scale 
	"Answer a new Point that is the product of the receiver and scale (which is a 
	Point or Number)."

	| scalePoint |
	scalePoint _ scale asPoint.
	^x * scalePoint x @ (y * scalePoint y)!

+ delta 
	"Answer a new Point that is the sum of the receiver and delta (which is a Point 
	or Number)."

	| deltaPoint |
	deltaPoint _ delta asPoint.
	^x + deltaPoint x @ (y + deltaPoint y)!

- delta 
	"Answer a new Point that is the difference of the receiver and delta (which is a 
	Point or Number)."

	| deltaPoint |
	deltaPoint _ delta asPoint.
	^x - deltaPoint x @ (y - deltaPoint y)!

/ scale 
	"Answer a new Point that is the quotient of the receiver and 
	scale (which is a Point or Number)."

	| scalePoint |
	scalePoint _ scale asPoint.
	^x / scalePoint x @ (y / scalePoint y)!

// scale 
	"Answer a new Point that is the quotient of the receiver and scale (which is a 
	Point or Number)."

	| scalePoint |
	scalePoint _ scale asPoint.
	^x // scalePoint x @ (y // scalePoint y)!

abs
	"Answer a new Point whose x and y are the absolute values of the receiver's
	x and y."

	^Point x: x abs y: y abs!

minus:  arg
	^self - arg!

plus: arg
	^self +arg! !

!Point methodsFor: 'truncation and round off'!

rounded
	"Answer a new Point that is the receiver's x and y rounded."

	^x rounded @ y rounded!

truncated
	"Answer a new Point that is the receiver's x and y truncated."

	^x truncated @ y truncated!

truncateTo: grid
	"Answer a new Point that is the receiver's x and y truncated to grid x and grid y."

	(grid isKindOf: Point)
		ifTrue: [^(x truncateTo: grid x) @ (y truncateTo: grid y)]
		ifFalse: [^(x truncateTo: grid) @ (y truncateTo: grid)]! !

!Point methodsFor: 'polar coordinates'!

r
	"Answer the receiver's radius in polar coordinate system."

	^(self dotProduct: self) sqrt!

theta
	"Answer the angle the receiver makes with origin in radians.   
	right is 0; down is 90."

	| tan theta |
	x = 0
		ifTrue: [y >= 0
				ifTrue: [^1.5708"90.0 degreesToRadians"]
				ifFalse: [^4.71239"270.0 degreesToRadians"]]
		ifFalse: 
			[tan _ y asFloat / x asFloat.
			theta _ tan arcTan.
			x >= 0
				ifTrue: [y >= 0
						ifTrue: [^theta]
						ifFalse: [^360.0 degreesToRadians + theta]]
				ifFalse: [^180.0 degreesToRadians + theta]]! !

!Point methodsFor: 'point functions'!

dist: aPoint 
	"Answer the distance between aPoint and the receiver."

	^(aPoint - self) r!

dotProduct: aPoint 
	"Answer a Number that is the dot product of the receiver and the argument, aPoint.
	That is, the two points are multiplied and the coordinates of the result summed."

	^(x* aPoint x) +  (y * aPoint y)!

grid: aPoint 
	"Answer a new Point to the nearest rounded grid modules specified 
	by aPoint."

	| newX newY |

	aPoint x = 0
		ifTrue:	[newX _ 0]
		ifFalse:	[newX _ x roundTo: aPoint x].
	aPoint y = 0
		ifTrue:	[newY _ 0]
		ifFalse:	[newY _ y roundTo: aPoint y].
	^newX @ newY!

nearestIntegerPointOnLineFrom: point1 to: point2 
	"Answer the closest integer point to the receiver on the line 
	determined by (point1, point2)--much faster than the more
	accurate version if the receiver and arguments are integer points"
	"43@55 nearestIntegerPointOnLineFrom: 10@10 to: 100@200"

	| dX dY newX newY dX2 dY2 |
	dX _ point1 x - point2 x.
	dY _ point1 y - point2 y.
	dX = 0
		ifTrue: [dY = 0
				ifTrue: [^point1]
				ifFalse: [^point1 x @ y]]
		ifFalse: [dY = 0
				ifTrue: [^x @ point1 y]].
	dX2 _ dX * dX.
	dY2 _ dY * dY.
	newX _ x * dX2 + (point2 x * dY2) + (y - point2 y * dX * dY) // (dX2 + dY2).
	newY _ x - newX * dX // dY + y.
	^newX @ newY!

nearestPointOnLineFrom: point1 to: point2 
	"Answer the closest point to the receiver on the line 
	determined by (point1, point2)."
	"43@55 nearestPointOnLineFrom: 10@10 to: 100@200"

	| dX dY newX newY dX2 dY2 |
	dX _ point1 x - point2 x.
	dY _ point1 y - point2 y.
	dX = 0
		ifTrue: [dY = 0
				ifTrue: [^point1]
				ifFalse: [^point1 x @ y]]
		ifFalse: [dY = 0
				ifTrue: [^x @ point1 y]].
	dX2 _ dX * dX.
	dY2 _ dY * dY.
	newX _ x * dX2 + (point2 x * dY2) + (y - point2 y * dX * dY) / (dX2 + dY2).
	newY _ x - newX * dX / dY + y.
	^newX @ newY!

normal
	"Answer a new Point representing the unit vector rotated 90 deg 
	toward the y axis."

	^(y negated @ x) unitVector!

pointNearestLine: point1 to: point2
	"Given a line determined by (point1, point2), find the points on the
	line that have either an X or a Y coordinate in common with the
	receiver, and return the one closer to the receiver.

	See Point>>nearestPointOnLineFrom:to: for a more useful message"

	"43@55 pointNearestLine: 10@10 to: 100@200"

	| relPoint delta |
	delta _ point2 - point1. 			"normalize coordinates"
	relPoint _ self - point1.
	delta x = 0 ifTrue: [^point1 x@y].
	delta y = 0 ifTrue: [^x@point1 y].
	delta x abs > delta y abs 		"line more horizontal?"
		ifTrue: [^x@(point1 y + (relPoint x * delta y // delta x))]
		ifFalse: [^(point1 x + (relPoint y * delta x // delta y))@y]!

transpose
	"Answer a new Point whose x is the receiver's y and whose y is the 
	receiver's x."

	^y @ x!

truncatedGrid: aPoint 
	"Answer a new Point to the nearest truncated grid modules specified 
	by aPoint."

	^(x truncateTo: aPoint x) @ (y truncateTo: aPoint y)!

unitVector
	"Answer the receiver scaled to unit length."

	^self / self r! !

!Point methodsFor: 'converting'!

asPoint
	"Answer the receiver itself."

	^self!

corner: aPoint 
	"Answer a new Rectangle whose origin is the receiver and whose corner is aPoint.
	This is one of the infix ways of expressing the creation of a rectangle."

	^Rectangle origin: self corner: aPoint!

extent: aPoint 
	"Answer a new Rectangle whose origin is the receiver and whose extent is aPoint. 
	This is one of the infix ways of expressing the creation of a rectangle."

	^Rectangle origin: self extent: aPoint! !

!Point methodsFor: 'coercing'!

coerce: aNumber
	"Answer a new Point whose coordinates are the argument, aNumber."

	^aNumber asPoint!

generality
	"Answer the number representing the ordering of the receiver in the
	generality hierarchy."

	^180! !

!Point methodsFor: 'transforming'!

scaleBy: factor 
	"Answer a new Point scaled by factor (an instance of Point)."

	^(factor x * x) @ (factor y * y)!

translateBy: delta 
	"Answer a new Point translated by delta (an instance of Point)."

	^(delta x + x) @ (delta y + y)! !

!Point methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream in terms of infix notation."

	x printOn: aStream.
	aStream nextPut: $@.
	y printOn: aStream!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates a point similar to the receiver.  The general format
	for points is
		( class-name x: aNumber y: aNumber)"


	aStream nextPut: $(;
	nextPutAll: self species name;
	nextPutAll: ' x: ';
	store: x;
	nextPutAll: ' y: ';
	store: y;
	nextPut: $).! !

!Point methodsFor: 'testing'!

isZero
	"Answer whether 'self = self class zero'"

	^x isZero and: [y isZero]! !

!Point methodsFor: 'private: private'!

setX: xPoint setY: yPoint 
	"Initialize the instance variables."
	
	x _ xPoint.
	y _ yPoint! !

!Point methodsFor: 'cxx hack'!

asSimpleRegion
	^ self!

cast: aClass
	^aClass == PointPos ifTrue: [self] ifFalse: [super cast: aClass]!

{Heaper} convert: type {Category}
	"do a type conversion and a cast"
	^(Converter fetchConverter: PointPos with: type) convert: self!

extent
	^ self!

isKindOf: category

	^ category == PointPos! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Point class
	instanceVariableNames: ''!


!Point class methodsFor: 'instance creation'!

create: xInteger with: yInteger 
	"Answer a new instance of a Point with coordinates xInteger and yInteger.  This is for c++."

	^self basicNew setX: xInteger setY: yInteger!

x: xInteger y: yInteger 
	"Answer a new instance of a Point with coordinates xInteger and yInteger."

	^self basicNew setX: xInteger setY: yInteger! !

!Point class methodsFor: 'constants access'!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^1@1!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^0@0! !