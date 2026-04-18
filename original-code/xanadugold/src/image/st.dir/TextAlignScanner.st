'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:00 pm'!

TextDisplayScanner subclass: #TextAlignScanner
	instanceVariableNames: 'compositionScanner '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Support'!
TextAlignScanner comment:
'Class TextAlignScanner supports the text alignment functions (justification, centering and right flush). Its instances hold a CompositionScanner to get a TextLineInterval which contains some paddingWidth.

Instance Variables:

	compositionScanner <CompositionScanner> A scanner which measures a line and determines where the line breaks and space padding should occur.'!


!TextAlignScanner methodsFor: 'initialize-release'!

initializeFromCompositor: aCompositor stop: newStop

	super initializeFromCompositor: aCompositor stop: newStop.
	compositionScanner == nil 
		ifTrue: [compositionScanner _ CompositionScanner new]! !

!TextAlignScanner methodsFor: 'stop conditions'!

cr

	lastIndex_ lastIndex + 1.
	^false!

crossedX

	self checkEmphasis.
	^true!

endOfRun

	| runLength |
	lastIndex = line last
		ifTrue: [ "just displaying and at end of line"
				self checkEmphasis. ^true].
	self checkEmphasis.
				runLength _ text runLengthFor: (lastIndex _ lastIndex + 1).
				self setStopConditions.
				runX _ destX.
				destY _ lineY + self fontAscentDelta.		"fontAscent delta"
	(runStopIndex _ lastIndex + (runLength - 1)) > line last 
		ifTrue: [runStopIndex _ line last].

	^false!

paddedSpace
	"Each space is a stop condition when the alignment = justified.  Padding must be added to the base width of the space according to which space in the line this space is and according to the amount of space that remained at the end of the line when it was composed."

	spaceCount _ spaceCount + 1.
	destX _ destX + spaceWidth + (line justifiedPadFor: spaceCount).
	lastIndex _ (spaceIndex _ lastIndex) + 1.
	^false!

setStopConditions
	"Set the font and the stop conditions for the current run."

	font _ textStyle fontAt: (text emphasisAt: lastIndex).
	super setStopConditions.
	stopConditions 
		at: Space asInteger + 1 
		put: (textStyle alignment = Justified
				ifTrue: [#paddedSpace]
				ifFalse: [nil])!

tab
	"This attempts to handle leading and internal tabs in a 
	justified line.  Leading tabs are considered legal and should be 
	reflected on the display gracefully."

	| index|
	textStyle alignment = Justified
		ifTrue: [index _ line first.
				[index <= lastIndex] whileTrue:
					[(text at: index) == Space
						ifTrue: [destX _ destX +
										(textStyle tabWidth -
										(line justifiedTabDeltaFor: spaceCount))
									max: destX.
								lastIndex _ lastIndex + 1.
								^false].
					index _ index + 1]].
	destX _ textStyle
				nextTabXFrom: destX
				leftMargin: leftMargin
				rightMargin: rightMargin.
	lastIndex _ lastIndex + 1.
	^false! !

!TextAlignScanner methodsFor: 'scanning'!

displayOneLine: lineIndex start: startIndex in: aCompositor
	"Display a line whose start caracter index and line index are startIndex lineIndex, and return the character index of next line start."

	| runLength |
	compositionScanner in: aCompositor.
	line _ compositionScanner composeLine: lineIndex fromCharacterIndex: startIndex inParagraph: aCompositor.
	lastIndex _ line first.
	self setStopConditions.
	offsetX _ aCompositor compositionRectangle left.
	offsetY _ aCompositor topAtLineIndex: lineIndex.
	rightMargin _ (aCompositor rightMarginForDisplay) - offsetX.
	runX _ spaceX _ destX _ leftMargin _ 
		(aCompositor leftMarginForDisplayForLine: lineIndex) - offsetX.
	lineY _ destY _ 0.
	destY _ lineY + self fontAscentDelta.
	runLength _ text runLengthFor: line first.
	(runStopIndex _ lastIndex + (runLength - 1)) > line last 
		ifTrue: [runStopIndex _ line last].
	spaceCount _ 0.
	displaying _ true.
	self clearLineFormAt: 0@0.
	[self perform: 
		(self scanCharactersFrom: lastIndex
			to: runStopIndex
			in: text string
			rightX: rightMargin
			stopConditions: stopConditions
			displaying: displaying)] whileFalse: [].
	self copyLineFormOnDisplayMediumAt: offsetX @ offsetY.
	^line last + 1!

nextLineStart: startIndex line: lineIndex in: aCompositor
	"Return the character index of start of the next line."

	compositionScanner in: aCompositor.
	line _ compositionScanner composeLine: lineIndex fromCharacterIndex: startIndex inParagraph: aCompositor.
	^line last + 1! !