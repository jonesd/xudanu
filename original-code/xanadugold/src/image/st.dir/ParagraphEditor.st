'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:44 pm'!

ScrollController subclass: #ParagraphEditor
	instanceVariableNames: 'paragraph startBlock stopBlock beginTypeInBlock emphasisHere initialText selectionShowing '
	classVariableNames: 'CurrentEvent CurrentSelection Keyboard PreviousSelections UndoSelection '
	poolDictionaries: 'TextConstants '
	category: 'Interface-Text'!
ParagraphEditor comment:
'Class ParagraphEditor contains the main handling of text editing.  It ought to be used only on smallish paragraphs.

Instance Variables:

	paragraph
<Paragraph>  A pointer to the text form being edited.  The Paragraph is optimized for managing replacements in it''s stylized string and for scrolling.

	startBlock
	stopBlock
<CharacterBlock>  These variables contain the string indices, characters, and bounding boxes of the starting and stopping characters in the stylized string which will be operated upon by the next command.

	beginTypeInBlock
<CharacterBlock>  Used to manage typing and to distinguish selection arising from the last characters typed in from selection with the mouse or which is the result of some special keystroke.

	emphasisHere
<Integer> Used to denote the emphasis change at the current startBlock.

	initialText
<Text>  A copy of the string held by the Paragraph at the time the text editor was instantiated.  It is currently used to manage the editing of Smalltalk code, and is reinstalled in the Paragraph when a "cancel" is executed and is overwritten when an "accept" is executed.

	selectionShowing
<Boolean>  true = on, false = off.  Since selection involves raw modification of the bits in the destinationForm of the Paragraph, it must be monitored closely and with care.


Class Variables:
	CurrentEvent		<KeyboardEvent>
	CurrentSelection	<Text>
	Keyboard			<Array of: Symbols>
	PreviousSelections	<OrderedCollection of: Strings>
	TextEditorYellowButtonMenu		<PopupMenu>
	TextEditorYellowButtonMessages	<Array of: Strings>
	UndoSelection 		<Text>'!


!ParagraphEditor methodsFor: 'initialize-release'!

changeParagraph: aParagraph 
	"Install aParagraph as the one to be edited by the receiver."

	paragraph _ aParagraph.
	self resetState!

resetState 
	"Establish the initial conditions for editing the paragraph:  place caret
	before first character, set the emphasis to that of the first character,
	and save the paragraph for purposes of canceling."

	| insetDisplayBox |
	insetDisplayBox _ paragraph compositionRectangle.
	startBlock _ 
		CharacterBlock
			stringIndex: 1
			character: nil
			boundingRectangle: (insetDisplayBox topLeft extent: 0 @ 0).
	stopBlock _ startBlock copy.
	beginTypeInBlock _ startBlock copy.
	self setEmphasisHere.
	selectionShowing _ false.
	initialText _ paragraph text copy! !

!ParagraphEditor methodsFor: 'basic control sequence'!

controlInitialize 
	super controlInitialize.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self initializeSelection.
	beginTypeInBlock _ nil.!

controlTerminate 
	super controlTerminate.
	self closeTypeIn ifTrue: [startBlock _ stopBlock copy].
	"so leaving and entering window won't select last type-in"! !

!ParagraphEditor methodsFor: 'control defaults'!

controlActivity 
	self scrollBarContainsCursor
		ifTrue: 
			[self scroll]
		ifFalse: 
			[self processKeyboard.
			self processMouseButtons].!

isControlActive
	^super isControlActive & sensor blueButtonPressed not!

processKeyset
	"Clever trick to remove this method after it is called for the last time."

	ParagraphEditor removeSelector: #processKeyset! !

!ParagraphEditor methodsFor: 'scrolling'!

canScroll 
	^true!

scroll
	self updateMarker.
	super scroll!

scrollAmount 
	^sensor cursorPoint y - scrollBar top!

scrollBy: heightToMove 
	"Move the paragraph by the amount, heightToMove, and reset the text selection."
	self deselect.
	paragraph scrollBy: heightToMove.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self select!

scrollToTop
	"Scroll so that the paragraph is at the top of the view."
	self scrollView: (paragraph clippingRectangle top 
		- paragraph compositionRectangle top)!

scrollView: anInteger 
	| maximumAmount minimumAmount amount |
	maximumAmount _ 
		paragraph clippingRectangle top - paragraph compositionRectangle top max: 0.
	minimumAmount _ 
		paragraph clippingRectangle top 
			+ paragraph lineGrid - paragraph compositionRectangle bottom min: 0.
	amount _ (anInteger min: maximumAmount) max: minimumAmount.
	amount ~= 0
		ifTrue:
			[self deselect.
			self scrollBy: amount negated.
			self select].!

viewDelta 
	^paragraph clippingRectangle top 
		- paragraph compositionRectangle top 
		- ((marker top - self scrollBarOnlyArea top) asFloat 
				/ self scrollBarOnlyArea height asFloat * self scrollRectangleHeight asFloat)
			roundTo: paragraph lineGrid! !

!ParagraphEditor methodsFor: 'marker adjustment'!

computeMarkerRegion
	paragraph compositionRectangle height = 0
		ifTrue:	[^0@0 extent: 10 @ self scrollBarOnlyArea height]
		ifFalse:	[^0@0 extent:
					10 @ ((paragraph clippingRectangle height asFloat /
							self scrollRectangleHeight * self scrollBarOnlyArea height) rounded
							min: self scrollBarOnlyArea height)]!

markerDelta
	^marker top - self scrollBarOnlyArea top - ((paragraph clippingRectangle top -
		paragraph compositionRectangle top) asFloat /
			(self scrollRectangleHeight max: 1) asFloat *
				self scrollBarOnlyArea height asFloat) rounded!

updateMarker
	"A variation of moveMarker--only redisplay the marker in the scrollbar
	if an actual change has occurred in the positioning of the paragraph."

	| newMarkerRegion |
	newMarkerRegion _ self computeMarkerRegion.
	newMarkerRegion extent ~= marker region extent
		ifTrue: 
			[self markerRegion: newMarkerRegion.
			self moveMarker]! !

!ParagraphEditor methodsFor: 'sensor access'!

processBlueButton
	"The user pressed the view button on the mouse.  Determine what action to take."

	^self!

processKeyboard
	"Determine whether the user pressed the keyboard.  If so, read the keys."
	sensor keyboardPressed
		ifTrue: [self readKeyboard]!

processMouseButtons
	"Determine whether the user pressed any mouse button.  For each possible
	button, determine what actions to take."

	sensor redButtonPressed ifTrue: [self processRedButton].
	sensor yellowButtonPressed ifTrue: [self processYellowButton].
	sensor blueButtonPressed ifTrue: [self processBlueButton]!

processRedButton
	"The user pressed the select mouse button, meaning create a new text selection.
	Highlighting the selection is carried out by the paragraph itself.  Double
	clicking causes a selection of the area between the nearest enclosing delimitors;
	extension is based on both ends if different."

	| selectionBlocks |
	self deselect.
	self closeTypeIn.
	selectionBlocks _ paragraph mouseSelect: startBlock to: stopBlock.
	selectionShowing _ true.
	startBlock _ selectionBlocks at: 1.
	stopBlock _ selectionBlocks at: 2.
	self updateMarker.
	self setEmphasisHere!

processYellowButton
	"User pressed the operate button on the mouse.  Determine what
	actions to take."

	self yellowButtonActivity! !

!ParagraphEditor methodsFor: 'accessing'!

copySelection: aText
	"Set the current selection to be aText."

	CurrentSelection _ UndoSelection _ aText!

text
	"Answer the text of the paragraph being edited."

	^paragraph text! !

!ParagraphEditor methodsFor: 'displaying'!

display
	"Redisplay the receiver's paragraph."

	| selectionState |
	selectionState _ selectionShowing.
	self deselect.
	paragraph displayOn: Display.
	selectionState ifTrue: [self select]!

displayAt: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm 	
	"Redisplay the paragraph starting at aDisplayPoint, clipped by the rectangle,
	clipRectangle.  The characters are displayed with respect to the rule, ruleInteger, and
	the mask, aForm."
	self deselect.
	paragraph
		displayOn: Display
		at: aDisplayPoint
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm.
	self select! !

!ParagraphEditor methodsFor: 'menu messages'!

accept
	"Save the current text of the text being edited as the current acceptable
	version for purposes of canceling."
	initialText _ paragraph text copy!

again
	"Text subsititution.  If the left shift key is down, the substitution is made 
	throughout the entire Paragraph.  Otherwise, only the next possible 
	subsitution is made."

	| many |
	many _ sensor leftShiftDown.
	self deselect.
	self closeTypeIn.
	self select.
	many
		ifTrue: [[self againOnce] whileTrue]
		ifFalse: [self againOnce ifFalse: [self flash]].
	self moveMarker!

align
	"Align text according to the next greater alignment value--cycling among
	left flush, right flush, center, justified."

	self deselect.
	paragraph toggleAlignment.
	paragraph displayOn: Display.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self select!

cancel
	"Restore the text of the paragraph to be the text saved since initialization or
	the last accept."

	self controlTerminate.
	UndoSelection _ paragraph text.
	view clearInside.
	self changeParagraph: (paragraph text: initialText).
	paragraph displayOn: Display.
	self scrollToTop.
	self controlInitialize!

changeFont
	"Display menu of fonts and change selection to the choice."

	| choice fontArray menu |
	fontArray _ paragraph textStyle fontArray.
	menu _ PopUpTextMenu parseFromArray:
				((1 to: fontArray size) collect: [:i |
					Array with: (Text string: (fontArray at: i) name emphasis: i)
							with: i]).
	menu textStyle: paragraph textStyle.
	choice _ menu startUp.
	choice = 0 ifTrue: [^self].
	self deselect.
	startBlock stringIndex = stopBlock stringIndex
		ifTrue: 
			[emphasisHere _ choice.
			^self select].
	self replaceSelectionWith: 
				(Text string: self selection asString emphasis: choice).
	self closeTypeIn.
	self select!

changeTextStyle
	"Display menu of text styles and change to the choice."

	|styles choice|
	styles _ TextStyle styles asSortedCollection.
	choice _(PopUpMenu labelList: (Array with: styles)) startUp.
	choice = 0 ifTrue: [^self].
	paragraph textStyle: (TextStyle styleNamed: (styles at: choice)).
	paragraph
		recomposeIn: (view insetDisplayBox insetBy: view paragraphInset)
		clippingBox: view insetDisplayBox.
	self display!

copySelection
	"Copy the current selection and store it in the shared buffer."
	CurrentSelection _ UndoSelection _ self selection.
	sensor leftShiftDown
		ifTrue: [self class putExternalSelection: CurrentSelection asString].
	self addPreviousSelection: CurrentSelection!

cut
	"Remove the current selection and place it in the paste buffer"

	self deselect.
	self replaceSelectionWith: Text new.
	self selectAndScroll.
	self updateMarker.
	CurrentSelection _ UndoSelection copy.
	sensor leftShiftDown
		ifTrue: [self class putExternalSelection: CurrentSelection asString].
	self addPreviousSelection: CurrentSelection!

fit
	"Make the bounding rectangle of the paragraph contain all the text while not 
	changing the width of the view of the paragraph."

	self deselect.
	paragraph clearVisibleRectangle.
	paragraph fit.
	paragraph displayOn: Display.
	paragraph outline.
	self select.
	self updateMarker!

hardcopy
	"Print out my text"

	| document dateTime |
	self controlTerminate.
	dateTime _ Time dateAndTimeNow.
	Cursor wait
		showWhile: 
			[document _ Document new.
			document doFooter: true
					  footerString: ('Xanadu Operating Company Proprietary   ---   ',
					  			   (dateTime at: 1) printString,
					  			   ' at ', (dateTime at: 2) printString) 
					  doPageNumbers: true.
			document startParagraph.
			document addText: self text under: paragraph textStyle.
			document close.
			document toPrinter].
	self controlInitialize.!

paste
	"Paste the text from the shared buffer over the current selection and redisplay 
	if necessary. If the left shift key is down, present the user with a menu of
	the last few selections."

	| menuSelection textToPaste |
	sensor leftShiftDown
		ifTrue: 
			["self addPreviousSelection: self class getExternalSelection asText."
			"I removed this because it takes 30+ seconds on the Sun -- ravi"
			menuSelection _
				(PopUpMenu labelList: (Array with: (PreviousSelections collect:
								[:aText | (aText string contractTo: 60)
									collect: [:char | char isSeparator
											ifTrue: [$ ]
											ifFalse: [char]]]))) startUp.
			menuSelection = 0 ifTrue: [^self].
			textToPaste _ CurrentSelection _ PreviousSelections at: menuSelection.
			self promotePreviousSelectionAt: menuSelection]
		ifFalse: [textToPaste _ CurrentSelection].
	self addPreviousSelection: self selection.  "add the text being removed to buffer"
	self performPasteAction: textToPaste	"so subclasses can do other paste-like actions"!

performPasteAction: aString
	"Here we perform the default paste action for paragraphs.  Any subclass of us
	can choose to override this default in favor of some other paste-like action."

	self deselect.
	self closeTypeInAndSelectIf: false.
	self replaceSelectionWith: aString.
	self selectAndScroll.
	self updateMarker.!

promotePreviousSelectionAt: index 
	"Make the PreviousSelection at index be the first item on the 
	PreviousSelections list."

	| aText |
	aText _ PreviousSelections at: index.
	PreviousSelections removeAtIndex: index.
	PreviousSelections addFirst: aText!

undo
	"Reset the state of the paragraph prior to the previous cut or paste edit."

	self deselect.
	self closeTypeIn.
	self replaceSelectionWith: UndoSelection.
	self selectAndScroll.
	self updateMarker! !

!ParagraphEditor methodsFor: 'editing'!

accept: characterStream key: aChar
	"Save the current text of the text being edited as the current acceptable
	version for purposes of canceling."

	self accept.
	^true!

again: characterStream key: aChar
	"Redo the last edit"

	self again.
	^true!

backspace: characterStream key: aChar 
	"Backspace over the last character--i.e., cut the previous character."

	| startIndex |
	startBlock stringIndex < stopBlock stringIndex
		ifTrue: 
			[self cut.
			^true]
		ifFalse: 
			[characterStream isEmpty
				ifTrue: 
					[startIndex _ 1 max: startBlock stringIndex - 1.
					startBlock _ paragraph characterBlockForIndex: startIndex.
					beginTypeInBlock _ paragraph characterBlockForIndex: (beginTypeInBlock
stringIndex min: startIndex).
					self cut.
					^true]
				ifFalse: [characterStream skip: -1].
			^false]!

backwardCharacter: characterStream key: aChar
	"Jump typing cursor backward over a character"
	| startIndex |
	startIndex _ startBlock stringIndex.
	self deselect.
	startBlock stringIndex = stopBlock stringIndex 
		ifTrue: [stopBlock _ startBlock _ paragraph characterBlockForIndex: startIndex-1]
		ifFalse: [stopBlock _ startBlock _ paragraph characterBlockForIndex: startIndex].
	self select.
	^ true!

backWord: characterStream key: aChar
	"Backspace over the last word--i.e., cut the last word.  Initiated by ctrl w"

	| startIndex |
	characterStream isEmpty
		ifFalse: 
			[self replaceSelectionWith: 
				(Text string: characterStream contents emphasis: emphasisHere).
			startBlock _ stopBlock copy.
			characterStream reset].
	startIndex _ 1 max: startBlock stringIndex - 1.
	[startIndex > 1 and: [(paragraph text at: startIndex - 1) asCharacter tokenish]]
		whileTrue: [startIndex _ startIndex - 1].
	startBlock _ paragraph characterBlockForIndex: startIndex.
	beginTypeInBlock _ 
		paragraph characterBlockForIndex: 
				(beginTypeInBlock stringIndex min: startIndex).
	^false!

cancel: characterStream key: aChar
	"Restore the text of the paragraph to be the text saved since initialization or
	the last accept."

	self cancel.
	^true!

changeEmphasis: characterStream key: aChar
	"Change the emphasis of the current selection or prepare to accept characters with the change in emphasis.  Emphasis change amounts to a font change."

	| oldCode newCode  |
	
	oldCode _ paragraph text emphasisAt: startBlock stringIndex.
	((newCode _ FontKeys indexOf:  (aChar asciiValue)) = 0)
		ifTrue:	[newCode _ self emphasisDefault: oldCode keyedTo: aChar].
	(((paragraph textStyle isFontUnderlined: oldCode)
		and: [aChar ~= CtrlShiftMinus		"--unUnderline"])
			and: [aChar ~= Ctrlx				"clear emphasis"])
		ifTrue:	["If font being replaced was underlined, use underlined version
					of new font, unless unUnderline has just been struck"
				newCode _ paragraph textStyle underlinedFontFor: newCode].

	startBlock stringIndex = stopBlock stringIndex
	  ifTrue:  "only change emphasisHere while typing"
		[emphasisHere _ newCode.
		self select.
		^true].
	self replaceSelectionWith:
		(Text string: self selection asString emphasis: (newCode max: 1)).
	self closeTypeIn.
	self select.
	^true!

copy: characterStream key: aChar
	"Copy the current text selection."

	self copySelection.
	^true!

cr: characterStream key: aChar 
	"A carriage return character is to be added to the stream of 
	characters."

	^self normalCharacter: characterStream key: aChar!

cut: characterStream key: aChar
	"Cut out the current text selection."

	self cut.
	^true!

displayDate: characterStream key: aChar
	"Replace the current text selection with today's date--initiated by ctrl d."

	characterStream nextPutAll: Date today printString.
	^false!

displayIfFalse: characterStream key: aChar
	"Replace the current text selection with the text 'ifFalse:'--initiated by ctrl f."

	characterStream nextPutAll: 'ifFalse:'.
	^false!

displayIfTrue: characterStream key: aChar
	"Replace the current text selection with the text 'ifTrue:'--initiated by ctrl t."

	characterStream nextPutAll: 'ifTrue:'.
	^false!

enclose: characterStream key: aChar
	"Insert or remove bracket characters around the current
selection.
	If null selection, then make a pair of brackets with
cursor inside."

	| dChar left right startIndex stopIndex which text
oldSelection |
	dChar _ aChar asciiValue.
	characterStream reset.
	self deselect.
	startIndex _ startBlock stringIndex.
	stopIndex _ stopBlock stringIndex.
	which _ EncloseKeys indexOf: dChar.
	left _ '([<{"''({<''"' at: which.
	right _ ')]>}"'')}>''"' at: which.
	text _ paragraph text.
	((startIndex > 1 and: [stopIndex <= text size])
		and:
		[(text at: startIndex-1) = left and: [(text at:
stopIndex) = right]])
		ifTrue:
			["already enclosed; strip off brackets"
			oldSelection _ self selection.
			self selectFrom: startIndex-1 to: stopIndex; deselect.
			self replaceSelectionWith: oldSelection.
			self selectFrom: stopIndex-1 to: stopIndex-2]
		ifFalse:
			["not enclosed; enclose by matching brackets"
			self selectAt: startIndex; deselect.
			self setEmphasisHere.
			self replaceSelectionWith: (Text string: (String with:
left)
						emphasis: emphasisHere).
			self selectAt: stopIndex+1; deselect.
			self setEmphasisHere.
			self replaceSelectionWith: (Text string: (String with:
right)
						emphasis: emphasisHere).
			self selectFrom: stopIndex+1 to: stopIndex].
	^ true!

forwardCharacter: characterStream key: aChar
	"Jump typing cursor forward over a character"
	| stopIndex |
	stopIndex _ stopBlock stringIndex.
	self deselect.
	stopBlock stringIndex = startBlock stringIndex 
		ifTrue: [startBlock _ stopBlock _ paragraph characterBlockForIndex: stopIndex+1]
		ifFalse: [startBlock _ stopBlock _ paragraph characterBlockForIndex: stopIndex].
	self select.
	^ true!

indentedCR: characterStream key: aChar
	"Replace the current text selection with a CR plus 
	the number of tabs and spaces found at the beginning of 
	the current line"

	| text index character whiteString |
	"Construct text, which is the body of text up to the current position."
	text _ (paragraph text copyFrom: 1 to: startBlock stringIndex - 1)
				, characterStream contents asText.
	"Sniff backwards along text string till CR or beginning of string."
	index _ text size + 1.
	character _ nil.
	[character = CR or: [index = 1]]
		whileFalse: 
			[index _ index - 1.
			character _ text at: index].
	"Special exit for immediate encounter of CR or string beginning."
	(text size = index) | ( text size = 0)
		ifTrue: 
			[characterStream nextPut: CR.
			^false"keep scanning"].
	"Now accunmulate whitespace into whiteString till first non-white  
	character, or end of string."
	whiteString _ String with: CR.
	character == CR ifTrue: [index _ index + 1].
	character _ text at: index.
	[character = Tab | (character = Space) & (index <= text size)]
		whileTrue: 
			[whiteString _ whiteString , (String with: character).
			index _ index + 1.
			index <= text size ifTrue: [character _ text at: index]].
	characterStream nextPutAll: whiteString.
	^false "keep scanning"!

leaveBrackets: characterStream key: aChar
	"Jump typing cursor over a close-bracket character"
	| stopIndex nextChar |
	stopBlock character notNil
		ifTrue:	[stopIndex _ stopBlock stringIndex.
				nextChar _ paragraph text at: stopIndex.
				(')]>}"''' includes: nextChar) ifFalse: [^false].
				self deselect.
				startBlock _ stopBlock _ paragraph characterBlockForIndex: stopIndex+1.
				self select]
		ifFalse:	[self select].
	^ true!

normalCharacter: characterStream key: aChar
	"A nonspecial character is to be added to the stream of characters."

	characterStream nextPut: aChar.
	^false!

paste: characterStream key: aChar
	"Replace the current text selection by the text in the shared buffer."

	self paste.
	^true!

readKeyboard
	"Read the keyboard and bring the characters into a type ahead stream."

	| typeAhead currentCharacter|
	self deselect.
	typeAhead _ WriteStream on: (String new: 128).
	beginTypeInBlock == nil
		ifTrue: 
			[UndoSelection _ self selection.
			beginTypeInBlock _ startBlock copy].
	[sensor keyboardPressed]
		whileTrue: 
			[CurrentEvent _ sensor keyboardEvent.
			currentCharacter _ CurrentEvent keyCharacter.
			(self perform: (Keyboard at: currentCharacter asciiValue + 1)
				 with: typeAhead with: currentCharacter)
				ifTrue: [^self]].
	self replaceSelectionWith:
		(Text string: typeAhead contents emphasis: emphasisHere).
	startBlock _ stopBlock copy.
	self selectAndScroll!

selectCurrentTypeIn: characterStream key: aChar
	"The user just finished typing in some text and then typed the esc key.  The
	typed text becomes the current text selection."

	CurrentEvent hasCtrl ifTrue: [^self enclose: characterStream key: aChar].
	characterStream isEmpty
		ifTrue: 
			[self deselect]
		ifFalse: 
			[self replaceSelectionWith: 
				(Text string: characterStream contents emphasis: emphasisHere).
			startBlock _ stopBlock copy].
	self closeTypeIn.
	startBlock = stopBlock 
		ifFalse: [startBlock _ 
					paragraph characterBlockForIndex: 
						stopBlock stringIndex - CurrentSelection size].
	self select.
	^true!

tab: characterStream key: aChar
	"A tab character is to be added to the stream of characters."

	CurrentEvent  hasCtrl
		ifTrue: [^self changeEmphasis: characterStream key: aChar]
		ifFalse: [^self normalCharacter: characterStream key: aChar]!

undo: characterStream key: aChar
	"Reset the state of the paragraph prior to the previous cut or paste edit."

	self undo.
	^true! !

!ParagraphEditor methodsFor: 'selecting'!

deselect
	"If the text selection is visible on the screen, reverse its highlight."
	selectionShowing ifTrue: [self reverseSelection]!

findAndSelect: aString
	"Search for the text aString in the text model and highlight it."

	| index |
	index _ paragraph text findString: aString startingAt: stopBlock stringIndex.
	index = 0 ifTrue: [^false].
	self selectAndScrollFrom: index to: index + aString size-1.
	^true!

initializeSelection
	"Do the initial activity when starting up the receiver.  For example, in the
	ParagraphEditor highlight the current selection."
	self select!

properSelectionEnds
	"Like selectionEnds, but not screwed up"

	^stopBlock stringIndex -1!

recomputeSelection
	"eg after changing the composition rectangle of the paragraph"
	self deselect.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	selectionShowing_ false!

reverseSelection
	"Reverse the valence of the current selection highlighting."

	selectionShowing _ selectionShowing not.
	startBlock = stopBlock
		ifTrue: [paragraph displayCaretAt: 
					startBlock topLeft + (0 @ paragraph textStyle baseline)]
		ifFalse: [paragraph reverseFrom: startBlock to: stopBlock]!

select
	"If the text selection is visible on the screen, highlight it."

	selectionShowing ifFalse: [self reverseSelection]!

selectAndScroll
	"Scroll until the selection is in the view and then highlight it."

	| lineHeight deltaY clippingRectangle |
	lineHeight _ paragraph textStyle lineGrid.
	clippingRectangle _ paragraph clippingRectangle.
	deltaY _ stopBlock top - clippingRectangle top.
	deltaY >= 0 
		ifTrue: [deltaY _ stopBlock bottom - clippingRectangle bottom max: 0].
						"check if stopIndex below bottom of clippingRectangle"
	deltaY ~= 0 
		ifTrue: [self scrollBy: (deltaY abs + lineHeight - 1 truncateTo: lineHeight)
									* deltaY sign].
	self select!

selectAndScrollFrom: start to: stop
	"Make the selection the text from start to stop in the paragraph.
	Scroll until the selection is in the view and then highlight it."

	self deselect.
	startBlock _ paragraph characterBlockForIndex: start.
	stopBlock _ paragraph characterBlockForIndex: stop + 1.
	self selectAndScroll!

selectAt: characterIndex 
	"Place the character before the character at position characterIndex.  Make
	certain the selection is in the view."

	self deselect.
	startBlock _ paragraph characterBlockForIndex: characterIndex.
	stopBlock _ startBlock copy.
	self selectAndScroll!

selectFrom: start to: stop
	"The text selection starts at the character at position start and ends at the
	character at position stop."

	self deselect.
	startBlock _ paragraph characterBlockForIndex: start.
	stopBlock _ paragraph characterBlockForIndex: stop+1.
	self select!

selection
	"Answer the text in the paragraph that is currently selected."
	^paragraph text copyFrom: startBlock stringIndex to: stopBlock stringIndex - 1!

selectionAsStream
	"Answer a ReadStream on the text in the paragraph that is currently selected."
	^ReadStream
		on: paragraph text asString
		from: startBlock stringIndex
		to: stopBlock stringIndex - 1!

selectionEnds
	"Answer the text in the paragraph that is currently selected."

	| tIdx |
	(tIdx _ stopBlock stringIndex) > 1
		ifTrue: [^tIdx - 1]
		ifFalse: [^1]!

selectionStarts
	^ startBlock stringIndex! !

!ParagraphEditor methodsFor: 'indicating'!

flash
	"Causes the view of he paragraph to complement twice in succession."
	paragraph flash! !

!ParagraphEditor methodsFor: 'copying'!

copy
	"Answer a copy of the receiver that goes one level deeper into the 
	paragraph. "

	| p c |
	p _ paragraph.
	paragraph _ paragraph copy.
	c _ super copy.
	paragraph _ p.
	^c! !

!ParagraphEditor methodsFor: 'private: private'!

addPreviousSelection: aText 
	"Save away a selection for use by leftShift-paste. Don't save it if it's 
	already on the list, or if it is all white space. Save only a few."

	(PreviousSelections includes: aText)
		ifTrue: [^self].
	(aText detect: [:aChar | aChar isSeparator not] ifNone: [nil]) == nil
		ifTrue: [^self].
	PreviousSelections size >= 7 ifTrue: [PreviousSelections removeLast].
	PreviousSelections addFirst: aText!

againOnce
	| nextStartIndex |
	nextStartIndex _ 
		paragraph text findString: UndoSelection startingAt: stopBlock stringIndex.
	nextStartIndex = 0 ifTrue: [^false].
	self deselect.
	startBlock _ paragraph characterBlockForIndex: nextStartIndex.
	stopBlock _ paragraph characterBlockForIndex: nextStartIndex + UndoSelection size.
	CurrentSelection = UndoSelection
		ifFalse: [self replaceSelectionWith: CurrentSelection].
	self selectAndScroll.
	^true!

closeTypeIn
	^ self closeTypeInAndSelectIf: true!

closeTypeInAndSelectIf: aBoolean
	beginTypeInBlock ~~ nil
		ifTrue: 
			[(beginTypeInBlock < startBlock) & aBoolean
				ifTrue:
					[CurrentSelection _ 
								paragraph text 
									copyFrom: beginTypeInBlock stringIndex 
									to: startBlock stringIndex - 1.
					startBlock _ beginTypeInBlock copy.
					self addPreviousSelection: CurrentSelection].
			beginTypeInBlock _ nil.
			^true]
		ifFalse: [^false]!

emphasisDefault: oldEmphasisCode keyedTo: keyboardCharacter
	"Some default ways to get common forms of emphasis -- returns a new emphasis code.  Subroutine for changeEmphasis.  If anyone else uses, please note here."

	keyboardCharacter = CtrlMinus					"underline"
		ifTrue:	[^ paragraph textStyle underlinedFontFor: oldEmphasisCode].
	keyboardCharacter = CtrlShiftMinus				"unUnderline"
		ifTrue:	[^ paragraph textStyle unUnderlinedFontFor: oldEmphasisCode].
	keyboardCharacter = Ctrlb						"Bold"
		ifTrue:	[^ paragraph textStyle boldFontFor: oldEmphasisCode].
	keyboardCharacter = CtrlB						"unBold"
		ifTrue:	[^ paragraph textStyle basalFontFor: oldEmphasisCode].
	keyboardCharacter = Ctrli						"Italic"
		ifTrue:	[^ paragraph textStyle italicFontFor: oldEmphasisCode].
	keyboardCharacter = CtrlI						"unItalic"
		ifTrue:	[^ paragraph textStyle basalFontFor: oldEmphasisCode].
	keyboardCharacter = Ctrlx						"clear emphasis, go to basal font"
		ifTrue:	[^ paragraph textStyle basalFontFor: oldEmphasisCode].!

replaceSelectionWith: aText
	beginTypeInBlock == nil ifTrue: [UndoSelection _ self selection].
	paragraph
		replaceFrom: startBlock stringIndex
		to: stopBlock stringIndex - 1
		with: aText
		displaying: true.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ 
		paragraph characterBlockForIndex: startBlock stringIndex + aText size!

scrollRectangleHeight
	^paragraph compositionRectangle height 
		+ paragraph clippingRectangle height 
		- paragraph lineGrid!

setEmphasisHere
	emphasisHere _ paragraph text emphasisAt: startBlock stringIndex!

yellowButtonMenu
	"Default menu for text pane of all paragraph editors."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept para)! !

!ParagraphEditor methodsFor: 'smalltalk: passe'!

fontMenu: characterStream key: aChar
	"Show a menu of the available fonts, and change the selected range to the chosen font"

	self passe!

initializeYellowButtonMenu
	"Default menu for text pane of all paragraph editors."
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ParagraphEditor class
	instanceVariableNames: ''!


!ParagraphEditor class methodsFor: 'class initialization'!

initialize
	"Initialize the yellow button menu information, the keyboard map for special
	control characters, and the shared buffers for copying text across views and
	managing undo."

	CurrentSelection _ UndoSelection _ Text new.
	PreviousSelections _ OrderedCollection new.
	self initializeDispatchTable!

initializeDispatchTable
	"Initialize the keyboard dispatch table"

	"ParagraphEditor initializeDispatchTable."


	Keyboard _ Array new: 256.
	Keyboard atAllPut: #normalCharacter:key:.
	Keyboard at: $z asciiValue - $_ asciiValue		put: #undo:key:. "ctrl-z"
	Keyboard at: $x asciiValue - $_ asciiValue		put: #backspace:key:.
	Keyboard at: 248 + 1 "ctrl-shift-x"			put: #backspace:key:.
	Keyboard at: $c asciiValue - $_ asciiValue		put: #copy:key:.
	Keyboard at: $v asciiValue - $_ asciiValue		put: #paste:key:.
	Keyboard at: 246 + 1 "ctrl-shift-v"			put: #paste:key:.
	Keyboard at: 127 + 1 "del"						put: #backspace:key:.
	Keyboard at: Tab asciiValue + 1				put: #tab:key:.	
	Keyboard at: CR asciiValue + 1				put: #indentedCR:key:.
	Keyboard at: BS asciiValue + 1				put: #backspace:key:.
	Keyboard at: $w asciiValue - $_ asciiValue	put: #backWord:key:.
	Keyboard at: 255 + 1 "ctrl-BS"				put: #backWord:key:.
	Keyboard at: $t asciiValue - $_ asciiValue		put: #displayIfTrue:key:.
	Keyboard at: $f asciiValue - $_ asciiValue		put: #displayIfFalse:key:.
	Keyboard at: $d asciiValue - $_ asciiValue		put: #displayDate:key:.
	Keyboard at: $s asciiValue - $_ asciiValue		put: #accept:key:. "Save - heh"
	Keyboard at: $q asciiValue - $_ asciiValue		put: #cancel:key:. "cancel - heh (qill)"
	Keyboard at: $a asciiValue - $_ asciiValue		put: #again:key:.
	Keyboard at: 225 + 1 "ctrl-shift-a"			put: #again:key:.
	
	FontKeys do: [:i | Keyboard at: i + 1 put: #changeEmphasis:key:].
	"Keyboard at: Ctrlv asciiValue + 1 put: #fontMenu:key:."

	Keyboard at: CtrlMinus asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: CtrlShiftMinus asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: Ctrlb asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: CtrlB asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: CtrlI asciiValue + 1 put: #changeEmphasis:key:.	
	"Keyboard at: Ctrlx asciiValue + 1 put: #changeEmphasis:key:."
	
	EncloseKeys _ #(200 27 220 251 194 199 15 16 10 11 12). "add ctrl-o,p,j,k,l"
	EncloseKeys do: [:i | Keyboard at: i + 1 put: #enclose:key:].
	Keyboard at: $n asciiValue - $_ asciiValue		put: #leaveBrackets:key:.
	Keyboard at: ESC asciiValue + 1				put: #selectCurrentTypeIn:key:.
	Keyboard at: $p asciiValue - $_ asciiValue		put: #backwardCharacter:key:.
	Keyboard at: $n asciiValue - $_ asciiValue		put: #forwardCharacter:key:.! !

!ParagraphEditor class methodsFor: 'instance creation'!

new
	"Answer a new instance of me with a null Paragraph to be edited."
	^ self newParagraph: '' asParagraph!

newParagraph: aParagraph 
	"Answer an instance of me with aParagraph as the text to be edited. "

	| aParagraphEditor |
	aParagraphEditor _ super new.
	aParagraphEditor changeParagraph: aParagraph.
	^aParagraphEditor! !

!ParagraphEditor class methodsFor: 'selection access'!

currentSelection
	"Answer the current selection."

	^CurrentSelection!

getExternalSelection: data
	| sel |
	sel _ self getExternalSelectionOrNil: data.
	^sel isNil ifTrue: [''] 
			ifFalse: [IOAccessor convertStringFromPlatform: sel]!

putExternalSelection: sel
	^self putExternalSelection: (IOAccessor convertStringForPlatform: sel)
		 with: nil! !

!ParagraphEditor class methodsFor: 'dispatch table access'!

dispatchTable
	"Answer the keyboard dispatch table."

	^Keyboard! !

!ParagraphEditor class methodsFor: 'private: private-selection access'!

getExternalSelection
	^self getExternalSelection: nil!

getExternalSelectionOrNil: data
	<primitive: 700>
	^nil!

putExternalSelection: sel with: data
	<primitive: 701>
	^self primitiveFailed! !

ParagraphEditor initialize!
