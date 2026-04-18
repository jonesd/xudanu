'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:58 pm'!

AbstractLayout subclass: #RegionLayout
	instanceVariableNames: 'myRegion {PointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Layout'!

(RegionLayout getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RegionLayout methodsFor: 'create/delete'!

create: region {PointRegion} 
	super create. 
	myRegion _ ((region intersect: AbstractLayout maxLayoutRegion) basicCast: Heaper) basicCast: PointRegion! !

!RegionLayout methodsFor: 'accessing'!

{PointPos} extent
	^myRegion extent!

{PointRegion} rectangle
	^myRegion asSimpleRegion quickCast: PointRegion!

{PointRegion} region
	^myRegion! !

!RegionLayout methodsFor: 'transforming'!

{AbstractLayout} scaledBy: scale {PointPos unused} 
	self unimplemented.
	^NULL!

{AbstractLayout} translatedBy: delta {PointPos}
	[Converter] USES.
	^RegionLayout create: (((delta convert: Dsp)
			ofAll: myRegion)
			quickCast: PointRegion)! !

!RegionLayout methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myRegion << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RegionLayout class
	instanceVariableNames: ''!

(RegionLayout getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RegionLayout class methodsFor: 'smalltalk: smalltalk only'!

make: thing 
	^(thing isKindOf: PointRegion)
		ifTrue: [self make.PointRegion: thing]
		ifFalse: [self make.XuPoint: thing]! !

!RegionLayout class methodsFor: 'pseudo constructors'!

{RegionLayout} emptyLayout
	"Return an empty Layout."
	
	^self create: PointRegion make.!

make
	"Return a full Layout."
	^self create: AbstractLayout maxLayoutRegion!

make.PointRegion: region {PointRegion}
	"Return a layout for the region."
	^self create: region!

make.XuPoint: point {PointPos} 
	"Return a layout for the region."

	^self create: (PointRegion regionExtent: point)! !