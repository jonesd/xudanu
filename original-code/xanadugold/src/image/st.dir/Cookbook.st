'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:58 pm'!

Heaper subclass: #Cookbook
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!

(Cookbook getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Cookbook methodsFor: 'accessing'!

{Category} bootCategory
	self subclassResponsibility!

{Recipe} fetchRecipe: cat {Category}
	self subclassResponsibility!

{Category} getCategoryFor: no {IntegerVar}
	self subclassResponsibility!

{Recipe} getRecipe: cat {Category}
	self subclassResponsibility!

{char star} id
	"return a string that uniquely determines the version of the cookbook. It 
	should change whenever classes are added or removed, or when their storage 
	or transmission protocol changes"

	self subclassResponsibility!

{Cookbook} next
	self subclassResponsibility!

{IntegerVar} numberOfCategory: cat {Category}
	self subclassResponsibility!

{PtrArray} recipes 
	self subclassResponsibility! !

!Cookbook methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	self subclassResponsibility! !

!Cookbook methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Cookbook class
	instanceVariableNames: ''!

(Cookbook getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Cookbook class methodsFor: 'declaring'!

{Cookbook} declareCookbook: id {char star} with: bootCat {Category} with: cuisine {Recipe}
	"Create and register a cookbook.  The cookbook can be looked up according to etiher its name or bootCategory."
	
	| recipes {PtrArray} count {Int32} |
	"preorder -> recipe."
	recipes _ WeakPtrArray make: XnExecutor noopExecutor with: Heaper preorderMax + 1.
	count _ ActualCookbook addCuisine: cuisine to: recipes.
	^ActualCookbook create: bootCat with: id with: recipes with: count!

{Cookbook} declareCookbook: id {char star} with: bootCat {Category} with: cuisine1 {Recipe} with: cuisine2 {Recipe}
	"Create and register a cookbook.  The cookbook can be looked up according to etiher its name or bootCategory."
	
	| recipes {PtrArray} count {Int32} |
	"preorder -> recipe."
	recipes _ WeakPtrArray make: XnExecutor noopExecutor with: Heaper preorderMax + 1.
	count _ ActualCookbook addCuisine: cuisine1 to: recipes.
	count _ count + (ActualCookbook addCuisine: cuisine2 to: recipes).
	^ActualCookbook create: bootCat with: id with: recipes with: count!

{Cookbook} declareCookbook: id {char star} with: bootCat {Category} with: cuisine1 {Recipe} with: cuisine2 {Recipe} with: cuisine3 {Recipe}
	"Create and register a cookbook.  The cookbook can be looked up according to etiher its name or bootCategory."
	
	| recipes {PtrArray} count {Int32} |
	"preorder -> recipe."
	recipes _ WeakPtrArray make: XnExecutor noopExecutor with: Heaper preorderMax + 1.
	count _ ActualCookbook addCuisine: cuisine1 to: recipes.
	count _ count + (ActualCookbook addCuisine: cuisine2 to: recipes).
	count _ count + (ActualCookbook addCuisine: cuisine3 to: recipes).
	^ActualCookbook create: bootCat with: id with: recipes with: count!

{Cookbook} declareCookbook: id {char star} with: bootCat {Category} with: cuisine1 {Recipe} with: cuisine2 {Recipe} with: cuisine3 {Recipe} with: cuisine4 {Recipe}
	"Create and register a cookbook.  The cookbook can be looked up according to etiher its name or bootCategory."
	
	| recipes {PtrArray} count {Int32} |
	"preorder -> recipe."
	recipes _ WeakPtrArray make: XnExecutor noopExecutor with: Heaper preorderMax + 1.
	count _ ActualCookbook addCuisine: cuisine1 to: recipes.
	count _ count + (ActualCookbook addCuisine: cuisine2 to: recipes).
	count _ count + (ActualCookbook addCuisine: cuisine3 to: recipes).
	count _ count + (ActualCookbook addCuisine: cuisine4 to: recipes).
	^ActualCookbook create: bootCat with: id with: recipes with: count! !

!Cookbook class methodsFor: 'creation'!

{Cookbook} make
	"Just return the empty cookbook."
	^ActualCookbook make.String: 'empty'!

{Cookbook} make.Category: bootCat {Category}
	"Return the cookbook registered for the given bootCategory."
	
	^ActualCookbook make.Category: bootCat!

{Cookbook} make.String: id {char star}
	"Return the cookbook registered for the given string."

	^ActualCookbook make.String: id! !