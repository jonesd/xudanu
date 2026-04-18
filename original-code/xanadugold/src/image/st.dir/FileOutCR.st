'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:00 pm'!

CheckpointCR subclass: #FileOutCR
	instanceVariableNames: '
		myBaseline {UNKNOWN}
		myFilename {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!FileOutCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: baseline {Integer} with: name {String}

	super create: recorder with: #FILEOUT.
	myBaseline _ baseline.
	myFilename _ name.
	self link: #FILEOUT.!

from: input {FileStream}

	super from: input.
	myBaseline _ Integer readFrom: input nextChunk readStream.
	myFilename _ input nextChunk!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myBaseline _ Integer readFrom: input nextChunk readStream.
	myFilename _ input nextChunk! !

!FileOutCR methodsFor: 'storing'!

isPersistent
	"this goes into a file out so you know when it was made"
	^ true!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myBaseline printString.
	log nextChunkPut: myFilename! !

!FileOutCR methodsFor: 'accessing'!

baseline
	^ myBaseline!

{String} displayString
	| i |
	i _ myFilename size.
	[i = 0 or: [':\/ ' includes: (myFilename at: i)]]
		whileFalse: [i _ i - 1].
	^super displayString , ' on ' ,
		(myFilename , ' ' copyFrom: i+1 to: myFilename size + 1)!

filename
	^myFilename! !