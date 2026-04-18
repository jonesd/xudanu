'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:46 pm'!

ExternalConnection subclass: #FileConnection
	instanceVariableNames: 'fileName rwmode creationRule rememberedPosition '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
FileConnection comment:
'Instances of FileConnection hold descriptors for a named file. Connections can be reopened to a remembered position if the fileName is not nil.  The inputDescriptor and outputDescriptor are the same object.

Instance Variables:
	fileName				<String> 
	rwmode					<Symbol>
	creationRule			<Symbol>
	rememberedPosition 	<SmallInteger | nil>'!


!FileConnection methodsFor: 'accessing'!

dataSize
	"Answer the size of the file."

	^inputDescriptor fileSize!

name
	"Answer the receiver's name."

	^fileName! !

!FileConnection methodsFor: 'io buffer creation'!

defaultIoBuffer
	"Answer a PositionalIOBuffer connected to the receiver."

	^PositionalIOBuffer on: self!

defaultIoBufferInMode: binaryFlag
	"Answer a default ioBuffer approiate to the receiver with either binary or text mode."

	^PositionalIOBuffer on: self mode: binaryFlag! !

!FileConnection methodsFor: 'testing'!

canPersist
	"Answer a boolean as to whether the receiver can be reopened.
	The answer is true if the file name is known."

	^fileName notNil! !

!FileConnection methodsFor: 'status'!

isActive
	"Answer true if the receiver is open."

	^outputDescriptor ~~ nil!

open
	"Open the receiver."

	self isActive ifTrue: [^self].
	inputDescriptor _ IOAccessor
				openFileNamed: fileName
				direction: (IOAccessor perform: rwmode)
				creation: (IOAccessor perform: creationRule).
	outputDescriptor _ inputDescriptor! !

!FileConnection methodsFor: 'persistence'!

rememberedPosition
	"Answer the receiver's remembered file position."

	^rememberedPosition!

rememberPosition: aPosition
	"Remember the file position aPosition."

	rememberedPosition _ aPosition!

revive
	"Restart the connection."

	self open! !

!FileConnection methodsFor: 'private: private'!

setName: aName mode: aRwMode creationRule: aCreationRule

	fileName  _ aName asString.
	rwmode _ aRwMode.
	creationRule _ aCreationRule.
	self open.

	"Make sure that reopening does not cause truncation."

	creationRule == #truncateOrCreate
		ifTrue: [creationRule _ #noCreate]
		ifFalse: [creationRule == #truncateNoCreate
					ifTrue: [creationRule _ #noCreate]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FileConnection class
	instanceVariableNames: ''!


!FileConnection class methodsFor: 'instance creation'!

openFileNamed: aName mode: rwMode
	"Answer a new instance of the receiver with given name and read write mode."

	^self openFileNamed: aName mode: rwMode creationRule: #mayCreate!

openFileNamed: aName mode: rwMode creationRule: creationRule 
	"Answer a new instance of the receiver with given name, read write mode,
	and creation rule."

	^self new
		setName: aName
		mode: rwMode
		creationRule: creationRule! !