'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:11 pm'!

Heaper subclass: #ScreenPlayEvent
	instanceVariableNames: '
		myReceiver {Performer}
		myCastClass {Behavior}
		mySelector {Symbol}
		myArguments {MuTable of: Integer and: Performer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!

(ScreenPlayEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!