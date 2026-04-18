'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:47 pm'!

Converter subclass: #MuWordArray2STM
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-atmod'!

(MuWordArray2STM getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MuWordArray2STM methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	^ SelectedTextModel make: (LocalTextModel make.WordArray: (value basicCast: MuWordArray))! !

!MuWordArray2STM methodsFor: 'creation'!

create
	super create: MuWordArray with: SelectedTextModel! !