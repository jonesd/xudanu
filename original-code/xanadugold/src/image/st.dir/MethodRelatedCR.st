'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:01 pm'!

ClassOrMetaRelatedCR subclass: #MethodRelatedCR
	instanceVariableNames: '
		myAction {Symbol}
		mySelector {Symbol}
		myExistingMethod {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!MethodRelatedCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: meta {Boolean} with: action {Symbol} with: selector {Symbol}

	super create: recorder with: path with: vis with: class with: meta.
	self initialize: action with: selector.!

from: input {FileStream}

	super from: input.
	myAction _ input nextChunk asSymbol.
	mySelector _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myAction _ input nextChunk asSymbol.
	mySelector _ input nextChunk asSymbol.!

initialize: action {Symbol} with: selector {Symbol}

	| link {Symbol} |
	myAction _ action.
	mySelector _ selector. "accept, remove, source, or initial"
	link _ ChangeRecord meta: self meta selector: selector.
	self link: link.
	 "store it in the dictionary so we can tell what's changed"
	myExistingMethod _ self recorder link: self identifier! !

!MethodRelatedCR methodsFor: 'storing'!

fileOutOn: file {FileStream}
	"file out all changes associated with this record onto another file"
	
	myAction == #remove ifTrue:
		[super fileOutOn: file]
	ifFalse:
		[file cr; cr; nextPut: $!!;
			nextChunkPut: self classString , ' methodsFor: ' , self protocol storeString;
			cr; nextChunkPut: self changesString;
			nextChunkPut: ' ']!

isPersistent
	"don't file out initial or sources changes"
	
	^ myAction ~~ #initial and: [myAction ~~ #sources]!

recordOn: log {FileStream}

	super recordOn: log.
	log nextChunkPut: myAction;
		nextChunkPut: mySelector.! !

!MethodRelatedCR methodsFor: 'accessing'!

{Boolean} acceptText: aText from: aController
	| class {ClassDescription} protocol {Symbol} |
	self thingToDo. "use most recent name for class"
	class _ Smalltalk at: self className ifAbsent: [^ false].
	self meta ifTrue: [class _ class class].
	protocol _ class organization categoryOfElement: mySelector.
	(protocol == nil or: [protocol isEmpty]) ifTrue: [protocol _ #UNKNOWN].
	^ nil ~~ (class compile: aText classified: protocol notifying: aController)!

action
	^ myAction!

{String} changesString
	"get the corresponding string from the changes file"
	myAction == #sources ifTrue:
		[^ self recorder sources position: myChangesPosition; nextChunk].
	self recorder changes position: myChangesPosition.
	(myAction == #accept or: [myAction == #add]) ifTrue:
		[self recorder changes nextChunk; nextChunk].
	^ self recorder changes nextChunk!

{String} displayString

	^ super displayString  , ' > ' , myAction , ' ' , mySelector!

existingMethod
	"the method that was in the system when this record was created"
	^ myExistingMethod!

{CompiledCode} fetchCodeBlock
	| dClass {Behavior} |
	dClass _ Smalltalk at: self className asSymbol ifAbsent: [nil].
	dClass == nil ifTrue: [^nil].
	^dClass compiledMethodAt: self selector!

{Symbol} identifier
	"the symbol for looking up the latest version of this change"
	^ (self className , (self meta ifTrue: [' class>'] ifFalse: ['>']) , mySelector) asSymbol!

{Symbol} identifiers
	"records with equal identifiers affect the same  piece of the system"
	^ ChangeRecord class: self className meta: self meta selector: self selector!

protocol
	"get the protocol string for this method"
	
	| methodsFor index quote |
	(myAction ~~ #accept and: [myAction ~~ #add]) ifTrue:
		[^ #UNKNOWN].
	methodsFor _ self recorder changes position: myChangesPosition; nextChunk; nextChunk.
	index _ methodsFor indexOfSubCollection: 'methodsFor:' startingAt: 1.
	index = 0 ifTrue: [^ #UNKNOWN].
	^ (Compiler evaluate: (methodsFor copyFrom: index + 11 to: methodsFor size)) asSymbol!

selector
	^ mySelector!

sourcePosition

	myAction == #sources ifTrue:
		[self recorder sources position: myChangesPosition; nextChunk.
		^ self recorder sources position].
	self recorder changes position: myChangesPosition.
	(myAction == #accept or: [myAction == #add]) ifTrue:
		[self recorder changes nextChunk; nextChunk].
	^ self recorder changes position + 1! !