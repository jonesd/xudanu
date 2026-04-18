'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:24 pm'!

ListView subclass: #ChangeListView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Changes'!
ChangeListView comment:
'A ChangeListView is a list view of various system changes.'!


!ChangeListView methodsFor: 'initialize-release'!

release
	model release.
	super release! !

!ChangeListView methodsFor: 'model access'!

model: aChangeList
	super model: aChangeList.
	self list: model list.
	selection _ model listIndex.! !

!ChangeListView methodsFor: 'controller access'!

defaultControllerClass
	^ChangeListController! !

!ChangeListView methodsFor: 'selecting'!

displaySelectionBox
	super displaySelectionBox.
	self reverseRemoved!

reverseRemoved
	"Highlight all of the items that have been marked for removal."

	| box line |
	self selectionInterval do:
		[:index |
		(model hasRemoved: index) ifTrue:
			[box _ self selectionBox: index.
			line _ Rectangle origin: box leftCenter - (0@1) extent: box width @ 2.
			emphasisOn
				ifTrue: [Display reverse: (line intersect: self clippingBox)]
				ifFalse: [Display fill: (line intersect: self clippingBox) rule: Form reverse mask: Form gray]]]!

selectionBox: listIndex
	"Answer the rectangle in which a particular selection is displayed."

	^(self insetDisplayBox left @
			(list compositionRectangle top + (self selectionBoxOffset: listIndex)) 
		extent: self insetDisplayBox width @ list lineGrid)
		insetBy: (Rectangle left: 1 right: 1 top: 1 bottom: 0)!

selectionBoxOffset: listIndex
	"Answer an integer that determines the y position for the display box of a
	particular selection."
	^(listIndex - 1 + self minimumSelection - 1) * list lineGrid!

selectionIndex: yPosition
	"Answer the selection index corresponding to a particular Y coordinate."

	^(yPosition - list compositionRectangle top) // list lineGrid - self minimumSelection + 2!

selectionInterval
	"Answer the currently visible range of selection indices."

	^((self selectionIndex: self insetDisplayBox top) max: 1) to:
	 ((self selectionIndex: self insetDisplayBox bottom) min: model listSize)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeListView class
	instanceVariableNames: ''!


!ChangeListView class methodsFor: 'instance creation'!

open
	"Open a view for changes files.  Starts as an empty template."
	
	self openOn: ChangeList new

	"ChangeListView open"!

openOn: aChangeList
	"schedule a change browser"
	| topView aChangeListView aChangeView alignPoint |
	topView _ StandardSystemView new model: aChangeList.
	topView label: aChangeList listName.
	topView minimumSize: 180@180.
	topView borderWidth: 1.
	topView window: (0@0 extent: 180@410).
	aChangeListView _ self new.
	aChangeListView model: aChangeList.
	aChangeListView window: (0@0 extent: 180@120).
	aChangeListView insideColor: Form white.
	aChangeListView borderWidthLeft: 1 right: 1 top: 1 bottom: 1.
	topView addSubView: aChangeListView.
	alignPoint _ self
		openSwitches:
			#(	('show file' showingField: (1) switchField:perform: (1 fileName) 90)
				('show category' showingField: (2) switchField:perform: (2 category) 90)
			)
		topView: topView
		at: aChangeListView viewport bottomLeft
		model: aChangeList.
	alignPoint _ self
		openSwitches:
			#(	(file hasFilter: (1) switchFilter:perform: (1 file) 30)
				(type hasFilter: (2) switchFilter:perform: (2 class) 30)
				(class hasFilter: (3) switchFilter:perform: (3 baseClassName) 30)
				(category hasFilter: (4) switchFilter:perform: (4 category) 30)
				(selector hasFilter: (5) switchFilter:perform: (5 selector) 30)
				(same hasFilter: (6) switchFilter:perform: (6 values) 30)
			)
		topView: topView
		at: alignPoint
		model: aChangeList.
	aChangeView _ StringHolderView new.
	aChangeView model: aChangeList.
	aChangeView controller: ChangeController new.
	aChangeView window: (0@0 extent: 180@240).
	aChangeView insideColor: Form white.
	aChangeView borderWidthLeft: 1 right: 1 top: 1 bottom: 1.
	topView
		addSubView: aChangeView
		align: aChangeView viewport topLeft
		with: alignPoint.
	topView controller open.!

recover
	"Open a view of the current changes file since the last snapshot."
	
	self openOn: (ChangeList new recoverFile: (Filename named: (SourceFiles at: 2) name) readStream)

	"ChangeListView recover"! !

!ChangeListView class methodsFor: 'examples'!

recoverExample
	"One example of the use of the ChangeList is to view actions taken before a system failure.
	Assuming the file 'fileName.st' contains these actions, this example opens a browser on the
	contents."

	"ChangeListView recoverExample."

	ChangeListView openOn: (ChangeList new recoverFile: (Filename named: 'fileName.st') readStream).! !

!ChangeListView class methodsFor: 'private: private'!

openSwitches: parameters topView: topView at: initialPoint model: aChangeList
	"Define a related group of switches"
	| aSwitchView alignPoint |

	alignPoint _ initialPoint.

	parameters do:
		[:args |
			[:label :viewSelector :viewArguments :controllerSelector :controllerArguments :width |
			aSwitchView _ SwitchView new.
			aSwitchView model: aChangeList.
			aSwitchView controller: LockedSwitchController new.
			aSwitchView borderWidthLeft: 1 right: 1 top: 1 bottom: 1.
			aSwitchView selector: viewSelector.
			aSwitchView arguments: viewArguments.
			aSwitchView controller selector: controllerSelector.
			aSwitchView controller arguments: controllerArguments.
			aSwitchView window: (0 @ 0 extent: width @ 25).
			aSwitchView label: label asParagraph.
			topView addSubView: aSwitchView
				align: aSwitchView viewport topLeft
				with: alignPoint.
			alignPoint _ aSwitchView viewport topRight.
			] valueWithArguments: args].

	^initialPoint x @ aSwitchView viewport bottom! !