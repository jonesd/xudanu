'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:03 pm'!

CompositionScanner subclass: #TextDisplayScanner
	instanceVariableNames: 'lineY runX displaying stop stopBox offsetX offsetY bitblt displayMedium '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Support'!
TextDisplayScanner comment:
'Instances of class TextDisplayScanner behave like both a CompositionScanner and a DisplayScanner. The class scans and displays text at the same time. Scanning is done for each line one-at-a-time. After scanning, it returns a CharacterBlock which contains the stopBox (stopping) character index and location. If scanning doesn''t pass the stopping index, return nil.  The location is given as (topLeft position extent: 0 @ lineGrid). There is no justification function. This can be implemented in a subclass.
	 	
Instance Variables:

	lineY	<Integer>  Top of line currently being displayed or scanned.

	runX	<Integer>  Left of the first character in the current run--allows for underlining or similar emphasis.

	displaying	<Boolean>	A switch for displaying or measuring.

	stop <Integer>	 Index of new stopping character - 1.

	stopBox <CharacterBlock> 	A CharacterBlock of the new stopping character.

	offsetX <Integer>	X position of compositionRectangle origin on the DisplayScreen.

	offsetY <Integer>	Y position of compositionRectangle origin on the DisplayScreen.

	bitblt	<BitBlt>		Used to copy lineForm on the DisplayScreen or clear the lineForm.

	displayMedium <Form> a destination form that lineForm is copied on.
'!


!TextDisplayScanner methodsFor: 'initialize-release'!

initializeFromCompositor: aCompositor stop: newStop
	"Set the instance variables of the receiver so that the text style comes from aCompositor."

	self setTextStyleFrom: aCompositor.
	stop _ newStop - 1.
	stopBox _ nil! !

!TextDisplayScanner methodsFor: 'accessing'!

stopBox
	"Answer the stopping CharacterBlock that specifies the location of the cursor."

	^stopBox! !

!TextDisplayScanner methodsFor: 'stop conditions'!

cr
	"Answer true.  Set up values for the stopping CharacterBlock that specify the location of the cursor."

	displaying ifTrue: 
		[self checkEmphasis.
		lastIndex = stop
			ifTrue: [stopBox _ CharacterBlock
						stringIndex: stop + 1
						character: nil
						topLeft: (leftMargin + offsetX) @(lineY + textStyle lineGrid + offsetY)
						extent: 0 @ textStyle lineGrid]].
	lastIndex _ lastIndex + 1.
	spaceX _ destX.
	^true!

crossedX
	"Answer true. Wrap around from last space to end of line."

	displaying ifTrue: [self checkEmphasis].
	spaceCount > 0
		ifTrue:	
			[lastIndex _ spaceIndex + 1.
			destX _ spaceX.
			displaying ifTrue: 
				[self clearLineFormAt: destX@lineY.
				(lastIndex - 1) = stop
					ifTrue: [stopBox _ CharacterBlock
								stringIndex: lastIndex
								character: nil
								topLeft: (leftMargin + offsetX) @(lineY + textStyle lineGrid + offsetY)
								extent: 0 @ textStyle lineGrid]]].
	^true!

endOfRun
	"Answer true if scanning has reached the end of the paragraph.  Otherwise set stop conditions (to install a new font) or set up values for the CharacterBlock."

	| runLength |
	displaying ifTrue: [self checkEmphasis].
	lastIndex = text size
		ifTrue: 
		 	[lastIndex = stop 
				ifTrue:
				[stopBox _ CharacterBlock
					stringIndex: stop + 1
					character: nil
					topLeft: (destX + offsetX)@(lineY + offsetY)
					extent: 0 @ textStyle lineGrid].
			lastIndex _ lastIndex + 1.
			spaceX _ destX.
			^true]
		ifFalse: 
		 	[lastIndex < stop
				ifTrue: [runLength _ (text runLengthFor: (lastIndex _ lastIndex + 1)).
						runStopIndex _ lastIndex + (runLength - 1).
						self setStopConditions.
						destY _ lineY + self fontAscentDelta.
						runX _ destX.
						runStopIndex > stop ifTrue: [runStopIndex _ stop].
						^false].
			lastIndex = stop
				ifTrue: [stopBox _ CharacterBlock
							stringIndex: stop + 1
							character: nil
							topLeft: (destX + offsetX)@(lineY + offsetY)
							extent: 0 @ textStyle lineGrid.
						runLength _ (text runLengthFor: (lastIndex _ lastIndex + 1)).
						runStopIndex _ lastIndex + (runLength - 1).
						self setStopConditions.
						destY _ lineY + self fontAscentDelta.
						runX _ destX.
						^false].
			(displaying not or: [lastIndex > stop])
				ifTrue: [runLength _ (text runLengthFor: (lastIndex _ lastIndex + 1)).
						runStopIndex _ lastIndex + (runLength - 1).
						self setStopConditions.
						destY _ lineY + self fontAscentDelta.
						runX _ destX.
						^false]].! !

!TextDisplayScanner methodsFor: 'scanning'!

displayOneLine: lineIndex start: startIndex in: aCompositor
	"Display a line whose start caracter index and line index are startIndex, lineIndex and return the character index of start of the next line."

	| runLength |
	lastIndex _ startIndex.
	self setStopConditions.
	offsetX _ aCompositor compositionRectangle left.
	offsetY _ aCompositor topAtLineIndex: lineIndex.
	rightMargin _ aCompositor compositionRectangle width.
	runX _ spaceX _ destX _ leftMargin _ 0.
	lineY _ destY _ 0.
	destY _ lineY + self fontAscentDelta.
	runLength _ text runLengthFor: lastIndex.
	runStopIndex _ lastIndex + (runLength - 1).
	(lastIndex <= (stop + 1) and: [runStopIndex > stop]) 
		ifTrue: [runStopIndex _ stop].
	displaying _ true.
	spaceCount _ 0.
	self clearLineFormAt: 0@0.
	[self perform: 
		(self scanCharactersFrom: lastIndex
			to: runStopIndex
			in: text string
			rightX: rightMargin
			stopConditions: stopConditions
			displaying: displaying)] whileFalse: [].
	self copyLineFormOnDisplayMediumAt: offsetX @ offsetY.
	^lastIndex!

nextLineStart: startIndex line: lineIndex in: aCompositor
	"Answer the character index of start of the next line."

	| runLength |
	lastIndex _ startIndex.
	self setStopConditions.
	rightMargin _ aCompositor compositionRectangle width.
	runX _ spaceX _ destX _ leftMargin _ 0.
	lineY _ destY _ offsetX _ offsetY _ 0. "These are not used"
	runLength _ text runLengthFor: lastIndex.
	runStopIndex _ lastIndex + (runLength - 1).
	spaceCount _ 0.
	displaying _ false.
	[self perform: 
		(self scanCharactersFrom: lastIndex
			to: runStopIndex
			in: text string
			rightX: rightMargin
			stopConditions: stopConditions
			displaying: displaying)] whileFalse: [].
	^lastIndex!

scanLine: startIndex direction: rightOrLeft
	"Answer the character index of the rightOrLeft edge of the line."

	rightOrLeft == #left ifTrue: [^self scanLineLeft: startIndex].
	rightOrLeft == #right ifTrue: [^self scanLineRight: startIndex].
	self error: 'argument is not #right or #left'!

scanLineLeft: startIndex
	"Answer the character index of the left edge of the line."

	| sourceString stopIndex c |
	lastIndex _ startIndex - 1.
	sourceString _ text string.
	stopIndex _ 1.	
	[lastIndex >= stopIndex]
		whileTrue: 
			[c _ sourceString at: lastIndex.
			c == $
 ifTrue: [^lastIndex + 1].
			lastIndex _ lastIndex - 1].
	^lastIndex + 1!

scanLineRight: startIndex
	"Answer the character index of the right edge of the line."

	| sourceString stopIndex c | 
	lastIndex _ startIndex.
	sourceString _ text string.
	stopIndex _ sourceString size.	
	[lastIndex <= stopIndex]
		whileTrue: 
			[c _ sourceString at: lastIndex.
			c == $
 ifTrue: [^lastIndex].
			lastIndex _ lastIndex + 1].
	^lastIndex! !

!TextDisplayScanner methodsFor: 'private: private'!

checkEmphasis
	"Check any emphasis (underlining, italic, bold face) and synthesize font."

	| emphasis sourceRect italicY lineSegment displayDestX displayRunX |	
	(emphasis _ (font emphasis bitAnd: 7)) = 0
		ifTrue: [^self].
	displayDestX _ destX.
					displayRunX _ runX.
	emphasis >= 8	"overstrike"
		ifTrue:	[destForm
							fill: ((displayRunX @ (lineY + textStyle baseline-3))
							extent: (displayDestX - displayRunX) @ 1)
							rule: combinationRule mask: halftoneForm.
				emphasis _ emphasis - 8].
	emphasis >= 4	"underlined"
		ifTrue:	[lineSegment _
								((displayRunX @ (lineY + textStyle baseline + 1))
									extent: (displayDestX - displayRunX) @ 1).
							lineSegment bottom <= (clipY+clipHeight) ifTrue:
								[destForm fill: lineSegment
									rule: combinationRule
									mask: halftoneForm].
					emphasis _ emphasis - 4].
	emphasis >= 2	"italic"
		ifTrue:	[italicY _ lineY + textStyle lineGrid - 4.
							[italicY > lineY]
							whileTrue:
							[sourceRect _
								displayRunX @ lineY
									extent: (displayDestX - displayRunX + 2)
												@ (italicY - lineY).
							destForm
							copyBits: sourceRect
							from: destForm
							at: (displayRunX+1) @ lineY
							clippingBox: sourceRect
							rule: Form over mask: nil.
							italicY _ italicY - 4].
					emphasis _ emphasis - 2].
	emphasis >= 1	"bold face"
		ifTrue:	[sourceRect _ displayRunX @ lineY
								extent: (displayDestX - displayRunX + 1)
											@ textStyle lineGrid.
							destForm
							copyBits: sourceRect
							from: destForm
							at: (displayRunX+1) @ lineY
							clippingBox: sourceRect rule: Form under mask: nil]!

clearLineFormAt: aPoint

	(bitblt 
		setDestForm: destForm
		sourceForm: nil
		halftoneForm: Form white
		combinationRule: Form over
		destOrigin: aPoint
		sourceOrigin: destForm boundingBox origin
		extent: destForm boundingBox extent
		clipRect: destForm boundingBox) copyBits.!

copyLineFormOnDisplayMediumAt: aPoint

	bitblt 
		destForm: displayMedium;
		sourceForm: destForm;
		mask: nil;
		destOrigin: aPoint;
		clipWidth: displayMedium width;
		clipHeight: displayMedium height.
	bitblt copyBits.!

doesDisplaying

	^displaying!

fontAscentDelta

	(font emphasis bitAnd: Subscripted + Superscripted) = 0
		ifTrue: [^ textStyle baseline - font ascent].
	((font emphasis bitAt: SubscriptedBit) = 1)
		ifTrue:	[^textStyle baseline - 2].
	"Its Superscripted then"
	^textStyle baseline - (textStyle fontAt: (text emphasisAt: ((lastIndex - 1) max: 1))) ascent!

setDisplayMediumFrom: aCompositor

	destForm _ Form extent: aCompositor compositionRectangle width @ aCompositor textStyle lineGrid.
	halftoneForm _ aCompositor mask.
	outputMedium _ aCompositor outputMedium.
	displayMedium _ aCompositor destinationForm.
	self combinationRule: aCompositor rule.
	self clipRect: (0@0 extent: aCompositor compositionRectangle width @ aCompositor textStyle lineGrid).
	bitblt _ BitBlt new.
	bitblt
		sourceOrigin: 0@0;
		width: destForm width; height: destForm height;	
		combinationRule: Form over.
	bitblt clipX: 0; clipY: 0!

setTextStyleFrom: aCompositor

	text _ aCompositor text.
	textStyle _ aCompositor textStyle.
	sourceY _ 0! !