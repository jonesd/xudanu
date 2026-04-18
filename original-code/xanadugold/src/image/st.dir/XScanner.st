'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:08 pm'!

BitBlt subclass: #XScanner
	instanceVariableNames: 'lastIndex xTable stopConditions text textStyle leftMargin rightMargin font line runStopIndex spaceCount spaceWidth outputMedium '
	classVariableNames: 'CachedForm CachedScanner '
	poolDictionaries: 'TextConstants '
	category: 'Compositors-Smalltalk'!


!XScanner methodsFor: 'displaying'!

compose: string {MuWordArray} from: startIndex to: stopIndex attributes: atts compLimit: lim
	"This is the text display primitive."

	font _ atts font.
	xTable _ font xTable.
	destX _ 0.
	^self scanCharactersFrom: startIndex + 1
		to: stopIndex
		in: string gutsOf
		rightX: lim
		stopConditions: (stopConditions _ self stopConditions)
		displaying: false!

display: string from: startIndex to: stopIndex attributes: atts at: displayPos 
	"This is the text display primitive. display offset by one to
	 make up for 0 based addressing.  Don't increment stopIndex,
	 so it's a closed-open interval."

	font _ atts font.
	sourceForm _ font glyphs.
	height _ sourceForm height.
	xTable _ font xTable.
	sourceY _ 0.
	destX _ displayPos x.
	destY _ displayPos y.
	halftoneForm _ Form black.
	combinationRule _ 
		atts selected 
			ifTrue: [12] 
			ifFalse: [Form over].
	^self scanCharactersFrom: startIndex+1 
		to: stopIndex
		in: string gutsOf
		rightX: 100000
		stopConditions: (stopConditions _ self stopConditions)
		displaying: true.
	"Sensor ctrlDown ifTrue: [Transcript show: result; space]."
	"fake selection since the scanner doesn't do it."
	"combinationRule = 12 ifTrue: [width _ destX - displayPos x.
					destX _ displayPos x.
					sourceForm _ nil.
					combinationRule _ Form reverse.
					self copyBits]"!

display: string from: startIndex to: stopIndex attributes:
atts at: displayPos clipping: right
	"This is the text display primitive. display offset by
one to
	 make up for 0 based addressing.  Don't increment
stopIndex,
	 so it's a closed-open interval."

	font _ atts font.
	sourceForm _ font glyphs.
	height _ sourceForm height.
	xTable _ font xTable.
	sourceY _ 0.
	destX _ displayPos x.
	destY _ displayPos y.
	halftoneForm _ Form black.
	"Transcript show: ('display>', string gutsOf, '<'); cr;
endEntry."
	combinationRule _ 
		atts selected 
			ifTrue: [12] 
			ifFalse: [Form over].
	^self scanCharactersFrom: startIndex+1 
		to: stopIndex
		in: string gutsOf
		rightX: right
		stopConditions: (stopConditions _ self stopConditions)
		displaying: true.
	"Sensor ctrlDown ifTrue: [Transcript show: result;
space]."
	"fake selection since the scanner doesn't do it."
	"combinationRule = 12 ifTrue: [width _ destX - displayPos
x.
					destX _ displayPos x.
					sourceForm _ nil.
					combinationRule _ Form reverse.
					self copyBits]"!

odisplay: string from: startIndex to: stopIndex attributes: atts at: displayPos 
	"This is the text display primitive."

	| ascii maxAscii  |
	font _ atts font.
	sourceForm _ font glyphs.
	xTable _ font xTable.
	maxAscii _ font maxAscii.
	sourceY _ 0.
	height _ sourceForm height.
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

!XScanner methodsFor: 'access'!

lastIndex
	 "Answer the string index of last character scanned."

	^lastIndex!

lastX
	^destX!

stopConditions: anArray
	"Store the stop conditions to be the argument anArray."

	stopConditions _ anArray!

xTable: anArray 
	"Store the argument anArray to be the array of left x-coordinates of character glyphs."

	xTable _ anArray! !

!XScanner methodsFor: 'scanning'!

characterNotInFont
	"All fonts have an illegal character to be used when a character is  
	not within the font's legal range.  When characters out of ranged 
	are encountered in scanning text, then this special character 
	indicates the appropriate behavior.  The character is usually treated 
	as a unary message understood by a subclass of CharacterScanner."

	| illegalAsciiString saveIndex stopCondition | 
	saveIndex _ lastIndex.
	illegalAsciiString _ String with: (font maxAscii + 1) asCharacter.
	stopCondition _ self scanCharactersFrom: 1
						to: 1
						in: illegalAsciiString
						rightX: rightMargin
						stopConditions: self stopConditions
						displaying: true.
	lastIndex _ saveIndex + 1.
	stopCondition ~= (stopConditions at: EndOfRun)
		ifTrue:	[^self perform: stopCondition]
		ifFalse: [lastIndex > runStopIndex
					ifTrue:	[lastIndex _ lastIndex - 1.
							^self perform: (stopConditions at: EndOfRun)].
				^false]!

scanCharactersFrom: startIndex to: stopIndex in:
sourceString rightX: rightX stopConditions: stops
displaying: display
	"This is the inner loop of text display -- but consider 
	scanCharactersFrom: to:rightX: which would get the
string, 
	stopConditions and displaying from the instance. March
through 
	source String from startIndex to stopIndex. If any
character is 
	flagged with a non-nil entry in stops, then return the
corresponding 
	value. Determine width of each character from xTable. If
dextX 
	would exceed rightX, then return stops at: 258. If
displaying is true, 
	then display the character. Advance destX by the width of
the 
	character. If stopIndex has been reached, then return
stops at: 257. 
	Fail under the same conditions that the Smalltalk code
below would 
	cause an error. Optional. See Object documentation
whatIsAPrimitive."

	| ascii nextDestX |
	<primitive: 103>
	lastIndex _ startIndex.
	[lastIndex <= stopIndex]
		whileTrue: 
			[ascii _ (sourceString at: lastIndex) asciiValue.
			ascii > 255 ifTrue: [^#characterNotInFont].
			(stops at: ascii + 1) ~~ nil ifTrue: [^stops at: ascii
+ 1].
			sourceX _ xTable at: ascii + 1.
			nextDestX _ destX + (width _ (xTable at: ascii + 2) -
sourceX).
			nextDestX > rightX ifTrue: [^stops at: CrossedX].
			display ifTrue: [self copyBits].
			destX _ nextDestX.
			lastIndex _ lastIndex + 1].
	lastIndex _ stopIndex.
	^stops at: EndOfRun! !

!XScanner methodsFor: 'stop conditions'!

stopConditions
	"Set default stop conditions for the font."

	| stops |
	stops _ font stopConditions.
	"stops at: Space asInteger + 1 put: #space."
	stops at: Tab asInteger + 1 put: #tab.
	stops at: CR asInteger + 1 put: #cr.
	stops at: 10 + 1 put: #cr.
	stops at: EndOfRun put: #endOfRun.
	stops at: CrossedX put: #crossedX.

	"stops at: Ctrls asInteger + 1 put: #onePixelSpace.
	stops at: CtrlS asInteger + 1 put: #onePixelBackspace."
	stops at: Ctrlz asInteger + 1 put: #characterNotInFont.
	^stops! !

!XScanner methodsFor: 'private: private'!

initializeFromParagraph: aParagraph clippedBy: clippingRectangle
	text _ aParagraph text.
	textStyle _ aParagraph textStyle. 
	destForm _ aParagraph destinationForm.
	outputMedium _ aParagraph outputMedium.
	halftoneForm _ aParagraph mask.
	self combinationRule: aParagraph rule.
	self clipRect: clippingRectangle.
	sourceY _ 0.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XScanner class
	instanceVariableNames: ''!


!XScanner class methodsFor: 'instance creation'!

on: form 
	form == CachedForm ifTrue: [^CachedScanner].
	CachedForm _ form.
	^CachedScanner _ (self new) destForm: form; clipRect: form boundingBox; mask: Form gray! !

!XScanner class methodsFor: 'class initialization'!

initialize
	CachedForm _ nil.
	CachedScanner _ nil.! !

!XScanner class methodsFor: 'pseudo constructors'! !

XScanner initialize!
