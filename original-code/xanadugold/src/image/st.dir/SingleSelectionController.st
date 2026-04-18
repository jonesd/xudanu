'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:47 pm'!

FMController subclass: #SingleSelectionController
	instanceVariableNames: '
		mySelection {SelectionObject}
		selectionKey {Position}
		isSelecting {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
SingleSelectionController comment:
'Report selectionKey to mySelection during selection activities.  Selection activities transitions of the selectButton, and motion of the mouse while the selectButton is down.  Use a selectionGate to restrict the selection to a sequence of selectDown select motion, and selectUp events, all occurring in the same view.'!

(SingleSelectionController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SingleSelectionController methodsFor: 'create'!

create: selection {SelectionObject} with: key{Position}
	super create.
	mySelection _ selection.
	selectionKey _ key! !

!SingleSelectionController methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	event selectDownFn ifTrue: 
		[| uevent {UserEvent} |
		uevent _ event quickCast: UserEvent.
		uevent isShiftDown
			ifTrue: [mySelection extendSelect: selectionKey]
			ifFalse: [uevent isControlDown
					ifTrue: [mySelection multiSelect: selectionKey]
					ifFalse: [mySelection beginSelect: selectionKey]]].
	event traverse ifTrue: [mySelection continueSelect: selectionKey].
	event selectUpFn ifTrue: [mySelection endSelect: selectionKey]!

{BooleanVar} requestEvents: event {FMEvent} 
	^event selectUpFn or: [event selectDownFn or: [event traverse]]! !

!SingleSelectionController methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' on ('.
	oo << mySelection << ', selecting ' << isSelecting << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SingleSelectionController class
	instanceVariableNames: ''!

(SingleSelectionController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SingleSelectionController class methodsFor: 'pseudo constructors'!

make: selection {SelectionObject} with: pos {Position}

	^ self create: selection with: pos! !