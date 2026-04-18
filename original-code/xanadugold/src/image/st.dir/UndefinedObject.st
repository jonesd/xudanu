'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:09 pm'!

Object subclass: #UndefinedObject
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Objects'!


!UndefinedObject methodsFor: 'initialize-release'!

release
	"Releasing an undefined object is a no-op."! !

!UndefinedObject methodsFor: 'copying'!

deepCopy
	"Only one instance of UndefinedObject should ever be made, so answer 
	with self."

	^self!

shallowCopy
	"Only one instance of UndefinedObject should ever be made, so answer 
	with self."! !

!UndefinedObject methodsFor: 'printing'!

isLiteral
	"Answer that the receiver has a literal text form recognized 
	by the compiler. "

	^true!

printOn: aStream 
	"Print nil."

	aStream nextPutAll: 'nil'!

storeOn: aStream 
	"Append to the argument aStream the literal 'nil'."

	aStream nextPutAll: 'nil'! !

!UndefinedObject methodsFor: 'testing'!

isManifest
	"Answer whether receiver is manifestly storable."

	^true!

isNil
	^true!

notNil
	^false! !

!UndefinedObject methodsFor: 'dependents access'!

addDependent: ignored
	self error: 'Nil should not have dependents'! !

!UndefinedObject methodsFor: 'dependents collection'!

asDependentsAsCollection
	" Answer the receiver, considered as a
	collection of dependents, as a real
	Collection.  Since the receiver represents
	an empty dependents collection, answer
	an empty Collection. "

	^#()!

asDependentsWith: anObject
	" Answer the receiver, considered as a
	collection of dependents, with anObject
	added.  Since the receiver represents
	an empty dependents collection, answer
	anObject, representing a dependents
	collection consisting of just that object. "

	^anObject!

asDependentsWithout: anObject
	" Answer the receiver, considered as a
	collection of dependents, with the first
	occurrence of anObject (if any) removed.
	Since the receiver represents an empty
	dependents collection, answer the receiver. "

	^self! !

!UndefinedObject methodsFor: 'updating'!

performUpdate: aSymbol!

performUpdate: aSymbol with: anObject!

update: anAspect!

update: anAspect from: aParameter!

update: anAspect with: aParameter!

update: anAspect with: aParameter from: anObject!

updateRequest
	^true!

updateRequest: anAspectSymbol
	^true! !

!UndefinedObject methodsFor: 'no-class messages'!

fetchCxxClassDescription
	^nil!

removeFromSystem!

removeSelector: ignored!

subclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat 
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver)."

	ClassBuilder nilSuperclassSignal raiseRequest.
	^self class classBuilder
		superclass: self;
		environment: self class environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		beFixed;
		reviseSystem!

variableByteSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat
	"This is the standard initialization message for creating a new class as a
subclass
	of an existing class (the receiver) in which the subclass is to have indexable
	byte-sized nonpointer variables."

	ClassBuilder nilSuperclassSignal raiseRequest.
	^self class classBuilder
		superclass: self;
		environment: self class environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		beBytes;
		reviseSystem!

variableSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver) in which the subclass is to have indexable
	pointer variables."

	ClassBuilder nilSuperclassSignal raiseRequest.
	^self class classBuilder
		superclass: self;
		environment: self class environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		beVariable;
		reviseSystem! !

!UndefinedObject methodsFor: 'fileIn/Out'!

storeBinaryOn: stream 
	"Put a binary representation of the receiver into stream."

	stream storeNil! !

!UndefinedObject methodsFor: 'extensions'!

notNil: nonNilBlock {Block}
	"Execute nonNilBlock with the receiver as an argument if the receiver is non-nil."
	"The nil case is handled in the class that defines nil."

	"noop"!

notNil: nonNilBlock {Block} else: elseB {Block}
	"Execute nonNilBlock with the receiver as an argument if the receiver is
	 non-nil.  If the receiver is NULL, then execute the else block."
	
	^elseB value!

notNULL: nonNULLBlock {Block} 
	"Execute nonNullBlock with the receiver as an argument if the receiver is
	 non-null.  If the receiver is NULL, then BLAST."
	"Should nil act like non null or like null?  This must be an error."

	self error: 'Using nil in a NULL context.'!

notNULL: nonNullBlock {Block} else: elseB {Block}
	"Execute nonNullBlock with the receiver as an argument if the receiver is
	 non-null.  If the receiver is NULL, then execute the else block."
	"Should nil act like non null or like null?  This must be an error."

	self error: 'Using nil in a NULL context.'! !

!UndefinedObject methodsFor: 'As yet unclassified'!

DoIt
	| t1 |
	^SystemOrganization categories do: [:t2 | Transcript show: t2; cr.
		(SystemOrganization listAtCategoryNamed: t2)
			do: 
				[:t3 | 
				(t1 _ Smalltalk at: t3) fileOutAll.
				self halt.
				t1 fileOut]]! !

!UndefinedObject methodsFor: 'accessing'!

{Heaper wimpy} make
	"INLINE"
	
	^ TheRemovedObject! !

!UndefinedObject methodsFor: 'smalltalk: init'!

initTimeNonInherited
	TheRemovedObject _ PrimRemovedObject create!

linkTimeNonInherited
	TheRemovedObject _ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UndefinedObject class
	instanceVariableNames: ''!


!UndefinedObject class methodsFor: 'instance creation'!

new
	self error: 'You may not create any more undefined objects--use nil'! !