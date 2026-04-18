'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:38 pm'!

MichaelsCIVSuper subclass: #MichaelsCIVSub
	instanceVariableNames: ''
	classVariableNames: 'ClassVar {Heaper} '
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsCIVSub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsCIVSub methodsFor: 'creation'!

create
	super create.!

create: oo {ostream reference}
	super create: oo.
	oo << 'MichaelsCIVSub.  Level = ' << self fetchLevel << '
'.! !

!MichaelsCIVSub methodsFor: 'overriding'!

{Int4} fetchLevel
	^2! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MichaelsCIVSub class
	instanceVariableNames: ''!

(MichaelsCIVSub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsCIVSub class methodsFor: 'pseudo constructors'!

{MichaelsCIVSub} make
	^self create!

{MichaelsCIVSub} make: oo {ostream reference}
	^self create: oo! !

!MichaelsCIVSub class methodsFor: 'smalltalk initialization'!

{Int4} linkTimeNonInherited

	classInstanceVar _ 2.! !