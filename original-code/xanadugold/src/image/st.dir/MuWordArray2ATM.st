'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:47 pm'!

Converter subclass: #MuWordArray2ATM
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-atmod'!

(MuWordArray2ATM getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MuWordArray2ATM methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	
	^ LocalTextModel make.WordArray: (value basicCast: MuWordArray)! !

!MuWordArray2ATM methodsFor: 'creation'!

create
	super create: MuWordArray with: AttributedTextModel! !