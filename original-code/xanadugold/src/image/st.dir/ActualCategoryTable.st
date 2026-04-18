'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:24 pm'!

CategoryTable subclass: #ActualCategoryTable
	instanceVariableNames: 'myTable {PrimPtr2PtrTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Converters'!

(ActualCategoryTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ActualCategoryTable methodsFor: 'category accessing'!

{void} at: category {Category} introduce: value {Heaper}
	"add a new value, blasting if it is already there"
	myTable at: category introduce: value.!

{Heaper} fetchSubOf: category {Category}
	"find the contents at any subclass of this category"
	| result {Heaper} stepper {PrimPtr2PtrTableStepper} |
	result _ myTable fetch: category.
	result ~~ NULL ifTrue:
		[^result].
	stepper _ myTable stepper.
	[stepper hasValue] whileTrue: [ | aValue {Heaper wimpy} |
		aValue _ stepper get.
		((stepper heaperKey cast: Behavior) 
			isEqualOrSubclassOf: category) ifTrue: [^aValue].
		stepper step].
	^NULL!

{Heaper} fetchSuperOf: category {Category}
	"find the contents at the nearest superclass of this category"
	| parent {Category} |
	parent _ category.
	[parent ~~ NULL] whileTrue:
		[ | result {Heaper} |
		result _ myTable fetch: parent.
		result ~~ NULL ifTrue:
			[^result].
		parent _ parent fetchSuperCategory].
	^NULL!

{void} storeAll: other {CategoryTable}
	"store the contents of another category table into this one"
	| keys {PrimPtr2PtrTableStepper} |
	(keys _ (other cast: ActualCategoryTable) table stepper) forEach:
		[ :value {Heaper} |
			myTable at: keys heaperKey store: value]!

{PrimPtr2PtrTable} table
	^myTable! !

!ActualCategoryTable methodsFor: 'creation'!

create
	super create.
	myTable _ PrimPtr2PtrTable make: 16.! !

!ActualCategoryTable methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name.
	"myTable printOnWithSyntax: oo with: '[' with: ', ' with: ']'"! !