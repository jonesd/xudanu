'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:59 pm'!

CharacterScanner subclass: #DisplayScanner
	instanceVariableNames: 'lineY runX '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Support'!
DisplayScanner comment:
'Instances of class DisplayScanner hold the state of CharacterScanner in addition to the following required only for displaying or printing.  They are used to scan text and display it on the screen or in a hidden form.

Instance Variables

	lineY	<Integer>  Top of line currently being displayed or scanned.  The textStyle lineGrid is added or subtracted to discover the top of the next line.  May differ from destY when fonts of differing height fall on the same line.

	runX	<Integer>  Left of first character in the current run -- allows for creating underlining or similar emphasis.

Pool Dictionary:
	TextConstants	<Dictionary>'!


!DisplayScanner methodsFor: 'scanning'!

displayLines: linesInterval in: aParagraph clippedBy: visibleRectangle
	"The central display routine.  The call on the primitive 
	(scanCharactersFrom:to:in:rightX:) will be interrupted according to 
	the StopConditions array passed to the primitive at which time the 
	code to handle the stopCondition is run and the call on the primitive 
	continued until a stopCondition returns true which means the line has 
	terminated. "

	| runLength done lineGrid lineIndex stopCondition displaying|

	self initializeFromParagraph: aParagraph clippedBy: visibleRectangle.
	rightMargin _ aParagraph rightMarginForDisplay.
	lineGrid _ textStyle lineGrid.
	"assume outputMedium Display"
	lineY _ destY _ aParagraph topAtLineIndex: linesInterval first.
	displaying _ self doesDisplaying.
	linesInterval do: 
		[:index | 
		lineIndex _ index.
		runX _ destX _ leftMargin _
			aParagraph leftMarginForDisplayForLine: lineIndex.
		line _ aParagraph lineAt: lineIndex.
		text _ aParagraph textAt: lineIndex.
		lastIndex _ line first.
		self setStopConditions.	"also sets the font"
		destY _ lineY + self fontAscentDelta.		"fontAscent delta"
		runLength _ text runLengthFor: line first.
		(runStopIndex _ lastIndex + (runLength - 1)) > line last 
			ifTrue: [runStopIndex _ line last].
		spaceCount _ 0.
		done _ false.
		[done]
			whileFalse: 
				[stopCondition _ self scanCharactersFrom: lastIndex
									to: runStopIndex
									in: text string
									rightX: rightMargin
									stopConditions: stopConditions
									displaying: displaying.
				"see setStopConditions for stopping conditions for displaying."
				done _ self perform: stopCondition].
			"Y origin upper left -- increases as moving down page."
					lineY _ lineY + lineGrid].
		^lineIndex! !

!DisplayScanner methodsFor: 'stop conditions'!

cr
	"When a carriage return is encountered, simply increment the pointer into the paragraph."

	"When displaying line stopped in endOfRun, primitive hasn't incremented
				lastIndex when cr stop occurs, hence, "

				lastIndex_ lastIndex + 1.
				^false!

crossedX
	"Text display has wrapping.  The scanner just found a character past the 
	x location of the cursor.  We know that the cursor is pointing at a character 
	or before one."

	"This condition will sometimes be reached 'legally' during printing, 
	when, for instance the space that caused the line to wrap actually 
	extends over the right  boundary.  This character is allowed to print, 
	even though it is technically outside or straddling the 
	clippingRectangle since it is in the normal case not visible and is in 
	any case appropriately clipped by the scanner."

	self checkEmphasis.
	^true!

endOfRun
	"The end of a run in the display case either means that there is 
	actually a change in the style (run code) to be associated with the 
	string or the end of this line has been reached.  A check for any 
	emphasis (underlining, for example) that may run the length of the 
	run is done here before returning to displayLines: to do the next line"

	| runLength |
	lastIndex = line last
		ifTrue: [ "just displaying and at end of line"
				self checkEmphasis.
				^true].
	self checkEmphasis.
	runLength _ text runLengthFor: (lastIndex _ lastIndex + 1).
	self setStopConditions.
	runX _ destX.
	destY _ lineY + self fontAscentDelta.		"fontAscent delta"
	(runStopIndex _ lastIndex + (runLength - 1)) > line last 
		ifTrue: [runStopIndex _ line last].

	^false!

onePixelBackspace
	"Increment destX by 1"

	destX _ (destX - 1) max: runX.
	lastIndex _ lastIndex + 1.
	^false!

onePixelSpace
	"Increment destX by 1"

	destX _ destX + 1.
	lastIndex _ lastIndex + 1.
	^false!

paddedSpace
	"Each space is a stop condition when the alignment = justified.  
	Padding must be added to the base width of the space according to 
	which space in the line this space is and according to the amount of 
	space that remained at the end of the line when it was composed."

	spaceCount _ spaceCount + 1.
	destX _ destX + spaceWidth + (line justifiedPadFor: spaceCount).
	lastIndex _ lastIndex + 1.
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

!DisplayScanner methodsFor: 'private: private'!

checkEmphasis

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

doesDisplaying
	^true!

fontAscentDelta

	(font emphasis bitAnd: Subscripted + Superscripted) = 0
		ifTrue: [^ textStyle baseline - font ascent].
	((font emphasis bitAt: SubscriptedBit) = 1)
		ifTrue:	[^textStyle baseline - 2].
	"Its Superscripted then"
	^textStyle baseline - (textStyle fontAt: (text emphasisAt: ((lastIndex - 1) max: 1))) ascent!

initializeFromParagraph: aParagraph clippedBy: clippingRectangle

	super initializeFromParagraph: aParagraph clippedBy: clippingRectangle! !