'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:56 pm'!

CoreA subclass: #CoreC
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgcore'!

(CoreC getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CoreC methodsFor: 'create'!

create: n {Int32}
	super create: n! !

!CoreC methodsFor: 'accessing'!

{void} zap: oo {ostream reference} with: a {Int32} with: b {Int32}
	oo << self << '->zap (' << a << ',' << b << ')
'! !