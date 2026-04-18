'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:10 pm'!

LeafViewer subclass: #FillViewer
	instanceVariableNames: '
		myColor {FMColor}
		myFillRegion {PointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
FillViewer comment:
'Fill all available display area (or just my enclosure, if it''s been specified) with myColor'!

(FillViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FillViewer methodsFor: 'create'!

create: aColor {FMColor} with: anEnclosure {PointRegion}

	super create.
	myColor _ aColor.
	myFillRegion _ anEnclosure! !

!FillViewer methodsFor: 'accessing'!

{void} extent: newExtent {PointPos}

	myFillRegion _ PointRegion regionExtent: newExtent.
	self changedEnclosure!

{XnRegion} regionAt: index {IntegerVar unused}
	"Return the displayRegion occupied by the model position."
	
	self unimplemented.
	^NULL!

{Position} selectionFor: aPoint {PointPos unused}
	"Find the model position corresponding to the display
position (a XuPoint)."

	self unimplemented.
	^NULL!

{void} setEnclosure: newRegion {PointRegion} 
	| myOldEnclosure {PointRegion} |
	myOldEnclosure _ myFillRegion.
	myFillRegion _ newRegion.
	"My enclosure is 'changed' only if I grow (need to paint bits I didn't 
	get last time)"
	(myOldEnclosure == NULL or: 
		[myOldEnclosure left > myFillRegion left or: 
		[myOldEnclosure top > myFillRegion top or: 
		[myOldEnclosure right < myFillRegion right or: 
		[myOldEnclosure bottom < myFillRegion bottom]]]])
		ifTrue: [self changedEnclosure]!

{void} setSubstance: aColor {FMColor} 
	"Just stuff the substance into a variable."

	myColor _ aColor.
	self changedImage!

{FMColor} substance
	"Return the instVar for accessors."

	^myColor! !

!FillViewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp} 
	(aMedium inkColor: myColor) fill: self computeEnclosure.
	self validate! !

!FillViewer methodsFor: 'protected: protected'!

{PointRegion} computeEnclosure
	
	myFillRegion == NULL
		ifTrue: [self hack. "^PointRegion allPoints" ^ PointRegion make: -32768 with: -32768 with: 32767 with: 32767]
		ifFalse: [^ myFillRegion]! !

!FillViewer methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FillViewer class
	instanceVariableNames: ''!

(FillViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FillViewer class methodsFor: 'pseudo constructors'!

make: onColor {FMColor}

	^ self create: onColor with: NULL!

make: onColor {FMColor} with: enclosure {PointRegion} 
	^self create: onColor with: enclosure! !