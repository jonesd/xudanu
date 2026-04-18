'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:15 pm'!

XnModel subclass: #Image
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(Image getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Image methodsFor: 'accessing'!

{PointRegion} enclosure
	self subclassResponsibility! !

!Image methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	self subclassResponsibility! !

!Image methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << 'Image(' << self enclosure << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Image class
	instanceVariableNames: ''!

(Image getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Image class methodsFor: 'extern: global: pseudo constructors'!

{Image} image.void: bits {void star unused}
	[^FormImage create: bits] smalltalkOnly.
	"[^XViewImage create: bits] translateOnly.
	 "
	self subclassResponsibility.
	^ NULL!

{Image} image.XuPoint: point {PointPos unused}
	[^FormImage create: (Form extent: point)] smalltalkOnly.
	self subclassResponsibility.
	^NULL! !

!Image class methodsFor: 'smalltalk: pseudo constructors'!

make.void: bits {void star unused}
	[^FormImage create: bits] smalltalkOnly.
	"[^XViewImage create: bits] translateOnly.
	 "
	self subclassResponsibility.
	^ NULL!

make.XuPoint: point {PointPos unused}
	[^FormImage create: (Form extent: point)] smalltalkOnly.
	self subclassResponsibility.
	^NULL! !