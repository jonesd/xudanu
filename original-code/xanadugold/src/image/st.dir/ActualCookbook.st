'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:55 pm'!

Cookbook subclass: #ActualCookbook
	instanceVariableNames: '
		myName {char star}
		myBootCategory {Category}
		myNext {Cookbook}
		myRecipes {PtrArray of: Recipe}
		myDecoding {PtrArray of: Category}
		myEncoding {UInt32Array}'
	classVariableNames: 'TheCookbooks {Cookbook} '
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
ActualCookbook comment:
'We internally map from Category to preorder number for the category and lookup using that preorder number.'!

(ActualCookbook getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ActualCookbook methodsFor: 'accessing'!

{Category} bootCategory
	^myBootCategory!

{Recipe} fetchRecipe: cat {Category}
	^(myRecipes fetch: cat preorderNumber) cast: Recipe!

{Category} getCategoryFor: no {IntegerVar}
	| category {Category} |
	category _ (myDecoding fetch: no DOTasLong) cast: Category.
	category == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^category!

{Recipe} getRecipe: cat {Category}
	| recipe {Recipe} |
	recipe _ (myRecipes fetch: cat preorderNumber) cast: Recipe.
	recipe == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^recipe!

{char star} id
	^myName!

{Cookbook} next
	^myNext!

{IntegerVar} numberOfCategory: cat {Category}
	| num {Int32} |
	num _ myEncoding uIntAt: cat preorderNumber.
	num >= myRecipes count ifTrue: [Heaper BLAST: #UnencodedCategory].
	^num!

{PtrArray} recipes 
	^myRecipes! !

!ActualCookbook methodsFor: 'creation'!

create: cat {Category} with: id {char star} with: recipes {PtrArray of: Recipe} with: count {Int32}
	| preorderLimit {Int32} code {Int32} |
	super create.
	myName _ id.
	myBootCategory _ cat.
	preorderLimit _ Heaper preorderMax + 1.
	"preorder -> recipe."
	myRecipes _ recipes.
	"preorder -> code."
	myEncoding _ UInt32Array make: preorderLimit.
	"code -> category"
	myDecoding _ PtrArray nulls: count.
	code _ Int32Zero.
	Int32Zero almostTo: preorderLimit do: 
		[:i {Int32} |
		| recipe {Recipe} |
		recipe _ (myRecipes fetch: i) cast: Recipe.
		recipe == NULL
			ifTrue: [myEncoding at: i storeUInt: preorderLimit]
			ifFalse:
				[myEncoding at: i storeUInt: code.
				myDecoding at: code store: recipe categoryOfDish.
				code _ code + 1]].
	myNext _ TheCookbooks.
	TheCookbooks _ self!

{void} destroy
	"ActualCookbooks last for the whole run."! !

!ActualCookbook methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << 'an ' << self getCategory name! !

!ActualCookbook methodsFor: 'smalltalk: hooks:'!

{void RECEIVE.HOOK} receiveClassList: rcvr {Rcvr}
	| count {IntegerVar} |
	count _ rcvr receiveIntegerVar.
	myRecipes  _ MuTable make: HeaperSpace make.
	Int32Zero almostTo: count do: 
		[:i {Int32} | | clName {String} cl {Category} |
		clName _ rcvr receiveString.
		[cl _ Smalltalk at: clName asSymbol ifAbsent: [Cookbook BLAST: 'class name not recognized']] smalltalkOnly.
		myRecipes at: cl store: cl getRecipe.]!

{void SEND.HOOK} sendClassList: xmtr {Xmtr}
	xmtr sendIntegerVar: myRecipes count.
	myRecipes stepper forEach: [:rec | xmtr sendString: rec categoryOfDish name]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualCookbook class
	instanceVariableNames: ''!

(ActualCookbook getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ActualCookbook class methodsFor: 'global: utility'!

{Int32} addCuisine: cuisine {Recipe} to: recipes {PtrArray}
	| recipe {Recipe} count {Int32} |
	count _ Int32Zero.
	recipe _ cuisine.
	[recipe ~~ NULL] whileTrue:
		[recipes at: recipe categoryOfDish preorderNumber store: recipe.
		count _ count + 1.
		recipe _ recipe next].
	^count! !

!ActualCookbook class methodsFor: 'creation'!

{Cookbook} make.Category: bootCat {Category}
	| cookbook {Cookbook} |
	cookbook _ TheCookbooks.
	[cookbook ~~ NULL] whileTrue:
		[(cookbook bootCategory isEqual: bootCat) ifTrue: [^cookbook].
		cookbook _ cookbook next].
	Heaper BLAST: #UnknownCookbook.
	^NULL "fodder"!

{Cookbook} make.String: id {char star}
	| cookbook {Cookbook} |
	cookbook _ TheCookbooks.
	[cookbook ~~ NULL] whileTrue:
		[(String strcmp: cookbook id with: id) == Int32Zero ifTrue: [^cookbook].
		cookbook _ cookbook next].
	Heaper BLAST: #UnknownCookbook.
	^NULL "fodder"! !

!ActualCookbook class methodsFor: 'smalltalk: initialization'!

{void} cleanupGarbage
	TheCookbooks _ NULL!

initTimeNonInherited
	Cookbook declareCookbook: 'empty' with: Heaper with: NULL!

{void} linkTimeNonInherited
	TheCookbooks _ NULL! !