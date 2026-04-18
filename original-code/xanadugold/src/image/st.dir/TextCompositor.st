'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:01 pm'!

Object subclass: #TextCompositor
	instanceVariableNames: 'text textStyle offset form clippingRectangle compositionRectangle destinationForm rule mask marginTabsLevel firstIndent restIndent rightIndent outputMedium lines lastLine nextChar textSize lineLength scanner charsPerLine '
	classVariableNames: 'DefaultCompositionRectangle '
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Support'!
TextCompositor comment:
'Instances of class TextCompositor compose text and display it within compositionRectangle. The compositionRectangle is an inset box of clippingRectangle. The class uses lines, nextChar, lineLength, and scanner for composition.

Composition algorithm:

	1. update lines 
		before scanning text, the delta change due to insertion or deletion is added to each entry after the scanning start line. 
		
	2. composition and display 
		scanning is done by giving the scanner a character index where to start scanning.  The scanner returns a character index of next line''s start. Then it become a character index where to start next line scanning. This scanning corresponds to one line. Displaying is done with scanning at the same time. 
			
	3. compare next index with entry in lines
		During scanning, this compares a returned index with an entry in lines.
		Scanning is continued until each entry in lines is correct. After each line scan, the returned index is put into entry in line as the new value. If the returned index matches the entry in lines, then scanning stops.  If the entry is nil, then put the right index into the entry in lines and display the line.

	4. move down (text insertion)
		before the display scanning of each line, the start index of scanning and start index of next line is less than the entry in lines, move down all lines that follow the scanning line.
	
	5. move up (text deletion)
		before the display scanning of each line, try to find a entry which can be moved up, that is, if the next index which scanning starts from is greater than the current entry in lines, try to find the next matched entry until the index is less than the entry in lines. If any matched entry is found, then move the lines which are below the matched start line up to the index line.  Then the scanning line is set to be next to the moved lines.
		
	6. end of composition
		Composition can be stopped if the next index matches the next entry in lines,
		or by scanning up to end of text, or lastLine of compositionRectangle.
		Composition returns a CharacterBlock.
				
	7. exception
	  	 In the following case, return a characterBlock imediately and no composition will happen. 
	  	 Both starting index and stopping index are:	   
	   		below bottom
	   		above top
	  	 or 	 	    
	  		text size = 0.

Instance Variables:
	text	<Text>
	textStyle	<TextStyle>
	offset	<Point>
	form	<Form>

	clippingRectangle	<Rectangle>  A Rectangle in CurrentDisplay coordinates. Its intersection with the compositionRectangle in turn intersected with the destinationForm is the area in which characters are constrained to be displayed.

	compositionRectangle	<Rectangle>  A display region rectangle that is invariant as long as the user does not reframe or move the view. The compositionRectangle is inset from the clippingRectangle.

	destinationForm		<Form>  The Form into which the characters are scanned.  Typically CurrentDisplay.

	rule		<Integer>  The rule according to which character display behaves. 

	mask	<Form>  The form with which each character is combined by the scanner before applying the rule for display.

	marginTabsLevel	<Integer>  The margin tabs give the left and right indent values for a specified marginTabsLevel.  The marginTabsLevel is sometimes referred to as the nesting level and is an index into the marginTabsArray of the stringStyle.

	firstIndent	<Integer>  Amount to inset from the left margin for the first line of a paragraph. Initialized in the textStyle.

	restIndent	<Integer>  Amount to inset from the left margin for all but the first line of a paragraph. Initialized in the textStyle.

	rightIndent	<Integer>  Amount to inset from the right margin for all the lines of the paragraph. Initialized in the textStyle.

	outputMedium	<Symbol>	Either #Display or #DisplayPrinterWidths.  Needed by CompositionScanner for determining the nature of the font to be used for character widths.  For the DisplayScanner there are several places where distinguishing between displaying and printing is required.  Also used for some margin and grid computations.

	lines	<Array>  Keeps the first character index of each line of the compositionRectangle. If any character is not displayed, that entry in the array lines is nil. The last entry of lines which is not nil is nextChar. 

	lastLine		<Integer>  The index of the last validly composed line in the lines array.

	nextChar	<Integer>	The last characterIndex displayed within the compositionRectangle plus one. When end of text is within the compositionRectangle, nextChar = text size + 1. When end of text is beyond the compositionRectangle, nextChar < text size + 1.

	textSize	<Integer>

	lineLength	<Integer>	The size of lines which can be displayed within the compositionRectangle.

	scanner		<TextDisplayScanner>	Object to scan and display one line.
	
	charsPerLine <Integer> A default value used for scrolling.

Pool Dictionary:
	TextConstants	<Dictionary>

'!


!TextCompositor methodsFor: 'initialize-release'!

resetState
	"Establish the initial conditions"

	lines _ Array new: lineLength + 1.
	lines at: 1 put: 1.
	nextChar _ 1.
	lastLine _ 0.
	textSize _ 0.! !

!TextCompositor methodsFor: 'accessing'!

baseline
	"Answer the baseline of the receiver's text style."

	^textStyle baseline!

clippingRectangle 
	"Answer the rectangle, defined in absolute coordinates, whose intersection with the
	destinationForm is the area in which the characters are constrained to display."

	^clippingRectangle!

clippingRectangle: aRectangle 
	"Set the rectangle, defined in absolute coordinates, whose intersection with the
	destinationForm is the area in which the characters are constrained to display."

	clippingRectangle _ aRectangle!

compositionRectangle
	"Answer the rectangle whose width is the dimension, modified by 
	indents and tabsLevels, against which line wraparound is measured."

	^compositionRectangle!

compositionRectangle: compRectangle
	"Set the receiver's composition rectangle to be the argument compRectangle."

	compositionRectangle _ compRectangle!

destinationForm 
	 "Answer the Form into which the characters are scanned."

	^destinationForm!

destinationForm: aFormOrRectangle 
	"Set the Form or Rectangle into which the characters are scanned. "

	destinationForm _ aFormOrRectangle!

form
	"Answer the form or caching the bit representation of the receiver's composed text."

	^form!

height 
	"Answer the height of the composition rectangle."

	^compositionRectangle height!

lastLine
	"Answer the number of lines in the displayed text."

	^lastLine!

lineGrid
	"Answer the lineGrid of my TextStyle."

	^textStyle lineGrid!

lineLength
	"Answer the number of lines which can be displayed in the view."

	^lineLength!

lines
	"Answer the table which contains line start character indices."

	^lines!

mask 
	"Answer the form with which each character is combined by the scanner
	before applying the rule for display."

	^mask!

mask: maskForm 
	"Set the argument, maskForm, to be the form with which each character is
	combined by the scanner before applying the rule for display."

	mask _ maskForm.!

numberOfLines 
	"Answer the number of lines in the displayed text."

	^lastLine!

offset 
	"Answer the offset of the receiver."

	^offset!

offset: aPoint 
	"Set the offset to be the argument aPoint."

	offset _ aPoint!

outputMedium
	"Answer the outputMedium for the receiver."
	
	^outputMedium!

outputMedium: aSymbol
	"Set the argument to be the output medium for the receiver."

	outputMedium _ aSymbol.
	textStyle outputMedium: aSymbol!

replaceFrom: start to: stop with: aText
	"Replace the receiver's text starting at position start, stopping at stop, by the characters in aText."

	text replaceFrom: start to: stop with: aText.
	^self update: start to: stop withSize: aText size!

rule 
	"Answer the rule according to which character display behaves. For
	example, rule may equal over, under, reverse."

	^rule!

rule: ruleInteger 
	"Set the rule according to which character display behaves."

	rule _ ruleInteger.!

setCompositionRectangle: compRectangle 
	"Set the rectangle whose width is the dimension, modified by 
	indents and tabsLevels, against which line wraparound is measured."

	compositionRectangle _ compRectangle.!

string
	"Answer the string of the characters displayed by the receiver."

	^text string!

text 
	"Answer the text displayed by the receiver."

	^text!

text: aText
	"Set the text displayed by the receiver."

	text _ aText.
	scanner setTextStyleFrom: self!

textSize
	"Answer the receiver's text size."

	^textSize!

textStyle 
	"Answer the style by which the receiver displays its text."

	^textStyle!

textStyle: aTextStyle 
	"Set the style by which the receiver should display its text."

	textStyle _ aTextStyle.
	firstIndent _ textStyle firstIndent.
	restIndent _ textStyle restIndent.
	rightIndent _ textStyle rightIndent.
	form _ nil.
	self newLines.
	scanner setTextStyleFrom: self.
	self changed! !

!TextCompositor methodsFor: 'displaying'!

display
	"Show the text of the receiver on the display screen."

	self displayOn: Display!

displayAt: aPoint
	"Display the receiver located at aPoint within its clipping rectangle
	and according to the receiver's rule and mask."

	"Because Paragraphs cache so much information, computation is avoided and 
	displayAt: 0@0 is not appropriate here"

	self displayOn: destinationForm
		at: aPoint
		clippingBox: clippingRectangle
		rule: rule
		mask: mask!

displayMoveLines: topLine to: destLine
	"Move the paragraph such that line index topLine is set to line index destLine."

	| box move bottomLine firstClearLine lineIndex startIndex |
	box _ self compositionRectangle intersect: destinationForm boundingBox.
	move _ box left @ (self topAtLineIndex: topLine)
				corner: box corner.
	destinationForm
		copyBits: move
		from: destinationForm
		at: move left @ (self topAtLineIndex: destLine)
		clippingBox: box
		rule: Form over
		mask: nil.
	bottomLine _ self lineIndexOfTop: box corner y.
	topLine > destLine 
		ifTrue: "up"
			[firstClearLine _ lineLength + 1 + destLine - topLine.
			destinationForm white: 
				(box left @ (self topAtLineIndex: firstClearLine) 
								corner: self clippingRectangle corner).
			"In case that the view intersects bottom of the display screen."
			bottomLine < lineLength ifTrue: 
				[lineIndex _ bottomLine + destLine - topLine max: 1.
				destinationForm white: 
				(box left @ (self topAtLineIndex: lineIndex) 
								corner: box right @ (self topAtLineIndex: firstClearLine)).
				startIndex _ lines at: lineIndex.
				[startIndex < nextChar] whileTrue: 
					[startIndex _ 
						scanner displayOneLine: lineIndex start: startIndex in: self.
					lineIndex _ lineIndex + 1]]]
		ifFalse: "down"
			[destinationForm white: 
				(move origin corner: box right 
					@ (self topAtLineIndex: destLine))]!

displayOn: aDisplayMedium
	"Display on a new destination medium"

	self displayOn: aDisplayMedium
		at: compositionRectangle topLeft
		clippingBox: clippingRectangle
		rule: rule
		mask: mask!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Default display message when aDisplayPoint is in absolute screen 
	coordinates. "

	destinationForm _ aDisplayMedium.
	clippingRectangle _ clipRectangle.
	rule _ ruleInteger.
	mask _ aForm.
	compositionRectangle moveTo: aDisplayPoint.
	self setScanner.
	self displayLines!

displayOn: aDisplayMedium transformation: displayTransformation clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: ruleInteger mask: aForm 
	"Display the receiver where a DisplayTransformation is provided as an argument,
	rule is ruleInteger and mask is aForm.  Translate by relativePoint-alignmentPoint.
	Information to be displayed must be confined to the area that intersects with
	clipRectangle."

	self				"Assumes offset has been set!!!!!!!!!!"
	  displayOn: aDisplayMedium
	  at: (offset 
			+ (displayTransformation applyTo: relativePoint) 
			- alignmentPoint) rounded
	  clippingBox: clipRectangle
	  rule: ruleInteger
	  mask: aForm.! !

!TextCompositor methodsFor: 'display box access'!

boundingBox 
	"Answer the rectangular area that represents the boundaries of the 
	receiver's space of information."

	^offset extent: compositionRectangle extent!

computeBoundingBox
	"Answer the minimum enclosing rectangle around the composed test of the paragraph."

	^offset extent: compositionRectangle extent! !

!TextCompositor methodsFor: 'composition'!

compositionRectangle: compositionRect text: aText style: aTextStyle offset: aPoint outputMedium: aSymbol
	"Set the initial values in the TextCompositor."

	compositionRectangle _ compositionRect copy.
	text _ aText.
	textStyle _ aTextStyle.
	firstIndent _ textStyle firstIndent.
	restIndent _ textStyle restIndent.
	rightIndent _ textStyle rightIndent.
	marginTabsLevel _ 0.
	outputMedium _ aSymbol.
	rule _ DefaultRule.
	mask _ DefaultMask.
	destinationForm _ Display.
	clippingRectangle _ destinationForm boundingBox.
	offset _ aPoint.
	textSize _ text size.
	self newLines.
	self setScanner!

recomposeIn: compositionRect clippingBox: clippingRect 
	"Set the composition rectangle for the receiver so that the lines wrap
	within the rectangle, compositionRect, and the display of the text is
	clipped by the rectangle, clippingRect."

	self compositionRectangle: compositionRect copy
		text: text
		style: textStyle
		offset: offset
		outputMedium: #Display.
	self adjustCompositionRectangle.
	clippingRectangle _ clippingRect copy!

update: start to: stop withSize: size
	"Update the receiver after a replacement has occurred in the text starting at character index start, stopping at character index stop with a text whose size is size. The main composition algorithm is in this method. See the class comment."

	| delta newStop i j iNext lineStart nextStart nc |
	textSize _ text size.
	textSize = 0 ifTrue: 
		[self clearRestLinesFrom: 1.
		lines at: 1 put: 1.
		nextChar _ 1.
		lastLine _ 0.
		^self characterBlockForIndex: 1].
	i _ self startingLineAfterReplacingAt: start.
	delta _ size - (stop - start + 1).
	delta = 0 ifFalse: [self updateLinesBelow: i at: start delta: delta].
	newStop _ start + size.
	(start > nextChar and: [nextChar < (textSize + 1)]) "below bottom"
		ifTrue: [^self characterBlockForIndex: newStop].
	newStop < (lines at: 1) ifTrue: [^nil]. "above top"
	scanner initializeFromCompositor: self stop: newStop.
	iNext _ lines at: i.
	[i <= lineLength] whileTrue:
		[((lineStart  _ lines at: i) == nil 
				or: [lineStart = nextChar "extra line scanning" 
					or: [lineStart = iNext "only first line scanning"]])
			ifFalse: 
				[iNext < lineStart
					ifTrue:
						[j _ i.
						nextStart _ iNext.
						[j < lineLength 
								and: [(nextStart _ scanner nextLineStart: nextStart line: j in: self) <= lineStart]]
							whileTrue: [j _ j + 1].
						j > i ifTrue: "move down"
								[self moveLines: i to: j.
								(nc _ lines at: lineLength + 1) ~~ nil 
									ifTrue: [nextChar _ nc]]]
					ifFalse:
						[iNext >= newStop 
							ifTrue: "can be moved up, only after scanning through the stopIndex because of getting the stopBox."
								[j _ i.
						 		[(j _ j +1) <= lineLength and: [j > i
									and: [(nextStart _ lines at: j) ~~ nil 
										and: [iNext >= nextStart]]]] 
									whileTrue: 
										[iNext = nextStart 
											ifTrue: "move up"
												[self moveLines: j to: i.
												nextChar = (textSize +1)
													ifTrue: "end of text"
														[self updateLastLine.
														^scanner stopBox].
												iNext _ nextChar.
												i _ lineLength +1 - (j - i) "skip moved lines"]
										]]]].
		lines at: i put: iNext.
		iNext _ scanner displayOneLine: i start: iNext in: self.
		iNext = (textSize + 1) 
			ifTrue: "end of text"
				[self clearRestLinesFrom: i + 1.
				nextChar _ iNext.
				(lines at: i) = iNext ifFalse: [lines at: i + 1 put: iNext].
				self updateLastLine.
				lastLine = 0 ifTrue: [self setTopPosition: ((lines at: 1) - 1 max: 1)].
				^scanner stopBox].
		i _ i + 1.
		(i < lineLength 
				and: [(lines at: i) = iNext and: [(lines at: i + 1) ~= iNext 
						and: [newStop <= iNext]]])
			ifTrue: "encountered the right lines entry, no more scanning"
				[self updateLastLine.
				^scanner stopBox]
		].
	"scanned the whole lines"
	nextChar _ iNext. 
	lines at: i put: iNext.
	self updateLastLine.
	iNext < newStop 
		ifTrue: "the stop position is below bottom" 
			[^self characterBlockForIndex: newStop].
	^scanner stopBox! !

!TextCompositor methodsFor: 'character location'!

characterBlockAtPoint: aPoint 
	"Answer a CharacterBlock for characters in the text at point aPoint.  
	It is assumed that aPoint has been transformed into coordinates appropriate to 
	the receiver's destinationForm rectangle and the compositionRectangle."

	^TextCharacterBlockScanner new characterBlockAtPoint: aPoint in: self!

characterBlockForIndex: targetIndex 
	"Answer a CharacterBlock for character in the text at targetIndex.  The 
	coordinates in the CharacterBlock will be appropriate to 
	the receiver's destinationForm rectangle and the compositionRectangle."

	^TextCharacterBlockScanner new characterBlockForIndex: targetIndex in: self! !

!TextCompositor methodsFor: 'selecting'!

crIsLast
	"Answer true if the last character in the displayed text is cr."

	(textSize > 0 and: [nextChar > 1 and: [(text at: nextChar - 1) = $
]]) ifTrue: [^true].
	^false!

displayCaretAt: aPoint 
	"Display CaretForm located at aPoint with default settings for rule and halftone."

	Cursor caret
		displayOn: destinationForm
		at: aPoint
		clippingBox: clippingRectangle
		rule: Form reverse
		mask: Form black!

displayCaretForBlock: aCharacterBlock
	"Show caret at proper place for aCharacterBlock"

	self displayCaretAt: (aCharacterBlock topLeft + (0@textStyle baseline))!

dyForPoint: pt
	"See if pt is above or below clippingRectangle, answer the scroll amount."

	| dy dc |
	self updateCharsPerLine.
	((dy _ pt y - clippingRectangle top) < 0
				 and: [(dc _ 1 - (lines at: 1)) < 0])
		ifTrue: 
			[dy _ dy // textStyle lineGrid * charsPerLine.
			^(dy max: dc) - charsPerLine].
	((dy _ pt y - clippingRectangle bottom) > 0
	 			and: [(dc _ textSize + 1 - nextChar) > 0])
		ifTrue: 
			[dy _ dy // textStyle lineGrid * charsPerLine.
			^(dy min: dc) + charsPerLine].
	^0!

mouseSelect: previousStartBlock to: previousStopBlock
	"Answer with an Array of two CharacterBlocks that represent the text selection that the user makes. Allow for scrolling to extend selections."

	| pivotBlock startBlock stopBlock showingCaret dy pt okToScroll scrollDelay word |
	startBlock _ stopBlock _ pivotBlock _ self characterBlockAtPoint: Sensor cursorPoint.
	self displayCaretForBlock: pivotBlock.
	showingCaret _ true.
	okToScroll _ true.
	scrollDelay _ Delay forMilliseconds: 250.
	[Sensor redButtonPressed] whileTrue: [
		pt _ Sensor cursorPoint.
		(okToScroll
		 and: [(dy _ self dyForPoint: pt) ~= 0]) ifTrue: [
			[okToScroll _ false. scrollDelay wait. okToScroll _ true]
				forkAt: Processor userInterruptPriority.
			showingCaret
				ifTrue: [
					self displayCaretForBlock: pivotBlock.
					showingCaret _ false]
				ifFalse: [self reverseFrom: startBlock to: pivotBlock].
			self scrollBy: dy.
			pt _ dy < 0
				ifTrue: [clippingRectangle topLeft]
				ifFalse: [clippingRectangle bottomRight].
			pivotBlock _ self characterBlockForIndex: pivotBlock stringIndex.
			startBlock _ pivotBlock ].
		stopBlock _ self characterBlockAtPoint: pt.
		stopBlock = startBlock ifFalse: [
			showingCaret ifTrue: [
				self displayCaretForBlock: pivotBlock. showingCaret _ false].
			self reverseFrom: startBlock to: stopBlock.
			startBlock _ stopBlock] ].
	(showingCaret not and: [pivotBlock = stopBlock])
		ifTrue: [self displayCaretForBlock: pivotBlock].
	scrollDelay disable.
	(previousStartBlock = previousStopBlock and:
		[pivotBlock = stopBlock and: [stopBlock = previousStopBlock]])
		ifTrue:  "select a word or bracketed range"
			[word _ self selectWord: pivotBlock stringIndex.
			word first = word last ifFalse:
				[self displayCaretForBlock: pivotBlock.
				pivotBlock _ self characterBlockForIndex: word first.
				stopBlock _ self characterBlockForIndex: word last.
				self reverseFrom: pivotBlock to: stopBlock]].
	stopBlock < pivotBlock
		ifTrue: [^Array with: stopBlock with: pivotBlock]
		ifFalse: [^Array with: pivotBlock with: stopBlock]!

reverseFrom: characterBlock1 to: characterBlock2 
	"Reverse area between the two character blocks given as arguments."

	| start stop |
	characterBlock1 = characterBlock2 ifTrue: [^self].
	characterBlock1 < characterBlock2
		ifTrue: [start _ characterBlock1. stop _ characterBlock2]
		ifFalse: [start _ characterBlock2. stop _ characterBlock1].
	start top = stop top ifTrue: [
		^self reverseRectangle: (start origin corner: stop bottomLeft)].
	self reverseRectangle:
	 (start origin corner: compositionRectangle right @ start bottom).
	self reverseRectangle:
	 (compositionRectangle left@start bottom corner: compositionRectangle right@stop top).
	self reverseRectangle: (compositionRectangle left@stop top corner: stop bottomLeft).!

reverseRectangle: aRectangle
	"Highlight the part of aRectangle that is visible."

	| rect |
	rect _ aRectangle intersect: self visibleRectangle.
	destinationForm fill: rect rule: Form reverse mask: mask.!

selectWord: stringIndex
	"Select delimited text or word--the result of double-clicking."

	| openDelimiter closeDelimiter direction match level leftDelimiters rightDelimiters
	string here hereChar start stop |
	string _ text string.
	here _ stringIndex.
	(here between: 2 and: string size)
		ifFalse: ["if at beginning or end, select entire string"
			^ 1 to: string size + 1].
	leftDelimiters _ '([{<''"
'.
	rightDelimiters _ ')]}>''"
'.
	openDelimiter _ string at: here - 1.
	match _ leftDelimiters indexOf: openDelimiter.
	match > 0
		ifTrue: 
			["delimiter is on left -- match to the right"
			start _ here.
			direction _ 1.
			here _ here - 1.
			closeDelimiter _ rightDelimiters at: match]
		ifFalse: 
			[openDelimiter _ string at: here.
			match _ rightDelimiters indexOf: openDelimiter.
			match > 0
				ifTrue: 
					["delimiter is on right -- match to the left"
					stop _ here - 1.
					direction _ -1.
					closeDelimiter _ leftDelimiters at: match]
				ifFalse: ["no delimiters -- select a token"
					direction _ -1]].
	level _ 1.
	[level > 0 and: [direction > 0
			ifTrue: [here < string size]
			ifFalse: [here > 1]]]
		whileTrue: 
			[hereChar _ string at: (here _ here + direction).
			match = 0
				ifTrue: ["token scan goes left, then right"
					hereChar tokenish
						ifTrue: [here = 1
								ifTrue: 
									[start _ 1.
									"go right if hit string start"
									direction _ 1]]
						ifFalse: [direction < 0
								ifTrue: 
									[start _ here + 1.
									"go right if hit non-token"
									direction _ 1]
								ifFalse: [level _ 0]]]
				ifFalse: ["bracket match just counts nesting level"
					hereChar = closeDelimiter
						ifTrue: [level _ level - 1"leaving nest"]
						ifFalse: [hereChar = openDelimiter 
									ifTrue: [level _ level + 1"entering deeper nest"]]]].
	level > 0 ifTrue: ["in case ran off string end"	here _ here + direction].
	direction > 0
		ifTrue: [^ start to: here]
		ifFalse: [^ here + 1 to: stop + 1]! !

!TextCompositor methodsFor: 'scrolling'!

scrollBy: charsToMove
	"Move the paragraph by the amount, charsToMove."

	| chars newIndex startIndex lineIndex preIndex first |
	chars _ charsToMove.
	chars _ chars max: self compositionRectangleDelta.
	chars abs >= (lineLength * self updateCharsPerLine)
		ifTrue:
			[startIndex _ 
					(((lines at: 1) + chars) min: textSize) max: 1.
			newIndex _ 
					scanner scanLine: startIndex direction: #left.
			lineIndex _ 1.
			[newIndex < startIndex] whileTrue: 
				[preIndex _ newIndex.
				newIndex _ scanner nextLineStart: newIndex line: lineIndex in: self].
			first _ (newIndex = startIndex ifTrue: [newIndex] ifFalse: [preIndex]).
			lines at: 1 put: first.
			self displayLines.
			^self].
	chars  < 0	
		ifTrue:	"Moving down." 
			[self scrollDownBy: chars negated]
		ifFalse: "Moving up."
			[self scrollUpBy: chars].!

scrollDown: linesToMove
	"Scroll the paragraph down by the amount, linesToMove."

	| deltaLines tempLines delta realLinesToMove tempLinesPos stopIndex startIndex newIndex lineIndex first i | 
	stopIndex _ first _ lines at: 1.
	(first = 1 or: [linesToMove <= 0]) ifTrue: [^self].
	deltaLines _ linesToMove.
	lineLength <= 1 ifTrue: [deltaLines _ lineLength].
	tempLines _ Array new: deltaLines.
	self updateCharsPerLine.
	delta _ charsPerLine * deltaLines.
	lineIndex _ 0.
	[stopIndex ~= 1 and: [lineIndex < deltaLines]] 
		whileTrue: 
		[startIndex _ (delta >= stopIndex ifTrue: [1] ifFalse: [stopIndex - delta]).
		newIndex _ scanner scanLine: startIndex direction: #left.
		[newIndex < stopIndex] whileTrue: 
			[(lineIndex _ lineIndex + 1) > deltaLines
				ifTrue: 
					[tempLines replaceFrom: 1 to: deltaLines - 1 with: tempLines startingAt: 2.
					lineIndex _ deltaLines].
			tempLines at: lineIndex put: newIndex.
			newIndex _ scanner nextLineStart: newIndex line: lineIndex in: self].
		stopIndex _ tempLines at: 1.
		lineIndex < deltaLines 
			ifTrue:
				[i _ lineIndex + 1.
				deltaLines _ deltaLines - lineIndex.
				[(i _ i - 1) > 0] whileTrue: [tempLines at: i + deltaLines put: (tempLines at: i)].
				lineIndex _ 0.
				delta _ charsPerLine * deltaLines.
				tempLinesPos _ i + deltaLines]
			ifFalse: [tempLinesPos _ 0]].
	realLinesToMove _ linesToMove - tempLinesPos.
	self moveLines: 1 to: realLinesToMove + 1.
	startIndex _ tempLines at: tempLinesPos + 1.
	stopIndex _ first.
	lineIndex _ 0.
	[(lineIndex _ lineIndex + 1) <= lineLength and: [startIndex < stopIndex]] 
		whileTrue: 
		[lines at: lineIndex put: startIndex.
		startIndex _ scanner displayOneLine: lineIndex start: startIndex in: self].
	lines at: lineIndex put: startIndex.
	self updateLastLine.
	nextChar _ lines at: lastLine + 1!

scrollDownBy: charsToMove
	"Scroll the paragraph down by the amount, charsToMove."

	| characterIndex |
	textSize = 0 ifTrue: [^self].
	characterIndex _ (charsToMove >= (lines at: 1) 
						ifTrue: [1] 
						ifFalse: [(lines at: 1) - charsToMove]).
	self setTopPosition: characterIndex!

scrollUp: linesToMove
	"Scroll the paragraph up by the amount, linesToMove."

	| deltaLines startIndex lineIndex stopIndex | 
	(textSize = 0 or: [linesToMove <= 0]) ifTrue: [^self]. 
	deltaLines _ linesToMove.
	deltaLines >= lastLine ifTrue: [deltaLines _ lastLine - 1].
	lineLength <= 1 ifTrue: [deltaLines _ lineLength].
	self moveLines: deltaLines + 1 to: 1.
	startIndex _ nextChar.
	lineIndex _ lastLine - deltaLines.
	stopIndex _ textSize.
	[(lineIndex _ lineIndex + 1) <= lineLength and: [startIndex <= stopIndex]] 
		whileTrue: 
		[lines at: lineIndex put: startIndex.
 		startIndex _ scanner displayOneLine: lineIndex start: startIndex in: self].
	startIndex = nextChar ifFalse:
		[nextChar _ startIndex.
		lines at: lineIndex put: startIndex].
	self updateLastLine!

scrollUpBy: charsToMove
	"Scroll the paragraph up by the amount, charsToMove."

	| startIndex linesToMove newIndex |
	linesToMove _ 1.
	startIndex _ lines at: 1.
	charsToMove > (nextChar - startIndex)
		 ifTrue:	[newIndex _ 
					((lines at: 1) + charsToMove) min: textSize.
				newIndex _ 
					scanner scanLine: newIndex direction: #left.
				lines at: 1 put: newIndex.
				self displayLines.
				^self].
	[charsToMove > ((lines at: linesToMove + 1) - startIndex)
		and: [linesToMove <= lastLine]]
		whileTrue: [linesToMove _ linesToMove + 1].
	self scrollUp: linesToMove!

scrollUpPosition: characterIndex
	"Scroll up until the charcter whose index is characterIndex is at the bottom of the view."

	| tempLines startIndex lineIndex stopIndex ring | 
	tempLines _ Array new: lineLength.
	startIndex _ nextChar.
	lineIndex _ 0.
	stopIndex _ (characterIndex > textSize ifTrue: [textSize] ifFalse: [characterIndex]).
	ring _ false.
	[startIndex <= stopIndex] 
		whileTrue: 
		[(lineIndex _ lineIndex + 1) > lineLength ifTrue: [lineIndex _ 1. ring _ true].
		tempLines at: lineIndex put: startIndex.
 		startIndex _ scanner nextLineStart: startIndex line: lineIndex in: self].
	lineIndex = lineLength ifTrue: [lineIndex _ 0. ring _ true].
	ring ifTrue: [self clearVisibleRectangle.
				startIndex _ tempLines at: lineIndex + 1.
				lineIndex _ 0]
		ifFalse: [self moveLines: lineIndex + 1 to: 1.
				startIndex _ nextChar.
				lineIndex _ lineLength - lineIndex].
	stopIndex _ textSize.
	[(lineIndex _ lineIndex + 1) <= lineLength and: [startIndex <= stopIndex]] 
		whileTrue: 
		[lines at: lineIndex put: startIndex.
 		startIndex _ scanner displayOneLine: lineIndex start: startIndex in: self].
	nextChar _ startIndex.
	lines at: lineIndex put: startIndex.
	self updateLastLine!

setBottomPosition: characterIndex
	"Scroll until the charcter whose index is characterIndex is at the bottom of the view."

	| stopIndex first deltaLines tempLines delta lineIndex scroll startIndex newIndex tempNextChar i linesToMove tempLinesPos |
	stopIndex _ first _ 
		(characterIndex > (textSize + 1) ifTrue: [textSize + 1] ifFalse: [characterIndex]).
	(characterIndex = 1 or: [lineLength = 0]) ifTrue: [^self].
	deltaLines _ lineLength.
	tempLines _ Array new: deltaLines + 1.
	delta _ self updateCharsPerLine.
	lineIndex _ 0.
	scroll _ false.
	[scroll not and: [lineIndex < deltaLines]] 
	whileTrue: 
	[startIndex _ (delta >= stopIndex ifTrue: [1] ifFalse: [stopIndex - delta]).
	newIndex _ scanner scanLine: startIndex direction: #left.
		[newIndex < stopIndex] whileTrue: 
			[((lineIndex _ lineIndex + 1) > deltaLines and: [newIndex ~= stopIndex])
				ifTrue: 
					[tempLines replaceFrom: 1 to: deltaLines - 1 with: tempLines startingAt: 2.
					lineIndex _ deltaLines].
			tempLines at: lineIndex put: newIndex.
			newIndex _ scanner nextLineStart: newIndex line: lineIndex in: self.
			newIndex = nextChar ifTrue: [scroll _ true]].
	stopIndex = first ifTrue: [tempNextChar _ newIndex].
	stopIndex _ tempLines at: 1.
	lineIndex < deltaLines
		ifTrue:
			[i _ lineIndex + 1.
			deltaLines _ deltaLines - lineIndex.
			[(i _ i - 1) > 0] whileTrue: [tempLines at: i + deltaLines put: (tempLines at: i)].
			lineIndex _ 0]].
	i _ lineLength + 1.
	[(i _ i -1) > 0 and: [(tempLines at: i) ~= nextChar]] whileTrue: [].
	linesToMove _ lineLength + 1 - i min: lineLength.
	scroll 
		ifTrue: [self moveLines: linesToMove + 1 to: 1.
				tempLinesPos _ lineLength - linesToMove + 1.
				startIndex _ tempLines at: tempLinesPos.
				lineIndex _ tempLinesPos - 1] 
		ifFalse: [self clearVisibleRectangle.
				startIndex _ tempLines at: 1.
				lineIndex _ 0].
	lines at: lineLength + 1 put: (nextChar _ tempNextChar).
	stopIndex _ textSize.
	[(lineIndex _ lineIndex + 1) <= lineLength and: [startIndex <= stopIndex]] 
		whileTrue: 
		[lines at: lineIndex put: startIndex.
		startIndex _
			scanner displayOneLine: lineIndex start: startIndex in: self].
	self updateLastLine!

setTopPosition: characterIndex
	"Scroll until the charcter whose index is characterIndex is at the top of the view."

	| stopIndex newIndex startIndex preIndex first lineIndex |
 	stopIndex _ lines at: 1.
	(characterIndex >= stopIndex and: [characterIndex < nextChar])
		ifTrue: [^self].
	characterIndex >= nextChar ifTrue: [stopIndex _ textSize].
	newIndex _ scanner scanLine: characterIndex direction: #left.
	[newIndex < characterIndex] whileTrue: 
		[preIndex _ newIndex.
		newIndex _ scanner nextLineStart: newIndex line: 1 in: self].
	startIndex _ first _ (newIndex = characterIndex ifTrue: [newIndex] ifFalse: [preIndex]).
	lineIndex _ 0.
	[(lineIndex _ lineIndex + 1) <= lineLength and: [startIndex < stopIndex]]
	whileTrue: 
		[startIndex _ scanner nextLineStart: startIndex line: lineIndex in: self].
	startIndex = stopIndex
		ifTrue: [self moveLines: 1 to: lineIndex]
		ifFalse: [self clearVisibleRectangle.
				stopIndex _ textSize.
				lines at: lineIndex put: startIndex "extra line"].
	lineIndex _ 0.
	startIndex _ first.
	[(lineIndex _ lineIndex + 1) <= lineLength and: [startIndex < stopIndex]] whileTrue: 
		[lines at: lineIndex put: startIndex.
		startIndex _ scanner displayOneLine: lineIndex start: startIndex in: self].
	lines at: lineIndex put: startIndex.
	self updateLastLine.
	nextChar _ lines at: lastLine + 1! !

!TextCompositor methodsFor: 'alignment'!

centered 
	"Set the alignment for the style with which the receiver displays its text
	so that text is centered in the composition rectangle."

	textStyle setAlignment: Centered.!

justified 
	"Set the alignment for the style with which the receiver displays its text
	so that the characters in each of text end on an even border in the composition
	rectangle."

	textStyle setAlignment: Justified.!

leftFlush 
	"Set the alignment for the style with which the receiver displays its text
	so that the characters in each of text begin on an even border in the composition
	rectangle.  This is also known as ragged-right."

	textStyle setAlignment: LeftFlush.!

rightFlush 
	"Set the alignment for the style with which the receiver displays its text
	so that the characters in each of text end on an even border in the composition
	rectangle but the beginning of each line does not (ragged-left)."

	textStyle setAlignment: RightFlush!

toggleAlignment 
	"Set the alignment for the style with which the receiver displays its text
	so that it moves from centered to justified to leftFlush to rightFlush and back
	to centered again."

	textStyle setAlignment: textStyle alignment + 1.! !

!TextCompositor methodsFor: 'tab and margins'!

clearIndents
	"Reset all the indention settings to be 0."

	self firstIndent: 0.
	self restIndent: 0.
	self rightIndent: 0!

deltaMarginTabsLevel: anInteger
	"Delta the depth of 'nesting' for this paragraph -- an index into the marginTabsArray in the textStyle."

	self marginTabsLevel: anInteger + marginTabsLevel.!

firstIndent
	"Answer the horizontal indenting of the first line of a paragraph in the style of the receiver."

	^firstIndent!

firstIndent: anInteger 
	"Set the horizontal indenting of the first line of a paragraph in the style of the receiver to be anInteger."

	firstIndent _
		(anInteger max: 0) min: (compositionRectangle width - DefaultSpace - rightIndent)!

leftMarginForCompositionForLine: lineIndex
	"Build the left margin for composition of a line. 
	Depends upon marginTabsLevel and the indent."

	| scale |
	scale _ 1.
	lineIndex = 1
		ifTrue: [^(firstIndent + (textStyle leftMarginTabAt: marginTabsLevel)) * scale]
		ifFalse: [^(restIndent + (textStyle leftMarginTabAt: marginTabsLevel)) * scale].!

leftMarginForDisplayForLine: lineIndex
	"Build the left margin for display of a line.
	Depends upon leftMarginForComposition, compositionRectangle left, the outputMedium and
	the alignment."

	| pad scale line compositionScanner |
	scale _ 1.
	(textStyle alignment = LeftFlush or: [textStyle alignment = Justified])
		ifTrue: 
			[^((compositionRectangle left * scale)
				+ (self leftMarginForCompositionForLine: lineIndex))].
	"When called from character location code and entire string has been cut,
	there are no valid lines, hence following nil check."
	text size = 0
		ifFalse: 
			[compositionScanner _ CompositionScanner new in: self.
			line _ compositionScanner composeLine: lineIndex fromCharacterIndex: (lines at: lineIndex) inParagraph: self].
	(lineIndex <= lineLength and: [line ~~ nil])
		ifTrue: 
			[pad _ line paddingWidth]
		ifFalse: 
			[pad _ 
				compositionRectangle width - firstIndent - rightIndent].
	textStyle alignment = Centered 
		ifTrue: 
			[^((compositionRectangle left * scale)
				+ (self leftMarginForCompositionForLine: lineIndex)) + (pad // 2)].
	textStyle alignment = RightFlush 
		ifTrue:
			[^((compositionRectangle left * scale)
				+ (self leftMarginForCompositionForLine: lineIndex)) + pad].
	self error: 'no such alignment'!

marginTabsLevel
	"Answer the depth of 'nesting' for this paragraph -- an index into the marginTabsArray in the textStyle."

	^marginTabsLevel!

marginTabsLevel: anInteger
	"Set the depth of 'nesting' for this paragraph -- an index into the marginTabsArray in the textStyle."

	marginTabsLevel _ (anInteger max: 0) min: textStyle nestingDepth.
	"Check if we've nested so far that there is no room between the effective margins."
	[(self leftMarginForCompositionForLine: 1) >= (self rightMarginForComposition)
		and: [marginTabsLevel > 0]]
		whileTrue:
			[marginTabsLevel _ (marginTabsLevel - 1 max: 0)].
	[(self leftMarginForCompositionForLine: 2) >= (self rightMarginForComposition)
		and: [marginTabsLevel > 0]]
		whileTrue:
			[marginTabsLevel _ (marginTabsLevel - 1 max: 0)]!

restIndent
	"Answer the indent for all but the first line of a paragraph in the style of the receiver."

	^restIndent!

restIndent: anInteger 
	"Set the indent for all but the first line of a paragraph in the style of the receiver to be anInteger."

	restIndent _
		(anInteger max: 0) min: (compositionRectangle width - DefaultSpace - rightIndent)!

rightIndent
	"Answer the right margin indent for the lines of a paragraph in the style of the receiver."

	^rightIndent!

rightIndent: anInteger 
	"Set the right margin indent for the lines of a paragraph in the style of the receiver to be anInteger."

	| maxRightIndent |
	firstIndent > restIndent
		ifTrue:	[maxRightIndent _
					(compositionRectangle width- DefaultSpace - firstIndent) max: 1]
		ifFalse:	[maxRightIndent _
					(compositionRectangle width- DefaultSpace - restIndent) max: 1].
	rightIndent _ anInteger min: maxRightIndent!

rightMarginForComposition
	"Build the right margin for a line. 
	Depends upon compositionRectangle width, marginTabsLevel, and right 
	indent."

	| scale |
	scale _ 1.
	^(compositionRectangle width 
		- (textStyle rightMarginTabAt: marginTabsLevel) - rightIndent) * scale!

rightMarginForDisplay 
	"Build the right margin for a line.
	Depends upon compositionRectangle rightSide, marginTabsLevel, and right indent."

	| scale |
	scale _ 1.
	^(compositionRectangle right - 
		rightIndent - (textStyle rightMarginTabAt: marginTabsLevel)) * scale! !

!TextCompositor methodsFor: 'indicating'!

flash 
	"Complement twice the visible area in which the receiver displays."

	Display flash: self visibleRectangle!

outline 
	"Display a border around the visible area in which the receiver 
	presents its text."

	clippingRectangle bottom <= compositionRectangle bottom
	  ifTrue: [Display 
				border: (clippingRectangle intersect: compositionRectangle) 
				width: 2]
	  ifFalse: [Display 
				border: (clippingRectangle intersect: destinationForm boundingBox)
				width: 2].! !

!TextCompositor methodsFor: 'utilities'!

clearVisibleRectangle 
	"Display the area in which the receiver presents its text so that the area
	is all one tone--in this case, all white."

	destinationForm
	  fill: self visibleRectangle
	  rule: rule
	  mask: Form white.!

fit
	"Make the bounding rectangle of the receiver contain all the text without
	changing the width of the receiver's composition rectangle."

	[(self lineIndexOfTop: clippingRectangle top) = 1]
		whileFalse: [self scrollBy: charsPerLine].
	clippingRectangle bottom: compositionRectangle bottom!

gridWithLead: leadInteger 
	"Set the line grid of the receiver's style for displaying text to the height
	of the first font in the receiver's style + the argument, leadInteger."

	textStyle 
		gridForFont: (text emphasisAt: 1)
		withLead: leadInteger.		"assumes only one font referred to by runs"! !

!TextCompositor methodsFor: 'line access'!

lineAt: lineIndex
	"Answer the textLineInterval for the specified line."

	| i start stop |
	i _ lineIndex.
	start _ lines at: i.
	[start == nil] whileTrue: 
		[start _ lines at: (i _ i - 1)].
	start = nextChar
		ifTrue: 
			[self crIsLast
				ifTrue: [stop _ start]
				ifFalse: [stop _ start - 1.
						start _ lines at: i - 1]]
		ifFalse: 
			[stop _ (lines at: i + 1) -1]. 
	^TextLineInterval
			start: start 
			stop: stop
			internalSpaces: 0 
			paddingWidth: 0!

lineIndexOfCharacterIndex: characterIndex 
	"Answer the line index for a given characterIndex."

	| i lineIndex|
	i _ characterIndex.
	i <= (lines at: 1) ifTrue: [^1].
	i > nextChar ifTrue: [i _ nextChar].
	lineIndex _ 1.
	[(lines at: lineIndex) < i] whileTrue: [lineIndex _ lineIndex +1].
	^((lines at: lineIndex) = i) 
		ifTrue: [lineIndex] ifFalse: [lineIndex -1]!

lineIndexOfTop: top  
	"Answer the line index at a given top y coordinate."

	^(top - compositionRectangle top // textStyle lineGrid + 1 max: 1)
		min: lastLine!

textAt: lineIndex
	"Answer the text for the specified line."

	^ text!

topAtLineIndex: lineIndex 
	"Answer the top y coordinate of the given line."
	
	^compositionRectangle top + (lineIndex - 1 * textStyle lineGrid)! !

!TextCompositor methodsFor: 'converting'!

asForm
	"Answer a new Form made up of the bits that represent the receiver's
	displayable text."

	| aForm saveDestinationForm |
	aForm _ Form new extent: compositionRectangle extent.
	saveDestinationForm _ destinationForm.
	self displayOn: aForm
		at: 0 @ 0
		clippingBox: aForm boundingBox
		rule: Form over
		mask: Form black.
	aForm offset: offset.
	destinationForm _ saveDestinationForm.
	^aForm!

asParagraph
	"Answer a Paragraph whose text and style are identical to that of
	the receiver."

	^Paragraph withText: text style: textStyle copy!

asString
	"Answer the string of characters of the receiver's text."

	^text string!

asText
	"Answer the receiver's text."

	^text! !

!TextCompositor methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream 
		storeRecordOfClass: self class;
		nextPut: text;
		nextPut: clippingRectangle;
		nextPut: compositionRectangle! !

!TextCompositor methodsFor: 'private: private'!

adjustCompositionRectangle
	"Adjust the compositionRectangle height so that it fits lineLength lines."

	compositionRectangle _ 
			compositionRectangle height: textStyle lineGrid * lineLength.!

charsPerLine
	"Answer guess value, the number of characters per line."

	^charsPerLine!

clearRestLinesFrom: lineIndex

	| destY i linesLength | 
	destY _ self topAtLineIndex: lineIndex.
	destinationForm white: 
			(compositionRectangle left@destY 
							corner: (compositionRectangle bottomRight)).
	i _ lineIndex.
	linesLength _ lines size.
	[i <= linesLength] 
		whileTrue: 
		[lines at: i put: nil.
		i _ i + 1]!

composeForm 
	"Cache the form for displaying the paragraph."

	form _ self asParagraph asForm!

compositionRectangleDelta
	"A handy number -- mostly for scrolling"

	^(lines at: 1) negated!

displayLines
	"Redisplay the paragraph."

	| startIndex stopIndex lineIndex |
	lineIndex _ 1.
	stopIndex _ textSize _ text size.
	startIndex _ lines at: lineIndex.
	scanner initializeFromCompositor: self stop: stopIndex + 1.
	self clearVisibleRectangle.
	[startIndex <= stopIndex and: [lineIndex <= lineLength]] whileTrue: 
		[startIndex _ scanner displayOneLine: lineIndex start: startIndex in: self.
		lines at: (lineIndex _ lineIndex + 1) put: startIndex].
	[lineIndex <= lineLength] whileTrue: 
		[lines at: (lineIndex _ lineIndex + 1) put: nil].
	nextChar _ startIndex.
	self updateLastLine!

moveLines: start to: stop
	"Move the paragraph such that line index start is set to line index stop." 

	| delta linesToMove i firstClearLine linesToClear limit |
	(start = stop or: [lineLength <= 1]) ifTrue: [^self].
	delta _ stop - start.
	linesToMove _ lines size - (start max: stop) + 1.
	delta > 0 
		ifTrue:  "move down"
			[i _ start + linesToMove.
			[(i _ i - 1) >= start] whileTrue: 
				[lines at: i + delta put: (lines at: i)].
			firstClearLine _ start.
			linesToClear _ delta]
		ifFalse:  "move up"
			[i _ start.
			limit _ start + linesToMove.
			[i < limit] whileTrue: 
				[lines at: i + delta put: (lines at: i).
				i _ i + 1].
			firstClearLine _ stop + linesToMove.
			linesToClear _ delta negated].
			i _firstClearLine.
			limit _ firstClearLine + linesToClear.
			[i < limit] whileTrue:
				[lines at: i put: nil.
				i _ i + 1].
	self displayMoveLines: start to: stop!

newLines
	"Create a line table which maintains line start caracter indices."
 
	| newLineLengh start | 
	newLineLengh _ compositionRectangle height // textStyle lineGrid.
	lineLength == nil
		ifTrue: 
			[lines _ Array new: (newLineLengh + 1).
			lineLength _ newLineLengh. 
			lines at: 1 put: 1.
			nextChar _ 1]
		ifFalse: 
			[start _ lines at: 1.
			lines _ Array new: (newLineLengh + 1).
			lineLength _ newLineLengh.
			lines at: 1 put: start]!

nextChar
	"Answer next character index in the displayed text."

	^nextChar!

removeFirstChars: numberOfChars
	"Remove a number of characters from the beginning of the receiver, adjusting the composition rectangle so the displayed text moves as little as possible.  Special kludge for TextCollectorController."

	| delta scrollDelta |
	delta _ numberOfChars -1.
	scrollDelta _ self compositionRectangleDelta negated.
	delta > scrollDelta ifTrue:
		[delta _ scrollDelta.
		self clearVisibleRectangle].
	self replaceFrom: 1 to: numberOfChars with: '' asText.!

repositionAt: aPoint clippingBox: clippingBox
	compositionRectangle moveTo: aPoint.
	clippingRectangle _ clippingBox.!

setScanner

	textStyle alignment = LeftFlush 
		ifTrue: [scanner _ TextDisplayScanner new]
		ifFalse: [scanner _ TextAlignScanner new].
	scanner setDisplayMediumFrom: self.
	scanner setTextStyleFrom: self!

setText: aText textStyle: aTextStyle offset: aPoint 
	"Initialize the instance variables."

	text _ aText.
	textStyle _ aTextStyle.
	offset _ aPoint.
	form _ nil!

startingLineAfterReplacingAt: startIndex
	"Return the line index at which recomposition must start
after a replacement has occured at the character index
startIndex"

	| lineIndex string start i aChar |
	lineIndex _ self lineIndexOfCharacterIndex: startIndex.
	lineIndex <= 1 ifTrue: [^lineIndex].
	string _ text string.
	aChar _ string at: (start _ lines at: lineIndex) - 1.
	aChar == $
 ifTrue: [^lineIndex].
	i _ startIndex.
	[(i _ i - 1) >= start]
		whileTrue:
			[aChar _ string at: i.
			(aChar == $  or: [aChar == $	]) ifTrue: [^lineIndex]].
	^lineIndex - 1!

updateCharsPerLine
	"Compute guess value, the number of characters per line."

	charsPerLine _ ((nextChar - (lines at: 1)) asFloat / (lastLine max: 1) asFloat * 1 asFloat) rounded.
	^charsPerLine max: 1!

updateLastLine
	"Compute the number of lines in the displayed text."

	| i | 
	nextChar = (textSize + 1)
		ifTrue:
			[i _ lines size.
			[(lines at: i) == nil] whileTrue: [i _ i - 1].
			lastLine _ i - 1]
		ifFalse:
			[lastLine _ lineLength]!

updateLinesBelow: lineIndex at: start delta: delta
	"Update start index in the lines after a replacement has occurred at character index, start with text size delta."

	| linesLength i oldSize pos | 
	linesLength _ lineLength + 1.
	oldSize _ textSize - delta.
	((start >= nextChar and: [nextChar ~= 1]) 
     and: [nextChar < (oldSize + 1)]) 
		ifTrue: [^self]. "below bottom, no update"
	i _ lineIndex.
	start < (lines at: 1) 
		ifTrue: [pos _ scanner scanLine: start direction: #left.
				lines at: 1 put: pos].
	i _ i + 1.
	[i <= linesLength and: [(lines at: i) ~~ nil]] 
		whileTrue: 
		[(delta < 0 and: [delta abs > (lines at: i)]) 
			ifTrue: [pos _ 1]
			ifFalse: [pos _ (lines at: i) + delta].
		lines at: i put: pos.
		i _ i + 1].	
	nextChar _ nextChar + delta max: start!

visibleRectangle

	^ clippingRectangle intersect: destinationForm boundingBox! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextCompositor class
	instanceVariableNames: ''!


!TextCompositor class methodsFor: 'instance creation'!

initialize	
	"TextCompositor initialize."

	DefaultCompositionRectangle _ 0@0 corner: 100@100.!

new
	"Do not allow an uninitialized view.  Create with text that has no characters."

	^self withText: '' asText!

withText: aText 
	"Answer an instance of the receiver with text set to aText and style set to
	the system's default text style."

	^self withText: aText style: DefaultTextStyle copy!

withText: aText style: aTextStyle 
	"Answer an instance of the receiver with text set to aText and style set to aTextStyle."

	^super new
		compositionRectangle: DefaultCompositionRectangle
		text:	aText
		style: aTextStyle
		offset: (0@0)
		outputMedium: #Display!

withText: aText style: aTextStyle compositionRectangle: compRect clippingRectangle: clipRect 
	"Answer an instance of the receiver with text set to aText, style 
	set to aTextStyle, to be displayed within rectangular areas defined 
	by compRect and clipRect."

	| para |
	para _ super new
				compositionRectangle: compRect
				text: aText
				style: aTextStyle
				offset: 0 @ 0
				outputMedium: #Display.
	para clippingRectangle: clipRect.
	^para! !

!TextCompositor class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag

	| obj text compRect clipRect |
	text _ stream next.
	compRect _ stream next.
	clipRect _ stream next.
	obj _ self 
		withText: text
		style: TextStyle default
		compositionRectangle: compRect
		clippingRectangle: clipRect.
	stream register: obj id: tag.
	^obj! !

TextCompositor initialize!
