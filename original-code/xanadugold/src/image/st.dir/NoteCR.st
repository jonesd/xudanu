'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:01 pm'!

CheckpointCR subclass: #NoteCR
	instanceVariableNames: 'myComment {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!NoteCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: comment {String}

	super create: recorder with: #NOTE.
	myComment _ comment.
	self link: #NOTE.!

from: input {FileStream}

	super from: input.
	myComment _ input nextChunk.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myComment _ input nextChunk.! !

!NoteCR methodsFor: 'storing'!

{Boolean} isPersistent
	"whether this should persist in standard file outs"
	^ true!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myComment.! !

!NoteCR methodsFor: 'accessing'!

comment
	^ myComment!

{String} displayString

	^ super displayString , (myComment copyReplaceAll: '
' with: ' ')! !