'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:00 pm'!

CheckpointCR subclass: #FileInCR
	instanceVariableNames: 'myFileName {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!FileInCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: filename {String}

	super create: recorder with: #FILEIN.
	myFileName _ filename.
	self link: #FILEIN.!

from: input {FileStream}

	super from: input.
	myFileName _ input nextChunk!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myFileName _ input nextChunk! !

!FileInCR methodsFor: 'storing'!

isEssential
	^true!

isPersistent
	^true!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myFileName.! !

!FileInCR methodsFor: 'accessing'!

{String} displayString
	| i |
	i _ myFileName size.
	[i = 0 or: [':\/ ' includes: (myFileName at: i)]]
		whileFalse: [i _ i - 1].
	^ super displayString , ' ' , (myFileName copyUpTo: $ ) , ' ' ,
		(myFileName , ' ' copyFrom: i+1 to: myFileName size + 1)!

fileName
	^ myFileName! !