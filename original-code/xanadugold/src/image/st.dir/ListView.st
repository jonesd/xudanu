'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:40 pm'!

View subclass: #ListView
	instanceVariableNames: 'list selection topDelimiter bottomDelimiter lineSpacing isEmpty emphasisOn '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Lists'!
ListView comment:
'Class ListView is an abstract class representing a list of items.  It provides support for storing a selection of one item, as well as formatting the list for presentation on the screen.  The default controller is ListController.

Instance Variables:
	list				<Array> of Strings, each one an item
	selection		<Integer> index into the array, list
	topDelimiter	<String>, usually  ------------, indicating the top of the list
	bottomDelimiter	<String>, usually  ------------, indicating the bottom of the list
	lineSpacing		<Integer> the amount of extra space between line items
	isEmpty			<Boolean> true if the list is empty
	'!


!ListView methodsFor: 'initialize-release'!

initialize
	super initialize.
	insideColor _ Form white.
	topDelimiter _ '------------'.
	bottomDelimiter _ '------------'.
	lineSpacing _ 0.
	isEmpty _ true.
	emphasisOn _ true! !

!ListView methodsFor: 'list access'!

list
	"Answer the list of items the receiver displays."
	^list!

list: itemCollection 
	"Create the textList corresponding to the items in itemCollection."

	isEmpty _ itemCollection isNil.
	list _ TextList onList:
		(topDelimiter == nil
			ifTrue: [itemCollection]
			ifFalse: [(Array with: topDelimiter) ,
					itemCollection ,
					(Array with: bottomDelimiter)]).
	selection _ 0.
	self positionList!

reset
	"Set the list of items displayed to be empty."

	isEmpty _ true.
	self list: Array new!

resetAndDisplayView
	"Set the list of items displayed to be empty and redisplay the receiver."

	isEmpty
		ifFalse: 
			[self reset.
			self displayView]! !

!ListView methodsFor: 'delimiters'!

bottomDelimiter
	"Answer the string used to indicate the bottom of the list."
	^bottomDelimiter!

bottomDelimiter: aString 
	"Set the string used to indicate the bottom of the list."
	bottomDelimiter _ aString!

noBottomDelimiter
	"Set the string used to indicate the bottom of the list to be nothing."
	bottomDelimiter _ nil!

noTopDelimiter
	"Set the string used to indicate the top of the list to be nothing."
	topDelimiter _ nil!

topDelimiter
	"Answer the string used to indicate the top of the list."
	^topDelimiter!

topDelimiter: aString 
	"Set the string used to indicate the top of the list."
	topDelimiter _ aString! !

!ListView methodsFor: 'displaying'!

display
	"Show the list of items on the screen."
	list == nil ifTrue: [self list: Array new].
	self isUnlocked ifTrue: [self positionList].
	super display!

displaySelectionBox
	"If the receiver has a selection and that selection is visible on the display
	screen, then highlight it."
	| selectionRect | 
	(selection == nil) ifTrue: [^ VOID]. "heh - temp repair unknown bug 13 October 1990"
	(selection > 0 and: [self selectionBox intersects: self clippingBox])
		ifTrue:
			[selectionRect _ self selectionBox intersect: self clippingBox.
			emphasisOn
				ifTrue: [Display reverse: selectionRect]
				ifFalse: [Display fill: selectionRect rule: Form reverse mask: Form gray.
						Display fill: (selectionRect insetBy: 1) rule: Form reverse mask: Form gray]]!

displayView
	self clearInside.
	list displayOn: Display.
	self displaySelectionBox! !

!ListView methodsFor: 'deEmphasizing'!

deEmphasizeView
	emphasisOn ifTrue:
		[self deselect.
		emphasisOn _ false.
		self displaySelectionBox]!

emphasizeView
	emphasisOn ifFalse:
		[self deselect.
		emphasisOn _ true.
		self displaySelectionBox]! !

!ListView methodsFor: 'controller access'!

defaultControllerClass
	^ListController! !

!ListView methodsFor: 'display box access'!

boundingBox
	"Answer the rectangular area that represents the boundaries of the 
	receiver's space of information."

	^list boundingBox! !

!ListView methodsFor: 'clipping box access'!

clippingBox
	"Answer the rectangle in which the model can be displayed--this
	is the insetDisplayBox inset by the height of a line for an item."

	^self insetDisplayBox insetBy: 
		(Rectangle
			left: 0
			right: 0
			top: 0
			bottom: self insetDisplayBox height \\ list lineGrid)! !

!ListView methodsFor: 'selecting'!

deselect
	"If the receiver has a selection, then it is highlighted.  Remove the highlighting."
	self displaySelectionBox!

findSelection: aPoint 
	"Determine which selection is displayed in an area containing the point,
	aPoint.  Answer the selection if one contains the point, answer nil otherwise."

	| trialSelection |
	(self clippingBox containsPoint: aPoint) ifFalse: [^nil].
	trialSelection _ aPoint y - list compositionRectangle top // list lineGrid + 1.
	trialSelection < self minimumSelection | (trialSelection > self maximumSelection)
		ifTrue: [^nil]
		ifFalse: [^trialSelection - self minimumSelection + 1]!

isSelectionBoxClipped
	"Answer whether there is a selection and whether the selection is visible
	on the screen."

	^selection ~= 0 & (self selectionBox intersects: self clippingBox) not!

maximumSelection
	"Answer which selection is the last possible one."
	topDelimiter == nil
		ifTrue: [^list numberOfLines]
		ifFalse: [^list numberOfLines - 1]!

minimumSelection
	"Answer which selection is the first possible one."
	topDelimiter == nil
		ifTrue: [^1]
		ifFalse: [^2]!

moveSelectionBox: anInteger 
	"Presumably the selection has changed to be anInteger.  Deselect the
	previous selection and display the new one, highlighted."

	selection ~= anInteger
		ifTrue: 
			[self deselect.
			selection _ anInteger.
			self displaySelectionBox]!

selection
	"Answer the receiver's current selection."
	^selection!

selectionBox
	"Answer the rectangle in which the current selection is displayed."

	^(self insetDisplayBox left @ (list compositionRectangle top + self selectionBoxOffset) 
		extent: self insetDisplayBox width @ list lineGrid)
		insetBy: (Rectangle left: 1 right: 1 top: 0 bottom: 0)!

selectionBoxOffset
	"Answer an integer that determines the y position for the display box of the
	current selection."
	^selection - 1 + self minimumSelection - 1 * list lineGrid! !

!ListView methodsFor: 'updating'!

update: aSymbol 
	aSymbol == #list
		ifTrue: 
			[self list: model list.
			self displaySafe: [self displayView].
			^self].
	aSymbol == #listIndex
		ifTrue: 
			[self moveSelectionBox: model listIndex.
			^self]! !

!ListView methodsFor: 'private: private'!

computeCompositionOrigin
	"Return a new composition rectangle origin positioned correctly in the view's clipping rectangle, such that the currently selected item is visible."

	| origin offset |
	origin _ self insetDisplayBox topLeft + (4@0)	.
	offset _ (selection - 1 + self minimumSelection - 1) * list lineGrid.

	"position selection at top of list"
	^origin x @ (origin y - 
						(offset
							min: ((list height - self insetDisplayBox height 
									+ list lineGrid truncateTo: list lineGrid)
							max: 0)))!

positionList
	|clippingBox translation|
	clippingBox	_ self clippingBox.
	clippingBox extent = list clippingRectangle extent
		ifTrue: [translation _  clippingBox origin - list clippingRectangle origin.
				list clippingRectangle: clippingBox.
				list setCompositionRectangle: (list compositionRectangle translateBy: translation)]
		ifFalse: [list repositionAt: self computeCompositionOrigin clippingBox: self clippingBox]!

wrappingBox
	| aRectangle |
	aRectangle _ self insetDisplayBox. 
	selection = 0
		ifTrue: [^aRectangle topLeft + (4 @ 0) extent: list compositionRectangle extent]
		ifFalse: [^aRectangle left + 4 @ 
					(aRectangle top - 
						(self selectionBoxOffset 
							min: ((list height - aRectangle height 
									+ list lineGrid truncateTo: list lineGrid)
							max: 0))) 
					extent: list compositionRectangle extent]! !