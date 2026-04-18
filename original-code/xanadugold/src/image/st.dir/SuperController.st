'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:48 pm'!

FMController subclass: #SuperController
	instanceVariableNames: 'myController {FMController}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
SuperController comment:
'Instances contain another controller in them.'!

(SuperController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SuperController methodsFor: 'protected: accessing'!

{FMController} controller
	^myController! !

!SuperController methodsFor: 'create'!

create: controller {FMController}
	super create.
	myController _ controller.! !

!SuperController methodsFor: 'smalltalk:'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: myController! !

!SuperController methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	"Pass the event down the controller hierarchy."

	myController handleEvent: event!

{BooleanVar} requestEvents: event {FMEvent} 
	"Pass the request query down the hierarchy."
	
	^event requestIn: myController! !

!SuperController methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !