'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:02 pm'!

CategorizedCR subclass: #OrgRenameCR
	instanceVariableNames: 'myOldName {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!OrgRenameCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: oldName {Symbol}

	super create: recorder with: path.
	myOldName _ oldName.!

from: input {FileStream}

	super from: input.
	myOldName _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myOldName _ input nextChunk asSymbol.! !

!OrgRenameCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , ' was ' , myOldName!

oldName
	^ myOldName!

{Symbol} unmap: link {Symbol}
	"the link that should be used to continue forward from here along the 'same' chain"
	
	link = myOldName
		ifTrue: [^ self leaf]
		ifFalse: [^ super map: link]! !

!OrgRenameCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myOldName.! !