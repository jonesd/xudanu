'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:47 pm'!

Converter subclass: #ATM2STM
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-atmod'!

(ATM2STM getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ATM2STM methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}

	^ SelectedTextModel make: (value basicCast: AttributedTextModel)! !

!ATM2STM methodsFor: 'creation'!

create
	super create: AttributedTextModel with: SelectedTextModel! !