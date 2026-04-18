'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:22 pm'!

StringHolder subclass: #ChangeList
	instanceVariableNames: 'listName changes selectionIndex list filter removed filterList filterKey changeDict doItDict checkSystem fieldList '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Changes'!
ChangeList comment:
'Class ChangeList knows how to scan a changes file and produce Change objects from it.  It also functions as a model for a ListView.

Instance Variables:
	listName <String>  label for browser, the set of files that have been read 
	changes <OrderedCollection of: Change>  the underlying collection of changes 
	selectionIndex <Integer>  currently selected change, or 0 if none 
	currentChange <String>  text of current selection 
	list <OrderedCollection of: Change>  filtered collection of changes 
	filter <BlockContext>  filter predicate 
	removed <Set>  removed changes 
	filterList <nil | Array of: Symbol>  individual filters
	filterKey <Change>  the change supplying the key value(s) for the filter(s) 
	changeDict <Dictionary from: Symbol to: (OrderedCollection of: Change)>  cross-index for conflict detection 
	doItDict <Dictionary from: String to: (OrderedCollection of: Change)>  cross-index for conflict detection 
	fieldList <nil | Array of: Symbol>  individual field options
	'!


!ChangeList methodsFor: 'initialize-release'!

initialize
	super initialize.
	listName _ ''.
	changes _ OrderedCollection new.
	list _ OrderedCollection new.
	selectionIndex _ 0.
	filter _ [:change | true].
	removed _ Set new.
	filterList _ #().
	fieldList _ #()!

recoverFile: aFileStream
	"Recover all the changes from a .changes file since the last snapshot."

	| position |
	position _ self findLast: '''----SNAPSHOT----''!!' in: aFileStream.
	position isNil
		ifTrue: [position _ 0].
	aFileStream position: position.
	self scanFile: aFileStream!

release
	"Break BlockContext cycles."

	filter _ nil.
	filterList _ #()!

scanFile: aFileStream
	"Obtain changes from aFileStream."

	ChangeScanner new scanFile: aFileStream do: [:change | changes add: change].
	listName size = 0
		ifTrue: [listName _ aFileStream name]
		ifFalse: [listName _ listName, ' ..'].
	self updateList!

scheduleMessageBrowser
	"Create and schedule a browser on the changed messages."

	| change |
	selectionIndex > 0 ifTrue:
		[change _ list at: selectionIndex.
		(change isKindOf: MethodDefinitionChange) ifTrue:
			[^BrowserView openListBrowserOn: (Array with: change name) label: 'current definition']].
	^nil! !

!ChangeList methodsFor: 'accessing'!

addChangeSet: aChangeSet
	"The changed message list of the argument aChangeSet is added as part of the receiver's list of changes."

	self addChanges: aChangeSet changedMessageList!

filterCopy
	"Answer a list of all the items not marked for removal."
	
	^self class new listName: '(', self listName, ')' changes: list removed: (list select: [:c | removed includes: c])!

hasRemoved: index
	"Answer whether the item at position index has been marked for removal.  Answer false if position index is outside the boundaries of the receiver's list."
	
	^index > 0 and: [index <= list size and: [removed includes: (list at: index)]]!

list
	"Answer an OrderedCollecton of Change items in the change list."

	| name v |
	^list collect:
		[:c |
		name _ nil.
		fieldList do:
			[:f |
			f == nil ifFalse:
				[v _ c perform: f.
				v == nil ifFalse:
					[name == nil ifTrue: [name _ WriteStream on: (String new: 50)].
					name nextPut: $(; nextPutAll: v; nextPutAll: ') ']]].
		name == nil ifTrue: [c name] ifFalse: [name nextPutAll: c name.  name contents]]!

listName
	"Answer the label for a browser on the receiver.  The default is Changes."
	
	listName size = 0
		ifTrue: [^'Changes']
		ifFalse: [^listName]!

listSize
	"Answer the number of items in the receiver."

	^list size! !

!ChangeList methodsFor: 'selecting'!

contents: aString
	"Set the receiver's message selector to be item."

	"ignore"!

deselect
	"If the receiver has a selection, then it is highlighted.  Remove the highlighting."
	selectionIndex _ 0.
	contents _ ''!

listIndex
	"Answer the position of the current selection."

	^selectionIndex!

selection
	"Answer the text of the item currently selected."

	selectionIndex > 0 ifTrue: [^(list at: selectionIndex) text]!

toggleListIndex: anInteger
	"If the item at position anInteger is selected, deselect it, or vice versa."

	selectionIndex = anInteger
		ifTrue:
			[self deselect]
		ifFalse:
			[selectionIndex _ anInteger.
			contents _ self selection].
	self changed: #listIndex! !

!ChangeList methodsFor: 'filtering'!

hasFilter: index
	"Answer whether one of the receiver's filters is set to on."

	^index <= filterList size and: [(filterList at: index) notNil]!

switchFilter: index perform: aSymbol
	"Set the action aSymbol to be the action associated with the filter 
	denoted by index (the position in the list of filters)."


	index > filterList size
		ifTrue:
			[filterList _ filterList , (Array new: index - filterList size)].
	(filterList at: index) isNil
		ifTrue:
			[selectionIndex > 0 ifTrue:
				[filterKey _ list at: selectionIndex.
				filterList at: index put: aSymbol]]
		ifFalse:
			[filterList at: index put: nil].
	self updateList! !

!ChangeList methodsFor: 'checking'!

checkWith: aConflictChecker 
	"For each item in the list that is not removed, check to see if there is 
	a conflict with other items."

	list do: [:change | (removed includes: change)
			ifFalse: [change checkWith: aConflictChecker]]!

checkWithSystem: aBoolean
	changeDict _ Dictionary new.
	doItDict _ Dictionary new.
	checkSystem _ aBoolean.
	list do: [:change |
		(removed includes: change) ifFalse: [change checkWith: self]]! !

!ChangeList methodsFor: 'checking-change'!

addDoIt: aChange
	| fileName |
	fileName _ aChange fileName.
	(doItDict at: fileName ifAbsent: [doItDict at: fileName put: OrderedCollection new])
		add: aChange!

changesAt: changeName
	^changeDict at: changeName ifAbsent: [#()]!

changesAt: changeName add: aChange
	(changeDict at: changeName ifAbsent: [changeDict at: changeName put: OrderedCollection new])
		add: aChange!

checkSystem
	^checkSystem!

equalWithoutComments: text1 and: text2
	| stream1 stream2 t |
	stream1 _ ReadStream on: text1.
	stream2 _ ReadStream on: text2.
	[(t _ self nextNonComment: stream1) = (self nextNonComment: stream2)]
		whileTrue:
			[t == nil ifTrue: [^true]].
	^false! !

!ChangeList methodsFor: 'checking-reporting'!

reportConflictsByClassWithExtension: extension
	"report conflicts among the changes"
	self reportChangesOn: nil extension: extension.
	^self finishReportOn: (Filename named: 'DoIts', extension) writeStream!

reportConflictsOn: aStream
	"report conflicts among the changes"
	self reportChangesOn: aStream extension: nil.
	^self finishReportOn: aStream! !

!ChangeList methodsFor: 'fileIn/Out'!

doThis
	selectionIndex > 0 ifTrue: [(list at: selectionIndex) fileIn]!

doThis: listIndex
	(list at: listIndex) fileIn!

fileOutOn: aFile
	| previous current |
	current _ previous _ nil.
	list do:
		[:next |
		(removed includes: next) ifFalse:
			[current == nil
				ifFalse: [current fileOutOn: aFile previous: previous next: next].
			previous _ current.
			current _ next]].
	current == nil ifFalse:
		[current fileOutOn: aFile previous: previous next: nil]! !

!ChangeList methodsFor: 'lock access'!

isUnlocked
	^true!

lock
	"ignore"!

unlock
	"ignore"! !

!ChangeList methodsFor: 'private: private'!

addFilter: aSymbol
	| value oldFilter |
	value _ filterKey perform: aSymbol.
	filter isNil
		ifTrue: [filter _ [:change | (change perform: aSymbol) = value]]
		ifFalse:
			[oldFilter _ filter.
			filter _ [:change | (oldFilter value: change) and: [(change perform: aSymbol) = value]]]!

findLast: aString in: aStream
	"Return the position in the stream of the end of the last occurrence of aString (presumably a snapshot message)"
	| firstChar endPosition position count index lastEnd |
	firstChar _ aString first.
	aStream setToEnd.
	position _ aStream position.
	lastEnd _ nil.
	[endPosition _ position.
	lastEnd == nil and: [(position _ endPosition - 5000 max: 0) < endPosition]]
		whileTrue:
			[aStream position: position.
			count _ endPosition - position.
			[count > 0]
				whileTrue:
					[count _ count - 1.
					aStream next == firstChar
						ifTrue:
							[index _ 2.
							[index <= aString size and: [(aString at: index) = aStream next]]
								whileTrue: [index _ index + 1].
							index > aString size
								ifTrue: [lastEnd _ aStream position]
								ifFalse: [aStream position: endPosition - count]]]].
	^lastEnd!

findLast: aString in: aStream before: pos
	"Return the position in the stream of the end of the last occurrence of aString (presumably a snapshot message)"
	| firstChar endPosition position count index lastEnd |
	firstChar _ aString first.
	aStream position: pos.
	position _ aStream position.
	lastEnd _ nil.
	[endPosition _ position.
	lastEnd == nil and: [(position _ endPosition - 5000 max: 0) < endPosition]]
		whileTrue:
			[aStream position: position.
			count _ endPosition - position.
			[count > 0]
				whileTrue:
					[count _ count - 1.
					aStream next == firstChar
						ifTrue:
							[index _ 2.
							[index <= aString size and: [(aString at: index) = aStream next]]
								whileTrue: [index _ index + 1].
							index > aString size
								ifTrue: [lastEnd _ aStream position]
								ifFalse: [aStream position: endPosition - count]]]].
	^lastEnd!

listName: aString changes: aChangeCollection removed: aSet
	listName _ aString.
	changes addAll: aChangeCollection.
	list addAll: aChangeCollection.
	removed addAll: aSet!

showingField: index
	^index <= fieldList size and: [(fieldList at: index) notNil]!

switchField: index perform: aSymbol
	index > fieldList size
		ifTrue:
			[fieldList _ fieldList , (Array new: index - fieldList size)].
	(fieldList at: index) isNil
		ifTrue:
			[fieldList at: index put: aSymbol]
		ifFalse:
			[fieldList at: index put: nil].
	self updateSelection: selectionIndex!

updateList
	| oldChange newIndex |
	selectionIndex > 0 ifTrue: [oldChange _ list at: selectionIndex].
	filter _ nil.
	filterList do: [:aSymbol | aSymbol notNil ifTrue: [self addFilter: aSymbol]].
	filter isNil ifTrue: [filter _ [:change | true]].
	list _ changes select: [:change | filter value: change].
	newIndex _
		oldChange == nil
			ifTrue: [0]
			ifFalse: [list indexOf: oldChange].
	self updateSelection: newIndex!

updateSelection: newIndex
	self deselect.
	self changed: #list.
	newIndex > 0 ifTrue:
		[self toggleListIndex: newIndex]! !

!ChangeList methodsFor: 'private: private-checking'!

finishReportOn: aStream
	"report conflicts among the changes"
	
	doItDict associationsDo:
		[:aDoIt |
		aStream cr; nextChunkPut: '"*** DoIts in ', aDoIt key, ' ***"'; cr; cr.
		aDoIt value do:
			[:doit | self tabText: doit text on: aStream] ].

	aStream isEmpty ifTrue:
		[Transcript show: '*** no conflicts ***'.
		aStream nextChunkPut: '"*** no conflicts ***"'; cr].
	^aStream close!

identifySubset: contendors name: change on: reportStream extension: extension 
	"report conflicts among the changes--if all of the changes are
	textually identical, there are no conflicts, so don't do a report"

	| matched |
	matched _ true.
	1 to: contendors size - 1 do: 
		[:i | 
		| firstText |
		matched ifTrue:
			[firstText _ (contendors at: i) text.
			i + 1 to: contendors size do: 
				[:j | 
				| secondText |
				secondText _ (contendors at: j) text.
				matched _ matched and: [firstText = secondText]]]].
	matched
		ifFalse: 
			[| aStream oldText |
			aStream _ reportStream.
			extension == nil ifFalse: [aStream _ (Filename named: ((change copyUpTo: $ )
								copyWithout: $ )
								, extension) appendStream].
			aStream cr; nextChunkPut: '"*** conflict: ' , change , ' ***"'; cr.
			oldText _ '...'.
			contendors do: [:contendor | oldText _ self
							writeContendor: contendor
							on: aStream
							oldText: oldText].
			extension == nil ifFalse: [aStream close]]!

nextNonComment: sourceStream
	"Return the next item from the sourceStream (assumed not
atEnd),
	carefully ignoring comments and separators."

	| aChar sepr |
	sepr _ false.
	[true]
		whileTrue:
			[sourceStream atEnd ifTrue: [^nil].
			aChar _ sourceStream peek.
			aChar = $$ ifTrue: [sourceStream next.  ^sourceStream
next].	"catch chars/strings"
			aChar = $' ifTrue: [^String readFrom: sourceStream].
			aChar = $"
				ifTrue: [sourceStream next; skipThrough: $".  sepr _
true]
				ifFalse:
					[aChar isSeparator
						ifTrue: [sourceStream skipSeparators.  sepr _ true]
						ifFalse: [sepr ifTrue: [^Character space].
								sourceStream next.
								^aChar]]]!

reportChangesOn: reportStream extension: extension 
	"report conflicts among the changes"

	| contendors |
	changeDict keys asSortedCollection do: 
		[:change | 
		contendors _ changeDict at: change.
		contendors size > 1
			ifTrue: [self
				identifySubset: contendors
				name: change
				on: reportStream
				extension: extension]]!

tabText: text on: aStream
	"report conflicts among the changes"
	| cr previous terminator |
	cr _ Character cr.
	terminator _ $!!.
	previous _ cr.
	text do:
		[:aChar |
		aChar = cr ifFalse: [previous = cr ifTrue: [aStream
tab]].
		aStream nextPut: (previous _ aChar).
		aChar = terminator ifTrue: [aStream nextPut: aChar]].
	aStream nextPut: terminator; cr!

writeContendor: source on: aStream oldText: oldText
	"write out the change"

	| text method endComment code |
	aStream cr; nextChunkPut: '"File: ', source fileName, '"'; cr.
	text _ source text.
	(source isKindOf: MethodDefinitionChange) ifFalse:
		[self tabText: text on: aStream.
		^oldText].
	method _ ReadStream on: text.
	method skipSeparators; skipThrough: Character cr; skipSeparators. 	"skip header"
	(method peekFor: $")
		ifTrue:
			[method skipThrough: $"; skipSeparators].
	endComment _ method position.
	code _ method nextChunk.
	(self equalWithoutComments: code and: oldText)
		ifTrue:
			[method reset.
			aStream cr; nextPutAll: (method next: endComment);
					nextPutAll: '[SAME CODE AS ABOVE]'; cr]
		ifFalse:
			[aStream cr; nextChunkPut: text; cr].
	^code! !

!ChangeList methodsFor: 'private: private-changing'!

addChanges: changedMessages
	ChangeScanner new scanChangedMessages: changedMessages do: [:change | changes add: change].
	self updateList! !

!ChangeList methodsFor: 'private: private-menu messages'!

forget
	changes _ changes select: [:c | (removed includes: c) not].
	removed _ Set new.
	self updateList!

removeAll
	removed addAll: list!

restoreAll
	list do: [:change | removed remove: change ifAbsent: []]!

restoreCurrent
	selectionIndex > 0 ifTrue:
		[removed remove: (list at: selectionIndex) ifAbsent: []]! !

!ChangeList methodsFor: 'removing'!

removeCurrent
	selectionIndex > 0
		ifTrue: 
			[removed add: (list at: selectionIndex).
			"selectionIndex = list size
				ifFalse: 
					[self toggleListIndex: selectionIndex + 1]"]!

removePrevious
	selectionIndex > 0 ifTrue:
		[1 to: selectionIndex - 1 do: [:each | removed add: (list at: each)]]!

restorePrevious
	selectionIndex > 0 ifTrue: 
		[1 to: selectionIndex - 1 do: [:each | removed remove: (list at: each) ifAbsent: []]]! !