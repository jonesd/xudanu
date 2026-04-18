'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:45 pm'!

Form subclass: #Cursor
	instanceVariableNames: 'name {UNKNOWN}'
	classVariableNames: '
		BigNormalCursor {UNKNOWN} 
		BlankCursor {UNKNOWN} 
		BottomLeftCursor {UNKNOWN} 
		BullCursor {UNKNOWN} 
		CaretCursor {UNKNOWN} 
		CornerCursor {UNKNOWN} 
		CrossHairCursor {UNKNOWN} 
		CurrentCursor {UNKNOWN} 
		DownCursor {UNKNOWN} 
		GarbageCursor {UNKNOWN} 
		HandCursor {UNKNOWN} 
		MarkerCursor {UNKNOWN} 
		NormalCursor {UNKNOWN} 
		OriginCursor {UNKNOWN} 
		ReadCursor {UNKNOWN} 
		ScrollCursor {UNKNOWN} 
		SquareCursor {UNKNOWN} 
		ThumbsDownCursor {UNKNOWN} 
		ThumbsUpCursor {UNKNOWN} 
		TopRightCursor {UNKNOWN} 
		UpCursor {UNKNOWN} 
		UseBigCursor {BooleanVar} 
		WaitCursor {UNKNOWN} 
		WriteCursor {UNKNOWN} 
		XeqCursor {UNKNOWN} '
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!



!Cursor methodsFor: 'updating'!

changed: aParameter 
	"Receiver changed.  The change is denoted by the argument 
	anAspectSymbol.  Usually the argument is a Symbol that is part of 
	the dependent's change protocol, that is, some aspect of the 
	object's behavior.  Inform all of the dependents."

	self == CurrentCursor ifTrue: [self beCursor].
	super changed: aParameter! !

!Cursor methodsFor: 'displaying'!

beCursor
	"Tell the VM to use the receiver as the current cursor image."

	^self beCursorOffsetBy: 0 @ 0 - offset!

beCursorOffsetBy: aPoint 
	"Tell the interpreter to use the receiver as the current cursor image, 
	using the supplied point as the 'hot-spot'.  Fail if the receiver does 
	not match the size expected by the hardware, or if the hot-spot is 
	not within the cursor's bounding-box.  Essential.  See Object 
	documentation whatIsAPrimitive."

	<primitive: 702>
	((aPoint isKindOf: Point)
		and: [(aPoint x isKindOf: SmallInteger)
				& (aPoint y isKindOf: SmallInteger)])
		ifFalse: [^self beCursorOffsetBy: aPoint rounded]
		ifTrue: [self primitiveFailed]!

beGarbageCollectionCursor
	"Tell the VM to use the receiver as the current cursor image."

	^self beGarbageCollectionCursorOffsetBy: 0 @ 0 - offset!

beGarbageCollectionCursorOffsetBy: aPoint 
	"Tell the interpreter to use the receiver as the garbage collection cursor 
	image, using the supplied point as the 'hot-spot'.  Fail if the receiver does 
	not match the size expected by the hardware, or if the hot-spot is 
	not within the cursor's bounding-box.  Optional.  See Object 
	documentation whatIsAPrimitive."

	<primitive: 704>
	((aPoint isKindOf: Point)
		and: [(aPoint x isKindOf: SmallInteger)
				& (aPoint y isKindOf: SmallInteger)])
		ifFalse: [^self beGarbageCollectionCursorOffsetBy: aPoint rounded]
		ifTrue: [self primitiveFailed]!

show
	"Make the current cursor shape be the receiver."

	Sensor currentCursor: self!

showGridded: gridPoint 
	"Make the current cursor shape be the receiver, forcing the location 
	of cursor to the point nearest the point gridPoint."

	Sensor primCursorLocPut: (Sensor cursorPoint grid: gridPoint).
	Sensor currentCursor: self!

showWhile: aBlock 
	"While evaluating the argument, aBlock, make the receiver be the cursor shape."

	| oldcursor value |
	oldcursor _ Sensor currentCursor.
	self show.
	[value _ aBlock value.]
		valueNowOrOnUnwindDo: [oldcursor show].
	^value! !

!Cursor methodsFor: 'printing'!

printOn: aStream  
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	self storeOn: aStream base: 2!

storeOn: aStream base: anInteger 
	"Store the receiver out in the form:  Form extent:fromArray:#()offset:"

	aStream nextPut: $(.
	super storeOn: aStream base: anInteger.
	aStream nextPutAll: ' name: '.
	name storeOn: aStream.
	aStream nextPut: $).! !

!Cursor methodsFor: 'name'!

name
	"Answer the string labelling the receiver."

	^name!

name: aString
	"Make the argument aString, be the label for the receiver."

	name _ aString! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Cursor class
	instanceVariableNames: ''!



!Cursor class methodsFor: 'class initialization'!

initialize
	"Create all the standard cursors."
	"Cursor initialize."

	BlankCursor _ Cursor new.
	self initNormal.
	self initXeq.
	self initRead.
	self initWrite.
	self initUp.
	self initDown.
	self initMarker.
	self initScroll.
	self initOrigin.
	self initCorner.
	self initTopRight.
	self initBottomLeft.
	self initCrossHair.
	self initCaret.
	self initWait.
	self initGarbage.
	self initThumbsUp.
	self initThumbsDown.
	self initBull.
	self initHand.
	self initBigNormal.!

install
	"Set up standard cursors for selection and garbage collection."

	self currentCursor: self normal.
	self garbageCollectionCursor: self garbage! !

!Cursor class methodsFor: 'instance creation'!

extent: extentPoint fromArray: anArray offset: offsetPoint 
	"Answer a new instance of the receiver with width and height specified by
	extentPoint, offset by offsetPoint, and bits from anArray.  Provide an error
	notification if the extentPoint is not 16@16."

	extentPoint = (16 @ 16)
		ifTrue: 
			[^super
				extent: extentPoint
				fromArray: anArray
				offset: offsetPoint]
		ifFalse: [self error: 'cursors must be 16@16']!

extent: extentPoint fromArray: anArray offset: offsetPoint name: aString 
	"Answer a new instance of the receiver with width and height 
	specified by extentPoint, offset by offsetPoint, and bits from 
	anArray.   Provide an error notification if the extentPoint is not 16@16."

	extentPoint = (16 @ 16)
		ifTrue: [^(super
				extent: extentPoint
				fromArray: anArray
				offset: offsetPoint)
				name: aString]
		ifFalse: [self error: 'cursors must be 16@16']!

new	
	"Answer a new instance of the receiver that is a blank image."

	"Cursor new bitEdit."

	^self
		extent: 16 @ 16
		fromArray: Array new
		offset: 0 @ 0! !

!Cursor class methodsFor: 'current cursor'!

bigCursor: big {Boolean}

	UseBigCursor := big not not. "ensure its a boolean"
	Cursor normal show!

currentCursor
	"Answer the instance of the receiver that is the one currently displayed."

	^CurrentCursor!

currentCursor: aCursor 
	"Make the instance of Cursor, aCursor, be the current cursor.  Display
	it.  Provide an error notification if the argument is not a Cursor."

	aCursor class == self
		ifTrue: 
			[CurrentCursor == aCursor
				ifFalse: [CurrentCursor _ aCursor.
						aCursor beCursor]]
		ifFalse: [self error: 'The new cursor must be an instance of class Cursor']!

cursorLink: boolean 
	"Cause the cursor to track the pointing device location if the argument is true.  
	Decouple the cursor from the pointing device if the argument is false.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 92>
	^self primitiveFailed!

garbageCollectionCursor: aCursor 
	"Make the instance of Cursor, aCursor, be the garbage collection
	cursor.  Provide an error notificaton if the argument is not a Cursor."

	aCursor class == self
		ifTrue: [aCursor beGarbageCollectionCursor]
		ifFalse: [self error: 'The cursor must be an instance of class Cursor']!

usingBigCursor

	^UseBigCursor! !

!Cursor class methodsFor: 'constants'!

bigNormal

	^BigNormalCursor!

blank
	"Answer the instance of the receiver that is all white."

	^BlankCursor!

bottomLeft
	"Answer the instance of the receiver that is a bottom left corner."

	^BottomLeftCursor!

bull
	"Answer the instance of the receiver that is a bull's-eye."

	^BullCursor!

caret
	"Answer the instance of the receiver that is a caret."

	^CaretCursor!

corner
	"Answer the instance of the receiver that is the shape of the bottom right corner of
	a rectangle."

	^CornerCursor!

crossHair
	"Answer the instance of the receiver that is the shape of a cross."

	^CrossHairCursor!

down
	"Answer the instance of the receiver that is the shape of an arrow facing downward."

	^DownCursor!

execute
	"Answer the instance of the receiver that is the shape of an arrow slanted left
	with a star next to it."

	^XeqCursor!

garbage
	"Answer the instance of the receiver that is the shape of a garbage can with 
	open lid."

	^GarbageCursor!

hand
	"Answer the instance of the receiver that is the shape of a hand."

	^HandCursor!

marker
	"Answer the instance of the receiver that is displayed when thumb-scrolling."

	^MarkerCursor!

normal
	"Answer the instance of the receiver that is the shape of an arrow slanted left."

	^UseBigCursor ifTrue: [^BigNormalCursor] ifFalse: [^NormalCursor]!

origin
	"Answer the instance of the receiver that is the shape of the top left 
	corner of a rectangle."

	^OriginCursor!

read
	"Answer the instance of the receiver that is the shape of eyeglasses."

	^ReadCursor!

scroll
	"Answer the instance of the receiver that is up and down arrows."

	^ScrollCursor!

square
	"Answer the instance of the receiver that is the shape of a square."

	^SquareCursor!

thumbsDown
	"Answer the instance of the receiver that is a thumbs down."

	^ThumbsDownCursor!

thumbsUp
	"Answer the instance of the receiver that is thumbs up."

	^ThumbsUpCursor!

topRight
	"Answer the instance of the receiver that is a top right corner."

	^TopRightCursor!

up
	"Answer the instance of the receiver that is the shape of an arrow facing upward."

	^UpCursor!

wait
	"Answer the instance of the receiver that is the shape of an hour glass."

	^WaitCursor!

write
	"Answer the instance of the receiver that is the shape of a pen writing."

	^WriteCursor! !

!Cursor class methodsFor: 'private: private-constant initialization'!

initBigNormal

	UseBigCursor := false.
	BigNormalCursor := ((Cursor
		extent: 16@16
		fromArray: #(
			2r1000000000000000
			2r1100000000000000
			2r1110000000000000
			2r1111000000000000
			2r1111100000000000
			2r1111110000000000
			2r1111111000000000
			2r1111111100000000
			2r1111111110000000
			2r1111111111000000
			2r1111111111100000
			2r1111111111110000
			2r1111000000000000
			2r1110000000000000
			2r1100000000000000
			2r1000000000000000)
		offset: 0@0) name: 'bigNormal')!

initBottomLeft
	BottomLeftCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1111111111111111
		2r1111111111111111)
			offset: -2@-2 name: 'bottomLeft')!

initBull
		BullCursor _ (Cursor 
			extent: 16@16
			fromArray: #(
		2r0000000000000000
		2r0000011111000000
		2r0001100100110000
		2r0010000100001000
		2r0100000100000100
		2r0100000100000100
		2r1000000100000010
		2r1000000100000010
		2r1111111111111110
		2r1000000100000010
		2r1000000100000010
		2r0100000100000100
		2r0100000100000100
		2r0010000100001000
		2r0001100100110010
		2r0000011111000000)
			offset: -8@-9 name: 'bull').!

initCaret
	CaretCursor _ (Cursor
	  extent: 16@16
	  fromArray: #(
		2r110000000
		2r110000000
		2r1111000000
		2r11111100000
		2r11001100000
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0)
	offset: -8@0 name: 'caret').!

initCorner
	CornerCursor _ (Cursor 
			extent: 16@16
			fromArray: #(
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r1111111111111111
		2r1111111111111111)
			offset: -14@-14
			name: 'corner')!

initCrossHair
	CrossHairCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r1111111111111110
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0)
			offset: -7@-7 name: 'crossHair')!

initDown
	DownCursor _ (Cursor 
			extent: 16@16
			fromArray: #(
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r1111110000000000
		2r0111110000000000
		2r0011110000000000
		2r0001110000000000
		2r0000110000000000
		2r0000010000000000)
			offset: -5@-7 name: 'down')!

initGarbage
	GarbageCursor _ (Cursor
	extent: 16@16
	fromArray: #(
		2r111111100000
		2r1000000011000
		2r1000000000100
		2r111111100100
		2r1111111111000
		2r1011111101000
		2r1000000001000
		2r1001001001000
		2r1001001001000
		2r1001001001000
		2r1001001001000
		2r1001001001000
		2r1001001001000
		2r1001001001000
		2r100000010000
		2r11111100000)
	offset: 0@0 name: 'garbage')!

initHand
	HandCursor _ (Cursor
			extent: 16 @ 16
			fromArray: #(
		2r110000000
		2r1101001110000
		2r10011001001000
		2r10011001001010
		2r1001001001101
		2r1001001001001
		2r110100000001001
		2r1001100000000001
		2r1000100000000010
		2r100000000000010
		2r10000000000010
		2r1000000000100
		2r1000000000100
		2r100000001000
		2r10000001000
		2r10000001000)
			offset: 0 @ 0
			name: 'hand').!

initMarker
	MarkerCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r0
		2r0
		2r0
		2r0000001000000000
		2r0000001110000000
		2r0000001111100000
		2r1111111111111000
		2r1111111111111110
		2r1111111111111000
		2r0000001111100000
		2r0000001110000000
		2r0000001000000000
		2r0
		2r0
		2r0
		2r0)
			offset: -7@-7 name: 'mark')!

initNormal
	NormalCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r1000000000000000
		2r1100000000000000
		2r1110000000000000
		2r1111000000000000
		2r1111100000000000
		2r1111110000000000
		2r1111111000000000
		2r1111100000000000
		2r1111100000000000
		2r1001100000000000
		2r0000110000000000
		2r0000110000000000
		2r0000011000000000
		2r0000011000000000
		2r0000001100000000
		2r0000001100000000)
	offset: 0@0 name: 'normal')!

initOrigin
	OriginCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r1111111111111111
		2r1111111111111111
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000)
			offset: -2@-2 name: 'origin')!

initRead
	ReadCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r0000110000000110
		2r0001001000001001
		2r0001001000001001
		2r0010000000010000
		2r0100000000100000
		2r1111101111100000
		2r1000010000100000
		2r1000010000100000
		2r1011010110100000
		2r0111101111000000
		2r0
		2r0
		2r0
		2r0
		2r0
		2r0)
	offset: 0@0
	name: 'read')!

initScroll
	ScrollCursor _ (Cursor 
			extent: 16@16
			fromArray: #(
		2r0000100000000000
		2r0000110000000000
		2r0000111000000000
		2r0000111100000000
		2r0000111110000000
		2r0000111111000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r0000110000000000
		2r1111110000000000
		2r0111110000000000
		2r0011110000000000
		2r0001110000000000
		2r0000110000000000
		2r0000010000000000)
			offset: -5@-7 name: 'scroll')!

initThumbsDown
	ThumbsDownCursor _ (Cursor
			extent: 16@16
			fromArray:
				#(
		2r111111110000
		2r100000001000
		2r1111100000111
		2r10000000000000
		2r11111100000000
		2r10000000000000
		2r11111100000000
		2r10000000000000
		2r1000010000011
		2r111110001100
		2r10001000
		2r10001000
		2r1111000
		2r1001000
		2r1101000
		2r10000)
			offset: 0@0 name: 'thumbsDown').!

initThumbsUp
	ThumbsUpCursor _ (Cursor
			extent: 16@16
			fromArray: 
				#(
		2r10000
		2r1101000
		2r1001000
		2r1111000
		2r10001000
		2r10001000
		2r111110001100
		2r1000010000011
		2r10000000000000
		2r11111100000000
		2r10000000000000
		2r11111100000000
		2r10000000000000
		2r1111100000111
		2r100000001000
		2r111111110000)
			offset: -15@0 name: 'thumbsUp').!

initTopRight
	TopRightCursor _ (Cursor 
			extent: 16@16
			fromArray: #(
		2r1111111111111111
		2r1111111111111111
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011
		2r0000000000000011)
			offset: -14@-14
			name: 'topRight')!

initUp
	UpCursor _ (Cursor 
			extent: 16@16
			fromArray: #(
		2r1000000000000000
		2r1100000000000000
		2r1110000000000000
		2r1111000000000000
		2r1111100000000000
		2r1111110000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000
		2r1100000000000000)
	 		offset: 0@-7 name: 'up')!

initWait
	WaitCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r1111111111111111
		2r1000000000000001
		2r0100000000000010
		2r0010000000000100
		2r0001110000111000
		2r0000111101110000
		2r0000011011100000
		2r0000001111000000
		2r0000001111000000
		2r0000010110100000
		2r0000100010010000
		2r0001000110001000
		2r0010001101000100
		2r0100111111110010
		2r1011111111111101
		2r1111111111111111)
			offset: 0@0
			name: 'wait')!

initWrite
	WriteCursor _ (Cursor
	extent: 16@16
	fromArray: #(
		2r0000000000000110
		2r0000000000001111
		2r0000000000010110
		2r0000000000100100
		2r0000000001001000
		2r0000000010010000
		2r0000000100100000
		2r0000001001000011
		2r0000010010000010
		2r0000100100000110
		2r0001001000001000
		2r0010010000001000
		2r0111100001001000
		2r0101000010111000
		2r0110000110000000
		2r1111111100000000)
	offset: 0@0
	name: 'write')!

initXeq
	XeqCursor _ (Cursor
			extent: 16@16
			fromArray: #(
		2r1000000000010000
		2r1100000000010000
		2r1110000000111000
		2r1111000111111111
		2r1111100011000110
		2r1111110001000100
		2r1111111001111100
		2r1111100001101100
		2r1111100011000110
		2r1001100010000010
		2r0000110000000000
		2r0000110000000000
		2r0000011000000000
		2r0000011000000000
		2r0000001100000000
		2r0000001100000000)
	offset: 0@0 
	name: 'xeq')! !

Cursor initialize!
