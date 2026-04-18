'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:01 pm'!

ProtocolRelatedCR subclass: #MoveMethodCR
	instanceVariableNames: 'mySelector {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!MoveMethodCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: meta {Boolean} with: newProtocol {Symbol} with: selector {Symbol}

	super create: recorder with: path with: vis with: class with: meta with: #move with: newProtocol.
	mySelector _ selector.!

from: input {FileStream}

	super from: input.
	mySelector _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	mySelector _ input nextChunk asSymbol.! !

!MoveMethodCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: mySelector.! !

!MoveMethodCR methodsFor: 'accessing'!

selector
	^ mySelector! !