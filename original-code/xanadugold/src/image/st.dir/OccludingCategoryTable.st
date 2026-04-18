'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:03 pm'!

CategoryTable subclass: #OccludingCategoryTable
	instanceVariableNames: '
		myFront {CategoryTable}
		myBack {CategoryTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-convert'!

(OccludingCategoryTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OccludingCategoryTable methodsFor: 'instance creation'!

create: front {CategoryTable} with: back {CategoryTable}
	super create.
	myFront _ front.
	myBack _ back.! !

!OccludingCategoryTable methodsFor: 'category accessing'!

{void} at: category {Category unused} introduce: value {Heaper unused}
	"add a new value, blasting if it is already there"
	self unimplemented!

{Heaper} fetchSubOf: category {Category}
	"find the contents at any subclass of this category"
	| result {Heaper} |
	(result _ myFront fetchSubOf: category) ~~ NULL
		ifTrue: [^result].
	^myBack fetchSubOf: category!

{Heaper} fetchSuperOf: category {Category}
	"find the contents at the nearest superclass of this category"
	| result {Heaper} |
	(result _ myFront fetchSuperOf: category) ~~ NULL
		ifTrue: [^result].
	^myBack fetchSuperOf: category!

{void} storeAll: other {CategoryTable unused}
	"store the contents of another category table into this one"
	Heaper BLAST: #FatalError.! !

!OccludingCategoryTable methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '{'.
	myFront printOn: oo.
	oo << ' || '.
	myBack printOn: oo.
	oo << '}'! !