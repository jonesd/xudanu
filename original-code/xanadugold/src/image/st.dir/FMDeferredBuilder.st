'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:37 pm'!

FMBuilder subclass: #FMDeferredBuilder
	instanceVariableNames: 'myBuilder {VariableModel of: FMBuilder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!
FMDeferredBuilder comment:
'This class represents a builder used for late
binding during execution.  It is used in conjunction with
directors where the builder for components is not known at
the time the director is built (and the director cannot
otherwise control the scaffolding of the correct builder)'!

(FMDeferredBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMDeferredBuilder */
friend SPTR(FMDeferredBuilder)  fMDeferredBuilder
(FMBuilder * onBuilder);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDeferredBuilder methodsFor: 'accessing'!

{FMBuilder} builder

	^ myBuilder getValue cast: FMBuilder!

{VariableModel of: FMBuilder} builderModel

	^ myBuilder! !

!FMDeferredBuilder methodsFor: 'build'!

{FMBuilding} build: thing {Heaper}

	^ (myBuilder getValue cast: FMBuilder) build: thing! !

!FMDeferredBuilder methodsFor: 'private: create'!

create: aBuilder {FMBuilder}

	super create.
	myBuilder _ VariableModel make: aBuilder! !

!FMDeferredBuilder methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMDeferredBuilder class
	instanceVariableNames: ''!

(FMDeferredBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMDeferredBuilder */
friend SPTR(FMDeferredBuilder)  fMDeferredBuilder
(FMBuilder * onBuilder);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDeferredBuilder class methodsFor: 'pseudoConstructors'!

make: onBuilder {FMBuilder}

	^ self create: onBuilder! !