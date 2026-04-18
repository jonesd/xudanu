'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:45 pm'!

SuperController subclass: #FocusController
	instanceVariableNames: '
		myView {Viewer}
		isFocused {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
FocusController comment:
'Only pass events to my controller if the last selectDown event came through me.  Then I become a focus, and pass events on to myController.'!

(FocusController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FocusController methodsFor: 'creation'!

create: view {Viewer} with: controller {FMController}
	super create: controller.
	myView _ view.
	isFocused _ false! !

!FocusController methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	[PointRegion] USES.
	 
	event selectDownFn ifTrue: [
		((event quickCast: UserEvent) visible: myView enclosure in: myView)
			ifTrue: [isFocused _ true]
			ifFalse: [isFocused _ false]].
	(isFocused or: [event keystroke not]) 
		ifTrue: [super handleEvent: event]!

{BooleanVar} requestEvents: event {FMEvent} 
	event selectDownFn ifTrue: [^true].
	isFocused
		ifTrue: [^super requestEvents: event]
		ifFalse: [event keystroke
				ifTrue: [^false]
				ifFalse: [^super requestEvents: event]]! !

!FocusController methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FocusController class
	instanceVariableNames: ''!

(FocusController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FocusController class methodsFor: 'pseudo constructors'!

make: focussingView {Viewer} with: gatedControl {FMController}
	^self create: focussingView with: gatedControl! !