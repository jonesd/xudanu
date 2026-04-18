'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:40 pm'!

FMScaffold subclass: #FMTableScaffold
	instanceVariableNames: 'dictInternal {ScruTable of: Category and: FMBuilder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMTableScaffold getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTableScaffold */
friend SPTR(FMScaffold) fMScaffold (ScruTable OF2(Category,FMBuilder) * dict);
friend SPTR(FMScaffold) fMScaffold (ScruTable OF2(Category,FMBuilder) * dict, FMScaffold * other);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTableScaffold methodsFor: 'unprotected: accessing'!

{FMBuilder} fetchBuilder: model {Heaper} 
	"Return the appropriate builder for model."

	| cat {Category star} |
	cat _ model getCategory.
	[cat isEqual: Heaper]
		whileFalse: 
			[| builder {Heaper} |
			builder _ dictInternal fetch: (HeaperAsPosition make: cat).
			builder ~~ NULL ifTrue: [^builder quickCast: FMBuilder].
			cat _ cat getSuperCategory].	
	"Didn't find one. Look in the parent scaffold."
	self fetchParent == NULL
		ifTrue: [^ NULL]
		ifFalse: [^ self fetchParent fetchBuilder: model]! !

!FMTableScaffold methodsFor: 'printing'!

{void}printOn: oo {ostream reference}
	oo << self getCategory name << '(' << dictInternal << ' | ' << self fetchParent << ')'! !

!FMTableScaffold methodsFor: 'private: creation'!

create: dict {ScruTable of: Category and: FMBuilder} with: parent {FMScaffold | NULL}
	super create: parent.
	dictInternal _ dict! !