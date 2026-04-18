'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:44 pm'!

FMController subclass: #FMBitEditor
	instanceVariableNames: '
		myView {Viewer}
		myImage {Image}
		myPen {Image}
		imageWarp {Warp}'
	classVariableNames: 'UnitBox {PointRegion} '
	poolDictionaries: ''
	category: 'FM-Control'!
FMBitEditor comment:
'The controller for a simple bit editor.  This should use the information in Traverse events to draw at least a line on the image.

the color is either nil or a one-bit image that can be quickly displayed onto the imageInternal.  The imageWarp is just a cache for fast displaying.  The cachedWarp should exist only during a click and drag.

The bit editor should really apply a transformation to the first position, then read back the results and paint with that.'!

(FMBitEditor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMBitEditor methodsFor: 'create/delete'!

create: aView {Viewer} with: anImage {Image} 
	super create.
	myView _ aView.
	myImage _ anImage.
	imageWarp _ Warp make: myImage with: myImage enclosure.
	myPen _ NULL! !

!FMBitEditor methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	
	event selectDownFn ifTrue: 
		[| point {PointPos} |
		point _ event pointIn: myView.
		myPen _ self getPen: point.
		self draw: myPen point: point].
	event selectUpFn ifTrue: [myPen _ NULL].
	event traverse ifTrue: [self draw: myPen point: (event pointIn: myView)]!

{BooleanVar} requestEvents: event {FMEvent}
	myPen == NULL
		ifTrue: [^ event selectDownFn]
		ifFalse: [^ event traverse or: [event selectUpFn]]! !

!FMBitEditor methodsFor: 'private: actions-private'!

{void} draw: aPen {Image} point: aPoint{PointPos}
	"draw at aPoint using the current pen"

	imageWarp
		copyBits: UnitBox
		from: aPen
		at: aPoint!

{Image} getPen: aPoint {PointPos} 
	"Return the color to be used when drawing starts at a
particular point."

	| pen {Image} dWarp {Warp} |
	pen _ Image image.XuPoint: ((PointPos make: 1 with: 1) basicCast: PointPos).
	dWarp _ Warp make: pen with: pen enclosure.
	dWarp copyBits: (PointRegion make: aPoint)
		from: myImage
		at: (PointPos make).
	(dWarp inkColorMap: FMColorMap selectColorMap) fill: UnitBox.
	^pen! !

!FMBitEditor methodsFor: 'protected: creation'!

{void} destruct
	imageWarp _ NULL.
	super destruct! !

!FMBitEditor methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMBitEditor class
	instanceVariableNames: ''!

(FMBitEditor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMBitEditor class methodsFor: 'smalltalk: smalltalk initialization'!

{void} initTimeNonInherited
	UnitBox _  PointRegion regionExtent: (PointPos make: 1 with: 1)!

{void}linkTimeNonInherited
	UnitBox _  NULL! !