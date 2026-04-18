'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:22 pm'!

Object subclass: #BitBltWarp
	instanceVariableNames: '
		destForm {Image}
		sourceForm {Image}
		halftoneForm {Image}
		combinationRuleInternal {short var}
		destX {long}
		destY {long}
		opWidth {long}
		opHeight {long}
		sourceX {long}
		sourceY {long}
		leftInternal {long}
		topInternal {long}
		widthInternal {long}
		heightInternal {long}
		origin {PointPos}
		myLastView {Warp star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!
BitBltWarp comment:
'The BitBltWarp is a special drawing engine for smalltalk.  It is patterned after the BitBlt class in order to use the primitives of that class for actual drawing.'!

(BitBltWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BitBltWarp methodsFor: 'accessing'!

clipExtent: extent {Point}

	widthInternal _ extent x.
	heightInternal _ extent y!

{Rectangle} clipRect

	^ (leftInternal@topInternal) extent: (widthInternal@heightInternal)!

clipRect: rect {Rectangle}

	topInternal _ rect top.
	leftInternal _ rect left.
	widthInternal _ rect width.
	heightInternal _ rect height!

{void} combinationRule: aRule {IntegerVar}
	
	combinationRuleInternal isInteger ifFalse: [self halt].
	combinationRuleInternal _ aRule!

{PointRegion} enclosure
	^PointRegion make: (PointPos make: leftInternal - origin x with: topInternal - origin y)
		with: (PointPos make: leftInternal - origin x + widthInternal with: topInternal - origin y + heightInternal)!

{UInt4} hashForEqual
	^ self basicCast: UInt4!

{BooleanVar}isEqual: other{Heaper}
	"Return true if the two objects are equal.  (Same destination area, same transformation)."
	^ other == self! !

!BitBltWarp methodsFor: 'smalltalk: smalltalk coloring'!

{Warp}ink.Halftone: mask {Image}
	"Create a warp that uses mask as its ink.  If the current ink is a mask,
	 then the new warp should use the combination (and) of the two.  Another day."

	self hack.
	^BitBltWarp
		create: destForm
		with: leftInternal
		with: topInternal
		with: widthInternal
		with: heightInternal
		with: origin
		with: combinationRuleInternal
		with: mask! !

!BitBltWarp methodsFor: 'coloring'!

{void} inkColor: color {FMColor | NULL}
	"This routine changes the ink to a color."
	color == NULL ifTrue:
		[combinationRuleInternal _ Form over]
	ifFalse: [color == FMColor fmBlackColor ifTrue:
		[combinationRuleInternal _ Form under]
	ifFalse: [color == FMColor fmWhiteColor ifTrue:
		[combinationRuleInternal _ Form erase]
	ifFalse:
		[combinationRuleInternal _ Form over.
		Transcript show: 'wierd color in ink.color'; cr; endEntry]]]!

{void} inkColorMap: colorMap {FMColorMap | NULL}
	"This routine changes the ink to a colorMap."
	colorMap == NULL ifTrue:
		["do nothing"] 
	ifFalse: [colorMap == FMColorMap selectColorMap ifTrue:
		[combinationRuleInternal _ Form reverse]
	ifFalse:
		[Heaper BLAST: #BadParameter]]!

{void} inkImage: image {Image | NULL}
	"Use image as my ink.  If the current ink is a mask,
	 then the new warp should use the combination (and) of the two.
	 This needs to make a new warp that understands replicating images."

	image ~~ NULL
		ifTrue: [self unimplemented]! !

!BitBltWarp methodsFor: 'Smalltalk only'!

{void}clipFully
	"Do the clipping in Smalltalk (after the primitive failed,
	and after truncating all parameters to integers).
	Fixes very negative or very large rectangles."

	| deltaLeft{IntegerVar} deltaTop{IntegerVar} deltaRight{IntegerVar} deltaBottom{IntegerVar} |

	deltaLeft _ leftInternal - destX max: 0.
	deltaTop _ topInternal - destY max: 0.
	deltaRight _ leftInternal + widthInternal - (destX + opWidth) min: 0.
	deltaBottom _ topInternal + heightInternal - (destY + opHeight) min: 0.

	destX _ destX + deltaLeft.
	destY _ destY + deltaTop.
	sourceX _ sourceX + deltaLeft.
	sourceY _ sourceY + deltaTop.

	opHeight _ opHeight - deltaTop + deltaBottom max: 0.
	opWidth  _ opWidth - deltaLeft  + deltaRight max: 0.

	leftInternal _ leftInternal max: 0.
	topInternal _ topInternal max: 0.
	heightInternal _ heightInternal max: 0.
	widthInternal _ widthInternal max: 0!

{void}copyBits
	"Perform the movement of bits from one SmalltalkForm to another described by 
	the instance variables of the receiver. Fail if any instance variables 
	are not of the right type (Integer or SmalltalkForm) or if combinationRule is 
	not between 0 and 15 inclusive. Set the variables and try again 
	(BitBlt|copyBitsAgain). Essential. See SmalltalkObject documentation 
	whatIsAPrimitive."

	<primitive: 96> 
	combinationRuleInternal = Form paint
		ifTrue: [^self paintBits]
		ifFalse: [^(self copy) truncateFully; copyBitsAgain"Handle Float coordinates"]!

{void}copyBitsAgain
	<primitive: 96>
	(self destinationEnclosure intersects: (PointRegion regionExtent: (PointPos make: destX with: destY) with: (PointPos make: opWidth with: opHeight)))	"check for intersection before clipping"
		ifTrue: [self clipFully.	"Clipping for very negative or very large rectangles"
				^self copyBitsAgainAgain]!

{void}copyBitsAgainAgain
	<primitive: 96>
	self primitiveFailed!

{void}drawLoopX: xDelta{IntegerVar} Y: yDelta{IntegerVar} 
	"This is the Bresenham plotting algorithm (IBM Systems Journal Vol 
	4 No. 1, 1965). It chooses a principal direction, and maintains  
	a potential, P.  When P's sign changes, it is time to move in the 
	minor direction as well.  Optional.  See SmallTalkObject documentation whatIsAPrimitive."

	| dx{IntegerVar} dy{IntegerVar} px{IntegerVar} py{IntegerVar} P{IntegerVar} i{IntegerVar} |
	<primitive: 104>
	combinationRuleInternal = Form paint 
		ifTrue: [^self paintLoopX: xDelta Y: yDelta ].
	dx _ xDelta sign.
	dy _ yDelta sign.
	px _ yDelta abs.
	py _ xDelta abs.
	self copyBits.
	py > px
		ifTrue: 
			["more horizontal"
			P _ py // 2.
			i _ 0.
			[(i _ i + 1) <= py]
				whileTrue: 
					[destX _ destX + dx.
					(P _ P - px) < 0
						ifTrue: 
							[destY _ destY + dy.
							P _ P + py].
					self copyBits]]
		ifFalse: 
			["more vertical"
			P _ px // 2.
			i _ 0.
			[(i _ i + 1) <= px]
				whileTrue: 
					[destY _ destY + dy.
					(P _ P - py) < 0
						ifTrue: 
							[destX _ destX + dx.
							P _ P + px].
					self copyBits]]!

{Warp} ink: ink {Heaper}
	"Return a new warp with a new drawing ink."

	(ink isKindOf: FMColor) ifTrue: [self inkColor: ink]
	ifFalse: [(ink isKindOf: FMColorMap) ifTrue: [^self inkColorMap: ink]
	ifFalse: [(ink isKindOf: Form) 
				ifTrue: [ink extent = (Point create: 16 with: 16)
					ifTrue: [self ink.Halftone: ink]
					ifFalse: [self inkImage: ink]]
	ifFalse: [self error: 'unknown ink type.']]]
	"	^color isColor
		ifTrue: [self ink.Color: color]
		ifFalse: [color extent = (XuPoint create: 16 with: 16)
				ifTrue: [self ink.Halftone: color]
				ifFalse: [self ink.Image: color]]"!

{void}paintBits
	"Perform the paint operation, which may require two calls to BitBlt."
	| oldMask{Image} |

	(halftoneForm == nil or: [halftoneForm == Form black]) ifFalse: 		"optimization"
		[oldMask _ halftoneForm.
		combinationRuleInternal _ Form erase.
		halftoneForm _ nil.
		self copyBits. 			"first erase hole in dest"
		halftoneForm _ oldMask].
	halftoneForm == Form white ifFalse: 		"optimization"
		[combinationRuleInternal _ Form under.
		self copyBits].
	combinationRuleInternal _ Form paint. 	"restore rule"

	"(Form dotOfSize: 32)
		displayOn: Display
		at: Sensor cursorPoint
		clippingBox: Display boundingBox
		rule: Form paint
		mask: Form lightGray"!

{void}paintLoopX: xDelta{IntegerVar} Y: yDelta{IntegerVar} 
	"Perform the paint operation, which may require two calls to BitBlt."

| oldMask{Image} startX{IntegerVar} startY{IntegerVar} |
	(halftoneForm == nil or: [halftoneForm == Form black])
		ifFalse: 
			["optimization"
			startX _ destX.
			startY _ destY.
			oldMask _ halftoneForm.
			combinationRuleInternal _ Form erase.
			halftoneForm _ nil.
			self drawLoopX: xDelta Y: yDelta.
			"first erase hole in dest"
			halftoneForm _ oldMask.
			destX _ startX.
			destY _ startY	].
	halftoneForm == Form white
		ifFalse: 
			["optimization"
			combinationRuleInternal _ Form under.
			self drawLoopX: xDelta Y: yDelta].
	combinationRuleInternal _ Form paint!

{void}truncateFully
	"Truncate all coordinates in case any of them was a float."

	destX _ destX truncated.
	destY _ destY truncated.
	opWidth _ opWidth truncated.
	opHeight _ opHeight truncated.

	sourceX _ sourceX truncated.
	sourceY _ sourceY truncated.

	leftInternal _ leftInternal truncated.
	topInternal _ topInternal truncated.
	widthInternal _ widthInternal truncated.
	heightInternal _ heightInternal truncated!

xScanner
	| tScanner |
	tScanner _ XScanner on: destForm. 
	tScanner clipRect: (leftInternal@topInternal
				extent: (widthInternal@heightInternal)).
	^tScanner! !

!BitBltWarp methodsFor: 'display'!

{void}copyBits: encl{PointRegion} from: source{Image} at: pos{PointPos}
	"Display a rectangle from sourceForm into the receiver."

	sourceForm _ source.
	sourceX _ encl left.
	sourceY _ encl top.
	[(sourceX == NULL or: [sourceX == nil]) ifTrue: [self error: 'nil sourceX.'].] smalltalkOnly.
	opWidth _ encl width.
	opHeight _ encl height.
	destX _ pos x + origin x.
	destY _ pos y + origin y.
	self copyBits!

{void} display: chars {MuWordArray} from: startIndex
{IntegerVar} to: stopIndex {IntegerVar} attributes: atts
{AttributeGroup} at: displayPos {PointPos} with: clipExtent
{PointPos}
	| saveClip {Rectangle} |
	"This is the text display primitive.  Offset by one for
	 0 based addressing.  Note that this makes the interval
closed-open."

	"saveClip _ self clipRect.
	self clipRect: ((displayPos x @ (displayPos y)) extent:
clipExtent asSTPoint)."
	self xScanner display: chars
		from: startIndex
		to: stopIndex
		attributes: atts
		at: (displayPos x + origin x) @ (displayPos y + origin y)
		clipping: leftInternal + clipExtent x.
	"self clipRect: saveClip"!

{void}drawFrom: startPoint{PointPos} to: stopPoint{PointPos}
	"Draw a line from startPoint to stopPoint."

	| offset{PointPos} point1{PointPos} point2{PointPos} |
	"Always draw down, or at least left-to-right"
	((startPoint y = stopPoint y and: [startPoint x < stopPoint x])
		or: [startPoint y < stopPoint y])
		ifTrue: [point1 _ startPoint. point2 _ stopPoint]
		ifFalse: [point1 _ stopPoint. point2 _ startPoint].
	opWidth _ sourceForm width.
	opHeight _ sourceForm height.
	offset _ sourceForm offset.
	destX _ (point1 x + offset x + origin x) rounded.
	destY _ (point1 y + offset y + origin y) rounded.
	self drawLoopX: (point2 x - point1 x) rounded 
				  Y: (point2 y - point1 y) rounded!

{void} fill: encl {PointRegion} 
	"Replace a rectangular area of the receiver with the pattern 
	described by aForm according to the rule anInteger."

	| l {IntegerVar} t {IntegerVar} |
	sourceForm _ nil.
	encl isSimple
		ifTrue: [((opWidth _ encl right - (l _ encl left)) > 0 
					and: [(opHeight _ encl bottom - (t _ encl top)) > 0])
				ifTrue: 
					[destX _ l + origin x.
					destY _ t + origin y.
					self copyBits]]
		ifFalse: [encl simpleRegions forEach: [:region {PointRegion} | 
			((opWidth _ region right - (l _ region left)) > 0 
				and: [(opHeight _ region bottom - (t _ region top)) > 0])
					ifTrue: 
						[destX _ l + origin x.
						destY _ t + origin y.
						self copyBits]]]! !

!BitBltWarp methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << 'BitBltWarp' << ' on (' << self enclosure << ' origin: ' << origin << ')'! !

!BitBltWarp methodsFor: 'create'!

create: dForm{Image} with: encl{PointRegion}
	super create.
	destForm _ dForm.
	leftInternal _ encl left.
	topInternal _ encl top.
	widthInternal _ encl width.
	heightInternal _ encl height.
	origin _ PointPos make.
	sourceX _ sourceY _ destX _ destY _ opWidth _ opHeight _ 0.
	combinationRuleInternal _ 3.
	myLastView _ NULL.!

create: dForm{Image} with: encl{PointRegion} with: home{PointPos}
	super create.
	destForm _ dForm.
	leftInternal _ encl left.
	topInternal _ encl top.
	widthInternal _ encl width.
	heightInternal _ encl height.
	origin _ home.
	sourceX _ sourceY _ destX _ destY _ opWidth _ opHeight _ 0.
	combinationRuleInternal _ 3.
	myLastView _ NULL.!

create: dForm{Image} with: encl{PointRegion} with: home{PointPos} with: mask{Image}
	super create.
	destForm _ dForm.
	leftInternal _ encl left.
	topInternal _ encl top.
	widthInternal _ encl width.
	heightInternal _ encl height.
	halftoneForm _ mask.
	origin _ home.
	sourceX _ sourceY _ destX _ destY _ opWidth _ opHeight _ 0.
	combinationRuleInternal _ 3.
	myLastView _ NULL.!

create: dForm{Image} with: encl{PointRegion} with: home{PointPos} with: mask{Image} with: rule{short}
	super create.
	destForm _ dForm.
	leftInternal _ encl left.
	topInternal _ encl top.
	widthInternal _ encl width.
	heightInternal _ encl height.
	halftoneForm _ mask.
	origin _ home.
	sourceX _ sourceY _ destX _ destY _ opWidth _ opHeight _ 0.
	combinationRuleInternal _ rule.
	myLastView _ NULL.!

create: dForm{Image} with: left{long} with: top{long} with: width{long} with: height{long} with: home{PointPos} with:
rule{short} with: mask{Image}
	super create.
	destForm _ dForm.
	leftInternal _ left.
	topInternal _ top.
	widthInternal _ width.
	heightInternal _ height.
	halftoneForm _ mask.
	origin _ home.
	sourceX _ sourceY _ destX _ destY _ opWidth _ opHeight _ 0.
	combinationRuleInternal _ rule.
	myLastView _ NULL.! !

!BitBltWarp methodsFor: 'protected: protected accessing'!

{PointRegion} destinationEnclosure
	^PointRegion make: leftInternal with: topInternal
		with: leftInternal + widthInternal with: topInternal + heightInternal!

{Image} getBits: from {PointRegion}

	| newForm {Form} newDrive {BitBltWarp} |
	newForm _ Form extent: from extent.
	newDrive _ BitBltWarp make: newForm with: (PointRegion regionExtent: from extent).
	newDrive copyBits: from from: destForm at: (PointPos make).
	^ destForm!

{BooleanVar} setupFrom: warp {Warp}
	"whether last setup was from warp; this is private between the two classes"
	"this is subclassResponsibility only because BitBltWarp needs its instance
	variables in the right place for primitives"
	myLastView == warp ifTrue: [^true].
	myLastView _ warp.
	^false! !

!BitBltWarp methodsFor: 'incremental redisplay'!

{BooleanVar} attemptToMove: viewer {Viewer} with: oldWarp {Warp} with: newWarp {Warp} 
	"This routine must create a new image with the bits of the screen 
	designated by oldWarp and prepare them for displaying at newWarp. 
	The routine is called by display:using: when a view is moved rather 
	than just moving the bits. This is done to make the problem of 
	sequencing various bit moves easier. A more efficient technique could 
	be implemented which carefully tracks what is still valid after bits 
	are moved directly on the screen."

"	| bits2move {Image} |
	bits2move _ self getBits: oldWarp enclosure.
	MoveStore introduce: (Pair make: newWarp enclosure with: bits2move).
	^ true"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BitBltWarp class
	instanceVariableNames: ''!

(BitBltWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BitBltWarp class methodsFor: 'smalltalk: smalltalk create'!

create: a with: b
^self new create: a with: b!

create: dForm {Image} with: encl {PointRegion} with: home {PointPos} 
	^self new
		create: dForm
		with: encl
		with: home!

create: dForm {Image} with: encl {PointRegion} with: home {PointPos} with: mask {Image} 
	^self new
		create: dForm
		with: encl
		with: home
		with: mask!

create: dForm {Image} with: encl {PointRegion} with: home {PointPos} with: mask {Image} with: rule {short} 
	^self new
		create: dForm
		with: encl
		with: home
		with: mask
		with: rule!

create: dForm {Image} with: left {long} with: top {long} with: width {long} with: height {long} with: home {PointPos} with: rule {short} with: mask {Image} 
	^self new
		create: dForm
		with: left
		with: top
		with: width
		with: height
		with: home
		with: rule
		with: mask! !