'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:59 pm'!

CxxRelatedCR subclass: #CxxFieldCR
	instanceVariableNames: 'myField {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!CxxFieldCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: cat {Collection} with: vis {Symbol} with: field {Symbol}

	super create: recorder with: cat with: vis.
	myField _ field.
	self recorder link: self identifier.
	self recorder link: self leaf!

from: input {FileStream}

	super from: input.
	myField _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myField _ input nextChunk asSymbol.! !

!CxxFieldCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myField.! !

!CxxFieldCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , ': ' , myField!

field
	^ myField!

{Symbol} identifier
	"the symbol for looking up the latest version of this change"
	^ (self leaf , (ChangeRecord visibility: self visibility field: myField)) asSymbol!

{Symbol} identifiers

	^ ChangeRecord leaf: self leaf visibility: self visibility field: self field! !