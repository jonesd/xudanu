'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:00 pm'!

Object subclass: #StrikeFont
	instanceVariableNames: 'xTable glyphs name stopConditions minAscii maxAscii maxWidth strikeLength ascent descent xOffset raster subscript superscript emphasis '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Support'!
StrikeFont comment:
'Class StrikeFont represents a compact encoding of a set of Forms corresponding to characters in the ASCII character set.  All the forms are placed side by side in a large form whose height is the font height, and whose width is the sum of all the character widths.  The xTable gives the left-x coordinates of the subForms corresponding to the characters.

Instance Variables:

	xTable	<Array>  Of left x-coordinate of character in glyphs.
	glyphs	<Form>  Containing bits representing the characters.
	name	<String>  Name of this font.
	stopConditions	<Array>  Of selectors to be performed in scanning text.
	minAscii, maxAscii	<Integer>  Giving range supported by this font.
	maxWidth	<Integer>  Width of widest char. Not presently used, but may be for font modification.
	strikeLength	<Integer>  Not used.
	ascent, descent	<Integer>  Max extent of chars above and below the baseline
	xOffset	<Integer>  For kerning (not presently used)
	raster	<Integer>  Specifies layout of the glyphs form
	subscript, superscript	<Integer>  Further vertical offset relative to baseline
	emphasis	<Integer>  code for synthetic bold, italic, underline, strike-out

Pool Dictionary:
	TextConstants	<Dictionary>'!


!StrikeFont methodsFor: 'accessing'!

ascent
	"Answer the font's maximum extent of characters above the baseline."

	^ascent!

characterFormAt: character 
	"Answer a Form copied out of the glyphs for this character."

	| characterForm ascii |
	ascii _ character asciiValue.
	ascii > maxAscii ifTrue: [ascii _maxAscii].
	characterForm _ Form new extent: (self widthOf: character) @ self height.
	characterForm
		copyBits: (Rectangle origin: (xTable at: ascii + 1)
					@ 0 extent: (self widthOf: character)
					@ self height)
		from: glyphs
		at: 0 @ 0
		clippingBox: characterForm boundingBox
		rule: Form over
		mask: Form black.
	^characterForm!

characterFormAt: character put: aForm
	"Replace the glyph for this character with aForm."

	| sizedForm ascii newGlyphs deltaWidth |
	ascii _ character asciiValue + 1.
	ascii > maxAscii ifTrue: [^self]. ascii < minAscii ifTrue: [^self].
	"sizedForm is the argument form with the correct height and no more than maxWidth"
	sizedForm _ Form extent: ((aForm width min: self maxWidth) @ self height).
	sizedForm
		copyBits: aForm boundingBox
		from: aForm
		at: 0 @ 0
		clippingBox: sizedForm boundingBox
		rule: Form over
		mask: Form black.
	newGlyphs _
		Form extent: (glyphs width - (self widthOf: character) + sizedForm width) @ self height.
	newGlyphs	"get glyphs below character"
		copyBits: (0@0 extent: (xTable at: ascii) @ self height)
		from: glyphs
		at: 0 @ 0
		clippingBox: newGlyphs boundingBox
		rule: Form over
		mask: Form black.
	newGlyphs	"get glyphs for character"
		copyBits: sizedForm boundingBox
		from: sizedForm
		at: (xTable at: ascii) @ 0
		clippingBox: newGlyphs boundingBox
		rule: Form over
		mask: Form black.
	newGlyphs	"get glyphs above character"
		copyBits: ((xTable at: ascii + 1) @ 0 corner: glyphs extent)
		from: glyphs
		at: (xTable at: ascii) + sizedForm width @ 0
		clippingBox: newGlyphs boundingBox
		rule: Form over
		mask: Form black.
	glyphs _ newGlyphs.
	"now update xTable"
	deltaWidth _ sizedForm width - (self widthOf: character).
	ascii+1 to: xTable size do:
		[:i | xTable at: i put: (xTable at: i) + deltaWidth]!

descent
	"Answer the font's maximum extent of characters below the baseline."

	^descent!

familySizeFace
	"Answer an array with family name <String>, point size
<Integer>, and face code <Integer>."

	" (1 to: 12) collect: [:x | (TextStyle default fontAt: x)
familySizeFace] "

	| fontName firstDigit lastDigit |
	fontName_ name asUppercase.
	firstDigit _ fontName findFirst: [:aChar | aChar isDigit].
	lastDigit _ fontName findLast: [:aChar | aChar isDigit].
	^Array with: (fontName copyFrom: 1 to: firstDigit-1)
		with: (Integer readFromString: (fontName copyFrom:
firstDigit to: lastDigit))
		with: (#('B' 'I' 'BI') indexOf:
					(fontName copyFrom: lastDigit+1 to: fontName size))!

fontName
	"Answer the receiver's name."

	emphasis >= 4
		ifTrue: [^name, 'u']
		ifFalse: [^name]!

glyphs
	"Answer a Form containing the bits representing the characters of the receiver."

	^glyphs!

height
	"Answer the height of the font, total of maximum extents of characters
	above and below the baseline."

	^self ascent + self descent!

maxAscii
	"Answer the integer that is the last Ascii character value of the receiver."

	^maxAscii!

maxWidth
	"Answer the integer that is the width of the receiver's widest character."

	^maxWidth!

minAscii
	"Answer the integer that is the first Ascii character value of the receiver."

	^minAscii!

name
	"Answer the receiver's name."

	^name!

name: aString
	"Set the receiver's name."

	name _ aString.!

raster
	"Answer an integer that specifies the layout of the glyphs' form."

	^raster!

spaceWidth
	"Answer the width of the argument as a character in the receiver."

	| ascii |
	ascii _ $ asciiValue.
	^(xTable at: ascii + 2) - (xTable at: ascii + 1)!

stopConditions
	"Answer the array of selectors to be performed in scanning text made
	up of the receiver's characters."

	^stopConditions!

subscript
	"Answer an integer that is the further vertical offset relative to the
	baseline for positioning characters as subscripts."

	^subscript!

subscript: anInteger
	"Answer an integer that is the further vertical offset relative to the
	baseline for positioning characters as subscripts."

	subscript _ anInteger.!

superscript
	"Answer an integer that is the further vertical offset relative to the
	baseline for positioning characters as superscripts."

	^superscript!

superscript: anInteger
	"Answer an integer that is the further vertical offset relative to the
	baseline for positioning characters as superscripts."

	superscript _ anInteger.!

widthOf: aCharacter 
	"Answer the width of the argument as a character in the receiver."

	| ascii |
	ascii _ (aCharacter asciiValue min: maxAscii + 1) max: minAscii.
	^(xTable at: ascii + 2) - (xTable at: ascii + 1)!

widths
	"Answer the width of the argument as a character in the receiver."

	| widths width |
	widths _ IntegerTable make.IntegerVar: 256.
	width _ self widthOf: (Character value: 255).
	0 to: minAscii do: [:ascii | widths atInt: ascii store: width].
	minAscii to: maxAscii do: 
		[:ascii | widths atInt: ascii store: (xTable at: ascii + 2) - (xTable at: ascii + 1)].
	^widths!

xTable
	"Answer an array of the left x-coordinate of characters in glyphs."

	^xTable! !

!StrikeFont methodsFor: 'testing'!

checkCharacter: character 
	"Answer a character that is within the ascii range of the receiver--either character
	or the last character in the receiver."

	| ascii |  
	ascii _ character asciiValue.
	((ascii < minAscii) or: [ascii > maxAscii])
			ifTrue: [^maxAscii asCharacter]
			ifFalse:	[^character]!

hashForEqual
	^self hash!

isEqual: other
	^self = other! !

!StrikeFont methodsFor: 'displaying'!

characters: anInterval in: sourceString displayAt: aPoint clippedBy: clippingRectangle rule: ruleInteger mask: aForm 
	"Simple, slow, primitive method for displaying a line of characters.  No 
	wrap-around is handled."

	| ascii character characterForm |
	anInterval do: 
		[:i | 
		ascii _ (character _ sourceString at: i) asciiValue.
		(ascii < minAscii or: [ascii > maxAscii])
			ifTrue: [character _ (ascii _ maxAscii) asCharacter].
		characterForm _ self characterFormAt: character.
		characterForm
			displayOn: Display
			at: aPoint
			clippingBox: clippingRectangle
			rule: ruleInteger
			mask: aForm.
		aPoint x: aPoint x + (self widthOf: character)].
	^aPoint x!

composeWord: aTextLineInterval in: sourceString beginningAt: xInteger 
	"Non-primitive composition of a word -- add up widths of characters, add sum to 
	beginning x and answer the resulting x.  Similar to performance of scanning 
	primitive, but without stop conditions."

	| character resultX |
	resultX _ xInteger.
	aTextLineInterval do: 
		[:i | 
		character _ sourceString at: i.
		resultX _ resultX + (self widthOf: character)].
	^resultX!

displayLine: aString at: aPoint 
	"Display the characters in aString, starting at position aPoint."

	self characters: (1 to: aString size)
		in: aString
		displayAt: aPoint
		clippedBy: Display boundingBox
		rule: Form over
		mask: Form black! !

!StrikeFont methodsFor: 'emphasis'!

emphasis
	"Answer the integer code for synthetic bold, itallic, and underline."

	^emphasis!

emphasis: code 
	"Set the integer code for synthetic bold, itallic, underline, and strike-out,
	where bold=1, itallic=2, underlined=4, struck out=8, subscript=16, superscript=32."

	emphasis _ code!

emphasized: code 
	"Answer a copy of the receiver with emphasis set to code."

	"TextStyle default fontAt: 9 put: ((TextStyle default fontAt: 1) emphasized: 4)"

	^self copy emphasis: code + emphasis!

emphasized: code named: aString
	"Answer a copy of the receiver with emphasis set to code."

	| copy |
	copy _ self copy emphasis: (code + emphasis).
	copy name: aString.
	^copy! !

!StrikeFont methodsFor: 'printing'!

printOn: aStream
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	aStream nextPutAll: self class name, ' name ', name, ' emphasis ';
		print: emphasis; nextPut: Character cr.!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates an object similar to the receiver."


	| s |
	s _ WriteStream on: (String new: 128).
	s nextPutAll: '#(' , name printString; space.
	s print: minAscii; space.
	s print: maxAscii; space.
	s print: maxWidth; space.
	s print: strikeLength; space.
	s print: ascent; space.
	s print: descent; space.
	s print: xOffset; space.
	s print: raster; space.
	s nextPutAll: ') '.
	aStream nextPutAll: '(StrikeFont new setFrom: ' , s contents.
	aStream nextPutAll: ' glyphs: '. (glyphs storeOn: aStream base: 10).
	aStream nextPutAll: ' xTable: '. (xTable storeOn: aStream).
	aStream nextPut: $)! !

!StrikeFont methodsFor: 'fileIn/Out'!

storeBinaryOn: stream
	" The semantics of whether StrikeFonts are
	shared or not, and unique (by name) or not,
	are hopelessly muddled.  We just store the name
	and hope for the best. "

	stream storeRecordOfClass: self class.
	stream nextPut: name.! !

!StrikeFont methodsFor: 'private: private'!

ascent: anInteger
	"Set the font's maximum extent of characters above the baseline."

	ascent _ anInteger.!

characterForm: character 
	"Answer a Form copied out of the glyphs for this character."
	
	^self characterFormAt: character!

glyphs: aForm
	"Set the Form containing the bits representing the characters of the receiver."

	glyphs _ aForm.!

scrunch
	"Run through glyphs, taking one bit of white space out,
	and update xTable accordingly."

	| x aChar form | 
	x _ (self widthOf: (Character value: minAscii))-1.
	minAscii+1 to: maxAscii do:
		[:ascii |  aChar _ Character value: ascii.
		form _ self characterFormAt: aChar.
		form displayOn: glyphs at: x@0.
		xTable at: ascii+1 put: x.
		x _ x + form width-1].
	xTable at: maxAscii+2 put: x!

setFrom: anArray glyphs: someGlyphs xTable: aXtable
	"Initialize the instance variables."

	name 			_ anArray at: 1.
	minAscii			_ anArray at: 2.
	maxAscii		_ anArray at: 3.
	maxWidth		_ anArray at: 4.
	strikeLength	_ anArray at: 5.
	ascent			_ anArray at: 6.
	descent			_ anArray at: 7.
	xOffset			_ anArray at: 8.
	raster			_ anArray at: 9.
	superscript		_ ascent - descent // 3.	
	subscript		_ descent - ascent // 3.	
	emphasis		_ 0.
	glyphs			_ someGlyphs.
	xTable 			_ aXtable.

	"This has to do with scanning characters, not with the font"
	stopConditions _ Array new: 258.
	stopConditions atAllPut: nil.
	1 to: (minAscii - 1) do:
		[:index | stopConditions at: index put: #characterNotInFont].
	(maxAscii + 3) to: stopConditions size do:
		[:index | stopConditions at: index put: #characterNotInFont].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StrikeFont class
	instanceVariableNames: ''!


!StrikeFont class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag

	| fontName obj |
	fontName _ stream next.
	" Try finding the font in a named
	TextStyle before enumerating all instances. "
	obj _ TextStyle findFont: fontName.
	obj isNil
		ifTrue:
			[obj _ self allInstances 
				detect: [:f | f name = fontName]
				ifNone: [self error: 'font ' , fontName , ' not found']].
	stream register: obj id: tag.
	^obj! !

!StrikeFont class methodsFor: 'examples'!

sample
	"Displays a line of text on the display screen wherever you click the mouse."
	"StrikeFont sample."

	Sensor waitClickButton.
	(TextStyle default fontAt: 1)
		displayLine: 'A line of text.'
		at: Sensor cursorPoint.! !