'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:58 pm'!

AppA subclass: #AppD
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgapp'!

(AppD getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(PACKAGE StubAHook ); add: #DEFERRED; yourself)!

!AppD methodsFor: 'accessing'!

{void} bang: oo {ostream reference} with: x {Int32}
	oo << self << '->bang (' << x << ')
'! !