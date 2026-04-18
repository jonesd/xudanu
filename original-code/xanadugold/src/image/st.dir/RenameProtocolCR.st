'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:03 pm'!

ProtocolRelatedCR subclass: #RenameProtocolCR
	instanceVariableNames: 'myOldProtocol {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!RenameProtocolCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: meta {Boolean} with: newProtocol {Symbol} with: oldProtocol {Symbol}

	super create: recorder with: path with: vis with: class with: meta with: #rename with: newProtocol.
	myOldProtocol _ oldProtocol.!

from: input {FileStream}

	super from: input.
	myOldProtocol _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myOldProtocol _ input nextChunk asSymbol.! !

!RenameProtocolCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myOldProtocol.! !

!RenameProtocolCR methodsFor: 'accessing'!

oldProtocol
	^ myOldProtocol! !