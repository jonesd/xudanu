'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:55 pm'!

Heaper subclass: #CoreA
	instanceVariableNames: 'myNumber {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgcore'!

(CoreA getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CoreA methodsFor: 'create'!

create
	super create.
	myNumber _ 666!

create: n {Int32}
	super create.
	myNumber _ n! !

!CoreA methodsFor: 'accessing'!

{Int32 INLINE} number
	^myNumber!

{void} zip: oo {ostream reference} with: a {Int32}
	oo << self << '->zip (' << a << ')
'! !

!CoreA methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumber << ')'! !