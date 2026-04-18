'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:57 pm'!

AbstractLayout subclass: #ExtentLayout
	instanceVariableNames: '
		heightInternal {IntegerVar}
		widthInternal {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Layout'!

(ExtentLayout getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ExtentLayout methodsFor: 'create/delete'!

create
	super create.
	widthInternal _ IntegerVar0.
	heightInternal _ IntegerVar0!

create: extent {PointPos} 
	super create.
	widthInternal _ extent x.
	heightInternal _ extent y!

create: width {IntegerVar} with: height {IntegerVar} 
	super create.
	widthInternal _ width.
	heightInternal _ height! !

!ExtentLayout methodsFor: 'accessing'!

{PointPos} extent
	^PointPos make: widthInternal with: heightInternal!

{IntegerVar} height
	^heightInternal!

{PointRegion} rectangle
	^PointRegion
		make: IntegerVar0
		with: IntegerVar0
		with: widthInternal
		with: heightInternal!

{PointRegion} region
	^PointRegion
		make: IntegerVar0
		with: IntegerVar0
		with: widthInternal
		with: heightInternal!

{IntegerVar} width
	^widthInternal! !

!ExtentLayout methodsFor: 'transforming'!

{AbstractLayout} scaledBy: scale {PointPos} 
	^ExtentLayout create: widthInternal * scale x with: heightInternal * scale y!

{AbstractLayout} translatedBy: delta {PointPos} 
	^ExtentLayout create: widthInternal + delta x with: heightInternal + delta y! !

!ExtentLayout methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << $( << widthInternal << ',' << heightInternal << $)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExtentLayout class
	instanceVariableNames: ''!

(ExtentLayout getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ExtentLayout class methodsFor: 'pseudoConstructors'!

make
	^ self create: IntegerVar0 with: IntegerVar0!

make: extent {PointPos}

	^ self create: extent!

make: xExtent {IntegerVar} with: yExtent {IntegerVar}
	^ self create: xExtent with: yExtent! !