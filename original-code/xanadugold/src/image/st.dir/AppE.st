'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:58 pm'!

AppD subclass: #AppE
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgapp'!

(AppE getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(PACKAGE StubAHook ); yourself)!

!AppE methodsFor: 'accessing'!

{void} boom: oo {ostream reference} with: a {Int32} with: b {Int32}
	oo << self << '->boom (' << a << ',' << b << ')
'! !