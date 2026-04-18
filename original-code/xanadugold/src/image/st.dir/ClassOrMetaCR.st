'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:57 pm'!

ClassOrMetaRelatedCR subclass: #ClassOrMetaCR
	instanceVariableNames: 'myClassOrMetaType {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ClassOrMetaCR methodsFor: 'creation'!

ClassOrMetaCR.initialize: type {Symbol}

	myClassOrMetaType _ type. "organization"
	self link: self otherLink.
	self recorder link: self identifier.!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: meta {Boolean} with: type {Symbol}

	super create: recorder with: path with: vis with: class with: meta.
	self ClassOrMetaCR.initialize: type.!

from: input {FileStream}

	super from: input.
	myClassOrMetaType _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myClassOrMetaType _ input nextChunk asSymbol.! !

!ClassOrMetaCR methodsFor: 'accessing'!

classOrMetaType
	^ myClassOrMetaType!

{String} displayString

	^ super displayString , ' ' , myClassOrMetaType!

{Symbol} identifier
	"the symbol for looking up the latest version of this change"
	^ ChangeRecord class: self className meta: self meta!

identifiers
	^ Array with: self className with: self otherLink!

{Symbol} otherLink
	self meta ifTrue: [^ #CLASSMETA] ifFalse: [^ #CLASSNONMETA]! !

!ClassOrMetaCR methodsFor: 'storing'!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myClassOrMetaType.! !