'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:33 pm'!

ImmuSet subclass: #EmptyImmuSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!

(EmptyImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!EmptyImmuSet methodsFor: 'enumerating'!

{IntegerVar} count
	^ IntegerVar0!

{Stepper} stepper
	^ Stepper emptyStepper!

{Heaper} theOne
	Heaper BLAST: #NotOneElement.
	^ NULL! !

!EmptyImmuSet methodsFor: 'adding-removing'!

{ImmuSet} with: anElement {Heaper}
	^TinyImmuSet make: anElement!

{ImmuSet} without: anElement {Heaper unused}
	^ self! !

!EmptyImmuSet methodsFor: 'accessing'!

{BooleanVar} hasMember: someone {Heaper unused}
	^ false!

{BooleanVar} isEmpty
	^ true!

{BooleanVar} isSubsetOf: another {ScruSet unused}
	^ true! !

!EmptyImmuSet methodsFor: 'operations'!

{ImmuSet} intersect: another {ScruSet unused} 
	^ self!

{ImmuSet} minus: another {ScruSet unused}
	^ self!

{ImmuSet} unionWith: another {ScruSet}
	^ another asImmuSet! !

!EmptyImmuSet methodsFor: 'conversion'!

{MuSet} asMuSet
	^ MuSet make! !

!EmptyImmuSet methodsFor: 'unprotected for initer create'!

create
	super create! !

!EmptyImmuSet methodsFor: 'creation'!

{void} destroy
	"Don't destroy our single instance"! !

!EmptyImmuSet methodsFor: 'protected: destruct'!

{void} destruct
	"This object is a canonical single instance, so its destructor should only be called after main has exited."
	 
	'if (!!Initializer::inStaticDestruction()) BLAST(SanityViolation);' translateOnly.
	super destruct! !

!EmptyImmuSet methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EmptyImmuSet class
	instanceVariableNames: ''!

(EmptyImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!EmptyImmuSet class methodsFor: 'rcvr pseudo constructor'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: ImmuSet make.
	^ImmuSet make! !