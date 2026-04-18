'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:47 pm'!

FMController subclass: #SimpleScrollController
	instanceVariableNames: '
		myView {Viewer}
		myOffsetVar {VariableModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!

(SimpleScrollController getOrMakeCxxClassDescription)
	friends:
'/* friends for class SimpleScrollController */
friend SPTR(SimpleScrollController) 
simpleScrollController (Viewer * view, VariableModel *
var);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SimpleScrollController methodsFor: 'control'!

{void} handleEvent: anEvent {FMEvent} 
	myOffsetVar setValue: (anEvent pointIn: myView)!

{BooleanVar} requestEvents: event {FMEvent}
	"Inform the handler if event is desired."

	^event selectUpFn or: [event traverse or: [event selectUpFn]]! !

!SimpleScrollController methodsFor: 'private: create'!

create: view {Viewer} with: var {VariableModel}
	super create.
	myView _ view.
	myOffsetVar _ var! !

!SimpleScrollController methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimpleScrollController class
	instanceVariableNames: ''!

(SimpleScrollController getOrMakeCxxClassDescription)
	friends:
'/* friends for class SimpleScrollController */
friend SPTR(SimpleScrollController) 
simpleScrollController (Viewer * view, VariableModel *
var);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SimpleScrollController class methodsFor: 'pseudo
constructors'!

make: view {Viewer} with: var {VariableModel}
	^ self create: view with: var! !