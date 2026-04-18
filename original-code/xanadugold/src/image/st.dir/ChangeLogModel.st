'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:04 pm'!

Model subclass: #ChangeLogModel
	instanceVariableNames: '
		myModel {UNKNOWN}
		myKey {UNKNOWN}
		myChange {UNKNOWN}
		myReference {UNKNOWN}
		myComputeBetterCompare {UNKNOWN}
		myBetterCompareCache {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log'!



!ChangeLogModel methodsFor: 'initialize'!

on: model {Dictionary of: Symbol and: (OrderedCollection of: ChangeRecord)}

	myModel _ model.
	myKey _ nil.
	myChange _ nil.
	myReference _ nil.
	myComputeBetterCompare _ false! !

!ChangeLogModel methodsFor: 'doIt/accept/explain'!

acceptText: aText from: aController
	"Text has been changed."

	myChange == nil
		ifTrue: [^ false]
		ifFalse: [^ myChange acceptText: aText from: aController]!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^ nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^ nil!

doItValue: ignored
	"Set the value to be returned when the interrupted process proceeds."!

explainSpecial: string 
	^ nil! !

!ChangeLogModel methodsFor: 'key list'!

hide
	myKey == nil ifTrue: [^nil].
	myModel removeKey: myKey.
	self newKeyList: nil!

hideKey
	| sorted index next |
	sorted _ myModel asSortedCollection.
	index _ (sorted indexOf: (myModel associationAt: myKey)) + 1.
	index <= sorted size
		ifTrue: [next _ (sorted at: index) key]
		ifFalse: [next _ nil].
	myModel removeKey: myKey.
	self newKeyList: next!

keyList
	^ myModel keys asSortedCollection!

keyMenu
	myKey == nil ifTrue:
		[^nil].
	^PopUpMenu fromArray: #(
		('hide'		hide		'Xu: Hide the selected element.'))!

keyName
	^ myKey!

keyName: key
	myKey _ key.
	(key == #one or: [key == nil]) ifTrue:
		[myChange _ myReference _ nil]
	ifFalse:
		[| changes |
		changes _ myModel at: myKey.
		myChange _ changes first.
		myReference _ changes at: (changes size min: 2)].
	self changed: #changeName!

newKeyList: initial

	myKey _ initial.
	self changed: #keyName.! !

!ChangeLogModel methodsFor: 'change list'!

changeList

	myKey == nil
		ifTrue: [^ nil]
		ifFalse: [^ (myModel at: myKey) collect: [ :record | self makeChangeRep: record]]!

changeMenu
	"Menu for Xanadu-style history browser."
	| menuArray compareArray |
	
	myChange == nil ifTrue: [^ nil].

	menuArray _ #(('previous'		previous		'Xu: Change the selection to the previous definition of the thing currently selected.')
		('reference'		reference		'Xu: Make the currently selected thing a reference for making comparisons.')
		('switch'		switch			'Xu: Swap current selection with reference.')
		('no reference'	noReference	'Xu: Get rid of the reference (so text display isn''t cluttered with difference marks).')
		('history'		history		'Xu: look at the history of the method back to some specified fork')).

	
	(myChange isKindOf: MethodRelatedCR) 
	   ifTrue: [menuArray _ #(
		('spawn method'	spawnMethod		'Xu: Create a MethodBrowser on the selected method.') 
		-
		), menuArray].

	compareArray _ myComputeBetterCompare
		ifTrue: [#(- ('faster compare'		computeBetterCompare		'Xu: compute a comparison faster'))]
		ifFalse: [#(- ('better compare'		computeBetterCompare		'Xu: compute a more useful comparison'))].
	menuArray _ menuArray, compareArray.

	^PopUpMenu fromArray: menuArray!

changeName

	^ self makeChangeRep: myChange!

changeName: selection

	myChange _ selection ~~ nil ifTrue: [selection record].
	self changed: #text.!

newChangeList: initial

	myChange _ initial.
	self changed: #changeName.! !

!ChangeLogModel methodsFor: 'text'!

text
	myChange == nil ifTrue:
		[^Text new]
	ifFalse: [myReference == nil
		ifTrue: [^myChange changesString asText]
		ifFalse:
			[myComputeBetterCompare 
				ifFalse: [^myChange changesString differences: myReference changesString]
				ifTrue:
					[^self differenceFrom: myChange changesString to: myReference changesString]]]!

textMenu

	myChange == nil ifTrue: [^nil].
	^PopUpMenu standardCodeMenu.! !

!ChangeLogModel methodsFor: 'private: private-menu messages'!

computeBetterCompare
	myComputeBetterCompare _ myComputeBetterCompare not.
	self changed: #text!

history
	myChange ~~ nil ifTrue:
		[ChangeLog browseAll: myChange identifiers
			from: myChange logPosition
			backTo: (ChangeLog choose: #FORK from: myChange logPosition backTo: -1)]!

makeChangeRep: aChangeRecord
	^ ChangeRecordRep create: aChangeRecord with: (aChangeRecord == myReference ifTrue: [2] ifFalse: [1])!

noReference
	| temp |
	myReference _ nil.
	temp _ myChange.
	myChange _ nil.
	self changed: #changeName.
	myChange _ temp.
	self changed: #changeName.
	self changed: #text.!

previous
	"go back to the previous superceded record"
	
	| previous |
	previous _ myChange recorder fetch: myChange previous.
	((myModel at: myKey) includes: previous)
		ifTrue: [^ self newChangeList: previous]
		ifFalse: [^ nil]!

reference
	"make the selected one the reference model"
	
	myReference _ myChange.
	myChange _ nil.
	self changed: #changeName.
	myChange _ myReference.
	self changed: #changeName.
	self changed: #text.!

selectedClass

	(myChange == nil or: [(myChange isKindOf: ClassRelatedCR) not]) ifTrue: [^ nil].
	((myChange isKindOf: ClassOrMetaRelatedCR) and: [myChange meta])
		ifTrue: [^ (Smalltalk at: myChange className ifAbsent: [^ nil]) class]
		ifFalse: [^ Smalltalk at: myChange className ifAbsent: [^ nil]]!

spawnEdits: aText from: aController
	| newController | 
	myChange == nil ifTrue: [^ nil].
	newController _ aController copy.  "Copy gets the changes"
	aController cancel; controlTerminate.   "Cancel changes in spawning browser"
	ChangeLogModel openSimpleOn: (Array with: myChange) withController: newController.!

{NOWAIT} spawnMethod

	| cls {Behavior} rep {MethodRep} coll {Collection of: MethodRep} |
	(myChange isKindOf: MethodRelatedCR) assert.
	cls _ Smalltalk at: myChange className.
	cls isBehavior assert.
	myChange meta
		ifTrue: [cls _ cls class].
	rep _ MethodRep make: cls with: myChange selector.
	coll _ OrderedCollection new.
	coll add: rep.
	(EnumerateMethods make: coll with: rep printString) browse: rep!

switch
	"switch the selected and the reference"
	| temp |
	(myChange == nil or: [myReference == nil]) ifTrue:
		[^ false].
	temp _ myReference.
	myReference _ myChange.
	myChange _ temp.
	self changed: #changeName.! !

!ChangeLogModel methodsFor: 'comparing'!

differenceFrom: startString to: endString
	(myBetterCompareCache notNil and: [myBetterCompareCache matches: startString with: endString])
		ifTrue: [^myBetterCompareCache emphasize: startString]
		ifFalse: 
			[myBetterCompareCache _ (TextLCSFinder make: startString with: endString) fillInTable.
			^myBetterCompareCache emphasize: startString]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeLogModel class
	instanceVariableNames: ''!



!ChangeLogModel class methodsFor: 'instance creation'!

openOn: records {Dictionary of: Symbol and: (OrderedCollection of: ChangeRecord)}

	^ self openOn: records label: 'Change Log'!

openOn: records {Dictionary of: Symbol and: (OrderedCollection of: ChangeRecord)} label: label {String}

	| view model cv |
	records isEmpty ifTrue: [^ Transcript cr; show: 'Nobody'].
	model _ self new on: records.
	view _ StandardSystemView model: model
		label: label
		minimumSize: 200 @ 200.
	view addSubView: (SelectionInListView
			on: model
			aspect: #keyName
			change:  #keyName:
			list: #keyList
			menu: #keyMenu
			initialSelection: #keyName)
		in: (0@0 extent: 0.3@0.3)
		borderWidth: 1.
	view addSubView: (SelectionInListView
			on: model
			printItems: true
			oneItem: false
			aspect: #changeName
			change:  #changeName:
			list: #changeList
			menu: #changeMenu
			initialSelection: #changeName)
		in: (0.3@0 extent: 0.7@0.3)
		borderWidth: 1.
	view addSubView: (cv _ CodeView
			on: model
			aspect: #text
			change: #acceptText:from:
			menu: #textMenu
			initialSelection: nil)
		in: (0@0.3 extent: 1@0.7)
		borderWidth: 1.
	cv controller: AlwaysAcceptCodeController new.
	view controller open.!

openSimpleOn: records {OrderedCollection of: ChangeRecord}

	self openSimpleOn: records label: 'Change Log'!

openSimpleOn: records {OrderedCollection of: ChangeRecord} label: label {String}

	| dict view model cv |
	records isEmpty ifTrue: [^ Transcript cr; show: 'Nobody'].
	dict _ IdentityDictionary new.
	dict at: #one put: records.
	model _ self new on: dict.
	model keyName: #one.
	view _ StandardSystemView model: model
		label: label
		minimumSize: 200 @ 200.
	view addSubView: (SelectionInListView
			on: model
			printItems: true
			oneItem: false
			aspect: #changeName
			change:  #changeName:
			list: #changeList
			menu: #changeMenu
			initialSelection: #changeName)
		in: (0@0 extent: 1@0.3)
		borderWidth: 1.
	view addSubView: (cv _ CodeView
			on: model
			aspect: #text
			change: #acceptText:from:
			menu: #textMenu
			initialSelection: nil)
		in: (0@0.3 extent: 1@0.7)
		borderWidth: 1.
	cv controller: AlwaysAcceptCodeController new.
	view controller open.!

openSimpleOn: records {OrderedCollection of: ChangeRecord} label: label {String} withController: aController

	| dict view model subview |
	records isEmpty ifTrue: [^ Transcript cr; show: 'Nobody'].
	dict _ IdentityDictionary new.
	dict at: #one put: records.
	model _ self new on: dict.
	model keyName: #one.
	view _ StandardSystemView model: model
		label: label
		minimumSize: 200 @ 200.
	view addSubView: (SelectionInListView
			on: model
			printItems: true
			oneItem: false
			aspect: #changeName
			change:  #changeName:
			list: #changeList
			menu: #changeMenu
			initialSelection: #changeName)
		in: (0@0 extent: 1@0.3)
		borderWidth: 1.
	view addSubView: (subview _ CodeView
			on: model
			aspect: #text
			change: #acceptText:from:
			menu: #textMenu
			initialSelection: nil)
		in: (0@0.3 extent: 1@0.7)
		borderWidth: 1.
	subview controller: aController.
	view controller open.!

openSimpleOn: records {OrderedCollection of: ChangeRecord} withController: aController

	self openSimpleOn: records label: 'Change Log' withController: aController! !