'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:59 pm'!

CategorizedCR subclass: #CxxRelatedCR
	instanceVariableNames: 'myVisibility {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!CxxRelatedCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: cat {Collection} with: vis {Symbol}

	super create: recorder with: cat.
	myVisibility _ vis. "public, protected, private, test"!

from: input {FileStream}

	super from: input.
	myVisibility _ ChangeRecord visibilityFrom: input nextChunk first.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myVisibility _ ChangeRecord visibilityFrom: input nextChunk first.! !

!CxxRelatedCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: (ChangeRecord visibility: myVisibility).! !

!CxxRelatedCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , (ChangeRecord visibility: myVisibility)!

visibility
	^ myVisibility! !