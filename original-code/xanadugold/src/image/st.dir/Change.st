'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:51 pm'!

Object subclass: #Change
	instanceVariableNames: 'file position '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
Change comment:
'Class Change represents a single change of some kind.  It has many subclasses for specific kinds of changes.  The text which represents the instance is a chunk of a file starting at a particular position.  Since so many kinds of changes are related to classes, categories, and methods, there are dummy accessing methods for these parameters in class Change.

Instance Variables:
	file 			<FileStream>
	position		<Integer>
'!


!Change methodsFor: 'initialize-release'!

file: aFileStream position: anInteger
	file _ aFileStream.
	position _ anInteger! !

!Change methodsFor: 'accessing'!

baseClassName
	| size cn |
	cn _ self className.
	size _ cn size.
	size < 7 ifTrue: [^cn].
	^(cn copyFrom: size - 5 to: size) = ' class'
		ifTrue: [cn copyFrom: 1 to: size - 6]
		ifFalse: [cn]!

category
	^''!

className
	^''!

classObject
	"Return the class in the present system referenced by my className"
	^nil!

defaultName: initialString
	"The default name is the first few characters of the
text."
	| text cr |
	text _ WriteStream on: (String new: 50).
	text nextPutAll: initialString.
	cr _ Character cr.
	self text do:
		[:aChar |
		(aChar = cr or: [text position >= 40]) ifTrue: [text
nextPutAll: ' ...'.  ^text contents].
		text nextPut: aChar].
	^text contents!

guaranteedClassObject
	"Return the class in the present system referenced by my className.
	If no such class exists, return Object."
	| obj |
	obj _ self classObject.
	^obj isBehavior
		ifTrue: [obj]
		ifFalse: [Object]!

name
	"Return the name which should appear in the list view."
	self subclassResponsibility!

parameters
	"Return the parameters used for the 'same as' test"
	self subclassResponsibility!

selector
	^''!

text
	"Answer the text displayed by the receiver."

	file position: position.
	^file nextChunk!

text: aString
	| tempStream |
	tempStream _ ReadWriteStream on: (String new: aString size + 20).
	tempStream nextChunkPut: aString.
	tempStream position: 0.  "Needed to set readLimit = writePosition"
	file _ ReadStream on: tempStream contents.
	position _ 0!

values
	"Return the value to be used for the 'same as' filter"
	^Array with: self class with: self parameters! !

!Change methodsFor: 'file accessing'!

file
	^file!

fileName
	(file isKindOf: BufferedExternalStream)
		ifTrue: [^file name]
		ifFalse: [^'some local stream']! !

!Change methodsFor: 'checking'!

checkWith: aConflictChecker
	"This is a default, most subclasses do something more intelligent."
	aConflictChecker addDoIt: self! !

!Change methodsFor: 'fileIn/Out'!

fileIn
	^self guaranteedClassObject evaluatorClass evaluate: self text logged: true!

fileOutOn: aStream
	"Default, subclasses may do something different"
	aStream nextChunkPut: self text; cr; cr!

fileOutOn: aStream previous: previousChange next: nextChange
	"Default, subclasses may be able to encode runs more compactly"
	self fileOutOn: aStream! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Change class
	instanceVariableNames: ''!


!Change class methodsFor: 'instance creation'!

file: f position: p
	^super new file: f position: p! !