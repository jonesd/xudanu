'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:56 pm'!

CoreA subclass: #CoreB
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgcore'!

(CoreB getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CoreB methodsFor: 'create'!

create: n {Int32}
	super create: n! !

!CoreB methodsFor: 'accessing'!

{Int32} zoom: oo {ostream reference}
	oo << self << '->zoom ()
'.
	^self number * 10! !