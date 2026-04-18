'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:43 pm'!

ClickAction subclass: #DoubleClickAction
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
DoubleClickAction comment:
'As ClickAction, but require a doubleClick.'!

(DoubleClickAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DoubleClickAction methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	(event selectUpFn and: [(event cast: ButtonEvent) clickCount >= 2])
		ifTrue: [self invoke].! !

!DoubleClickAction methodsFor: 'create'!

create: thunk {Thunk}
	super create: thunk! !

!DoubleClickAction methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DoubleClickAction class
	instanceVariableNames: ''!

(DoubleClickAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DoubleClickAction class methodsFor: 'pseudo constructors'!

make: onAction {Thunk}
	^ self create: onAction! !