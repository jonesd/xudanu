'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:58 pm'!

ClassRelatedCR subclass: #ClassOrMetaRelatedCR
	instanceVariableNames: 'myMeta {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ClassOrMetaRelatedCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: (myMeta ifTrue: ['T'] ifFalse: ['F']).! !

!ClassOrMetaRelatedCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: meta {Boolean}

	super create: recorder with: path with: vis with: class.
	myMeta _ meta.!

from: input {FileStream}

	super from: input.
	myMeta _ input nextChunk = 'T'.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myMeta _ input nextChunk = 'T'.! !

!ClassOrMetaRelatedCR methodsFor: 'accessing'!

{String} classString
	"string identifying the class and meta status"
	^ myMeta
		ifTrue: [myClassName , ' class']
		ifFalse: [myClassName asString]!

{String} displayString

	^ super displayString , (myMeta ifTrue: [' class'] ifFalse: [''])!

meta
	^ myMeta! !