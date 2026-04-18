'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:02 pm'!

CategorizedCR subclass: #OrganizationCR
	instanceVariableNames: 'myOrgType {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!OrganizationCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: type {Symbol}

	super create: recorder with: path.
	myOrgType _ type. "add or remove"!

from: input {FileStream}

	super from: input.
	myOrgType _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myOrgType _ input nextChunk asSymbol.! !

!OrganizationCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , ' ' , myOrgType!

orgType
	^ myOrgType! !

!OrganizationCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myOrgType.! !