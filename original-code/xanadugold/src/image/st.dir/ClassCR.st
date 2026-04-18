'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:57 pm'!

ClassRelatedCR subclass: #ClassCR
	instanceVariableNames: 'myClassType {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ClassCR methodsFor: 'creation'!

ClassCR.initialize: type {Symbol}

	myClassType _ type. "add, accept, remove, field name"
	self link: self classTypeChain.
	self recorder link: self identifier.!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: type {Symbol}

	super create: recorder with: path with: vis with: class.
	self ClassCR.initialize: type.!

from: input {FileStream}

	super from: input.
	myClassType _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myClassType _ input nextChunk asSymbol.! !

!ClassCR methodsFor: 'accessing'!

classType
	^ myClassType!

classTypeChain
	(#(add accept remove) includes: myClassType)
		ifTrue: [^#CLASSDEF]
		ifFalse: [^('CLASS-' , myClassType asUppercase) asSymbol]!

{String} displayString

	^ super displayString , ' ' , myClassType!

{Symbol} identifier
	"the symbol for looking up the latest version of this change"
	^ ChangeRecord class: self className!

identifiers
	^ Array with: self className with: self classTypeChain! !

!ClassCR methodsFor: 'storing'!

{Boolean} isEssential
	"should this record be filed out even if it is superceded? (e.g. initial class definition)"
	
	^ myClassType ~~ #accept!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myClassType.! !