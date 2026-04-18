'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:56 pm'!

Package subclass: #StubA
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgstub'!

(StubA getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(PACKAGE CoreA ); add: #DEFERRED; yourself)!

!StubA methodsFor: 'accessing'!

{Int32} number
	^self contents number!

{void} zip: oo {ostream reference} with: n {Int32}
	oo << self << '->zip (' << n << ')
'.
	self contents zip: oo with: n! !

!StubA methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self contents << ')'! !