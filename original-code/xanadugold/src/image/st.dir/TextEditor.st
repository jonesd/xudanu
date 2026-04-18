'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:57 pm'!

ParagraphEditor subclass: #TextEditor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-TextEditor'!
TextEditor comment:
'Instance of class TextEditor holds a TextCompositor instead of a Paragraph.  After replacing text, it eliminates characterBlock scanning for getting startBlock and stopBlock.  Because it receives a stopBlock from a TextCompositor, the startBlock''s characterIndex and topLeft position which are used for selection have not been changed even after replacing text.  The scroll bar behaves differently from that of the superclass.  The scroll frame represents the length of the document and the gray box occupies a region according to portion of character size visible in the compositionRectangle.  The scroll amount is determined by size of characters to move.'!


!TextEditor methodsFor: 'initialize-release'!

changeCompositor: aCompositor
	"Install aCompositor as the receiver's instance variable."

	paragraph _ aCompositor.
	self resetState! !

!TextEditor methodsFor: 'scrolling'!

scrollAbsolute

	| oldMarker delta newMarkerRegion oldCursorY cursorY offsetY |
	oldCursorY _ marker center y.
	self canScroll ifTrue: [Cursor marker showWhile:
		[[sensor anyButtonPressed] whileTrue:
			[oldMarker _ marker copy.
			cursorY _ sensor cursorPoint y.
			delta _ ((marker center y - cursorY) asFloat / scrollBar inside height asFloat 
						* (paragraph textSize max: 1) asFloat) truncated.
			(oldCursorY - cursorY) * delta <= 0 ifTrue: [delta _ 0].
			self scrollView: delta.
			oldCursorY _ cursorY.
			newMarkerRegion _ self computeMarkerRegion.
			offsetY _ (((paragraph lines at: 1) - 1) asFloat 
							/ (paragraph textSize max: 1) asFloat 
								* scrollBar inside height asFloat) rounded 
									min: scrollBar inside height - newMarkerRegion height. 
			marker region: (marker left@(scrollBar inside top + offsetY) extent: newMarkerRegion corner).
			(oldMarker areasOutside: marker), (marker areasOutside: oldMarker) do:
				[:region | Display fill: region rule: Form reverse mask: Form gray]].
		scrollBar display.
		self moveMarker]]!

scrollAmount

	^paragraph lineLength - 1 min: (((sensor cursorPoint y - self scrollBarOnlyArea top) asFloat 
				/ paragraph lineGrid asFloat) truncated max: 1)!

scrollBy: charsToMove 
	"Move the paragraph by the amount, charsToMove, and reset the text selection." 

	self deselect.
	paragraph scrollBy: charsToMove.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self select!

scrollDown
	Cursor down showWhile:
	[self canScroll
		ifTrue: 
			[self scrollViewDown.
			self updateMarker].
	sensor waitNoButton]!

scrollToTop
	"Scroll so that the paragraph is at the top of the view."

	self scrollView: (paragraph lines at: 1)!

scrollUp
	Cursor up showWhile:
	[self canScroll
		ifTrue: 
			[self scrollViewUp.
			self updateMarker].
	sensor waitNoButton]!

scrollView: anInteger
 
	| maximumAmount minimumAmount amount |
	maximumAmount _ 
		(paragraph lines at: 1) max: 0.
	minimumAmount _ 
		(paragraph lines at: 1) - paragraph textSize - 1 min: 0.
	amount _ (anInteger min: maximumAmount) max: minimumAmount.
	amount ~= 0
		ifTrue:
			[self deselect.
			self scrollBy: amount negated.
			self select].!

scrollViewDown
	"Scroll the receiver's view down the default amount."
	
	self deselect. 
	paragraph scrollDown: self scrollAmount.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self select!

scrollViewUp
	"Scroll the receiver's view up the default amount."
	
	self deselect. 
	paragraph scrollUp: self scrollAmount.
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self select!

viewDelta

	^(paragraph lines at: 1) - 1 
		- ((marker top - self scrollBarOnlyArea top) asFloat 
				/ self scrollBarOnlyArea height asFloat * (paragraph textSize max: 1) asFloat) truncated! !

!TextEditor methodsFor: 'marker adjustment'!

computeMarkerRegion
	"Answer the rectangular area in which the gray area of the scroll bar
	should be displayed."

	paragraph textSize = 0
		ifTrue:	
			[^0@0 extent: 10 @ self scrollBarOnlyArea height]
		ifFalse:	
			[^0@0 extent: 10 @ 
				((((paragraph nextChar - (paragraph lines at: 1)) asFloat 
						/ (paragraph textSize max: 1) asFloat 
							* self scrollBarOnlyArea height asFloat) rounded max: 4) 	
						min: self scrollBarOnlyArea height)]!

markerDelta
	^marker top - self scrollBarOnlyArea top 
		- (((paragraph lines at: 1) - 1) asFloat / 
				(paragraph textSize max: 1) asFloat *
					self scrollBarOnlyArea height asFloat) rounded!

updateMarker
	"Redisplay the marker in the scrollbar."

	| newMarkerRegion |
	newMarkerRegion _ self computeMarkerRegion.	
	newMarkerRegion extent ~= marker region extent
		ifTrue: 
			[self markerRegion: newMarkerRegion.
			self moveMarker].
	self markerDelta = 0 ifFalse: [self moveMarker]! !

!TextEditor methodsFor: 'displaying'!

display
	"Show the paragraph of the receiver on the display screen."

	| selectionState |
	selectionState _ selectionShowing.
	self deselect.
	paragraph displayOn: Display.
	self recomputeSelection.
	selectionState ifTrue: [self select]! !

!TextEditor methodsFor: 'menu messages'!

cancel
	"Restore the text of the paragraph to be the text saved since initialization or
	the last accept."

	self controlTerminate.
	UndoSelection _ paragraph text.
	view clearInside.
	paragraph resetState.
	self changeCompositor: (paragraph text: initialText).
	paragraph displayOn: Display.
	self scrollToTop.
	self controlInitialize! !

!TextEditor methodsFor: 'editing'!

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
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	self closeTypeIn.
	self select.
	^true! !

!TextEditor methodsFor: 'selecting'!

find: aString
	"Locate aString in the text of the receiver."

	| index |
	index _ paragraph text findString: aString startingAt: stopBlock stringIndex.
	index = 0 ifTrue: [^false].
	startBlock _ startBlock stringIndex: index.
	stopBlock _ stopBlock stringIndex: index + aString size.
	^true!

{void} findInterval: interval {Interval}

	startBlock _ startBlock stringIndex: interval first.
	stopBlock _ stopBlock stringIndex: interval last + 1!

indexOfSelection
	"Answer the index of the current selection."

	^startBlock stringIndex!

reverseSelection
	"Reverse the valence of the current selection highlighting."

	selectionShowing _ selectionShowing not.
	startBlock = stopBlock
		ifTrue: [paragraph displayCaretAt: 
					stopBlock topLeft + (0 @ paragraph textStyle baseline)]
		ifFalse: [paragraph reverseFrom: startBlock to: stopBlock]!

selectAndScroll
	"Scroll until the selection is in the view and then highlight it."

	| first start stop |
	first _ paragraph lines at: 1.
	start _ startBlock stringIndex.
	stop _ stopBlock stringIndex.
	(stop between: first and: paragraph nextChar)
		ifTrue: 
			[(paragraph crIsLast and: [paragraph lastLine = paragraph lineLength 
					and: [stop = paragraph nextChar 
							and: [paragraph textSize + 1 >= paragraph nextChar]]])
				ifTrue: [paragraph scrollUp: 1.
						startBlock _ paragraph characterBlockForIndex: start.
						stopBlock _ paragraph characterBlockForIndex: stop].
			(start >= first and: [startBlock top < paragraph compositionRectangle top])
				ifTrue: [startBlock _ paragraph characterBlockForIndex: start]
			]
		ifFalse:
			[stop > paragraph nextChar
				ifTrue: 
					[start <= first 
						ifTrue: [paragraph setTopPosition: start]
						ifFalse: [paragraph setBottomPosition: stop]]
				ifFalse: [paragraph setTopPosition: start].
			startBlock _ paragraph characterBlockForIndex: start.
			stopBlock _ paragraph characterBlockForIndex: stop].
	self select!

selectAndScrollUp
	"Scroll up until the selection is in the view and then highlight it."

	| first start stop |
	first _ paragraph lines at: 1.
	start _ startBlock stringIndex.
	stop _ stopBlock stringIndex.
	(stop between: first and: paragraph nextChar)
		ifTrue: 
			[(paragraph crIsLast and: [paragraph lastLine = paragraph lineLength 
					and: [stop = paragraph nextChar 
							and: [paragraph textSize + 1 >= paragraph nextChar]]])
				ifTrue: [paragraph scrollUp: 1.
						startBlock _ paragraph characterBlockForIndex: start.
						stopBlock _ paragraph characterBlockForIndex: stop].
			(start >= first and: [startBlock top < paragraph compositionRectangle top])
				ifTrue: [startBlock _ paragraph characterBlockForIndex: start]
			]
		ifFalse:
			[paragraph scrollUpPosition: stop.
			startBlock _ paragraph characterBlockForIndex: start.
			stopBlock _ paragraph characterBlockForIndex: stop].
	self select! !

!TextEditor methodsFor: 'updating'!

replaceSelectionWith: aText

	beginTypeInBlock == nil ifTrue: [UndoSelection _ self selection].
	stopBlock _ paragraph
					replaceFrom: startBlock stringIndex
					to: stopBlock stringIndex - 1
					with: aText.
	stopBlock == nil 
		ifTrue: 
			[startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
			stopBlock _ paragraph characterBlockForIndex: startBlock stringIndex + aText size]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextEditor class
	instanceVariableNames: ''!


!TextEditor class methodsFor: 'instance creation'!

new
	"Answer a new instance of the receiver with a null Paragraph to be edited."
	| aTextCompositor |
	aTextCompositor _ TextCompositor new.
	aTextCompositor text: '' asText.
	^ self newCompositor: aTextCompositor!

newCompositor: aCompositor 
	"Answer an instance of the receiver with aParagraph as the text to be edited."

	| aTextEditor |
	aTextEditor _ super new.
	aTextEditor changeCompositor: aCompositor.
	^aTextEditor! !