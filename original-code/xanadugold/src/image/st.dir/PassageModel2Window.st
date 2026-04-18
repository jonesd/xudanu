'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:24 pm'!

Converter subclass: #PassageModel2Window
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(PassageModel2Window getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageModel2Window methodsFor: 'converting'!

{Heaper} convert: value {Heaper}
	^PassageWindowModel make: (value quickCast: PassageModel)!

create
	super create: PassageModel with: WindowModel! !

!PassageModel2Window methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
 oo<<  self getCategory name! !