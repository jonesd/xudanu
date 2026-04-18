'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:00 pm'!

CheckpointCR subclass: #ForkCR
	instanceVariableNames: 'myComment {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ForkCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: comment {String}

	super create: recorder with: #FORK.
	myComment _ comment.
	self link: #FORK.!

from: input {FileStream}

	super from: input.
	myComment _ input nextChunk.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myComment _ input nextChunk.! !

!ForkCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myComment.! !

!ForkCR methodsFor: 'accessing'!

comment
	^ myComment!

{String} displayString

	^ super displayString , (myComment copyReplaceAll: '
' with: ' ')! !