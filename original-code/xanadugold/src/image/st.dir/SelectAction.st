'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:47 pm'!

ClickAction subclass: #SelectAction
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
SelectAction comment:
'Invoke a thunk on every mouseMotion while the select button is down.'!

(SelectAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectAction methodsFor: 'control'!

{void} handleEvent: event {FMEvent unused}
	self invoke!

{BooleanVar} requestEvents: event {FMEvent}
	^event selectUpFn  or: [event selectDownFn or: [event traverse]]! !

!SelectAction methodsFor: 'create'!

create: thunk {Thunk}
	super create: thunk! !

!SelectAction methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !