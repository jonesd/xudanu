'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:24 pm'!

Heaper subclass: #CategoryTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Converters'!

(CategoryTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CategoryTable methodsFor: 'deferred category accessing'!

{Heaper} fetchSubOf: category {Category}
	"find the contents at any subclass of this category"
	self subclassResponsibility!

{Heaper} fetchSuperOf: category {Category}
	"find the contents at the nearest superclass of this category"
	self subclassResponsibility!

{void} storeAll: other {CategoryTable}
	"store the contents of another category table into this one"
	self subclassResponsibility! !

!CategoryTable methodsFor: 'category accessing'!

{void} at: category {Category unused} introduce: value {Heaper unused}
	"add a new value, blasting if it is already there"
	Heaper BLAST: #FatalError.!

{Heaper} getSubOf: category {Category}
	"find the contents at any subclass of this category"
	| result {Heaper} |
	result _ self fetchSubOf: category.
	result == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^result!

{Heaper} getSuperOf: category {Category}
	"find the contents at the nearest superclass of this category"
	| result {Heaper} |
	result _ self fetchSuperOf: category.
	result == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^result! !

!CategoryTable methodsFor: 'creation'!

create
	super create.! !

!CategoryTable methodsFor: 'testing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CategoryTable class
	instanceVariableNames: ''!

(CategoryTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CategoryTable class methodsFor: 'pseudo constructors'!

make
	^ActualCategoryTable create!

make: front {CategoryTable} with: back {CategoryTable}
	^OccludingCategoryTable create: front with: back! !