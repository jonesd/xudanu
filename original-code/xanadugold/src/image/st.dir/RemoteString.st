'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:30 pm'!

Object subclass: #RemoteString
	instanceVariableNames: 'sourceFileNumber filePosition '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Support'!
RemoteString2 comment:
'Instances of class RemoteString hold the file reference to the class comment (or any other piece of executable text).

Instance Variables:
	sourceFileNumber	<Integer> index into SourceFiles
	filePosition			<Integer> position in that file for start of the string
'!


!RemoteString methodsFor: 'accessing'!

position
	"Answer the location of the string on a file."

	^filePosition!

sourceFileNumber
	"Answer the index of the file on which the string is stored."
	^sourceFileNumber!

string
	"Answer the receiver's string if remote files are enabled."

	| theFile |
	(SourceFiles == nil or: [sourceFileNumber == nil])
		ifTrue: [^'']
		ifFalse: 
			[theFile _ SourceFiles at: sourceFileNumber.
			theFile position: filePosition.
			^theFile nextChunk]! !

!RemoteString methodsFor: 'private: private'!

fileNumber: sourceIndex position: anInteger

	sourceFileNumber _ sourceIndex.
	filePosition _ anInteger!

string: aString onFileNumber: anInteger 
	"Store this as my string if source files exist"

	| theFile |
	SourceFiles == nil
		ifFalse: 
			[theFile _ SourceFiles at: anInteger.
			theFile cr.
			self string: aString
				onFileNumber: anInteger
				toFile: theFile.
			theFile commit]!

string: aString onFileNumber: anInteger toFile: aFileStream 
	"Store this as the receiver's string if source files exist."

	| position |
	sourceFileNumber _ anInteger.
	filePosition _ aFileStream writePosition.
	aFileStream nextChunkPut: aString! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RemoteString class
	instanceVariableNames: ''!


!RemoteString class methodsFor: 'instance creation'!

empty
	"Answer a new instance of RemoteString for file indexed by 1,
	at the position 0.  Assumes that the string is already stored
	on the file and the instance will be used to access it."

	^self newFileNumber: 1 position: 0!

newFileNumber: sourceIndex position: anInteger 
	"Answer a new instance of RemoteString for file indexed by sourceIndex,
	at the position anInteger.  Assumes that the string is already stored
	on the file and the instance will be used to access it."

	^self new fileNumber: sourceIndex position: anInteger!

newString: aString onFileNumber: sourceIndex 
	"Answer a new instance of RemoteString for string, aString, on file indexed by
	sourceIndex.  Puts the string on the file and creates the remote reference."

	^self new string: aString onFileNumber: sourceIndex!

newString: aString onFileNumber: sourceIndex toFile: aFileStream
	"Answer a new instance of RemoteString for string, aString, on file indexed by
	sourceIndex.  Puts the string on the file, aFileStream, and creates the remote
	reference.  Assumes that the index corresponds properly to aFileStream."

	^self new string: aString onFileNumber: sourceIndex toFile: aFileStream! !