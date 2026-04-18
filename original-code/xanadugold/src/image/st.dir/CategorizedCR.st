'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:55 pm'!

ChangeRecord subclass: #CategorizedCR
	instanceVariableNames: 'myLeaf {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!CategorizedCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {OrderedCollection of: Symbol}
	"cat is the path down in the organization"
	super create: recorder.
	myLeaf _ ChangeRecord pathLeaf: path!

from: input {FileStream}

	super from: input.
	myLeaf _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myLeaf _ input nextChunk asSymbol.! !

!CategorizedCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myLeaf.! !

!CategorizedCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , '  ' , myLeaf asSymbol!

leaf
	^ myLeaf! !