'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:03 pm'!

SimpleUpdateRecord subclass: #WindowFrontUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(WindowFrontUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowFrontUpdate methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name  << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WindowFrontUpdate class
	instanceVariableNames: ''!

(WindowFrontUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowFrontUpdate class methodsFor: 'make'!

make
	^theRecord cast: self! !