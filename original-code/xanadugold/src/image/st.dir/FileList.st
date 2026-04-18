'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:12 pm'!

FileModel subclass: #FileList
	instanceVariableNames: '
		list {UNKNOWN}
		myPattern {UNKNOWN}
		isReading {UNKNOWN}'
	classVariableNames: '
		DefaultPattern {UNKNOWN} 
		SaveEvery {IntegerVar} '
	poolDictionaries: ''
	category: 'Tools-File Model'!
FileList comment:
'Class FileList represents a FileModel that can be viewed as a filtered list (menu) of file names as well as the text of a file.

Instance Variables:
	list				<SortedCollection of: Strings> file names
	myPattern		<Text> representing the filter to select the list
	isReading		<Boolean> true if system is in the process of reading the contents of a file

Class Variables:
	DefaultPattern	<nil | String> the initial pattern for retrieving the file name list
	FileMenu		<ActionMenu> of operations on the file name list
	PatternMenu	<ActionMenu> of operations to modify the pattern string'!



!FileList methodsFor: 'pattern'!

acceptPattern: aText from: aController
	"The text consists of file names and file name patterns separated by carriage returns.
	Patterns can include the characters * (any chars) and # (any single char).
	Make my new list be those file names on my directory which match the patterns."

	| testPattern readStream newList |
	Cursor execute showWhile:
		[self pattern:  aText string.
		readStream _ ReadStream on: self pattern asString.
		newList _ SortedCollection new.
		[readStream atEnd] whileFalse:
			[testPattern _ readStream upTo: Character cr. "get next name/pattern"
			(testPattern includes: $*) | (testPattern includes: $#)
				ifTrue: 
					[Filename errorReporter errorSignal
						handle: [:ex | aController == nil
									ifFalse:	[aController deselect; replaceSelectionWith: ex parameter errorString asText; select].
								Cursor normal show.
								^false]
						do: [newList addAll: (self filesMatching: testPattern)]]
				ifFalse: [(self isLegalFileName: testPattern)
							ifTrue: [newList add: (Filename defaultClass canonicalize: testPattern)]]].
		self list: newList.
		self changed: #fileName].
	^true!

pattern
	"Answer the receiver's current file name pattern."

	^ myPattern!

pattern: aString 
	"Set a new pattern for the receiver.  Inform any dependents so that the labels 
	for the receiver's views can be updated."

	myPattern _ aString asText.
	self changed: #newPattern!

patternMenu
	"Menu for FileListBrowser filename pattern pane."

	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept pattern)! !

!FileList methodsFor: 'file name list'!

copyName
	"Put a copy of the current selections name in the text buffer."
 
	ParagraphEditor new copySelection: self nameOfSelection asText!

deleteFile
	"Remove the selected file from its directory."

	| fn |
	fn _ fileName asFilename.
	fn exists
		ifTrue: [(self confirm: 'really remove the selected file?') ifFalse: [^self].
				fn delete].
	list remove: self nameOfSelection.
	self changed: #fileName.!

{void} fileInManyFiles 
	
	| initialFile {Filename} finalFile {Filename} count {IntegerVar} |
	initialFile _ Filename named: fileName.
	finalFile _ nil.
	ChangeRecorder startingAtChangesFile: fileName doWhile: [:fName {String} |
		| file {Filename} |
		file _ Filename named: fName.
		file exists
			ifTrue: [finalFile _ file.
					true]
			ifFalse: [false]].
	finalFile _ Filename named: (Filename
		requestFileName: 'file in from ', initialFile tail, ' up to and including' 
		default: finalFile asString
		version: #old
		ifFail: [^VOID]).
	count _ 1.
	ChangeRecorder startingAtChangesFile: fileName doWhile: [:fName {String} |
		| file {Filename} |
		(SaveEvery ~~ nil and: [(count \\ SaveEvery) == 0])
			ifTrue: [Smalltalk snapshot].
		count _ count + 1. 
		file _ Filename named: fName.
		file exists assert: 'Must exist'.
		self fileNameAndUpdateView: file asString.
		self fileInFile.
		fName = finalFile asString
			ifTrue: 
				[Transcript cr; show: 'Done'.
				^VOID].
		true].!

fileListMenu 
	"Menu for middle pane of fileList when a non-direcory file is selected."

	fileName == nil ifTrue: [^nil].
	
	^PopUpMenu fromArray: #(
		('get contents'	getFile			'')	"All are standard smalltalk unless otherwise stated."
		('file in'			fileInFile			'')
		('file in many'	fileInManyFiles	'Xu: File in changes files starting with the selected one and saving the image occasionally')
		-
		('copy name'	copyName		'')
		('rename'		renameFile		'')
		-
		('remove'		deleteFile		'')
		-
		('spawn'		spawnFileList	'') ).!

fileName
	"Answer the current selection's file name."
 
	^fileName!

fileName: selection 
	"Change the file selection.  If the argument selection is not nil, it is 
	the name of a file to be viewed."

	self setFileName: selection.
	isReading _ false.
	self changed: #text!

fileNameAndUpdateView: selection 
	"This is an increadible kludge, but the real problem is ListViews & Controllers
	aren't following the Model-View-Controller discipline"

	self fileName: selection.
	self dependents do: [:dep |
		(dep isKindOf: ListView)
			ifTrue: [dep moveSelectionBox: (self fileNameList indexOf: selection)]]!

fileNameList
	"Answer the receiver's list of file names."
	
	^ list!

getFile
	"Get the contents of the selected file."

	self changeRequest ifFalse: [^self].
	isReading _ true.
	self changed: #text!

isSelected
	"Answer true if a file is selected."

	^isReading!

nameOfSelection
	"Answer the name of the current selection."

	^ fileName!

renameFile
	"Rename the selected file.  Prompt the user for a new name."

	| newList newName continue |
	fileName == nil ifTrue: [^nil].
	self changeRequest ifFalse: [^nil].
	continue _ true.
	[continue] whileTrue:
		[newName _ FillInTheBlank
				request: 'New name for file?'
				initialAnswer: self nameOfSelection.
		newName isEmpty ifTrue: [^nil].
		((self isLegalFileName: newName) and: [newName asFilename exists not])
			ifTrue: [continue _ false]
			ifFalse: [(BinaryChoice message: 'File exists or bad file name. Try again?')
						ifFalse: [^nil]]].

	Cursor execute showWhile:
		[| fName |
		newList _ list copyWithout: self nameOfSelection.
		fName _ fileName asFilename.
		fName exists
			ifTrue:	[fName renameTo: newName].
		newList add: newName.
		list _ newList.
		self changed: #fileName.
		self changed: #text]!

spawnFileList
	"Open a FileList on the current selection."

	self class openOnFileNames: (Array with: self nameOfSelection) label: self nameOfSelection! !

!FileList methodsFor: 'text'!

text
	"Answer the text for the selected file."

	isReading
		ifTrue: [^super text]
		ifFalse: [^'' asText]! !

!FileList methodsFor: 'list access'!

list: aList
	"Set the list of files to be aList."

	list _ aList.
	isReading _ false! !

!FileList methodsFor: 'file accessing'!

filesMatching: pattern
	"Answer a list of file names matching the pattern string.  Do this by asking the appropriate directory."

	^Filename defaultClass filesMatching: pattern!

isLegalFileName: pattern
	"Answer whether pattern is a valid file name.  Do this by asking the appropriate directory."

	^OSErrorHolder invalidArgumentsSignal
		handle: [ :ex | ex returnWith: false ]
		do: [| name |
			name _ pattern asFilename asString.
			Filename isCaseSensitive
				ifTrue:	[pattern = name]
				ifFalse:	[pattern sameAs: name]]!

setToRead
	"Set the interface to indicate that the selected file is being read."

	isReading _ true! !

!FileList methodsFor: 'private: private'!

chooseVolume: volName from: aController

	| choice menu volumes|
	volumes _ Filename volumes.
	menu _ PopUpMenu labelList: (Array with: volumes).
	choice _ menu startUp.
	choice = 0 ifTrue: [^self].
	self setVolume: (volumes at: choice) from: aController!

setVolume: volName from: aController

	| volume |
	volume _ (volName, '*') asText.
	aController deselect.
	aController view newText: volume; displayView.
	aController selectFrom: volume size + 1 to: volume size.
	self acceptPattern: volume from: aController.!

spawnFile: aText from: aController
	"Open a file editor that edits the current selection."
	
	|fileModel newController|
	fileModel _ FileModel new.
	fileModel setFileName: self nameOfSelection.
	newController _ aController copy. 		 "Copy gets the changes"
	aController cancel; controlTerminate.   "Cancel changes in spawning fileModel"
	FileModel open: fileModel named: self nameOfSelection withController: newController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FileList class
	instanceVariableNames: ''!



!FileList class methodsFor: 'preferences'!

{void} saveEvery: n {IntegerVar | nil}
	"How often (in terms of file ins) should we snapshot the image (when doing 
	a file in many)?"
	
	"FileList saveEvery: 5" 
	"FileList saveEvery: nil" 
	
	SaveEvery _ n! !

!FileList class methodsFor: 'class initialization'! !

!FileList class methodsFor: 'instance creation'!

open
	"Create and schedule a view of a new instance of the receiver.
	For example, evaluate
		FileList open"

	^self openOnPattern: self defaultPattern!

openOnFileNames: aFileNameList label: labelString
	"Create and schedule a view of a new instance of the receiver such that the
	instance references the files named in the argument, aFileNameList."

	| topView aFileList |
	aFileList _ self new list: aFileNameList.
	topView _ FileListView model: aFileList label: labelString minimumSize: 200 @ 200.
	topView addSubView:
			(SelectionInListView on: aFileList aspect: #fileName change: #fileName:
				list: #fileNameList menu: #fileListMenu initialSelection: nil)
		in: (0@0 extent: 1@0.2) borderWidth: 1.
	topView addSubView:
			(CodeView on: aFileList aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: nil)
		in: (0@0.2 extent: 1@0.8) borderWidth: 1.
	topView icon: (Icon constantNamed: #default).
	topView controller open!

openOnPattern: aPattern
	"Create and schedule a view of a new instance of the receiver with the using 
	the pattern aPattern.  For example, evaluate
		FileList openOnPattern: '*'"

	| topView aFileList patternView label|
	aFileList _ self new.
	aPattern = '' 
		ifFalse: [Cursor read showWhile:
					[aFileList list: (SortedCollection new addAll: (aFileList filesMatching: aPattern))].
				label _ 'File List on ', aPattern asString ]
		ifTrue: [label _ 'File List'].
	aFileList pattern: aPattern.
	topView _ FileListView
		 model: aFileList
		 label:	label
		 minimumSize: 200 @ 200.
	patternView _ CodeView
		 on: aFileList
		 aspect: #pattern
		 change: #acceptPattern:from:
		 menu: #patternMenu
		 initialSelection: nil.
	topView
		 addSubView: patternView
		 in: (0@0 extent: 1@0.07)
		 borderWidth: 1.
	patternView controller: AlwaysAcceptCodeController new.
	topView addSubView:
		(SelectionInListView
			 on: aFileList
			 aspect: #fileName
			 change: #fileName:
			 list: #fileNameList
			 menu: #fileListMenu
			 initialSelection: nil)
		in: (0@0.07 extent: 1@0.23)
		borderWidth: 1.
	topView addSubView:
		(OnlyWhenSelectedCodeView
			 on: aFileList
			 aspect: #text
			 change: #acceptText:from:
			 menu: #textMenu
			 initialSelection: nil
			selection: #isSelected)
		in: (0@0.3 extent: 1@0.7)
		 borderWidth: 1.
	topView icon: (Icon constantNamed: #default).
	topView controller open! !

!FileList class methodsFor: 'default pattern access'!

defaultPattern
	"Answer the default file pattern."

	DefaultPattern == nil
		ifTrue: [^'']
		ifFalse: [^DefaultPattern]!

defaultPattern: aString
	"Set the default file pattern to be aString."

	"FileList defaultPattern: '*'"

	DefaultPattern _ aString! !