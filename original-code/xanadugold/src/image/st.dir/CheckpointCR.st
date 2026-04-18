'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:56 pm'!

ChangeRecord subclass: #CheckpointCR
	instanceVariableNames: '
		myCheckpointType {UNKNOWN}
		myImagePrefix {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!CheckpointCR methodsFor: 'storing'!

{Boolean} isPersistent
	"whether this should persist in standard file outs"
	^ false!

recordOn: logFile
	"Write the type, image name, time and date, last change position, and the save number."
	
	super recordOn: logFile.
	logFile nextChunkPut: myCheckpointType;
		nextChunkPut: myImagePrefix.! !

!CheckpointCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: type {Symbol}
	super create: recorder.
	myCheckpointType _ type.
	self link: #CHECKPOINT.
	myImagePrefix _ Smalltalk currentImagePrefix.!

from: input {FileStream}

	super from: input.
	myCheckpointType _ input nextChunk asSymbol.
	myImagePrefix _ input nextChunk.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myCheckpointType _ input nextChunk asSymbol.
	myImagePrefix _ input nextChunk.! !

!CheckpointCR methodsFor: 'accessing'!

checkpointType
	^ myCheckpointType!

{String} displayString

	^ super displayString , ' -- ' , myCheckpointType , ' -- '!

imagePrefix
	^ myImagePrefix! !