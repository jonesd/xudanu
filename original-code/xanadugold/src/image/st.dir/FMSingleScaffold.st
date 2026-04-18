'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:40 pm'!

FMScaffold subclass: #FMSingleScaffold
	instanceVariableNames: '
		myBuilder {FMBuilder}
		myCategory {Category star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMSingleScaffold getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMSingleScaffold */
friend SPTR(FMScaffold) fMScaffold (Category * cat, FMBuilder * builder);
friend SPTR(FMScaffold) fMScaffold (Category * cat, FMBuilder * builder, FMScaffold * other);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMSingleScaffold methodsFor: 'private: creation'!

create: cat {Category star} with: onBuilder {FMBuilder} with: parent {FMScaffold}

	super create: parent.
	myBuilder _ onBuilder.
	myCategory _ cat! !

!FMSingleScaffold methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' << myCategory << ' -> '.
	oo << myBuilder << ' | ' << self fetchParent << ')'! !

!FMSingleScaffold methodsFor: 'unprotected: accessing'!

{FMBuilder} fetchBuilder: model {Heaper} 
	"Return the appropriate builder for model."

	(model getCategory isEqualOrSubclassOf: myCategory)
		ifTrue: [^myBuilder]
		ifFalse: [self fetchParent == NULL
				ifTrue: [^NULL]
				ifFalse: [^self fetchParent fetchBuilder: model]]! !