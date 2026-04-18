'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:13 pm'!

Model subclass: #FileModel
	instanceVariableNames: 'fileName '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-File Model'!
FileModel comment:
'Class FileModel represents an interface between a file and an editable view of it.  As a StringHolder, the string is the contents of the file.

Instance Variables:
	fileName	<String> the name of the file currently being viewed

Class Variables:
	TextMenu	<ActionMenu> of operations on the text contents of a file'!


!FileModel methodsFor: 'accessing'!

fileName
	"Answer the currently selected file name."

	^fileName! !

!FileModel methodsFor: 'text'!

text
	"Answer the text of the receiver."

	| fileNameObject |
	fileName == nil ifTrue: [^nil].
	(fileNameObject _ fileName asFilename) exists
		ifTrue: [^Cursor read showWhile:
					[fileNameObject contentsOfEntireFile asText]]
		ifFalse: [^'-new file-' asText
				emphasizeFrom: 2
				to: 9
				with: 3]!

textMenu 
	"Menu for FileListBrowser text pane when displaying a file."
	
	fileName == nil ifTrue: [^ nil].
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text file),
		(PopUpMenu shortForm ifTrue: [#()] ifFalse: [#(longFile)]).! !

!FileModel methodsFor: 'file access'!

fileInFile
	"Read the entire file as Smalltalk code after logging a version fork."
	ChangeLog logFileIn: ' before ', fileName.
	(Filename named: fileName) fileIn.
	ChangeLog logFileIn: ' after ', fileName.!

fileItIn: fullText from: controller
	"Make a Stream on the text selection and fileIn it."

	| selection |
	selection _ controller selection.
	(ReadWriteStream on: selection from: 1 to: selection size) fileIn! !

!FileModel methodsFor: 'doIt/accept/explain'!

acceptText: aText from: aController
	"Update the contents of the file stream with the receiver's contents."

	| stream |
	Cursor write showWhile:
		[stream _ (Filename named: fileName) writeStream.
		[stream nextPutAll: aText string]
			valueNowOrOnUnwindDo: [stream close]].
	^true!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^ nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^ nil!

doItValue: ignored
	"Set the value to be returned when the interrupted process proceeds."! !

!FileModel methodsFor: 'private: private'!

getNew: ignoreText from: aController
	"Reinitialize the information the receiver models by re-reading the file stream."

	self changeRequest ifFalse: [^ aController view flash].
	self changed: #text!

setFileName: fullFileName

	fileName _ fullFileName!

setFileStream: aStream 

	aStream release.		"close, since later a new file stream will be created"
	fileName _ aStream name!

spawnFile: aText from: aController
	| newController | 
	newController _ aController copy.  "Copy gets the changes"
	aController cancel; controlTerminate.   "Cancel changes in spawning fileModel"
	self class open: self copy named: fileName withController: newController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FileModel class
	instanceVariableNames: ''!


!FileModel class methodsFor: 'class initialization'! !

!FileModel class methodsFor: 'instance creation'!

fileName: aFileName 
	"Answer an instance of the receiver on the argument, aFileStream."

	^self new setFileName: aFileName asString!

fileStream: aFileStream 
	"Answer an instance the receiver on the argument, aFileStream."

	^self new setFileStream: aFileStream!

open: aFileModel named: aString 
	"Create and schedule a view whose model is aFileModel and whose label is aString."

	| topView fn |
	fn _ aFileModel fileName asFilename.
	fn exists
		ifTrue:
			[fn isReadable
				ifFalse:	[Filename errorReporter inaccessableSignal raiseWith: 'File is readProtected'].
			fn isDirectory
				ifTrue:	[Filename errorReporter inaccessableSignal raiseWith: 'File is a directory']]
		ifFalse:	[fn canBeWritten
				ifFalse:	[Filename errorReporter inaccessableSignal raiseWith: 'File can''t be created']].
	topView _ StandardSystemView model: aFileModel label: aString minimumSize: 180 @ 180.
	topView addSubView:
			(CodeView on: aFileModel aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: nil)
		in: (0@0 extent: 1@1) borderWidth: 1.
	topView controller open!

open: aFileModel named: aString withController: aController
	"Create and schedule a FileModel view with changes made in another editor."

	| topView textView |
	topView _ StandardSystemView model: aFileModel label: aString minimumSize: 180 @ 180.
	textView _ CodeView on: aFileModel aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: nil.
	textView controller: aController.
	topView addSubView: textView in: (0@0 extent: 1@1) borderWidth: 1.
	topView controller open! !