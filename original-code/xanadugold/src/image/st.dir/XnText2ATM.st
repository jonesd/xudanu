'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:21 pm'!

Converter subclass: #XnText2ATM
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Text'!

(XnText2ATM getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XnText2ATM methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	
	| myText {XuText} |
	myText _ value basicCast: XuText.
	^ WaldoTextModel make: myText! !

!XnText2ATM methodsFor: 'creation'!

create
	"super create: XuText with: AttributedTextModel"! !