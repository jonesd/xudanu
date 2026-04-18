'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:02 pm'!

ClassOrMetaRelatedCR subclass: #ProtocolRelatedCR
	instanceVariableNames: '
		myAction {UNKNOWN}
		myProtocol {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ProtocolRelatedCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: meta {Boolean} with: action {Symbol} with: protocol {Symbol}
	super create: recorder with: path with: vis with: class with: meta.
	myAction _ action. "add, remove, move, rename, or accept"
	myProtocol _ protocol.!

from: input {FileStream}

	super from: input.
	myAction _ input nextChunk asSymbol.
	myProtocol _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myAction _ input nextChunk asSymbol.
	myProtocol _ input nextChunk asSymbol.! !

!ProtocolRelatedCR methodsFor: 'storing'!

recordOn: log {FileStream} 
	super recordOn: log.
	log nextChunkPut: myAction.
	(myProtocol == nil or: [myProtocol isEmpty])
		ifTrue: [log nextChunkPut: 'UNKNOWN']
		ifFalse: [log nextChunkPut: myProtocol]! !

!ProtocolRelatedCR methodsFor: 'accessing'!

action
	^ myAction!

{String} displayString

	^ super displayString , ' ' , myAction , ' ''' ,  myProtocol , ''''!

protocol
	^ myProtocol! !