'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:38 pm'!

Heaper subclass: #MichaelsCIVSuper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsCIVSuper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsCIVSuper methodsFor: 'overriding'!

{Int4} fetchLevel
	^1! !

!MichaelsCIVSuper methodsFor: 'creation'!

create
	super create.!

create: oo {ostream reference}
	super create.
	oo << 'MichaelsCIVSuper.  Level = ' << self fetchLevel << '
'.! !

!MichaelsCIVSuper methodsFor: 'accessing'!

{Int4} fetchClassInstanceVar
	^self class staticFetchClassInstanceVar! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MichaelsCIVSuper class
	instanceVariableNames: 'classInstanceVar {Int4} '!

(MichaelsCIVSuper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsCIVSuper class methodsFor: 'pseudo constructors'!

{MichaelsCIVSuper} make
	^self create!

{MichaelsCIVSub} make: oo {ostream reference}
	^self create: oo! !

!MichaelsCIVSuper class methodsFor: 'accessing'!

{Int4} staticFetchClassInstanceVar
	^classInstanceVar! !

!MichaelsCIVSuper class methodsFor: 'smalltalk initialization'!

{Int4} linkTimeNonInherited

	classInstanceVar _ 1.!

needsColons
	"Tells translator that we need the scope-resolution ::s to get to class methods."
	^true! !