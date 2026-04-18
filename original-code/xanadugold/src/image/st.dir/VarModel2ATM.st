'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:48 pm'!

Converter subclass: #VarModel2ATM
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-atmod'!

(VarModel2ATM getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VarModel2ATM methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	
	^ VarTextModel make: (value basicCast: VariableModel)! !

!VarModel2ATM methodsFor: 'creation'!

create
	super create: VariableModel with: AttributedTextModel! !