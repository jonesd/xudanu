'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:23 pm'!

Warp subclass: #ScaledWarp
	instanceVariableNames: '
		warpInternal {Warp}
		scaleInternal {PointPos}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!

(ScaledWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScaledWarp methodsFor: 'accessing'!

{PointRegion}enclosure
	^self unTransform: warpInternal enclosure!

{Color} ink
	^warpInternal ink!

{Warp} inkColor: colorObj{Color}
	"colorObj describes the new color to be used for drawing."!

{Warp} inkColorMap: colorMap {ColorMap} 
	"colorObj describes the new color to be used for drawing."

	^self unimplemented! !

!ScaledWarp methodsFor: 'transforming'!

{Warp}intersect: encl {XnRegion} 
	^ScaledWarp
		create: (warpInternal intersect: (self transform: encl))
		with: scaleInternal!

{Warp} intersect: encl {XnRegion} translateBy: aDsp {Dsp} 
	^ScaledWarp
		create: (warpInternal intersect: (self transform: encl) translateBy: aDsp)
		with: scaleInternal!

{ScaledWarp} scaleBy: aPoint {PointPos} 
	^aPoint = scaleInternal reciprocal
		ifTrue: [warpInternal]
		ifFalse: [ScaledWarp create: warpInternal with: scaleInternal * aPoint]!

{Heaper}transform: anObject{Heaper}
	^anObject scaledBy: scaleInternal!

{PointPos}transformPoint: pos {PointPos}
	^pos * scaleInternal!

{ScaledWarp} translateBy: aPoint {PointPos} 
	^ScaledWarp
		create: (warpInternal translatedBy: (self transformPoint: aPoint))
		with: scaleInternal!

{Heaper}unTransform: anObject{Heaper}
	^anObject scaledBy: scaleInternal reciprocal! !

!ScaledWarp methodsFor: 'display'!

{void}copyBits: encl{PointRegion} from: source{Image} at: pos{PointPos}
	"Display a rectangle from sourceForm into the receiver."
	"If encl is smaller than the form, it might be more efficient to make a new, 
	smaller form, then magnify that."

	warpInternal
		copyBits: (self transform: encl)
		from: (source magnifyBy: scaleInternal)
		at: (self transformPoint: pos)!

{void}display: string{MuWordArray} from: startIndex{IntegerVar} to: stopIndex{IntegerVar} attributes: atts{AttributeGroup} at: displayPos{PointPos}  
	"This is the text display primitive."

self unimplemented!

{void} drawFrom: startPoint {PointPos} to: stopPoint {PointPos}
	"Draw a line from startPoint to stopPoint."

	warpInternal drawFrom: (self transformPoint: startPoint) to: (self transformPoint: stopPoint)!

{void}fill: encl {PointRegion}
	"Replace a rectangular area of the receiver with the pattern described by aForm 
	according to the rule anInteger."

	warpInternal fill: (self transform: encl)! !

!ScaledWarp methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << $( << warpInternal << ' scaleBy: ' << scaleInternal << $)! !

!ScaledWarp methodsFor: 'create'!

create: warp{Warp} with: scale{PointPos}
	warpInternal _ warp.
	scaleInternal _ scale! !