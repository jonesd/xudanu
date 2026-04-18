'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:47 pm'!

SuperController subclass: #SelectionGate
	instanceVariableNames: '
		myView {Viewer}
		selecting {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
SelectionGate comment:
'Only allow selection events to my subView if the original selectDown for the pattern occurs within the boundaries of myView.  Only pass selection traverse events if they fall within the boundary, as well.'!

(SelectionGate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectionGate methodsFor: 'control'!

{void} handleEvent: event {FMEvent}

	event selectDownFn ifTrue: 
		[selecting _ true.
		super handleEvent: event].
	event traverse ifTrue: 
		[super handleEvent: event].
	event selectUpFn ifTrue: 
		[selecting _ false.
		super handleEvent: event].!

{BooleanVar} requestEvents: event {FMEvent} 
	"selecting 
	ifTrue: [^(super requestEvents: event) or: [event selectUpFn]] 
	ifFalse: [^event selectDownFn and: [(event cast: UserEvent)visible: myView 
	enclosure in: myView]] 
	"

	selecting
		ifTrue: [^(super requestEvents: event)
				or: [event selectUpFn]]
		ifFalse: [event selectDownFn
				ifTrue: [^(event cast: UserEvent)
						visible: myView enclosure in: myView]
				ifFalse: [^false]]! !

!SelectionGate methodsFor: 'create'!

create: view {Viewer} with: subController {FMController}
	super create: subController.
	myView _ view.
	selecting _ false! !

!SelectionGate methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectionGate class
	instanceVariableNames: ''!

(SelectionGate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectionGate class methodsFor: 'pseudo constructors'!

make: gatingView {Viewer} with: gatedControl {FMController}
	^ self create: gatingView with: gatedControl! !