'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:39 pm'!

Heaper subclass: #FMScaffold
	instanceVariableNames: 'myParent {FMScaffold | NULL}'
	classVariableNames: 'NoBuilderSignal {Signal smalltalk} '
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMScaffold getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMScaffold methodsFor: 'building'!

{FMBuilding} build: model {Heaper}
	"Find the appropriate FMBuilder from the table and apply it to model."
	
	| builder {FMBuilder} |
	builder _ self fetchBuilder: model.
	builder ~~ NULL ifTrue: [^builder build: model].
	Heaper BLAST: #NoBuilder  "With: model".
	^NULL! !

!FMScaffold methodsFor: 'testing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!FMScaffold methodsFor: 'unprotected accessing'!

{FMBuilder} fetchBuilder: model {Heaper} 
	"Return the appropriate builder for model."

	self subclassResponsibility! !

!FMScaffold methodsFor: 'protected: accessing'!

{FMScaffold} fetchParent

	^ myParent! !

!FMScaffold methodsFor: 'protected: creation'!

create
	super create.!

create: parent {FMScaffold}
	super create.
	myParent _ parent! !

!FMScaffold methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMScaffold class
	instanceVariableNames: ''!

(FMScaffold getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMScaffold class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage 
	Scaffold _ NULL! !

!FMScaffold class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited 
	"FMScaffold initialize."
	
	self REQUIRES: HeaperSpace.
	self REQUIRES:  MuTable.
	Scaffold fluidSet: (FMScaffold make: (MuTable make: HeaperSpace make))!

staticTimeNonInherited

	FMScaffold defineFluid: #Scaffold with: Emulsion globalEmulsion with: [NULL].! !

!FMScaffold class methodsFor: 'pseudo constructors'!

make.Category: cat {Category star} with: builder{FMBuilder}
	^FMSingleScaffold create: cat with: builder with: NULL!

make: dict {ScruTable of: Category and: FMBuilder}
	^FMTableScaffold create: dict with: NULL!

make: dict {ScruTable of: Category and: FMBuilder} with: other {FMScaffold}
	^FMTableScaffold create: dict with: other!

make: cat {Category star} with: builder {FMBuilder} with: other {FMScaffold}
	^FMSingleScaffold create: cat with: builder with: other! !