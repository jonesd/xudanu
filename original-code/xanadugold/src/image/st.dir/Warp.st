'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:25 pm'!

Heaper subclass: #Warp
	instanceVariableNames: '
		dspInternal {Dsp}
		restrictInternal {XnRegion}
		driveInternal {WarpDrive}
		myColor {FMColor}
		myColorMap {FMColorMap}
		myInkImage {Image}
		myCachedHash {UInt4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!
Warp comment:
'A Warp represents the capability to draw.  It
is stateless.  Clients of a warp are given the capability,
which they may copy, subdivide, or modify and pass on to
other clients.
	
old comment:
	Transformations on a warp produces a transformed warp
onto the same bits.  Thus, ''warp translateBy: offset''
creates a new warp with the origin moved by offset.  The
net effect is to translate supplied arguments by the same
amount.  This is opposite from the Viewers convention of
translating the bits by the offset.  This new convention
should be easier to explain.

obsolete comment:
Do warps have an enclosure?  Remember that enclosures
contain a transformation as well as a region.

not obsolete:
Warp transforms are separate from point and layout
transforms because they include color and intersection
transforms.

Combination rule and mask go together in DisplayStyle
objects.  These objects also represent color tables for
the move operation.'!

(Warp getOrMakeCxxClassDescription)
	friends:
'/* friends for class Warp */
friend SPTR(Warp) warp (Dsp *, XuRegion *, WarpDrive *);
friend SPTR(Warp) warp (Dsp *, XuRegion *, WarpDrive *, FMColor *, FMColorMap *, Image *);
friend class WarpDrive;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Warp methodsFor: 'coloring'!

{Warp} black
	"Return a warp that will draw in black."

	^self inkColor: FMColor fmBlackColor!

{Warp} inkColor: color {FMColor} 
	"Create a new warp that uses color as its ink for painting. All draw/paint/etc. 
	operations use the current ink to change the actual display. Painting with a 
	color simply overrides the existing colors on the display display in the areas 
	painted."

	^Warp create: dspInternal with: restrictInternal with: driveInternal
		with: color with: myColorMap with: NULL!

{Warp} inkColorMap: colorMap {FMColorMap} 
	"Create a new warp that uses colorMap as its ink for painting. All draw/paint/etc. 
	operations use the current ink to change the actual display. Painting with a 
	colorMap transforms the color in the area of the paint operations according to colorMap."
	^Warp make: dspInternal with: restrictInternal with: driveInternal
		with: myColor with: colorMap with: myInkImage!

{Warp} inkImage: image {Image} 
	"Create a new warp that uses image as its ink for painting. All draw/paint/etc. 
	operations use the current ink to change the actual display.  Painting with an
	image uses the image essentially as a halftone, replicating all over the area to be displayed.
	This can be combined with a colorMap."
	^Warp make: dspInternal with: restrictInternal with: driveInternal
		with: NULL with: myColorMap with: image!

{Warp} white
	"Return a warp that will draw in white."

	^self inkColor: FMColor fmWhiteColor! !

!Warp methodsFor: 'bordering'!

{void} borderWidth: aRegion {PointRegion} with: borderWidth {IntegerVar} 
	"Paint a border whose rectangular area is defined by aRectangle. The width of 
	the border of each side is borderWidth. Uses Form black for drawing the 
	border."

	self fill: (aRegion minus: (aRegion insetByInt: borderWidth))!

{void} borderWidths: aRegion {PointRegion} with: insets {PointPos} 
	"Paint a border whose rectangular area is defined by aRegion. The 
	width of each edge of the border is determined by the four 
	coordinates of insets."

	self fill: (aRegion minus: (aRegion insetByPoint: insets))! !

!Warp methodsFor: 'displaying'!

{void} copyBits: encl {PointRegion} from: source {Image} at: pos {PointPos} 
	"copy all the bits of source that fall within encl to the receiver, 
	translated so that the origin of the coordinate system of encl would 
	be at pos."

	| dispRect {PointRegion} |
	self setupDrive.
	dispRect _ ((encl intersect: source enclosure)
				intersect: (dspInternal inverseOfAll: restrictInternal)) cast: PointRegion.
	driveInternal engine
		copyBits: dispRect
		from: source
		at: ((dspInternal of: pos) cast: PointPos)!

{void} display: chars {MuWordArray} from: startIndex {IntegerVar} to: stopIndex {IntegerVar} attributes: atts {AttributeGroup} at: displayPos {PointPos} 
	"This is the basic string display primitive. display the run of 
	characters from startIndex to stopIndex from chars. The entire run is displayed with 
	the same attributes, described in atts. Display the run at displayPos in the 
	receiver's coordinate system."

	self setupDrive.
	driveInternal engine
		display: chars
		from: startIndex
		to: stopIndex
		attributes: atts
		at: ((dspInternal of: displayPos) cast: PointPos)
		with: (restrictInternal cast: PointRegion) extent!

{void}drawFrom: startPoint{PointPos} to: stopPoint{PointPos}
	"Draw a line from the startPoint to the stopPoint.  We don't currently use this, so it can be safely ignored for the moment."
	
	self setupDrive.
	driveInternal engine drawFrom: ((dspInternal of: startPoint) cast: PointPos)
		to: ((dspInternal of: stopPoint) cast: PointPos)!

{void} fill: region {XnRegion} 
	"Fill region with the current ink."


^VOID.
	"region isEmpty not ifTrue: [
	 
	self setupDrive.
		driveInternal engine fill: (((dspInternal of.Region: region)
				intersect: restrictInternal)
				cast: PointRegion)]"! !

!Warp methodsFor: 'smalltalk: smalltalk only'!

boundingBox
	self passe.
	^self enclosure!

copyBits: sourceRect from: sourceForm at: destOrigin clippingBox: clipRect rule: rule mask: aForm 
	"Copy into the rectangle sourceRect within the receiver those pits from the form
	sourceForm starting at position destOrigin according to the mixing rule rule and with
	aForm as the mask.  Clip the receiver's destination rectangle with respect to clipRect."
	"The clipping rectangle can only be my enclosure, so ignore it."


	self passe.	self copyBits: sourceRect from: sourceForm at: destOrigin!

{Warp}darkGray
	"Return a warp that will draw in darkGray."

	self passe.
	^self ink.Halftone: Form darkGray!

{Warp}gray
	"Return a warp that will draw in gray."

	self passe.
	^self ink.Halftone: Form gray!

{Warp}lightGray
	"Return a warp that will draw in lightGray."

	self passe.
	^self ink.Halftone: Form lightGray!

reverse

	self passe.	(self black inkColorMap: FMColorMap selectColorMap) fill: (self enclosure)!

{Warp}veryLightGray
	"Return a warp that will draw in veryLightGray."

	self passe.
	^self ink.Halftone: Form veryLightGray! !

!Warp methodsFor: 'transforming'!

{Warp} intersect: encl {XnRegion} 
	"Return a new warp that occupies the region of the current warp 
	intersent encl."

	^Warp
		make: dspInternal
		with: (restrictInternal intersect: encl)
		with: driveInternal
		with: myColor
		with: myColorMap
		with: myInkImage!

{Warp} intersect: encl {XnRegion} translateBy: aDsp {Dsp} 
	"This is equivalent to '(self intersect: encl) translateBy: aPoint'. It's 
	simply so common in scroll and multi-views that we have a special operation 
	for it. This operation will go away eventually."

	^Warp
		make: (dspInternal compose: aDsp)
		with: (restrictInternal intersect: (dspInternal ofAll: encl))
		with: driveInternal
		with: myColor
		with: myColorMap
		with: myInkImage!

{Warp} transformedBy: aDsp {Dsp} 
	"Return a new warp transformed by the dsp."

	^Warp
		make: (dspInternal compose: aDsp)
		with: restrictInternal
		with: driveInternal
		with: myColor
		with: myColorMap
		with: myInkImage!

{PointPos} transformPoint: pos {PointPos} 
	"This will be sent by other warps (ScaledWarps in particular), but 
	doesn't need to be implemented yet."

	^(dspInternal of: pos) cast: PointPos!

{PointPos} untransform.Point: pos {PointPos} 
	"This will be sent by other warps (ScaledWarps in particular), but 
	doesn't need to be implemented yet."

	^(dspInternal inverseOf: pos) cast: PointPos! !

!Warp methodsFor: 'accessing'!

{PointRegion} enclosure
	"Return the simpleRegion for the area that the receiver occupies in 
	local coordinates. For reference: 'self fill: self enclosure' will 
	completely paint the receiver in its current ink."

	^(dspInternal inverseOfAll: restrictInternal)
		cast: PointRegion! !

!Warp methodsFor: 'testing'!

{UInt32} hashForEqual
	myCachedHash == UInt32Zero
		ifTrue: [myCachedHash _ dspInternal hashForEqual
						 + restrictInternal hashForEqual 
						 + driveInternal hashForEqual.
			myColor ~~ NULL 
				ifTrue: [myCachedHash _ myCachedHash + myColor hashForEqual].
			myColorMap ~~ NULL 
				ifTrue: [myCachedHash _ myCachedHash + myColorMap hashForEqual].
			myInkImage ~~ NULL 
				ifTrue: [myCachedHash _ myCachedHash + myInkImage hashForEqual]].
	^myCachedHash!

{BooleanVar} isEqual: other {Heaper} 

	other == self ifTrue: [^true].
	other
		cast: Warp into: [:otherWarp |
			(dspInternal isEqual: otherWarp dsp) ifFalse: [^false].
			(restrictInternal isEqual: otherWarp restricted) ifFalse: [^false].
			(driveInternal isEqual: otherWarp drive) ifFalse: [^false].
			myColor == NULL
				ifTrue: [otherWarp fetchColor == NULL ifFalse: [^false]]
				ifFalse: [otherWarp fetchColor == NULL
						ifTrue: [^false]
						ifFalse: [(myColor isEqual: otherWarp fetchColor)
								ifFalse: [^false]]].
			myColorMap == NULL
				ifTrue: [otherWarp fetchColorMap == NULL ifFalse: [^false]]
				ifFalse: [otherWarp fetchColorMap == NULL
						ifTrue: [^false]
						ifFalse: [(myColorMap isEqual: otherWarp fetchColorMap)
								ifFalse: [^false]]].
			myInkImage == NULL
				ifTrue: [otherWarp fetchInkImage == NULL ifFalse: [^false]]
				ifFalse: [otherWarp fetchInkImage == NULL
						ifTrue: [^false]
						ifFalse: [(myInkImage isEqual: otherWarp fetchInkImage)
								ifFalse: [^false]]].
			^true]
		others: [^false]! !

!Warp methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' on (' << self enclosure.
	myColor ~~ NULL ifTrue: [oo << ', color: ' << myColor].
	myColorMap ~~ NULL ifTrue: [oo << ', colorMap: ' << myColorMap].
	myInkImage ~~ NULL ifTrue: [oo << ', inkImage: ' << myInkImage].
	oo << ')'! !

!Warp methodsFor: 'private: creation'!

create: dsp {Dsp} with: restrict {XnRegion} with: drive
{WarpDrive}
	super create.
	dspInternal _ dsp.
	restrictInternal _ restrict.
	driveInternal _ drive.
	myColor _ NULL.
	myColorMap _ NULL.
	myInkImage _ NULL.
	myCachedHash _ UInt32Zero!

create: dsp {Dsp} with: restrict {XnRegion} with: drive
{WarpDrive} with: color {FMColor} with: colorMap
{FMColorMap} with: image {Image}
	super create.
	dspInternal _ dsp.
	restrictInternal _ restrict.
	driveInternal _ drive.
	myColor _ color.
	myColorMap _ colorMap.
	myInkImage _ image.
	myCachedHash _ UInt32Zero!

{void} destruct

	dspInternal _ NULL.
	restrictInternal _ NULL.
	driveInternal _ NULL.
	myColor _ NULL.
	myColorMap _ NULL.
	myInkImage _ NULL.
	super destruct! !

!Warp methodsFor: 'private: accessing'!

{WarpDrive} drive

	^ driveInternal!

{Dsp} dsp

	^ dspInternal!

{FMColor} fetchColor
	^myColor!

{FMColorMap} fetchColorMap
	^myColorMap!

{Image} fetchInkImage
	^myInkImage!

{XnRegion} restricted

	^ restrictInternal! !

!Warp methodsFor: 'incremental redisplay'!

{void} display: viewer {Viewer} 
	"This routine is called to get a viewer displayed (on a WarpDrive) 
	appropriately shuffled by the warp."

	driveInternal display: viewer using: self! !

!Warp methodsFor: 'private: setup'!

{void} setupDrive
	"set up the warp drive with the color, color map, and ink parameters"

	(driveInternal setupFrom: self)
		ifFalse: 
			[driveInternal inkColor: myColor.
			driveInternal inkColorMap: myColorMap.
			driveInternal inkImage: myInkImage.
			[driveInternal engine clipRect: restrictInternal] smalltalkOnly]! !

!Warp methodsFor: 'smalltalk: passe'!

{Warp} ink: ink {Heaper}
	"Return a new warp with a new drawing ink."

	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Warp class
	instanceVariableNames: ''!

(Warp getOrMakeCxxClassDescription)
	friends:
'/* friends for class Warp */
friend SPTR(Warp) warp (Dsp *, XuRegion *, WarpDrive *);
friend SPTR(Warp) warp (Dsp *, XuRegion *, WarpDrive *, FMColor *, FMColorMap *, Image *);
friend class WarpDrive;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Warp class methodsFor: 'private: pseudoconstructor'!

make: dsp {Dsp} with: restrict {XnRegion} with: drive {WarpDrive}

	^ Warp create: dsp with: restrict with: drive!

make: dsp {Dsp} 
	with: restrict {XnRegion} 
	with: drive {WarpDrive} 
	with: color {FMColor} 
	with: colorMap {FMColorMap} 
	with: image {Image}
	(color ~~ NULL and: [image ~~ NULL]) ifTrue:
		[Heaper BLAST: #InvalidRequest].
	^Warp
		create: dsp
		with: restrict
		with: drive
		with: color
		with: colorMap
		with: image! !

!Warp class methodsFor: 'pseudo constructors'!

make: anImage {Image} with: bounds {PointRegion} 

	| dBounds {PointRegion} |
	dBounds _ bounds cast: PointRegion.
	^Warp
		make: PointTranslateDsp make
		with: dBounds
		with: (WarpDrive make: (WarpEngine make: anImage with: dBounds))! !