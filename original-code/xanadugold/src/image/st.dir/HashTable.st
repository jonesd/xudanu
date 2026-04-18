'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:54 pm'!

MuTable subclass: #HashTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(HashTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!HashTable methodsFor: 'accessing'!

{Heaper} at: key {Position} store: value {Heaper} 
	"Associate value with key, whether or not
	 there is a previous association."

	self subclassResponsibility!

{CoordinateSpace} coordinateSpace
	
	self subclassResponsibility!

{IntegerVar} count

	self subclassResponsibility!

{XnRegion} domain

	self subclassResponsibility.!

{Heaper} fetch: key {Position} 

	self subclassResponsibility!

{ScruTable} subTable: reg {XnRegion} 

	self subclassResponsibility!

{BooleanVar} wipe: anIdx {Position}
	"Remove a key->value association from the table.
	 Do not blast (or do anything else) if the key is not in my current domain."

	self subclassResponsibility! !

!HashTable methodsFor: 'testing'!

{BooleanVar} includesKey: aKey {Position}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility.! !

!HashTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	self subclassResponsibility!

{Heaper} theOne
	self subclassResponsibility! !

!HashTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	self subclassResponsibility! !

!HashTable methodsFor: 'creation'!

{ScruTable} copy
	self subclassResponsibility!

{ScruTable} emptySize: size {IntegerVar}

	self subclassResponsibility! !

!HashTable methodsFor: 'protected: create'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HashTable class
	instanceVariableNames: ''!

(HashTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!HashTable class methodsFor: 'pseudo constructors'!

{HashTable INLINE} make.CoordinateSpace: cs {CoordinateSpace}
	^ActualHashTable make: cs!

make.CoordinateSpace: cs {CoordinateSpace} with: size {IntegerVar}
	^ActualHashTable make: cs with: (size DOTasLong bitOr: 1)! !

!HashTable class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: ImmuSet. "for the empty set domain"
	self REQUIRES: LPPrimeSizeProvider! !