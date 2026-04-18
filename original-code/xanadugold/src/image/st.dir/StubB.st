'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:57 pm'!

StubA subclass: #StubB
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgstub'!

(StubB getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(PACKAGE CoreB ); yourself)!

!StubB methodsFor: 'accessing'!

{Int32} zoom: oo {ostream reference}
	oo << self << '->zoom ()
'.
	^self contents zoom: oo! !