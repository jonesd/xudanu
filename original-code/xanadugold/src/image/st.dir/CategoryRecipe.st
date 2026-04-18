'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:49 pm'!

CopyRecipe subclass: #CategoryRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(CategoryRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CategoryRecipe methodsFor: 'accessing'!

{Heaper} parse: rcvr {SpecialistRcvr}

	| cat {Category} |
	cat _ (rcvr cast: SpecialistRcvr) receiveCategory.
	rcvr registerIbid: cat.
	^cat!

{void} parse: rcvr {Rcvr unused} into: memory {void star unused}

	Heaper BLAST: #NotBecomable! !

!CategoryRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CategoryRecipe class
	instanceVariableNames: ''!

(CategoryRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CategoryRecipe class methodsFor: 'smalltalk: smalltalk initialization'!

staticTimeNonInherited
	
	'extern Category * cat_Category;
		CategoryRecipe categoryRecipe(cat_Category, &XppCuisine);' translateOnly.
	[self create: Category with: (Smalltalk associationAt: #XppCuisine)] smalltalkOnly! !