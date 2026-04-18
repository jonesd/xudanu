'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:58 pm'!

Package subclass: #AppA
	instanceVariableNames: 'myNumber {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgapp'!

(AppA getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(PACKAGE StubA ); yourself)!

!AppA methodsFor: 'accessing'!

{void} zipTwice: oo {ostream reference} with: n {Int32}
	self contents zip: oo with: n.
	self contents zip: oo with: n + 1.! !

!AppA methodsFor: 'create'!

{void} constructPackage
	super constructPackage.
	myNumber _ self contents number * 10! !

!AppA methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumber << ',' << self contents << ')'! !