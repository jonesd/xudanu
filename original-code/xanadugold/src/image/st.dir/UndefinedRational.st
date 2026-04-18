'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:06 pm'!

Rational subclass: #UndefinedRational
	instanceVariableNames: ''
	classVariableNames: 'TheUndefined {UndefinedRational} '
	poolDictionaries: ''
	category: 'Xanadu-Calc'!

(UndefinedRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #EQ; yourself)!

!UndefinedRational methodsFor: 'creation'!

create
	super create: 1 with: Int32Zero! !

!UndefinedRational methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '()'! !

!UndefinedRational methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UndefinedRational class
	instanceVariableNames: ''!

(UndefinedRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #EQ; yourself)!

!UndefinedRational class methodsFor: 'rcvr pseudo constructor'!

{Heaper} make.Rcvr: rcvr {Rcvr unused}
	(rcvr cast: SpecialistRcvr) registerIbid: TheUndefined.
	^TheUndefined! !

!UndefinedRational class methodsFor: 'pseudo constructor'!

make
	^ TheUndefined! !

!UndefinedRational class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	TheUndefined _ self create!

linkTimeNonInherited
	TheUndefined _ NULL! !