'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:14 pm'!

FileList subclass: #HierarchicalFileList
	instanceVariableNames: 'selectionName isDirectory emptyDir myDirectory '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-File Model'!
HierarchicalFileList comment:
'
Class HierarchicalFileList represents a FileList on a hierarchically-structured file system.

Instance Variables:
	selectionName	<nil | String> name of the file or directory currently selected.
	isDirectory		<Boolean> true if the current selection is a directory rather than a file.
	emptyDir		<Boolean> only meaningful if isDirectory is true, then true if the currently selected directory is empty (contains no files).
	myDirectory	<String> name of the default working directory (here only for backwards compatibility).
'!


!HierarchicalFileList methodsFor: 'file name list'!

directoryPattern
	"Set the pattern to be the path to the selected directory."

	| newPattern |
	newPattern _ self nameOfSelection.
	newPattern == nil
		ifFalse: [self pattern: (newPattern asFilename constructString: '*') asString.
				self changed: #pattern.
				self acceptPattern: self pattern asText from: nil]!

fileListMenu
	"Menus for middle pane of fileList.  (When a non-directory file is selected, punts to the superclass.)"
	"All are standard smalltalk."
	
	fileName == nil
		ifTrue: [^PopUpMenu fromArray: #(
			('make directory'	makeDir				'') )].

	"If fileName exists and is a directory, return a special menu"
	isDirectory
		ifTrue: [^PopUpMenu fromArray: #(
			('new pattern'	directoryPattern	'')
			-
			('copy name'	copyName			'')
			-
			('rename'		renameFile			'')
			('remove'		removeDir			'')
			-
			('spawn'		spawnFileList		'') )].

	"If fileName does not exist or is not a directory return the standard menu"
	^super fileListMenu!

fileName: selection
	"If selection is not nil, it is either the name of a file to be viewed, or a directory"

	| file |
	isDirectory _ false.
	file _ nil.
	selection == nil ifFalse:
		[file _ selection.
		isDirectory _ Filename errorReporter inaccessableSignal
							handle: [:ex | ex returnWith: false]
							do: [file asFilename isDirectory]].
	self setFileName: file.
	self setSelection: selection.
	isReading _ false.
	emptyDir _ true.
	self changed: #text!

makeDir
	"Make a new directory."
	| continue newName |

	continue _ true.
	[continue] whileTrue:
		[newName _ FillInTheBlank request: 'New name for directory?' initialAnswer: ''.
		newName isEmpty ifTrue: [^nil].
		((self isLegalFileName: newName) and: [newName asFilename exists not])
			ifTrue: [continue _ false]
			ifFalse: [(self confirm: 'File exists or bad file name. Try again?')
						ifFalse: [^nil]]].
	(Filename named: newName) makeDirectory.
	list == nil ifTrue: [self list: SortedCollection new].
	list add: newName.
	self changed: #fileName!

nameOfSelection
	"Return the name of the current selection."

	^selectionName!

removeDir
	"Remove the selected directory."

	| fname nameOfSelection |
	fname _ Filename named: fileName.
	nameOfSelection _ self nameOfSelection.
	(self confirm: 'Remove directory ' , fileName)
		ifTrue: [Filename errorReporter errorSignal
				handle: 
					[:ex | 
					Transcript cr; show: 'can''t remove -- ' , ex parameter errorString.
					ex return]
				do: [fname directoryContents size > 0
						ifTrue: 
							[emptyDir _ false.
							self changed: #text]
						ifFalse: 
							[fname delete.
							list remove: nameOfSelection.
							self changed: #fileName]]]!

spawnFileList
	"Open a FileList if the current selection is a directory otherwise open a file editor."

	isDirectory
		ifTrue: [^self class openOnPattern: (self nameOfSelection asFilename constructString: '*')]
		ifFalse: [^FileModel
					open: (FileModel new setFileName: self nameOfSelection)
					named: self nameOfSelection]! !

!HierarchicalFileList methodsFor: 'text'!

getInfo
	"Display the information about the file, such as creation date and size."

	isReading _ false.
	self changed: #text.!

getInfo: aFileName 
	"Returns aText with proper emphasis information 
	 from the file system information on aFileName"

	| fn dates stream mod acc |
	fn _ aFileName asFilename.
	dates _ fn dates.
	mod _ dates at: #modified.
	mod == nil
		ifFalse:	[mod _ mod first printString,'   ',mod last printString].
	acc _ dates at: #accessed.
	acc == nil
		ifFalse:	[acc _ acc first printString,'   ',acc last printString].
	stream _ TextStream on: String new.
	stream emphasis: 3;
		nextPutAll: '- file -  Select ''get contents'' to view contents. ';
		cr; cr; emphasis: 2;
		nextPutAll: 'Size:     ';
		emphasis: 1;
		nextPutAll: fn fileSize printString;
		cr.
	mod == nil
		ifFalse:
			[stream	
				emphasis: 2;
				nextPutAll: 'Last modified:     ';
				emphasis: 1;
				nextPutAll: mod;
				cr].
	acc == nil
		ifFalse:
			[stream	
				emphasis: 2;
				nextPutAll: 'Last accessed:     ';
				emphasis: 1;
				nextPutAll: acc;
				cr].
	^stream contents!

text
	"Return the text for the text subview."

	| dirList dirStream msg |
	isDirectory
		ifTrue: [
			emptyDir
				ifFalse: [msg _ '- Directory is not empty, cannot be removed!! -']
				ifTrue: [msg _ '- directory -'.
					dirList _ SortedCollection new.
					dirStream _ String new writeStream.
					dirStream nextPutAll: msg ; cr; cr.
					dirList addAll: ((Filename named: self nameOfSelection) filesMatching: '*').
					dirList do: [:name | dirStream nextPutAll: name; cr].
					isReading _ true.
					^dirStream contents asText emphasizeFrom: 3 to: msg size - 2 with: 3]]
		ifFalse: [ "Then it is a file."
			isReading
				ifTrue:
					[fileName == nil ifTrue: [^nil].
					fileName asFilename exists
						ifTrue: [^Cursor read showWhile:
									[(Filename named: fileName) contentsOfEntireFile asText]]
						ifFalse:
							[msg _ '- new file -']]
				ifFalse:
					[fileName == nil
						ifTrue:
							[^'' asText]
						ifFalse:
							[fileName asFilename exists
								ifTrue:
									[^self getInfo: fileName]
								ifFalse:
									[fileName asFilename canBeWritten
										ifTrue: [msg _ '- new file -'.
												isReading _ true]
										ifFalse: [msg _ '- bad directory specification or no write permission -']]]]].
	^msg asText emphasizeFrom: 3 to: msg size - 2 with: 3!

textMenu
	"Menu for FileListBrowser text pane when displaying a directory (and punt to super when displaying a file)."
	
	isDirectory ifFalse: [^super textMenu].
	fileName == nil ifTrue: [^ nil].
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text dir).! !

!HierarchicalFileList methodsFor: 'private: private'!

filterOutMyDirectoryFrom: aList 
	"Return a list of my files without the current path."
	"Kept for backwards compatibility."

	^aList collect:
		[:name |
		(name findString: myDirectory startingAt: 1) = 1
			ifTrue: [Filename defaultClass localNameStringFrom:
						(name copyFrom: myDirectory size to: name size)]
			ifFalse: [name]]!

list: aList
	"Set my list of files."

	super list: aList asSortedCollection!

setSelection: selection
	"Set my current selection."

	selectionName _ selection!

setWorkingDirectory
	"Set my directory to be the current working directory."

	myDirectory _ Filename defaultDirectoryName.
	myDirectory last = Filename separator
		ifFalse:	[myDirectory _ myDirectory copyWith: Filename separator]!

spawnFile: aText from: aController
	"Open a FileList if the selected file is a directory otherwise open a file editor that edits the current selection."
	
	isDirectory 
		ifTrue: [self spawnFileList]	
		ifFalse: [^super spawnFile: aText from: aController].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HierarchicalFileList class
	instanceVariableNames: ''!


!HierarchicalFileList class methodsFor: 'instance creation'!

new

	^super new setWorkingDirectory! !