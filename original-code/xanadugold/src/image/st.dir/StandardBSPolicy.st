'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:50 pm'!

BinaryStoragePolicy subclass: #StandardBSPolicy
	instanceVariableNames: 'globalNames globalDictionary classDictionary '
	classVariableNames: 'ClassAssocPTag ClassRefPTag GAssocPTag GVarPTag MetaclassRefPTag OtherGlobals UndefinedNameSignal '
	poolDictionaries: ''
	category: 'System-Binary Storage'!
StandardBSPolicy comment:
'Class StandardBSPolicy implements a standard policy for BinaryStorage.  It detects references to objects or associations in the Smalltalk dictionary, to associations visible by name to a method, and to classes and metaclasses, and write them symbolically.

See the comment in the superclass for more information.

Instance Variables:
	globalNames	<IdentityDictionary>   holds value->name for globals other than classes 
	globalDictionary	<Dictionary>   the dictionary used for looking up global names (Smalltalk) 
	classDictionary	<Dictionary>   the statics visible to the current class being written

Class Variables:
	OtherGlobals	<Array of: Symbols>
	UndefinedNameSignal <Signal> Undefined name in BOSS file: 
	ClassAssocPTag	<SmallInteger>
	ClassRefPTag		<SmallInteger>
	GAssocPTag		<SmallInteger>
	GVarPTag			<SmallInteger>
	MetaclassRefPTag	<SmallInteger>
'!


!StandardBSPolicy methodsFor: 'initialize-release'!

initialize
	"Set the initial values of the receiver's variables."

	globalDictionary _ Smalltalk.
	globalNames _ nil.  "initialize only if needed"
	classDictionary _ nil  "rebind if needed"! !

!StandardBSPolicy methodsFor: 'binding'!

inClass: aClass do: aBlock
	| old |
	old _ classDictionary.
	classDictionary _ self staticsForClass: aClass.
	^aBlock valueNowOrOnUnwindDo: [classDictionary _ old]! !

!StandardBSPolicy methodsFor: 'storing'!

storeNew: anObject on: storage
	" Store (the contents of) a previously
	unregistered object."

	| name |
	globalNames == nil
		ifTrue:
			[" Initialize globalNames now. "
			| gnames |
			gnames _ self namesWithheld.
			globalNames _ IdentityDictionary new: gnames size * 2.
			gnames do:
				[:nm |
				(globalDictionary includesKey: nm)
					ifTrue: [globalNames at: (globalDictionary at: nm) put: nm]]].
	(name _ globalNames at: anObject ifAbsent: [nil]) == nil
		ifFalse:
			[^self storeGVar: name on: storage].
	anObject class isMeta  "i.e., anObject is a class"
		ifTrue:
			[^self storeClassRef: anObject on: storage].
	(anObject isMemberOf: Metaclass)
		ifTrue:
			[^self storeMetaclassRef: anObject on: storage].
	anObject class == Association
		ifTrue:
			[classDictionary notNil
				ifTrue:
			 		[(anObject == (classDictionary associationAt: anObject key ifAbsent: [nil]) or:
					 [anObject == (globalDictionary associationAt: anObject key ifAbsent: [nil]) or:
					  [anObject == (Undeclared associationAt: anObject key ifAbsent: [nil])]])
						ifTrue:
							[^self storeClassAssoc: anObject on: storage]]
				ifFalse:
					[anObject == (globalDictionary associationAt: anObject key ifAbsent: [nil])
						ifTrue:
							[^self storeGAssoc: anObject on: storage]]].
	" Just a plain vanilla object. "
	^super storeNew: anObject on: storage! !

!StandardBSPolicy methodsFor: 'reading'!

nextWithTag: pTag from: storage 
	"Read an item with the given policy tag from the storage stream."


	pTag = ClassRefPTag ifTrue: [^self nextClassRefFrom: storage].
	pTag = MetaclassRefPTag ifTrue: [^self nextMetaclassRefFrom: storage].
	pTag = GAssocPTag ifTrue: [^self nextGAssocFrom: storage].
	pTag = GVarPTag ifTrue: [^self nextGVarFrom: storage].
	pTag = ClassAssocPTag ifTrue: [^self nextClassAssocFrom: storage].
	^super nextWithTag: pTag from: storage! !

!StandardBSPolicy methodsFor: 'private: private-binding'!

staticsForClass: aClass
	"Construct a Dictionary that reflects the static naming environment of aClass."

	| dict |
	dict _ Dictionary new.
	aClass withAllSuperclasses reverseDo:
		[:class | | pools |
		"The following patch is required because Metaclasses
		don't report their instance's sharedPools
		(but they do report the classPool -- why??)."
		pools _ (class isMemberOf: Metaclass)
			ifTrue: [class soleInstance sharedPools]
			ifFalse: [class sharedPools].
		pools do:
			[:pool | pool associationsDo: [:assoc | dict add: assoc]].
		class classPool associationsDo:
			[:assoc | dict add: assoc]].
	^dict! !

!StandardBSPolicy methodsFor: 'private: private-tag storing'!

storeClassAssoc: anObject on: storage
	storage nextPTagPut: ClassAssocPTag.
	storage nextPut: anObject key!

storeClassRef: aClass on: storage
	storage nextPTagPut: ClassRefPTag.
	self storeClass: aClass on: storage!

storeGAssoc: anObject on: storage
	storage nextPTagPut: GAssocPTag.
	storage nextPut: anObject key!

storeGVar: name on: storage
	storage nextPTagPut: GVarPTag.
	storage nextPut: name!

storeMetaclassRef: aMetaclass on: storage
	storage nextPTagPut: MetaclassRefPTag.
	self storeClass: aMetaclass soleInstance on: storage! !

!StandardBSPolicy methodsFor: 'private: private-storing'!

storeClass: aClass on: storage
	| names |
	storage nextPut: aClass name.
	storage nextPut: aClass binaryStorageFormat.
	storage nextPut: aClass format.
	names _ (String new: 100) writeStream.
	aClass fastAllInstVarNamesDo: [:n | names nextPutAll: n; space].
	storage nextPut: names contents! !

!StandardBSPolicy methodsFor: 'private: private-tag reading'!

nextClassAssocFrom: storage
	| id key assoc |
	id _ storage assignId.
	key _ storage next.
	assoc _ classDictionary
		associationAt: key
		ifAbsent:
			[globalDictionary
				associationAt: key
				ifAbsent:
					[Undeclared
						associationAt: key
						ifAbsent:
							[assoc _ Association key: key value: nil.
							Undeclared add: assoc.
							assoc]]].
	storage register: assoc id: id.
	^assoc!

nextClassRefFrom: storage
	| id object |
	id _ storage assignId.
	object _ self nextClassFrom: storage.
	storage register: object id: id.
	^object!

nextGAssocFrom: storage
	| id key assoc |
	id _ storage assignId.
	key _ storage next.
	assoc _ globalDictionary
		associationAt: key
		ifAbsent: [UndefinedNameSignal raiseWith: key].
	storage register: assoc id: id.
	^assoc!

nextGVarFrom: storage
	| id name object |
	id _ storage assignId.
	name _ storage next.
	object _ globalDictionary
			at: name
			ifAbsent: [UndefinedNameSignal raiseWith: name].
	storage register: object id: id.
	^object!

nextMetaclassRefFrom: storage
	| id object |
	id _ storage assignId.
	object _ (self nextClassFrom: storage) class.
	storage register: object id: id.
	^object! !

!StandardBSPolicy methodsFor: 'private: private-reading'!

nextClassFrom: storage
	| object name bsFormat |
	name _ storage next.
	bsFormat _ storage next.
	object _ globalDictionary
			at: name
			ifAbsent: [UndefinedNameSignal raiseWith: name].
	" Use a handler to trap doesNotUnderstand:
	if object turns out not to be a class. "
	(Object messageNotUnderstoodSignal
		handle: [:ex | ex returnWith: false]
		do:
			[object binaryStorageFormat = bsFormat and:
				[| format |
				format _ storage next.
				object format = format and:
	 				[| instVars vars |
					instVars _ storage next.
					vars _ (String new: instVars size) writeStream.
					object fastAllInstVarNamesDo: [:v | vars nextPutAll: v; space].
					vars contents isEmpty or: [vars contents = instVars]]]])
		ifFalse: [self error: 'Incompatible class definition for ' , name].
	^object! !

!StandardBSPolicy methodsFor: 'private: private-constants'!

namesWithheld
	" Answer the names of global objects that should be
	encoded specially. "
	^OtherGlobals! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StandardBSPolicy class
	instanceVariableNames: ''!


!StandardBSPolicy class methodsFor: 'class initialization'!

initialize
	"StandardBSPolicy initialize"
	self initializeSignals.
	self initializeTags.
	self initializeGlobals!

initializeGlobals
	"StandardBSPolicy initializeGlobals"
	" Find all the global names that don't
	refer to classes. "
	| globals |
	globals _ OrderedCollection new.
	Smalltalk associationsDo:
		[:assoc |
		(assoc value isKindOf: Behavior) ifFalse:
			[globals addLast: assoc key]].
	OtherGlobals _ globals asArray!

initializeSignals
	"StandardBSPolicy initializeSignals"

	UndefinedNameSignal _ BinaryStorage errorSignal newSignal.
	UndefinedNameSignal
		nameClass: self message: #undeclaredSignal;
		notifierString: 'Undefined name in BOSS file: '!

initializeTags
	| t |
	t _ super initializeTags.
	ClassRefPTag _ t.  t _ t + 1.
	MetaclassRefPTag _ t.  t _ t + 1.
	GAssocPTag _ t.  t _ t + 1.
	GVarPTag _ t.  t _ t + 1.
	ClassAssocPTag _ t.  t _ t + 1.
	^t! !

!StandardBSPolicy class methodsFor: 'instance creation'!

new

	^super new initialize! !

!StandardBSPolicy class methodsFor: 'Signal constants'!

undeclaredSignal
	"Answer the signal that represents an undeclared name as an error condition"

	^UndefinedNameSignal! !

StandardBSPolicy initialize!
