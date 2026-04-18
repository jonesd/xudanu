'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:57 pm'!

ClassRelatedCR subclass: #ClassMoveCR
	instanceVariableNames: '
		myOldLeaf {UNKNOWN}
		myOldVisibility {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ClassMoveCR methodsFor: 'creation'!

ClassMoveCR.initialize: newPath {Collection} with: oldPath {Collection} with: oldVis {Symbol}

	myOldLeaf _ oldPath last.
	myOldVisibility _ oldVis.!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: oldPath {Collection} with: oldVis {Symbol}

	super create: recorder with: path with: vis with: class.
	self ClassMoveCR.initialize: path with: oldPath with: oldVis.!

from: input {FileStream}

	super from: input.
	myOldLeaf _ input nextChunk asSymbol.
	myOldVisibility _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myOldLeaf _ input nextChunk asSymbol.
	myOldVisibility _ input nextChunk asSymbol.! !

!ClassMoveCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , ' was in ' , myOldLeaf , (ChangeRecord visibility: myOldVisibility)!

oldLeaf
	^ myOldLeaf!

oldVisibility
	^ myOldVisibility! !

!ClassMoveCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myOldLeaf;
		nextChunkPut: myOldVisibility.! !