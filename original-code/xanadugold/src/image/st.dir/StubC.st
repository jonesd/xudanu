'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:57 pm'!

StubA subclass: #StubC
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgstub'!

(StubC getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(PACKAGE CoreC ); yourself)!

!StubC methodsFor: 'accessing'!

{void} zap: oo {ostream reference} with: a {Int32} with: b {Int32}
	oo << self << '->zap (' << a << ',' << b << ')
'.
	self contents zap: oo with: a with: b! !