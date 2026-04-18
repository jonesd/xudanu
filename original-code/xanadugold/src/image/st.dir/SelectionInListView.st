'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:41 pm'!

ListView subclass: #SelectionInListView
	instanceVariableNames: 'itemList printItems oneItem partMsg initialSelectionMsg changeMsg listMsg menuMsg '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Lists'!
SelectionInListView comment:
'SelectionInListView is a "pluggable" ListView. The notion of pluggable views is an experiment in user interface design. The idea is to provide a view which can be plugged onto any object, rather than having to define a new subclass specific to every kind of object which needs to be viewed. The chief mechanism is a set of selectors, which can be thought of as an adaptor to convert the generic listView operations (such as changeSelection) into model-specific operations (such as fileName:). An added feature of this listView is that it tries to preserve its selection through changes in the choice list. This effect, and also the choice of an intial selection are transmitted to the model just as a user-requested selection would be. See the protocol ''adaptor'' for use of the pluggable selectors. See the creation messages in my class for an explication of the various parameters. Browse senders of the creation messages in the class for examples in the system.

Instance Variables:
	itemList		<Array of: Strings>
	printItems	<Boolean> 
	oneItem		<Boolean>
	partMsg	<Symbol> message to send to find out about the changed aspect of the instance
	initialSelectionMsg	<Symbol> message to send to find out which item in the list is the initially selected one
	changeMsg	<Symbol> message to send to find out what changed
	listMsg	<Symbol> message to send to obtain the printable list
	menuMsg 	<Symbol> message to send to find out the menu '!


!SelectionInListView methodsFor: 'initialize-release'!

on: anObject printItems: flag1 oneItem: flag2
		aspect: m1 change: m3 list: m4 menu: m5 initialSelection: m6
	"Set the instance variables for the receiver."

	self model: anObject.
	printItems _ flag1.
	oneItem _ flag2.
	partMsg _ m1.
	changeMsg _ m3.
	listMsg _ m4.
	menuMsg _ m5.
	initialSelectionMsg _ m6.
	oneItem ifTrue:
		[self noTopDelimiter noBottomDelimiter.
		initialSelectionMsg == nil
			ifTrue: [self error: 'initialSelection must be specified for oneItem mode']].
	self list: self getList! !

!SelectionInListView methodsFor: 'list access'!

list: anArray 
	"Set the receiver's list to be anArray."

	| item theList |
	itemList _ anArray.
	anArray == nil
		ifTrue:  
			[isEmpty _ true.
			selection _ 0.
			^self changeModelSelection: 0].
	isEmpty _ false.
	printItems
		ifTrue: 
			[theList _ anArray collect: 
				[:each || strm |
				strm _ TextStream on: String new.
				strm print: each.
				strm contents" copyUpTo: Character cr"]]
		ifFalse: [theList _ anArray].
	list _ TextList onList: (topDelimiter == nil
					ifTrue: [theList]
					ifFalse: [(Array with: topDelimiter)
							, theList , (Array with: bottomDelimiter)]).
	item _ self initialSelection.
	selection _ (item == nil or: [item == NULL])
				ifTrue: [0]
				ifFalse: [itemList findFirst: [:x | x = item or: [x isString
								and: 
									[| i |
									i _ 1.
									[(x at: i) isSeparator]
										whileTrue: [i _ i + 1].
									i ~= 1 and: [(x copyFrom: i to: x size) asString = item asString]]]]].
	self positionList.
	self changeModelSelection: selection! !

!SelectionInListView methodsFor: 'adaptor'!

changeModelSelection: anInteger
	"Reset the selected item/model to be the item at location anInteger in the list."

	changeMsg ~~ nil ifTrue:
		[model perform: changeMsg with:
			(anInteger = 0 ifTrue: [nil] ifFalse: [itemList at: anInteger])]!

getList 
	"Answer the list to be displayed."

	| item |
	oneItem ifTrue:
		[item _ self initialSelection.
		item == nil ifTrue: [^ nil].
		^ Array with: item].
	listMsg == nil ifTrue: [^nil].
	^ model perform: listMsg!

initialSelection
	"Set the initial item to be selected."

	initialSelectionMsg == nil ifTrue: [^ nil].
	^ model perform: initialSelectionMsg!

yellowButtonMenu
	"Answer the menu to display when the operate button menu is 
	pressed."

	menuMsg == nil ifTrue: [^nil].
	^model perform: menuMsg! !

!SelectionInListView methodsFor: 'controller access'!

defaultControllerClass
	^ SelectionInListController! !

!SelectionInListView methodsFor: 'updating'!

update: aSymbol 
	aSymbol == partMsg
		ifTrue: ["aSymbol == #className ifTrue: [self halt]." 
			self list: self getList.
			self topView isCollapsed ifFalse: [self displaySafe: [self displayView]]].
	aSymbol == #empty
		ifTrue: [self resetAndDisplayView]! !

!SelectionInListView methodsFor: 'displaying'!

displayView
	isEmpty
		ifTrue: [self clearInside]
		ifFalse: [super displayView]! !

!SelectionInListView methodsFor: 'testing'!

isEmpty
	"Answer whether the receiver contains any elements."

	^ isEmpty! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectionInListView class
	instanceVariableNames: ''!


!SelectionInListView class methodsFor: 'instance creation'!

on: anObject
	aspect: aspectMsg change: changeMsg list: listMsg menu: menuMsg initialSelection: sel
	"Create a 'pluggable' listView viewing anObject.
	aspectMsg is sent to read the value of the current selection.
		It is also used as the changed: parameter for this view.
	changeMsg is sent to inform anObject of a new selection.
	listMsg is sent to read the current list which should be displayed.
	menuMsg is sent to read the yellowButton menu for this view.
	initialSelection is sent to read a selection to be selected initailly as a default."

	^ self new on: anObject printItems: false oneItem: false
		aspect: aspectMsg change: changeMsg list: listMsg menu: menuMsg initialSelection: sel!

on: anObject printItems: flag1 oneItem: flag2
	aspect: aspectMsg change: changeMsg list: listMsg menu: menuMsg initialSelection: sel
	"Create a listView with these parameters - see comment in on:aspect:change: . . .
	Moreover, if printItems is true, then the view will show the printStrings of the
		items in the list, rather than assuming they are already text-like objects.
	And if oneItem is true the list works as a read-only list of one item.  this is mainly
		used for the root list of various sub-browsers spawned from the browser."

	^ self new on: anObject printItems: flag1 oneItem: flag2
		aspect: aspectMsg change: changeMsg list: listMsg menu: menuMsg initialSelection: sel! !