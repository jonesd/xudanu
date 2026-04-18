'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:31 pm'!

Image subclass: #XViewImage
	instanceVariableNames: 'myEnclosure {PointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!
XViewImage comment:
'Todo stuff


'!

(XViewImage getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewImage methodsFor: 'testing'!

{UInt32} hashForEqual!

{BooleanVar} isEqual: other {Heaper}! !

!XViewImage methodsFor: 'creation'!

create.void: bits {void star} 
	super create.
	myEnclosure _ PointRegion make.
	
	" this is incorrect fix when we find what the bits are"!

create.XuPoint: point {PointPos} 
	super create.
	myEnclosure _ PointRegion make: point.! !

!XViewImage methodsFor: 'accessing'!

{PointRegion} enclosure
^myEnclosure! !

!XViewImage methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewImage class
	instanceVariableNames: ''!

(XViewImage getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewImage class methodsFor: 'global: pseudo constructors'!

{Image} image.void: bits {void star  }
	 
	 ^XViewImage create:   bits  .!

{Image} image.XuPoint: point {PointPos  }
	 
	 ^XViewImage create:   point  .! !