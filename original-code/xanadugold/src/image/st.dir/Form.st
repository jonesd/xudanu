'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:48 pm'!

DisplayMedium subclass: #Form
	instanceVariableNames: 'bits width height offset '
	classVariableNames: 'OneBitForm '
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
Form comment:
'The class Form denotes a rectangular pattern of dots represented as a Smalltalk Bitmap.

Instance Variables:
	bits		<WordArray> in which the receiver''s bits are stored
	width	<Number> width of the rectangle
	height	<Number> height of the rectangle
	offset	<Point> translation of the position of the pattern when displayed

Class Variables: 
	OneBitForm <Form> that is 1 bit wide and 1 bit high and is used as a constant in computations'!


!Form methodsFor: 'initialize-release'!

fromDisplay: aRectangle 
	"Create a virtual bit map from a user specified rectangular area on the 
	display screen. Reallocates bitmap only if aRectangle ~= the receiver's extent."

	(width = aRectangle width and: [height = aRectangle height])
		ifFalse: [self extent: aRectangle extent].
	self copyBits: (aRectangle origin extent: self extent)
		from: Display
		at: 0 @ 0
		clippingBox: Display boundingBox
		rule: Form over
		mask: Form black! !

!Form methodsFor: 'accessing'!

extent

	^width@height!

extent: aPoint 
	"Create a virtual bit map with width = (extent x) and height = (extent y) 
	with the bits all zeros (white).  The extent is guaranteed to be zero or a positive 
	size."

	^ self extent: aPoint offset: 0@0!

extent: extentPoint offset: offsetPoint 
	"Create a virtual bit map with width = (extent x) and height = (extent y) 
	with the bits all zeros (white)."

	| normalizedPoint |
	normalizedPoint _ extentPoint >= (0 @ 0)
				ifTrue: [extentPoint]
				ifFalse: [0 @ 0].
	width _ normalizedPoint x.
	height _ normalizedPoint y.
	offset _ offsetPoint.
	bits _ self bitsClass newWidth: width height: height.!

extent: extent offset: aPoint bits: aWordArray 
	"Create a virtual bitmap with width = (extent x) and height = (extent y) 
	with the bits = aWordArray.  This requires converting the word array
	to a FormBitmap."

	width _ extent x.
	height _ extent y.
	offset _ aPoint.
	bits _ self bitsClass newWidth: width height: height.
	1 to: aWordArray size do: [:i | self bitsWordAt: i put: (aWordArray at: i)]!

height

	^height!

offset
	"Answer the offset of the receiver."

	offset == nil
		ifTrue: [^0 @ 0]
		ifFalse: [^offset]!

offset: aPoint 
	"Make the argument aPoint the receiver's offset."

	offset _ aPoint!

size
	"Answer the number of words of bits in the receiver's bitmap."

	^self bitsWordSize!

width

	^width! !

!Form methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance variable.
	Also deep copy instance variables defined in subclasses, if any."

	| newForm |
	newForm _ self species extent: width @ height.
	newForm offset: offset deepCopy.
	newForm copyBits: self boundingBox
		from: self
		at: 0 @ 0
		clippingBox: newForm boundingBox
		rule: Form over
		mask: Form black.
	Form instSize + 1 to: self class instSize do:
		[:index |	"deep copy instance variables defined in subclasses"
		 newForm instVarAt: index put: (self instVarAt: index) deepCopy].
	^newForm! !

!Form methodsFor: 'displaying'!

copyBits: sourceRect from: sourceForm at: destOrigin clippingBox: clipRect rule: rule mask: aForm 
	"Copy into the rectangle sourceRect within the receiver those bits from the form
	sourceForm starting at position destOrigin according to the mixing rule rule and with
	aForm as the mask.  Clip the receiver's destination rectangle with respect to clipRect."

	(BitBlt 
		destForm: self
		sourceForm: sourceForm
		halftoneForm: aForm
		combinationRule: rule
		destOrigin: destOrigin
		sourceOrigin: sourceRect origin
		extent: sourceRect extent
		clipRect: clipRect) copyBits!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	aDisplayMedium copyBits: self boundingBox
		from: self
		at: aDisplayPoint + offset
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm!

displayOn: aDisplayMedium transformation: displayTransformation clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: ruleInteger mask: aForm 
	"Display the receiver where a DisplayTransformation is provided as an argument,
	rule is ruleInteger and mask is aForm.  Translate by relativePoint-alignmentPoint.
	Information to be displayed must be confined to the area that intersects with
	clipRectangle."

	"Graphically, it means nothing to scale a Form by floating point values.  
	Because scales and other display parameters are kept in floating point to 
	minimize round off errors, we are forced in this routine to round off to the 
	nearest integer."

	| absolutePoint scale magnifiedForm |
	absolutePoint _ displayTransformation applyTo: relativePoint.
	absolutePoint _ absolutePoint x truncated @ absolutePoint y truncated.
	displayTransformation noScale
		ifTrue: [magnifiedForm _ self]
		ifFalse: 
			[scale _ displayTransformation scale.
			scale _ scale x rounded @ scale y rounded.
			(1@1 = scale)
					ifTrue: [scale _ nil. magnifiedForm _ self]
					ifFalse: [magnifiedForm _ self magnifyBy: scale]].
	magnifiedForm
		displayOn: aDisplayMedium
		at: absolutePoint - alignmentPoint
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm!

drawLine: sourceForm from: beginPoint to: endPoint clippingBox: clipRect rule: anInteger mask: aForm 
	"Affect a form, the receiver, by modifying its contents so as to effectively
	draw line starting at beginPoint (a position relative to the receiver) and
	ending at endPoint, according to the combination rule anInteger, masked by
	aForm and clipped by clipRect.  Each position on the line is drawn with the
	form sourceForm."

	| dotSetter |
	dotSetter _ BitBlt
		destForm: self
		sourceForm: sourceForm
		halftoneForm: aForm
		combinationRule: anInteger
		destOrigin: beginPoint
		sourceOrigin: 0 @ 0
		extent: sourceForm extent
		clipRect: clipRect.
	dotSetter drawFrom: beginPoint to: endPoint! !

!Form methodsFor: 'display box access'!

boundingBox
	"Answer the minimum enclosing rectangle around the image."

	^Rectangle origin: 0 @ 0 corner: width @ height!

computeBoundingBox
	"Answer the minimum enclosing rectangle around the image."

	^Rectangle origin: 0 @ 0 corner: width @ height! !

!Form methodsFor: 'pattern'!

bits
	"Answer the receiver's bitmap containing its bits."

	| words |
	words _ WordArray new: self bitsWordSize.
	1 to: self bitsWordSize do: [:i | words at: i put: (self bitsWordAt: i)].
	^words!

bits: aWordArray 
	"Reset the bitmap containing the receiver's bits."

	aWordArray size = self bitsWordSize
		ifTrue: [self extent: width @ height offset: offset bits: aWordArray]
		ifFalse: [self error: 'Can''t change size of a Form''s bits.']!

bitsWordAt: index
	"Answer the value of a 16-bit word of bits from
	the receiver's bitmap.  See the documentation
	(not included here) for details."

	<primitive: 401>
	self primitiveFailed!

bitsWordAt: index put: value
	"Store a 16-bit word of bits into
	the receiver's bitmap.  See the documentation
	(not included here) for details."

	<primitive: 402>
	self primitiveFailed!

bitsWordSize
	"Answer the size of the receiver's bitmap,
	viewed as an array of 16-bit words.
	See the documentation (not included here)
	for details."

	<primitive: 403>
	self primitiveFailed!

valueAt: aPoint 
	"Answer whether a bit is on or off:  1 if the color at coordinate aPoint 
	is black in the receiver and 0 if the color is white."

	OneBitForm copyBits: (aPoint extent: 1 @ 1)
		from: self
		at: 0 @ 0
		clippingBox: self boundingBox
		rule: Form over
		mask: Form black.
	(OneBitForm bitsWordAt: 1) = 0
		ifTrue: [^0]
		ifFalse: [^1]!

valueAt: aPoint put: maskCode 
	"Set the bit in the receiver at coordinate aPoint to be white (0) or black (1)."
	
	maskCode = 0
	  ifTrue: [OneBitForm white] 
	  ifFalse: [OneBitForm black].
	self
	  copyBits: OneBitForm boundingBox
	  from: OneBitForm
	  at: aPoint
	  clippingBox: self boundingBox
	  rule: Form over
	  mask: Form black.! !

!Form methodsFor: 'bordering'!

borderWidth: anInteger 
	"Set the width of the border for the receiver to be anInteger and paint it
	using Form black as the border color."

	self border: self boundingBox width: anInteger mask: Form black!

borderWidth: anInteger mask: aMask
	"Set the width of the border for the receiver to be anInteger and paint it
	using aMask as the border color."

	self border: self boundingBox width: anInteger mask: aMask! !

!Form methodsFor: 'coloring'!

fill: aRectangle rule: anInteger mask: aForm 
	"Replace a rectangular area of the receiver with the pattern described by aForm 
	according to the rule anInteger."

	"Make up a BitBlt table and copy the bits"
	(BitBlt 
		destForm: self
		sourceForm: nil
		halftoneForm: aForm
		combinationRule: anInteger
		destOrigin: aRectangle origin
		sourceOrigin: self boundingBox origin
		extent: aRectangle extent
		clipRect: self boundingBox) copyBits! !

!Form methodsFor: 'printing'!

storeOn: aStream
	"Append to the argument aStream a description of the receiver in the form:  
			Form extent:fromArray:#()offset:"
	
	"Some examples are
	 | s | s_ WriteStream on: (String new: 2000).
	Form fromUser storeOn: s.
	(Compiler evaluate: s contents) displayAt: 0@0.

 	| f | f _ (Filename named: 'screen.file') writeStream.
	Display storeOn: f.
	f close.
	"

	self storeOn: aStream base: 10!

storeOn: aStream base: anInteger 
	"Store the receiver out in the form:  Form extent:fromArray:#()offset:"

	| theBits |
	aStream nextPut: $(.
	aStream nextPutAll: self species name.
	aStream crtab: 1.
	aStream nextPutAll: 'extent: '.
	self extent printOn: aStream.
	aStream crtab: 1.
	aStream nextPutAll: 'fromArray: #('.
	theBits _ self bits.
	1 to: theBits size do: 
		[:index | 
		anInteger = 10
			ifTrue: [aStream space]
			ifFalse: [aStream crtab: 2; nextPutAll: anInteger printString; nextPut: $r].
		(theBits at: index) printOn: aStream base: anInteger].
	aStream nextPut: $).
	aStream crtab: 1.
	aStream nextPutAll: 'offset: '.
	self offset printOn: aStream.
	aStream nextPut: $)! !

!Form methodsFor: 'image manipulation'!

convexShapeFill: aMask
	"Fill the interior of the outtermost outlined region in the receiver.  The 
	outlined region must not be concave by more than 90 degrees."

	| destForm tempForm skew |
	destForm _ Form extent: self extent.
	tempForm _ Form extent: self extent.
	self displayOn: tempForm at: (0@0) - self offset.
	skew _ 1.
	[skew < width] whileTrue:
		[tempForm displayOn: tempForm at: skew@0
			clippingBox: tempForm boundingBox rule: Form under mask: nil.
		skew _ skew+skew].
	tempForm displayOn: destForm.

	self displayOn: tempForm at: (0@0) - self offset.
	skew _ 1.
	[skew < width] whileTrue:
		[tempForm displayOn: tempForm at: skew negated@0
			clippingBox: tempForm boundingBox rule: Form under mask: nil.
		skew _ skew+skew].
	tempForm displayOn: destForm at: 0@0
		clippingBox: destForm boundingBox rule: Form and mask: nil.

	self displayOn: tempForm at: (0@0) - self offset.
	skew _ 1.
	[skew < height] whileTrue:
		[tempForm displayOn: tempForm at: 0@skew
			clippingBox: tempForm boundingBox rule: Form under mask: nil.
		skew _ skew+skew].
	tempForm displayOn: destForm at: 0@0
		clippingBox: destForm boundingBox rule: Form and mask: nil.

	self displayOn: tempForm at: (0@0) - self offset.
	skew _ 1.
	[skew < height] whileTrue:
		[tempForm displayOn: tempForm at: 0@skew negated
			clippingBox: tempForm boundingBox rule: Form under mask: nil.
		skew _ skew+skew].
	tempForm displayOn: destForm at: 0@0
		clippingBox: destForm boundingBox rule: Form and mask: nil.

	destForm displayOn: self at: 0@0
			clippingBox: self boundingBox rule: Form over mask: aMask!

copy: destRectangle from: sourcePt in: sourceForm rule: rule 
	"Copy into the destination rectangle destRectangle that is within the
	receiver those bits in the form sourceForm starting at position sourcePt
	according the masking rule rule."
	
	"[Sensor redButtonPressed] whileFalse:
		[Display copy: (30@30 extent: 300@300) 
				 from: Sensor cursorPoint in: Display rule: Form over]."

	(BitBlt 
		destForm: self
		sourceForm: sourceForm
		halftoneForm: nil
		combinationRule: rule
		destOrigin: destRectangle origin
		sourceOrigin: sourcePt
		extent: destRectangle extent
		clipRect: (0@0 extent: width@height)) copyBits!

magnifyBy: scale 
	"Answer a new form created as a multiple of the receiver;  the new form
	is larger, each bit in the receiver being blown up to extent=scale."

	"Check consistency of shrink and magnify:
	[Sensor redButtonPressed] whileFalse:
		[(((Form fromDisplay: (Sensor cursorPoint extent: 50@50))
			magnifyBy: 3@5) shrinkBy: 3@5)
				displayAt: 100@100]"

	| wideForm bigForm spacing |
	spacing _ 0 @ 0.
	wideForm _ self class new extent: (width * scale x) @ height.
	wideForm
		spread: self boundingBox
		from: self
		by: scale x
		spacing: spacing x
		direction: 1 @ 0.
	bigForm _ self class new extent: self extent * scale.
	bigForm
		spread: wideForm boundingBox
		from: wideForm
		by: scale y
		spacing: spacing y
		direction: 0 @ 1.
	^bigForm!

reflect: spec
	"Answer a new Form created by reflecting the receiver about the
	veritical or horizontal axis.  The argument spec = 0@1 for vertical 
	reflection, 1@0 for horizontal"

	"[Sensor redButtonPressed] whileFalse:
		[((Form fromDisplay: (Rectangle new origin: Sensor cursorPoint extent: 113@37)) reflect: 1@0)
			displayAt: 0@0]."

	| mask temp all newForm full half |
	all _ self boundingBox.
	mask _ Form extent: self extent.
	temp _ Form extent: self extent.
	full _ self extent*spec.
	mask black: (0@0 extent: self extent // (spec+1)).
	newForm _ self deepCopy.
	[full x + full y > 1] whileTrue:
		[half _ full // 2.
		temp copy: all from: 0@0 in: newForm rule: 3.
		temp copy: all from: full-half in: newForm rule: 6.
		temp copy: all from: 0@0 in: mask rule: 1.
		newForm copy: all from: 0@0 in: temp rule: 6.
		newForm copy: (all translateBy: full-half) from: 0@0 in: temp rule: 6.
		"Now refine the mask"
		mask copy: all from: half - (half//2) in: mask rule: 1.
		mask copy: (all translateBy: full-half) from: 0@0 in: mask rule: 7.
		full _ half].
	^ newForm!

rotate2: direction
	"Destructively rotate a square form of dimension 2^N by 90 degrees.
		direction = 1 for clockwise, -1 for counterclockwise"

	" [Sensor redButtonPressed] whileFalse:
		[((Form fromDisplay: (Rectangle new origin: Sensor cursorPoint extent: 128@128))
			rotate2: 1)
				displayAt: 0@0]."

	| mask temp all quad delta |
	all _ self boundingBox.
	mask _ Form extent: self extent.
	temp _ Form extent: self extent.
	mask white.   "set up the first mask"
	mask black: (0@0 extent: mask extent//2).
	quad_ self width // 2.
	[quad >= 1] whileTrue:
		[delta _ direction=1 ifTrue: [quad@0] ifFalse: [0@quad].
		temp copy: all from: 0@0 in: mask rule: 3.  "First exchange left and right halves"
		temp copy: (all translateBy: delta transpose) from: 0@0 in: mask rule: 7.
		temp copy: all from: 0@0 in: self rule: 1.
		self copy: all from: 0@0 in: temp rule: 6.
		temp copy: all from: delta in: self rule: 6.
		self copy: all from: delta in: self rule: 7.
		self copy: (all translateBy: delta) from: 0@0 in: temp rule: 6.
		temp copy: all from: 0@0 in: self rule: 3.  "then flip the diagonals"
		temp copy: all from: quad@quad in: self rule: 6.
		temp copy: all from: 0@0 in: mask rule: 1.
		self copy: all from: 0@0 in: temp rule: 6.
		self copy: all from: quad negated@quad negated in: temp rule: 6.
		mask copy: all from: (quad//2)@(quad//2) in: mask rule: 1. "Now refine the mask"
		mask copy: all from: quad negated@0 in: mask rule: 7.
		mask copy: all from: 0@quad negated in: mask rule: 7.
		quad_ quad//2]!

rotateBy: angle
	"Answer a copied Form rotated clockwise by angle in units of 90 degrees.
	angle = 0 means unchanged, 1 means clockwise 90 degrees, and so on"

"
	| f |
	[Sensor redButtonPressed] whileFalse:
		[f_ Form fromDisplay: (Sensor cursorPoint extent: 100@15).
		(f rotateBy: 0) displayAt: 100@100.
		(f rotateBy: 1) displayAt: 85@100.
		(f rotateBy: 2) displayAt: 0@85.
		(f rotateBy: 3) displayAt: 100@0]
"

	| rotSize newForm rotForm all destPt sourcePt sourceDelta destDelta rotOrigin |
	angle = 0 ifTrue: [^self deepCopy].  "null rotation"
	angle = 2 ifTrue: [^(self reflect: 0@1) reflect: 1@0].  "two reflections does 180 degrees"

	"Break the problem up into squares of size 2^N, and rotate them"
	rotSize _ (width min: height)   "minimum rotation size"
				max: 64.  "but faster if we do larger chunks"
	rotSize _ 2 raisedTo: ((rotSize-1) asFloat floorLog: 2)+1.  "force up to a power of 2"
	newForm _ self class extent: self extent transpose.
	rotForm _ Form extent: rotSize asPoint.
	all _ rotForm boundingBox.
	sourcePt _ 0@0.
	width >= height
		ifTrue:
			[sourceDelta _ rotSize@0.
			angle=1
				ifTrue:
					[destPt _ 0@0.
					destDelta _ sourceDelta transpose.
					rotOrigin _ (rotSize-height)@0]
				ifFalse:
					[destPt _ 0@(width-rotSize).
					destDelta _ (0@0) - sourceDelta transpose.
					rotOrigin _ 0@0]]
		ifFalse:
			[sourceDelta _ 0@rotSize.
			angle=1
				ifTrue:
					[destPt _ (height-rotSize)@0.
					destDelta _ (0@0) - sourceDelta transpose.
					rotOrigin _ 0@0]
				ifFalse:
					[destPt _ 0@0.
					destDelta _ sourceDelta transpose.
					rotOrigin _ 0@(rotSize-width)]].
	(width max: height) - 1 // rotSize + 1 timesRepeat:
		[rotForm copy: all from: sourcePt in: self rule: 3.
		rotForm rotate2: (angle=1 ifTrue: [1] ifFalse: [-1]).
		newForm copy: (all translateBy: destPt) from: rotOrigin in: rotForm rule: 3.
		sourcePt _ sourcePt + sourceDelta.
		destPt _ destPt + destDelta].
	^newForm!

shapeFill: aMask interiorPoint: interiorPoint
	"Fill the interior of some outlined region according to mask and rule.
	InteriorPoint marks a location in the interior or the region.  A mark is
	placed at this point as a seed, then the seed is smeared into a blob
	until there is no change in the blob when it fills the region.
	Uses the upper left corner of the display screen for computing the blob."

	| dirs smearForm previousSmear all cycle noChange |
	all _ self boundingBox.
	smearForm _ Form extent: self extent.
	smearForm valueAt: interiorPoint put: 1.		"Place a seed in the interior"
	previousSmear _ smearForm deepCopy.
	dirs _ Array with: 1@0 with: -1@0 with: 0@1 with: 0@-1.
	cycle _ 0.
	[(cycle _ cycle+1) \\ 10 = 0 and:   "check for no change every 10 smears"
		[previousSmear copy: all from: 0@0 in: smearForm rule: Form reverse.
		noChange _ previousSmear isAllWhite.
		previousSmear copy: all from: 0@0 in: smearForm rule: Form over.
		noChange]]
		whileFalse: 
			[dirs do:
				[:dir |    "smear in each of the four directions"
				smearForm copy: all from: dir in: smearForm rule: Form under.
				"After each smear, trim around the region border"
				smearForm copy: all from: 0@0 in: self rule: Form erase]].
	"Now paint the filled region in me with aMask"
	smearForm displayOn: self at: 0@0 clippingBox: self boundingBox
		rule: Form under mask: aMask!

shrinkBy: scale 
	"Answer a scaled-down copy of the receiver."

	"Each bit in the new form is a sample taken from the upper-left bit of 
	a rectangle of extent = scale in the receiver.  A more involved algorithm 
	would count the bits in the rectangle and produce black only if more 
	than half were black."

	| wideForm shrunkenForm saveOffset |
	saveOffset _ self offset.
	self offset: 0 @ 0.
	wideForm _ Form new extent: self width @ (self height // scale y).
	0 to: wideForm height-1 do: 
		[:index | 
		wideForm copy: (0 @ index extent: wideForm width @ 1)
			from: 0 @ (index * scale y)
			in: self
			rule: Form over].
	shrunkenForm _ self class new extent: self width // scale x @ wideForm height.
	0 to: shrunkenForm width-1 do: 
		[:index | 
		shrunkenForm
			copy: (index @ 0 extent: 1 @ wideForm height)
			from: (index * scale x) @ 0
			in: wideForm
			rule: Form over].
	self offset: saveOffset.
	shrunkenForm offset: offset // scale.
	^shrunkenForm!

spread: rectangle from: sourceForm by: scale spacing: spacing direction: dir 
	"Modify the form by scaling it by scale, spreading the contents by inserting
	white space at each multiple determined by the argument space along the
	vector dir."

	| slice sourcePt |
	slice _ 0 @ 0 corner: dir transpose * self extent + dir.
	sourcePt _ rectangle origin.
	1 to: (rectangle extent dotProduct: dir) do: 
		[:i | 
		"slice up original area"
		self copy: slice
			from: sourcePt
			in: sourceForm
			rule: 3.
		sourcePt _ sourcePt + dir.
		slice moveBy: dir * scale].
	1 to: scale - spacing - 1 do: 
		[:i | "smear out the slices, leave white space"
		self copy: (dir corner: self extent)
			from: 0 @ 0
			in: self
			rule: 7]!

wrapAround: aPoint
	"Answer a new form which contains the image of the receiver, but 
	translated by deltaPoint, with wrap-around.  Used for realigning 
	halftone masks.  Assumes the receiver is 16x16 with zero offset."

	"[Sensor anyButtonPressed] whileFalse:
		[((Cursor normal wrapAround: Sensor cursorPoint)
			magnifyBy: 8@8) displayAt: 100@100]"

	| newForm delta |
	newForm _ Form extent: width@height.
	delta _ (aPoint x\\16)@(aPoint y\\16).
	delta = (0@0) ifTrue: [^self].
	self displayOn: newForm at: delta-(16@16).
	self displayOn: newForm at: delta-(16@0).
	self displayOn: newForm at: delta-(0@16).
	self displayOn: newForm at: delta.
	^newForm! !

!Form methodsFor: 'fileIn/Out'!

fromClipboard
	"Answer an instance of the receiver with bitmap initialized from a
 	 PICT in the Macintosh clipboard."

	<primitive: 778>!

storeBinaryOn: stream
	" Store each scan line as a ByteArray. "

	|  words line |
	stream storeRecordOfClass: self class.
	stream nextPut: width.
	stream nextPut: height.
	stream nextPut: offset.
	words _ (width + 15) // 16.
	1 to: height do:
		[:y | | i0 |
		i0 _ y - 1 * words.
		line _ ByteArray new: words * 2.
		1 to: words do:
			[:x | | w |
			w _ self bitsWordAt: i0 + x.
			line at: x + x - 1 put: (w bitShift: -8).
			line at: x + x put: (w bitAnd: 255)].
		stream storeBytes: line]!

toClipboard
	"Store an instance of form to the clipboard in PICT format"

	<primitive: 777>!

writeOn: fileName
	"Save the receiver on the file fileName in the format--fileCode, extent, offset, bits."

	| file fileCode filePosition |
	fileCode _ 1.
	"This indicates that the instance is a Form.  Should probably be changed 
	when better methods for permanent storage are devised."
	file _ (Filename named: fileName) writeStream.
	[file binary.
	file nextWordPut: fileCode.
	file nextWordPut: width.
	file nextWordPut: height.
	file nextWordPut: offset x.
	file nextWordPut: offset y.
	filePosition _ 0.
	1 to: width + 15 // 16 do:
		[:j |
		1 to: height do: [:i | file nextWordPut: (self bitsWordAt: (filePosition _ filePosition + 1))]]
	] valueNowOrOnUnwindDo: [file close]! !

!Form methodsFor: 'editing'!

bitEdit
	"Create and schedule a view located in an area designated by the user that
	contains a view of the receiver magnified by 8@8 that can be modified
	using the Bit Editor.  It also contains a view of the original form."

	"Note that using direct messages to BitEditor, fixed locations and scales can be created.
	That is, also try
		BitEditor openOnForm: self at: <some point>.
		BitEditor openOnForm: self at: <some point> scale: <some point>."

	BitEditor openOnForm: self!

bitEditAt: magnifiedLocation
	"Create and schedule a view whose top left corner is magnifiedLocation and
	that contains a view of the receiver magnified by 8@8 that can be modified
	using the Bit Editor.  It also contains a view of the original form."

	BitEditor openOnForm: self at: magnifiedLocation!

bitEditAt: magnifiedFormLocation scale: scaleFactor 
	"Create and schedule a view whose top left corner is magnifiedLocation and
	that contains a view of the receiver magnified by scaleFactor that can be modified
	using the Bit Editor.  It also contains a view of the original form."

	BitEditor openOnForm: self at: magnifiedFormLocation scale: scaleFactor!

edit
	"Start up an instance of the FormEditor on this form. Typically the form 
	is not visible on the screen. The editor menu is located at the bottom of 
	the form editing frame. The form is displayed centered in the frame. 
	YellowButtonMenu accept is used to modify the form to reflect the 
	changes made on the screen version; cancel restores the original form to 
	the screen. Note that the changes are clipped to the original size of the 
	form."

	FormEditor openOnForm: self!

editAt: originPoint 
	"Start up an instance of the FormEditor on this form in an area whose 
	top left corrner is originPoint. Typically the form is not visible on the 
	screen. The editor menu is located at the bottom of the form editing 
	frame. The form is displayed centered in the frame. YellowBugMenu 
	accept is used to modify the form to reflect the changes made on the 
	screen version; cancel restores the original form to the screen. Note that 
	the changes are clipped to the original size of the form."

	FormEditor openOnForm: self at: originPoint! !

!Form methodsFor: 'examples'!

nextLifeGeneration
	"Try the game of Life."

	"First create a new Form and edit its bits.  Leave the BitEditor
	displayed on the screen so you can copy from it.
	
			Form fromUser bitEdit.

	Now evaluate the following statements, selecting as the initial
	image of life all or part of the image in the BitEditor.
	To stop the life generations from continuing, pressing the red button.

	| life |
	life _ Form fromUser.
	[Sensor redButtonPressed] whileFalse:
		[(life nextLifeGeneration magnifyBy: 8@8) displayAt: 0@0]"


	| nbr1 nbr2 nbr4 carry2 carry4 all delta |
	nbr1 _ Form extent: self extent.
	nbr2 _ Form extent: self extent.
	nbr4 _ Form extent: self extent.
	carry2 _ Form extent: self extent.
	carry4 _ Form extent: self extent.
	all _ self boundingBox.
	1 to: 8 do:
		[:i |
		delta _   "delta is the offset of the eight neighboring cells"
			((#(-1 0 1 1 1 0 -1 -1) at: i) @ (#(-1 -1 -1 0 1 1 1 0) at: i)).
		carry2 copy: all from: 0@0 in: nbr1 rule: 3.
		carry2 copy: all from: delta in: self rule: 1.  "AND for carry into 2"
		nbr1 copy: all from: delta in: self rule: 6.    "XOR for sum 1"
		carry4 copy: all from: 0@0 in: nbr2 rule: 3.
		carry4 copy: all from: 0@0 in: carry2 rule: 1. "AND for carry into 4"
		nbr2 copy: all from: 0@0 in: carry2 rule: 6.   "XOR for sum 2"
		nbr4 copy: all from: 0@0 in: carry4 rule: 6].   "XOR for sum 4 (ignore carry into 8)"
	self copy: all from: 0@0 in: nbr2 rule: 1.
	nbr1 copy: all from: 0@0 in: nbr2 rule: 1.
	self copy: all from: 0@0 in: nbr1 rule: 7.
	self copy: all from: 0@0 in: nbr4 rule: 4 "compute next generation"! !

!Form methodsFor: 'private: private'!

bitsClass
	"Answer the appropriate class for the receiver's bitmap.
	The default is FormBitmap."

	^FormBitmap!

isAllWhite
	"Answer whether the receiver is all white, i.e., contains all zeros."

	1 to: self bitsWordSize do: [:i | (self bitsWordAt: i) ~= 0 ifTrue: [^false]].
	^true!

setExtent: extentPoint fromArray: anArray setOffset: offsetPoint 
	"Initialize the instance variables.
	THIS MESSAGE IS REDUNDANT NOW."

	self extent: extentPoint offset: offsetPoint bits: anArray! !

!Form methodsFor: 'xcomp displaying'!

display: string from: startIndex to: stopIndex attributes: atts at: displayPos 
	(XScanner on: self)
		display: string
		from: startIndex
		to: stopIndex
		attributes: atts
		at: displayPos + offset!

{PointRegion} enclosure
	^PointRegion
		make: offset x
		with: offset y
		with: offset x + width
		with: offset y + height!

warp
	^Warp make: (FormImage make.void: self) with: self boundingBox!

xScanner
	^XScanner on: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Form class
	instanceVariableNames: 'veryLightGrayMask lightGrayMask blackMask grayMask darkGrayMask whiteMask veryDarkGrayMask '!


!Form class methodsFor: 'class initialization'!

initialize
	"Initialize the class variable."

	"Form  initialize."

	self initializeMasks.
	OneBitForm _ Form new extent: 1 @ 1!

initializeMasks	
	"Set up the form color masks."

	"Form initializeMasks"

	| anArray |
	anArray _ Array new: 16.
	anArray atAllPut: 0.
	whiteMask _ Form extent: 16 @ 16 fromArray: anArray offset: 0 @ 0.
	anArray atAllPut: 65535.
	blackMask _ Form extent: 16 @ 16 fromArray: anArray offset: 0 @ 0.
	anArray atAll: (1 to: anArray size by: 2) put: 21845.
	anArray atAll: (2 to: anArray size by: 2) put: 43690.
	grayMask _ Form extent: 16 @ 16 fromArray: anArray offset: 0 @ 0.
	anArray atAll: (1 to: anArray size by: 2) put: 30583.
	anArray atAll: (2 to: anArray size by: 2) put: 56797.
	darkGrayMask _ Form extent: 16 @ 16 fromArray: anArray offset: 0 @ 0.
	lightGrayMask _ darkGrayMask deepCopy reverse.
	anArray atAll: (1 to: anArray size by: 4) put: 34952.
	anArray atAll: (2 to: anArray size by: 2) put: 0.
	anArray atAll: (3 to: anArray size by: 4) put: 8738.
	veryLightGrayMask _  Form extent: 16 @ 16 fromArray: anArray offset: 0 @ 0.
	veryDarkGrayMask _ veryLightGrayMask deepCopy reverse.! !

!Form class methodsFor: 'instance creation'!

dotOfSize: diameter
	"Create a form which contains a round black dot."

	"(Form dotOfSize: 8) displayAt: Sensor cursorPoint"

	| radius form bite |
	radius _ diameter//2.
	form _ self new extent: diameter@diameter offset: (0@0) - (radius@radius).	
	diameter <= 9 ifTrue: "special case for speed"
		[form black.
		diameter <= 2 ifTrue: [^form].
		bite _ diameter//3.
		form white: (0@0 extent: bite@1).
		form white: (0@(diameter-1) extent: bite@1).
		form white: (diameter-bite@0 extent: bite@1).
		form white: (diameter-bite@(diameter-1) extent: bite@1).
		form white: (0@0 extent: 1@bite).
		form white: (0@(diameter-bite) extent: 1@bite).
		form white: (diameter-1@0 extent: 1@bite).
		form white: (diameter-1@(diameter-bite) extent: 1@bite).
		^form].

	radius _ diameter-1//2.  "so circle fits entirely"
	(Circle new center: radius@radius radius: radius) displayOn: form.
	form convexShapeFill: Form black.	"fill the circle with black"
	^form!

extent: extentPoint
	"Answer an instance of the receiver with blank bitmap."

	^self basicNew
		setExtent: extentPoint
		fromArray: Array new
		setOffset: 0@0!

extent: extentPoint fromArray: anArray offset: offsetPoint 
	"Answer an instance of the receiver with bitmap initialized from anArray."

	^self basicNew
		setExtent: extentPoint
		fromArray: anArray
		setOffset: offsetPoint!

fromClipboard
	"Answer an instance of the receiver with bitmap initialized from a
 	 PICT in the Macintosh clipboard."

	^Form new fromClipboard!

fromDisplay: aRectangle 
	"Answer an instance of the receiver with bitmap initialized from the area of
	the display screen defined by aRectangle."

	^self new fromDisplay: aRectangle!

fromUser
	"Answer an instance of the receiver with bitmap initialized from the area of
	the display screen designated by the user"

	| aRectangle |
	aRectangle _ Rectangle fromUser.
	^self new fromDisplay: aRectangle!

fromUser: aPoint 
	"Answer an instance of the receiver with bitmap initialized from the area of
	the display screen designated by the user.  The grid for selecting an area
	is aPoint."

	| aRectangle |
	aRectangle _ Rectangle fromUser: aPoint.
	^self new fromDisplay: aRectangle!

readFormFile: file
	"Answer an instance of the receiver with bitmap initialized from the external file.  
	The file format is:  fileCode(1), extent, offset, bits."

	| newForm newWidth newHeight theBits filePosition offsetX offsetY |
	[file binary.
	file nextWord = 1 ifFalse: [^(Form new extent: 8 @ 8) black].	"reads fileCode"
	newForm _ self new.
	newWidth _ file nextWord.
	newHeight _ file nextWord.
	newForm extent: newWidth @ newHeight.
	offsetX  _ file nextWord.
	offsetY _ file nextWord.
	offsetX > 32767 ifTrue: [offsetX _ offsetX - 65536]. "stored two's-complement"
	offsetY > 32767 ifTrue: [offsetY _ offsetY - 65536]. "stored two's-complement"
	newForm offset: offsetX @ offsetY.
	theBits _ WordArray new: newWidth + 15 // 16 * newHeight.
	filePosition _ 0.
	1 to: newWidth + 15 // 16 do:
		[:j | 
		1 to: newHeight do:
			[:i | theBits at: (filePosition _ filePosition + 1) put: file nextWord]].
	newForm bits: theBits
	] valueNowOrOnUnwindDo: [file close].
	^newForm!

readFrom: fileName
	"Answer an instance of the receiver with bitmap initialized from 
	the external file named fileName.  Answer nil if the file does not
	contain a kind of Form."

	| file code |
	file _ (Filename named: fileName) readStream.
	[file binary.
	code _ file nextWord.	"reads fileCode"
	file skip: -2.
	code = 1 ifTrue: [^self readFormFile: file]
	] valueNowOrOnUnwindDo: [file close].
	^nil! !

!Form class methodsFor: 'mode constants'!

and
	"Answer the integer denoting the logical 'and' combination rule."

	^1!

erase
	"Answer the integer denoting mode erase."

	^4!

over
	"Answer the integer denoting mode over."

	^3!

paint
	"Answer the integer denoting the 'paint' combination rule."

	^16!

reverse
	"Answer the integer denoting mode reverse."

	^6!

under
	"Answer the integer denoting mode under."

	^7! !

!Form class methodsFor: 'mask constants'!

black
	"Answer the form denoting black mask."

	^blackMask!

darkGray
	"Answer the form denoting dark gray mask."

	^darkGrayMask!

gray
	"Answer the form denoting gray mask."

	^grayMask!

lightGray
	"Answer the form denoting light gray mask."

	^lightGrayMask!

veryDarkGray
	"Answer the form denoting very dark gray mask."

	^veryDarkGrayMask!

veryLightGray
	"Answer the form denoting very light gray mask."

	^veryLightGrayMask!

white
	"Answer the form denoting white mask."

	^whiteMask! !

!Form class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag

	| width height form words |
	form _ self basicNew.
	stream register: form id: tag.
	width _ stream next.
	height _ stream next.
	form extent: width@height offset: stream next.
	words _ (width + 15) // 16.
	1 to: height do:
		[:y | | i0 line |
		i0 _ y - 1 * words.
		line _ stream readBytes: ByteArray size: words * 2.
		1 to: words do:
			[:x |
			form bitsWordAt: i0 + x put:
				((line at: x + x - 1) bitShift: 8) +
				(line at: x + x)]].
	^form! !

!Form class methodsFor: 'examples'!

exampleEdits
	"In Form category editing are messages edit and bitEdit that make it possible to 
	create editors on instances of Form. "
	 
	"This is the general form editor--

	|f| 
	f _ Form fromUser. 
	f edit. 
	 
	and the bit editor
	|f | 
	f _ Form fromUser. 
	f bitEdit. 
	
	"
	^self!

exampleMagnify
	"Create a Form from the area around the cursor location
	and display its magnified view.  Move the cursor to see the
	effect.  Press red button to terminate the example."

	"Form exampleMagnify."
	
	[Sensor redButtonPressed] whileFalse:
		[((self fromDisplay: (Sensor cursorPoint extent: 50@50))
			magnifyBy: 3 @ 3)
				displayAt: 0 @ 0]!

exampleShrink
	"Create a Form from the area around the cursor location
	and display its shrunken view.  Move the cursor to see the
	effect.  Press red button to terminate the example."

	"Form exampleShrink."

	[Sensor redButtonPressed] whileFalse:
		[((self fromDisplay: (Sensor cursorPoint extent: 150@150))
			shrinkBy: 3 @ 3)
				displayAt: 0 @ 0]!

exampleSketch
	"This is a simple drawing algorithm to get a sketch on the display screen.  After 
	executing, just keep the mouse button depressed and a pen will let you 
	scribble."

	"Form exampleSketch."

	| aPen |
	aPen _ Pen new.
	Sensor waitButton.
	aPen place: Sensor cursorPoint.
	aPen down.
	[Sensor anyButtonPressed]
		whileTrue: [aPen goto: Sensor cursorPoint]!

exampleSpaceFill
	"This example demonstrates the area filling algorithm.
	The example starts by having the user sketch on the screen and then select
	a rectangular area of the screen which includes all of the area to be filled.
	Finally, (with crosshair cursor), the user points as the interior of the region
	to be filled, and the filling begins with that place as its seed."

	"Form exampleSpaceFill."

	| f r interiorPoint |
	self exampleSketch.		"sketch a little area with an enclosed region"
	r _ Rectangle fromUser.
	f _ self fromDisplay: r.
	Cursor crossHair showWhile:
		[interiorPoint _ Sensor waitButton - r origin].
	Cursor execute showWhile:
		[f shapeFill: Form gray interiorPoint: interiorPoint].
	f displayOn: Display at: r origin!

parcPlaceLogo
	"Answer an instance with the shape of the ParcPlace Systems, Inc. logo"

	^self
		extent: 126@82
		fromArray: #(65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 63743 65535 65535 65535 65535 65535 65535 65535 57599 65535 65535 65535 65535 65535 65535 65535 255 65535 65535 65535 65535 65535 65535 65528 255 65535 65535 65535 65535 65535 65535 65472 255 65535 65535 65535 65535 65535 65535 65024 255 65535 65535 65535 65535 65535 65535 61440 4351 65535 65535 65535 65535 65535 65535 32768 61695 35840 0 1023 65535 65535 65532 7 61694 3072 0 1023 65280 0 192 63 61680 3072 0 1023 65280 0 192 511 61568 3072 0 1023 65280 0 192 4095 61440 3135 65535 50175 65280 0 192 32767 57344 3135 65535 50175 65295 65535 61635 65535 1 3135 65535 50175 65295 65535 61635 65528 15 3135 65535 50175 65295 65535 61635 65472 127 3135 65535 50175 65295 65535 61635 64512 255 3135 65535 50175 65295 65535 61635 64512 4351 3135 65535 50175 65295 65535 61635 64512 61695 3135 65535 50175 65295 65535 61635 64519 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 61695 3135 65535 50175 65295 65535 61635 64575 57599 3135 65535 50175 65295 65535 61635 64575 255 3135 65535 50175 65295 65535 61635 64568 255 3135 65535 50175 65295 65535 61635 64512 1023 3135 65535 50175 65295 65535 61635 64512 8191 3135 65535 50175 65295 65535 61635 64512 65535 3135 65535 50175 65295 65535 61635 61447 65535 3135 65535 50175 65295 65535 61635 32831 65535 3072 0 1023 65295 65535 61632 63 65535 3072 0 1023 65280 0 192 63 65534 3072 0 1023 65280 0 192 3135 65520 3072 0 1023 65280 0 192 31807 65408 4095 65535 65535 65280 0 195 64575 64512 16383 65535 65535 65535 65535 65535 64575 57345 65535 65535 65535 65535 65535 65535 64575 15 65535 65535 65535 65535 65535 65535 64568 127 65535 65535 65535 65535 65535 65535 64512 1023 65535 65535 65535 65535 65535 65535 64512 8191 65535 65535 65535 65535 65535 65535 64512 65535 65535 65535 65535 65535 65535 65535 64519 65535 65535 65535 65535 65535 65535 65535 64575 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 65535 )
		offset: 0@0!

screenSaveWith: aForm velocity: step delay: milliseconds
	"Bounce the argument around the screen until a key or mouse 
	button is pressed."

	| point dir cBlit form delay |
	Display black.
	point _ Display extent // 2.
	dir _ step.
	delay _ Delay forMilliseconds: milliseconds.
	form _ (Form extent: aForm extent + (step abs*2)) black.
	aForm displayOn: form at: step abs.
	cBlit _ BitBlt
				destForm: Display
				sourceForm: form
				halftoneForm: nil
				combinationRule: Form over
				destOrigin: point - step abs
				sourceOrigin: 0 @ 0
				extent: form extent
				clipRect: Display boundingBox.
	[Sensor keyboardPressed or: [Sensor anyButtonPressed]]
		whileFalse: 
			[point _ point + dir.
			(point x < 0 or: [point x + aForm width > Display width])
				ifTrue: [dir _ dir * (-1 @ 1)].
			(point y < 0 or: [point y + aForm height > Display height])
				ifTrue: [dir _ dir * (1 @ -1)].
			cBlit destOrigin: point - step abs; copyBits.
			delay wait].
	[Sensor keyboardPressed]
		whileTrue: [Sensor keyboard].
	ScheduledControllers restore! !

Form initialize!
