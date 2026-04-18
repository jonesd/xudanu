'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:13 pm'!

Heaper subclass: #Recipe
	instanceVariableNames: '
		myCat {Category}
		myNext {Recipe}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!
Recipe comment:
'The table of all recipes in the system is maintained in the Cookbook module.  
Subclasses know how to craete instances of a particular class.'!

(Recipe getOrMakeCxxClassDescription)
	friends:
'friend class Cookbook;
friend Int4  addCuisineTo (APTR(Recipe) cuisine, APTR(PtrArray) recipes);';
	attributes: ((Set new) add: #NO.GC; add: #DEFERRED; yourself)!

!Recipe methodsFor: 'accessing'!

{Category} categoryOfDish

	^myCat! !

!Recipe methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myCat << ')'.! !

!Recipe methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self categoryOfDish hashForEqual * 701!

{BooleanVar} isEqual: other {Heaper}
	other cast: Recipe 
		into: [:rec | ^rec categoryOfDish isEqual: self categoryOfDish]
		others: [^false].
	^false! !

!Recipe methodsFor: 'private: accessing'!

{Recipe} next
	"Returnt the next recipe in the receiver's cuisine."
	
	^myNext! !

!Recipe methodsFor: 'protected: creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create.
	myCat _ cat.
	myNext _ cuisine refValue.
	cuisine refAssign: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Recipe class
	instanceVariableNames: ''!

(Recipe getOrMakeCxxClassDescription)
	friends:
'friend class Cookbook;
friend Int4  addCuisineTo (APTR(Recipe) cuisine, APTR(PtrArray) recipes);';
	attributes: ((Set new) add: #NO.GC; add: #DEFERRED; yourself)!

!Recipe class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	Recipe star defineGlobal: #XppCuisine with: NULL.!

{void} mapCuisine: cxc {CxxClassDescription}
	"Get a cuisine name from a directory name."

	| cuisine {char star} |
	cuisine _ cxc fetchAttribute: #COPY.
	cuisine == NULL ifTrue: [cuisine _ cxc fetchDirectory notNil: [:d | d key] else: ['Xanadu']].
	cuisine := cuisine asString.
	cuisine = 'xlatexpp' ifTrue: [^'XppCuisine'].
	cuisine = 'comm' ifTrue: [^'XppCuisine'].
	cuisine = 'server' ifTrue: [^'DiskCuisine'].
	cuisine = 'spires' ifTrue: [^'SpireCuisine'].
	^cuisine asString asCapitalized, 'Cuisine'!

{void} staticTimeNonInherited

	[Heaper allSubclassesDo: 
		[:cls {Behavior} |
		cls fetchCxxClassDescription notNil:
			[:cxc |
			((cxc includesAttribute: #COPY)
				and: [(cxc includesAttribute: #MANUAL.RECIPE) not
				and: [cxc includesAttribute: #CONCRETE]])
				ifTrue: 
					[ActualCopyRecipe create: cls with: 
						(Smalltalk associationAt: (self mapCuisine: cxc) asSymbol 
								ifAbsent: [Association new])].
			((cxc includesAttribute: #PSEUDO.COPY)
				and: [cxc includesAttribute: #CONCRETE])
				ifTrue: 
					[PseudoCopyRecipe create: cls with: 
						(Smalltalk associationAt: (self mapCuisine: cxc) asSymbol 
								ifAbsent: [Association new])].			
			"(cxc includesAttribute: #BY.PROXY)
				ifTrue: 
					[| proxy |
					proxy _ Smalltalk at: (cls name, 'Proxy') asSymbol ifAbsent: [].
					proxy ~~ nil ifTrue:
						[ActualProxyRecipe 
							create: proxy
							with: 
								(Smalltalk associationAt: (self mapCuisine: cxc) asSymbol 
									ifAbsent: [Association new])]]"]]] smalltalkOnly! !