'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:43 pm'!

FMController subclass: #ClickAction
	instanceVariableNames: 'myThunk {Thunk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
ClickAction comment:
'Invoke a thunk when the user clicks the mouse.  Restrict this to a view using a selectionGate'!

(ClickAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ClickAction methodsFor: 'create'!

create: thunk {Thunk}
	super create.
	myThunk _ thunk! !

!ClickAction methodsFor: 'smalltalk:'!

create: view{Viewer} with: thunk {Thunk}
	self passe!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: myThunk! !

!ClickAction methodsFor: 'protected: invoke'!

{void} invoke
	"The stream of events just triggerred the receiver.  Invoke its thunk."
	
	myThunk execute! !

!ClickAction methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	event selectUpFn ifTrue: 
		[self invoke].!

{BooleanVar} requestEvents: event {FMEvent}
	^event selectUpFn! !

!ClickAction methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClickAction class
	instanceVariableNames: ''!

(ClickAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ClickAction class methodsFor: 'pseudo constructors'!

make: thunk {Thunk}
	^ self create: thunk! !