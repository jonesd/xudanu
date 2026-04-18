'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:49 pm'!

Object subclass: #BinaryStoragePolicy
	instanceVariableNames: ''
	classVariableNames: 'DependentPTag RecordPTag '
	poolDictionaries: ''
	category: 'System-Binary Storage'!
BinaryStoragePolicy comment:
'A BinaryStoragePolicy represents a set of policies for a BinaryStorage, specifically:
	- What objects will be represented externally as symbolic references of some kind, rather than having their contents stored, and how such references are represented (when writing) and resolved (when reading);
	- For objects that do have their contents stored, how the container (class) is represented (e.g., whether it includes some kind of version number).

The default (abstract) policy represents all objects by their contents.  BinaryStoragePolicy is designed to work closely with BinaryStorage, but it is not allowed to use private messages of BinaryStorage, unless otherwise noted below.

Class Variables:
	DependentPTag		<SmallInteger>
	RecordPTag		<SmallInteger>

Implementation notes
------------------

When BinaryStorage encounters a new object while writing, it assigns a sequence number (id) to the object, and then sends the following message to the policy object:
	aBSPolicy storeNew: anObject on: aBStorage
The policy object gets to decide whether to encode the reference to anObject in some special way.  If it decides not to, it simply sends the message
	anObject storeBinaryOn: aBStorage
The default implementation of storeBinaryOn: sends the message
	aBStorage storeOther: anObject
which is forwarded to the policy object as
	aBSPolicy storeOther: anObject on: aBStorage
Other (class-specific) implementations of storeBinaryOn: will typically begin by sending the BinaryStorage the message
	aBStorage storeRecordOfClass: aClass
The BinaryStorage simply forwards this message to the policy object as
	aBSPolicy storeRecordOfClass: aClass on: aBStorage
Again, the policy object decides how to encode the class reference.

If the policy object wants to use a special encoding for external references or for particular objects, it sends the message
	aBStorage nextPTagPut: pTag
pTag is a small integer drawn from a separate space of tag values, called policy tags or PTags, that BinaryStorage provides for the policy object.  After putting out the tag, the policy object can write whatever it wants, however only using the public storing message (store:) of BinaryStorage.

When a BinaryStorage encounters a policy tag while reading, it simply sends the message
	aBSPolicy nextWithTag: pTag from: storage
If this pTag results in creating an object, the BinaryStoragePolicy must make sure to assign it a sequence number by sending the message
	objId _ storage assignId
and then, after reading the object,
	storage register: theObject id: objId
This is to make sure that the sequence numbers assigned when reading match the ones assigned when storing.
'!


!BinaryStoragePolicy methodsFor: 'binding'!

inClass: aClass do: aBlock 
	"Evaluate aBlock with the naming environment rebound to that of 
	aClass. (Since the default policy doesn't care about the naming 
	environment, this just evaluates aBlock.)"

	^aBlock value! !

!BinaryStoragePolicy methodsFor: 'storing'!

storeNew: anObject on: storage
	"Store (the contents of) a previously unregistered object. "

	" The default is to store as a plain vanilla object. "
	^self storeVanilla: anObject on: storage!

storeOther: anObject on: storage
	"This is the default implementation of storeBinaryOn:. "

	| bsize |
	self storeRecordOfClass: anObject class on: storage.
	anObject class isVariable
		ifTrue: [storage nextPut: (bsize _ anObject basicSize)]
		ifFalse: [bsize _ 0].
	1 to: anObject class instSize do:
		[:i | storage nextPut: (anObject instVarAt: i)].
	1 to: bsize do:
		[:i | storage nextPut: (anObject basicAt: i)]!

storeRecordOfClass: class on: storage
	"Store an indication that the following items are a record of a given class. "

	storage nextPTagPut: RecordPTag.
	storage nextPut: class! !

!BinaryStoragePolicy methodsFor: 'reading'!

nextWithTag: pTag from: storage
	"Read an item with the given policy tag from the storage stream. "

	pTag = RecordPTag
		ifTrue: [^self nextRecordFrom: storage].
	pTag = DependentPTag
		ifTrue: [^self nextDependentFrom: storage].
	self error: 'Unknown policy tag'.
	^nil! !

!BinaryStoragePolicy methodsFor: 'private: private-storing'!

storeVanilla: anObject on: storage
	" Store an object that is not an external reference.
	Dependents stored in DependentsFields must be treated specially. "

	| deps |
	deps _ DependentsFields at: anObject ifAbsent: [nil].
	deps == nil
		ifFalse:
			[deps _ anObject dependents.  "dependents are stored specially"
			(deps isEmpty not and: [(anObject isKindOf: Model) not])
				ifTrue:
					[1 to: deps size do: [:i | storage nextPTagPut: DependentPTag]]
				ifFalse: [deps _ nil]].
	anObject storeBinaryOn: storage.
	deps == nil
		ifFalse: [deps do: [:d | storage nextPut: d]]! !

!BinaryStoragePolicy methodsFor: 'private: private-tag reading'!

nextDependentFrom: storage
	| obj |
	obj _ storage next.
	obj addDependent: storage next.
	^obj!

nextRecordFrom: storage
	| id |
	id _ storage assignId.
	^storage next
		readBinaryFrom: storage
		tag: "should be id:" id! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BinaryStoragePolicy class
	instanceVariableNames: ''!


!BinaryStoragePolicy class methodsFor: 'class initialization'!

initialize
	"BinaryStoragePolicy initialize"
	self initializeTags!

initializeTags
	" Initialize the policy tags,
	and answer the next available tag value. "
	RecordPTag _ 0.
	DependentPTag _ 1.
	^2! !

BinaryStoragePolicy initialize!
