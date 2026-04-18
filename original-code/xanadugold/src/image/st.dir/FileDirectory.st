'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:39 pm'!

Object subclass: #FileDirectory
	instanceVariableNames: 'directoryName '
	classVariableNames: 'ExternalReferences Separator '
	poolDictionaries: ''
	category: 'OS-Support'!
FileDirectory comment:
'A FileDirectory is uniquely identified by the device or server to which it refers.  A FileDirectory is a collection of file names.

Instance Variables:
	directoryName <String> the path that identifies the FileDirectory to the operating system.

Class Variables:
	ExternalReferences <OrderedCollection>
		A collection of objects to be sent the message release upon quitting or snapshoting.
	Separator <Character>  the character used to separate items in file paths'!


!FileDirectory methodsFor: 'testing'!

includesKey: fileName
	"Answer whether there is a file with the given name in the receiver.  FileName is relative to the receiver."

	^(Filename named: (self fullPathFor: fileName)) exists! !

!FileDirectory methodsFor: 'accessing'!

contents
	"Answer an OrderedCollection containing all of the files within the receiver."

	^self fullName asFilename directoryContents!

fullName
	"Answer the full path name of the directory."

	^directoryName!

name
	"Answer the name of the directory."

	| tail |
	tail _ directoryName asFilename tail asFilename.
	^tail constructString: ''!

requestFileName: message default: default version: versionType ifFail: failBlock
	"Prompt for a file name.  Insist on an existing file if versionType = #old.  Evaluate failBlock if none obtained." 

	"(FileDirectory named: '' ) requestFileName: 'file:' default: '*.st' version: #any ifFail: [] "

	^directoryName asFilename requestFileName: message default: default version: versionType ifFail: failBlock!

size
	"Answer the number of files contained in the receiver."

	^self contents size! !

!FileDirectory methodsFor: 'dictionary removing'!

removeKey: fileName
	"Remove the file from the receiver."

	^self removeKey: fileName ifAbsent: [self error: 'file not found: ' , fileName]!

removeKey: fileName ifAbsent: failBlock
	"Remove the file from the receiver.  If the file does not exist, evaluate the fail block.
	FileName is assumed to be local to the receiver."

	(self includesKey: fileName)
		ifFalse: [^failBlock value].
	^(Filename named: (self fullPathFor: fileName)) delete! !

!FileDirectory methodsFor: 'file accessing'!

checkName: aFileName fixErrors: aBoolean 
	"Check a string aFileName for validity as a file name.  If there are problems 
	(e.g., illegal length or characters) and aBoolean is false, create an error;  if 
	there are problems and aBoolean is true, make the name legal (usually by 
	truncating and/or tranforming characters) and answer the new name.  Otherwise, 
	answer the name.  Default behavior is to get rid of ending period.  
	Subclasses can do any kind of checking they want and answer either the 
	name, or false if no good."

	| cstr |
	cstr _ Filename defaultClass canonicalize: aFileName.
	aFileName isEmpty ifTrue: [aBoolean ifFalse: [self error: 'file name empty']].
	cstr = aFileName
		ifTrue: 
			[aBoolean ifFalse: [self error: 'file name invalid'].
			^cstr]
		ifFalse: [^aFileName]!

filesMatching: aFilePattern
	"Answer an OrderedCollection of the files within the receiver that match the file name pattern given." 

	^directoryName asFilename filesMatching: aFilePattern!

fixFileName: fileName 
	"Make the argument, fileName, a string, into a legal file name.  
	fileName is assumed to be local to the receiver."

	^fileName!

isLegalFileName: fileName 
	"Answer whether fileName is a legal file name."

	^true!

rename: oldName newName: newName 
	"Rename the file oldName to be newName."

	^(Filename named: (self fullPathFor: oldName))
		renameTo: (self fullPathFor: newName)! !

!FileDirectory methodsFor: 'enumerating'!

do: aBlock
	"Evaluate the block with each filename in the receiver as an argument."

	self contents
		do:
			[:fileName |
			aBlock value: (Filename named: (self fullPathFor: fileName))]!

keysDo: aBlock 
	"Evaluate aBlock for each of the receiver's keys."

	self contents
		do:
			[:fileName |
			aBlock value: fileName]! !

!FileDirectory methodsFor: 'constants'!

separator
	"Answer the character that is the separator in path names."

	^Separator!

separatorString
	"Answer the string that is the separator in path names."

	^String with: Separator! !

!FileDirectory methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	super printOn: aStream.
	aStream nextPutAll: ' named ' ; nextPutAll: self fullName! !

!FileDirectory methodsFor: 'private: private'!

fullPathFor: fileName
	"Answer a full path name for the file whose local name is given."

	(self class name: fileName startsWith: self fullName)
		ifTrue: [^fileName]
		ifFalse: [^self fullName asFilename constructString: fileName]!

setNameFrom: aPathName
	"Set the name of the receiver."

	directoryName _ self class nameWithSeparator: aPathName! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FileDirectory class
	instanceVariableNames: ''!


!FileDirectory class methodsFor: 'class initialization'!

initialize
	"Initialize the receivers constants and the collection of external references."
	"FileDirectory initialize"	

	self initializeExternalReferences.
	self initializeConstants.! !

!FileDirectory class methodsFor: 'instance creation'!

default
	"Answer the default file directory."

	^self named: ''!

directoryFromName: fullName setFileName: localNameBlock 
	"Send the file directory and local name into the block localNameBlock."

	| nameArray directory |
	nameArray _ self nameAndDirectoryOf: (self fixFileName: fullName).
	directory _ self named: (nameArray at: 1).
	localNameBlock value: (nameArray at: 2).
	^directory!

forName: fullName setDirectoryAndNameIn: directoryAndNameBlock
	"Create an instance of me available within the scope of the block."

	| nameArray |
	nameArray _ self nameAndDirectoryOf: (self fixFileName: fullName).
	directoryAndNameBlock
		value: (self named: (nameArray at: 1))
		value: (nameArray at: 2)!

named: aPathName 
	"Create an instance of me representing the directory whose path is aPathname."

	^self new setNameFrom: (aPathName = ''
			ifTrue: [Filename defaultDirectory asString]
			ifFalse: [aPathName])! !

!FileDirectory class methodsFor: 'extern: external reference access'!

addExternalReference: anElement 
	"Add anElement as a file that is currently referenced in the system."

	(ExternalReferences includes: anElement)
		ifFalse: [ExternalReferences addLast: anElement]!

commitExternalReferences
	"Cause all open streams to flush their buffers"

	ExternalReferences do: [:i | i commit]!

initializeExternalReferences
	"ExternalReferences is an OrderedCollection of the files that are referenced
	in the system.  Initialize this class variable."

	ExternalReferences _ OrderedCollection new!

releaseExternalReferences
	"Remove and release all of the files referenced by the collection ExternalReferences."

	[ExternalReferences isEmpty]
		whileFalse: [ExternalReferences removeLast release]!

removeExternalReference: anElement 
	"Remove anElement as a file that is currently referenced in the system."

	ExternalReferences remove: anElement ifAbsent: []! !

!FileDirectory class methodsFor: 'utilities'!

canReadFile: fileName
	"Answer true if the file can be read."

	^(Filename named: fileName) isReadable!

canWriteFile: fileName
	"Answer true if the file can be written."

	^fileName asFilename canBeWritten!

cleanupGarbage
	ExternalReferences copy do: [:f | (('*.ent' match: f name) or: ['waldo' = f name]) ifTrue: [f close]]!

copyFileNamed: sourceName to: destName
	"Copy the file named sourceName to a file named destName."

	"FileDirectory copyFileNamed: 'sourceFileName' to: 'destFileName'"

	sourceName asFilename copyTo: destName asFilename!

filesMatching: aFilePattern 
	"Answer an OrderedCollection of files whose names match the 
	pattern given."

	^Filename filesMatching: aFilePattern!

fixFileName: aFileName
	"Make the file name a valid file name."

	^Filename defaultClass canonicalize: aFileName!

includesKey: aFileName
	"Answer true if the file system contains a file with the given name."

	^aFileName asFilename exists!

isDirectory: fileName
	"Answer true if the file is a directory."

	^Filename errorReporter inaccessableSignal
		handle: [:ex | ex returnWith: false]
		do: 
			[fileName asFilename isDirectory]!

isLegalFileName: fileDesignator
	"Answer whether the specified file name is legal."
	"Example: FileDirectory isLegalFileName: 'someFileName' "

	^fileDesignator = (Filename defaultClass canonicalize: fileDesignator)!

removeKey: fileDesignator
	"Delete the specified file from its directory."
	"Example:  FileDirectory removeKey: 'someFileName' "

	^self removeKey: fileDesignator ifAbsent: [nil]!

removeKey: fileDesignator ifAbsent: failBlock
	"Remove the specified file from its directory.  If the
	file is not in the directory, then answer the result of
	evaluating failBlock.  Otherwise, answer the fileDesignator."

	"For example:
		FileDirectory removeKey: 'someFileName' ifAbsent: [^nil]"

	^Filename errorReporter inaccessableSignal handle: [:ex | ex returnWith: failBlock value]
		do: 
			[(Filename named: fileDesignator) delete.
			true]!

requestFileName: message default: default version: versionType ifFail: failBlock
	"Prompt for a file name.  Insist on an existing file if versionType = #old.
	Evaluate failBlock if none obtained." 
	"FileDirectory requestFileName: 'file:' default: '*.st' version: #any ifFail: []"

	^Filename requestFileName: message default: default version: versionType ifFail: failBlock! !

!FileDirectory class methodsFor: 'constants'!

initializeConstants
	"Initialize the receivers constants."

	"FileDirectory initializeConstants"

	self separator: Filename separator.!

separator
	"Answer the character that is the separator in path names."

	^Separator!

separator: aChar
	"FileDirectory seperator: $/"

	Separator _ aChar!

separatorString
	"Answer the string that is the separator in path names."

	^String with: Separator! !

!FileDirectory class methodsFor: 'name parsing'!

name: aName startsWith: aPath
	"Answer true if the file name aName starts with aPath."

	^aName size >= aPath size and: [(aName copyFrom: 1 to: aPath size) = aPath]!

nameWithSeparator: aNameString
	"Answer a file name with a path separator appended to the end." 	

	^aNameString asFilename constructString: ''! !

!FileDirectory class methodsFor: 'private: private'!

nameAndDirectoryOf: fileName
	"Answer an array with the directory and file components of the given name."

	| fn dir fname |
	fn _ fileName asFilename.
	dir _ self nameWithSeparator: fn head.
	fname _ fn tail.
	^Array with: dir with: fname! !

FileDirectory initialize!
