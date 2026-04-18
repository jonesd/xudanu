'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:54 pm'!

Object subclass: #BitBlt
	instanceVariableNames: 'destForm sourceForm halftoneForm combinationRule destX destY width height sourceX sourceY clipX clipY clipWidth clipHeight '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Support'!
BitBlt comment:
'The BitBlt operation copies bits from one rectangle within a Form (source) to another (dest).  The result is stored according to a combination rule which specifies one of the sixteen possibilities for how white and black should be combined.

Instance Variables:
	destForm	<Form> destination of a copy
	sourceForm	<Form> source from which to copy
	halftoneForm	<Form> screen to mask the source during the copy
	combinationRule	<Integer> between 0 and 15
	destX	<Integer>
	destY	<Integer>
	width	<Integer>
	height	<Integer>
	sourceX	<Integer>
	sourceY	<Integer>
	clipX	<Integer>
	clipY	<Integer>
	clipWidth	<Integer>
	clipHeight 	<Integer>

If halftoneForm is not nil, it is a halftone screen which masks (is ANDed with) the source during the operation.  Halftones are 16x16 bit Forms which are repeated indefinitely as needed by the BitBlt operation. with the two forms and a halftoneForm.

If sourceForm is nil, the halftone is taken by itself to be the source, as for filling with a constant pattern.

The clipping parameters specify a rectangle in the destination outside of which BitBlt will not make any changes
'!


!BitBlt methodsFor: 'accessing'!

clipHeight: anInteger 
	"Set the clipHeight instance variable in BitBlt."

	clipHeight _ anInteger!

clipRect
	"Answer the clipX, clipY clipWidth and clipHeight instance variables in 
	BitBlt."

	^clipX @ clipY extent: clipWidth @ clipHeight!

clipRect: aRectangle 
	"Set the clipX, clipY clipWidth andclipHeight instance variables in BitBlt. 
	This is a shorthand way to set four of the parameters to BitBlt."

	clipX _ aRectangle left.
	clipY _ aRectangle top.
	clipWidth _ aRectangle width.
	clipHeight _ aRectangle height!

clipWidth: anInteger 
	"Set the clipWidth instance variable in BitBlt."

	clipWidth _ anInteger!

clipX: anInteger 
	"Set the clipX instance variable in BitBlt."

	clipX _ anInteger!

clipY: anInteger 
	"Set the clipY instance variable in BitBlt."

	clipY _ anInteger!

combinationRule: anInteger 
	"Set the combinationRule instance variable in BitBlt.  anInteger is in the range 0-16."

	combinationRule _ anInteger!

destForm: aForm 
	"Set the destinationForm instance variable in BitBlt."

	destForm _ aForm!

destOrigin: aPoint 
	"Set the destination coordinates to be those of aPoint."
	destX _ aPoint x.
	destY _ aPoint y!

destRect
	"Answer the destination rectangle."

	^destX@destY extent: width@height!

destRect: aRectangle 
	"Set the destination coordinates to be those of aRectangle top left and
	the width and height of the receiver to be the width and height of aRectangle."
	destX _ aRectangle left.
	destY _ aRectangle top.
	width _ aRectangle width.
	height _ aRectangle height!

destX: anInteger 
	"Set the destX instance variable in BitBlt."

	destX _ anInteger!

destY: anInteger 
	"Set the destY instance variable in BitBlt."

	destY _ anInteger!

height: anInteger 
	"Set the height instance variable in BitBlt ."

	height _ anInteger!

mask: aForm 
	"Set the halftoneForm instance variable in BitBlt."

	halftoneForm _ aForm!

sourceForm: aForm 
	"Set the sourceForm instance variable in BitBlt."

	sourceForm _ aForm!

sourceOrigin: aPoint 
	"Set the source form coordinats to be those of aPoint."
	sourceX _ aPoint x.
	sourceY _ aPoint y!

sourceRect: aRectangle 
	"Set the sourceX, sourceY width and height instance variables in BitBlt.  This 
	is a shorthand way to set four of the parameters to BitBlt."

	sourceX _ aRectangle left.
	sourceY _ aRectangle top.
	width _ aRectangle width.
	height _ aRectangle height!

sourceX: anInteger 
	"Set the sourceX instance variable in BitBlt."

	sourceX _ anInteger!

sourceY: anInteger 
	"Set the sourceY instance variable in BitBlt."

	sourceY _ anInteger!

width: anInteger 
	"Set the width instance variable in BitBlt."

	width _ anInteger! !

!BitBlt methodsFor: 'copying'!

clipFully
	"Do the clipping in Smalltalk (after the primitive failed,
	and after truncating all parameters to integers).
	Fixes very negative or very large rectangles."

	| deltaLeft deltaTop deltaRight deltaBottom |

	deltaLeft _ clipX - destX max: 0.
	deltaTop _ clipY - destY max: 0.
	deltaRight _ clipX + clipWidth - (destX + width) min: 0.
	deltaBottom _ clipY + clipHeight - (destY + height) min: 0.

	destX _ destX + deltaLeft.
	destY _ destY + deltaTop.
	sourceX _ sourceX + deltaLeft.
	sourceY _ sourceY + deltaTop.

	height _ height - deltaTop + deltaBottom max: 0.
	width  _ width - deltaLeft  + deltaRight max: 0.

	clipX _ clipX max: 0.
	clipY _ clipY max: 0.
	clipHeight _ clipHeight max: 0.
	clipWidth _ clipWidth max: 0!

copyBits
	"Perform the movement of bits from one Form to another described by 
	the instance variables of the receiver. Fail if any instance variables 
	are not of the right type (Integer or Form) or if combinationRule is 
	not between 0 and 15 inclusive. Set the variables and try again 
	(BitBlt|copyBitsAgain). Essential. See Object documentation 
	whatIsAPrimitive."

	<primitive: 96>
	combinationRule = Form paint
		ifTrue: [^self paintBits]
		ifFalse: [^(self copy) truncateFully; copyBitsAgain"Handle Float coordinates"]!

paintBits
	"Perform the paint operation, which may require two calls to BitBlt."
	| oldMask |

	(halftoneForm == nil or: [halftoneForm == Form black]) ifFalse: 		"optimization"
		[oldMask _ halftoneForm.
		combinationRule _ Form erase.
		halftoneForm _ nil.
		self copyBits. 			"first erase hole in dest"
		halftoneForm _ oldMask].
	halftoneForm == Form white ifFalse: 		"optimization"
		[combinationRule _ Form under.
		self copyBits].
	combinationRule _ Form paint. 	"restore rule"

	"(Form dotOfSize: 32)
		displayOn: Display
		at: Sensor cursorPoint
		clippingBox: Display boundingBox
		rule: Form paint
		mask: Form lightGray"!

truncateFully
	"Truncate all coordinates in case any of them was a Float."

	destX _ destX truncated.
	destY _ destY truncated.
	width _ width truncated.
	height _ height truncated.

	sourceX _ sourceX truncated.
	sourceY _ sourceY truncated.

	clipX _ clipX truncated.
	clipY _ clipY truncated.
	clipWidth _ clipWidth truncated.
	clipHeight _ clipHeight truncated! !

!BitBlt methodsFor: 'line drawing'!

drawFrom: startPoint to: stopPoint
	"Draw a line from startPoint to stopPoint."

	| offset point1 point2 |
	"Always draw down, or at least left-to-right"
	((startPoint y = stopPoint y and: [startPoint x < stopPoint x])
		or: [startPoint y < stopPoint y])
		ifTrue: [point1 _ startPoint. point2 _ stopPoint]
		ifFalse: [point1 _ stopPoint. point2 _ startPoint].
	width _ sourceForm width.
	height _ sourceForm height.
	offset _ sourceForm offset.
	destX _ (point1 x + offset x) rounded.
	destY _ (point1 y + offset y) rounded.
	self drawLoopX: (point2 x - point1 x) rounded 
				  Y: (point2 y - point1 y) rounded!

drawLoopX: xDelta Y: yDelta 
	"This is the Bresenham plotting algorithm (IBM Systems Journal Vol 
	4 No. 1, 1965). It chooses a principal direction, and maintains  
	a potential, P.  When P's sign changes, it is time to move in the 
	minor direction as well.  Optional.  See Object documentation whatIsAPrimitive."

	| dx dy px py P i |
	<primitive: 104>
	combinationRule = Form paint
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

paintLoopX: xDelta Y: yDelta 
	"Perform the paint operation, which may require two calls to BitBlt."

| oldMask startX startY |
	(halftoneForm == nil or: [halftoneForm == Form black])
		ifFalse: 
			["optimization"
			startX _ destX.
			startY _ destY.
			oldMask _ halftoneForm.
			combinationRule _ Form erase.
			halftoneForm _ nil.
			self drawLoopX: xDelta Y: yDelta.
			"first erase hole in dest"
			halftoneForm _ oldMask.
			destX _ startX.
			destY _ startY	].
	halftoneForm == Form white
		ifFalse: 
			["optimization"
			combinationRule _ Form under.
			self drawLoopX: xDelta Y: yDelta].
	combinationRule _ Form paint! !

!BitBlt methodsFor: 'private: private'!

copyBitsAgain
	<primitive: 96>
	(self clipRect intersects: self destRect)	"check for intersection before clipping"
		ifTrue: [self clipFully.	"Clipping for very negative or very large rectangles"
				^self copyBitsAgainAgain]!

copyBitsAgainAgain
	<primitive: 96>
	self primitiveFailed!

setDestForm: df sourceForm: sf halftoneForm: hf combinationRule: cr destOrigin: destOrigin sourceOrigin: sourceOrigin extent: extent clipRect: clipRect 
	| aPoint |
	destForm _ df.
	sourceForm _ sf.
	halftoneForm _ hf.
	combinationRule _ cr.
	destX _ destOrigin x.
	destY _ destOrigin y.
	sourceX _ sourceOrigin x.
	sourceY _ sourceOrigin y.
	width _ extent x.
	height _ extent y.
	aPoint _ clipRect origin.
	clipX _ aPoint x.
	clipY _ aPoint y.
	aPoint _ clipRect corner.
	clipWidth _ aPoint x - clipX.
	clipHeight _ aPoint y - clipY! !

!BitBlt methodsFor: 'display'!

display: string from: startIndex to: stopIndex attributes: atts at: displayPos 
	"This is the text display primitive."

	| ascii maxAscii font fontForm xTable |
	font _ atts font.
	fontForm _ font glyphs.
	xTable _ font xTable.
	maxAscii _ font maxAscii.
	sourceForm _ fontForm.
	sourceY _ 0.
	height _ fontForm height.
	destX _ displayPos x.
	destY _ displayPos y.
	halftoneForm _ Form black.
	combinationRule _ atts rule.
	startIndex to: stopIndex do: 
		[:i | 
		ascii _ (string at: i) asciiValue.
		ascii < maxAscii ifFalse: [ascii _ maxAscii].
		sourceX _ xTable at: ascii + 1.
		width _ (xTable at: ascii + 2)
					- sourceX.
		self copyBits.
		destX _ destX + width].
	"atts reverse.
	width _ destX - displayPos x.
	destX _ displayPos x.
	sourceForm _ nil.
	rule _ Form reverse."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BitBlt class
	instanceVariableNames: ''!


!BitBlt class methodsFor: 'instance creation'!

destForm: df sourceForm: sf halftoneForm: hf combinationRule: cr destOrigin: destOrigin sourceOrigin: sourceOrigin extent: extent clipRect: clipRect 
	"Answer an instance of the receiver with values set according to the 
	arguments. "

	^self new
		setDestForm: df
		sourceForm: sf
		halftoneForm: hf
		combinationRule: cr
		destOrigin: destOrigin
		sourceOrigin: sourceOrigin
		extent: extent
		clipRect: clipRect!

toReverse: aRectangle 
	"Answer a new instance of the receiveer that will reverse a particular rectangle in the 
	destination (which must be supplied later)."

	^self
		destForm: nil
		sourceForm: nil
		halftoneForm: nil
		combinationRule: Form reverse
		destOrigin: aRectangle origin
		sourceOrigin: 0 @ 0
		extent: aRectangle extent
		clipRect: aRectangle! !

!BitBlt class methodsFor: 'examples'!

exampleOne
	"This tests BitBlt by displaying the result of all sixteen combination rules 
	that BitBlt is capable of using.  (Please see the Byte magazine article by D. Ingalls 
	for the meaning of the combination rules and the complete documentation for 
	BitBlt in Smalltalk-80.)"

	"BitBlt exampleOne."

	| path |
	path _ Path new.
	0 to: 3 do: [:i | 0 to: 3 do: [:j | path add: j * 100 @ (i * 100)]].
	Display white.
	path _ path translateBy: 100 @ 100.
	1 to: 16 do: [:index | BitBlt
			exampleAt: (path at: index)
			rule: index - 1
			mask: Form gray]!

exampleTwo
	"This is to test painting with a gray tone. It also tests that the seaming with gray 
	patterns is correct in the implementation.  Lets you paint until you press a mouse button."
	"BitBlt exampleTwo."

	| f aBitBlt |
	"create a small black Form source as a brush."
	f _ Form new extent: 20 @ 20.
	f black.
	"create a BitBlt which will OR gray into the display"
	aBitBlt _ BitBlt
		destForm: Display
		sourceForm: f
		halftoneForm: Form gray
		combinationRule: Form under
		destOrigin: Sensor cursorPoint
		sourceOrigin: 0 @ 0
		extent: f extent
		clipRect: Display computeBoundingBox.

	"paint the gray Form on the screen for a while"
	[Sensor anyButtonPressed]
		whileFalse:
			[aBitBlt destOrigin: Sensor cursorPoint.
			aBitBlt copyBits]! !

!BitBlt class methodsFor: 'private: private'!

exampleAt: originPoint rule: rule mask:  mask 
	"This builds a source and destination form and copies the source to the destination
	using the specifed rule and mask.  It is called from the method named exampleOne."

	| s d border aBitBlt | 
	border_Form new extent: 32@32.
	border black.
	border fill: (1@1 extent: 30@30) mask: Form white.
	s_Form new extent: 32@32.
	s white.
	s fill: (7@7 corner: 25@25) mask: Form black.
	d_Form new extent: 32@32.
	d white.
	d fill: (0@0 corner: 32@16) mask: Form black.

	s displayOn: Display at: originPoint.
	border displayOn: Display at: originPoint rule: Form under.
	d displayOn: Display at: originPoint + (s width @0).
	border displayOn: Display at: originPoint + (s width @0) rule: Form under.

	d displayOn: Display at: originPoint + (s extent // (2 @ 1)).
	aBitBlt _ BitBlt
		destForm: Display
		sourceForm: s
		halftoneForm: mask
		combinationRule: rule
		destOrigin: originPoint + (s extent // (2 @ 1))
		sourceOrigin: 0 @ 0
		extent: s extent
		clipRect: Display computeBoundingBox.
	aBitBlt copyBits.
	border 
		displayOn: Display at: originPoint + (s extent // (2 @ 1))
		rule: Form under.
   
	"BitBlt exampleAt: 100@100 rule: 3 mask: Form gray."! !