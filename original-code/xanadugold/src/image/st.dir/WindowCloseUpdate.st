'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:03 pm'!

SimpleUpdateRecord subclass: #WindowCloseUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(WindowCloseUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowCloseUpdate methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WindowCloseUpdate class
	instanceVariableNames: ''!

(WindowCloseUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowCloseUpdate class methodsFor: 'make'!

make
	^theRecord cast: self! !