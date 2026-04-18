'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:46 pm'!

FMController subclass: #MultiSelectionController
	instanceVariableNames: '
		myView {Viewer}
		mySelection {SelectionObject}
		lastSelection {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
MultiSelectionController comment:
'Ask a view for the Positio corresponding to the mousePoint ov selection events, and report the selection to a selectionObject.

Selection activities transitions of the selectButton, and motion of the mouse while the selectButton is down.  Use a selectionGate to restrict the selection to a sequence of selectDown select motion, and selectUp events, all occurring in the same view.'!

(MultiSelectionController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiSelectionController methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	event selectDownFn ifTrue: 
		[| uevent {UserEvent} |
		uevent _ event quickCast: UserEvent.
		lastSelection _ myView selectionFor: (uevent pointIn: myView).
		uevent isShiftDown
			ifTrue: [mySelection extendSelect: lastSelection]
			ifFalse: [uevent isControlDown
					ifTrue: [mySelection multiSelect: lastSelection]
					ifFalse: [mySelection beginSelect: lastSelection]]].
	event traverse ifTrue: 
		[lastSelection _ myView selectionFor: ((event quickCast: UserEvent) pointIn: myView).
		mySelection continueSelect: lastSelection].
	event selectUpFn ifTrue: 
		[lastSelection ~~ NULL "hack fix. heh 21 September 1990, 15 December 1990 "
			ifTrue: [mySelection endSelect: lastSelection].
		lastSelection _ NULL]!

{BooleanVar} requestEvents: event {FMEvent} 
	[PointRegion] USES.
	^ ((event cast: UserEvent) visible: (myView enclosure) in: myView) 
		and: [event selectUpFn or: [event selectDownFn or: [event traverse]]]
						
	"For when regionAt is working everywhere...
	event selectUpFn or: [event selectDownFn or: 
		[lastSelection == NULL
			ifTrue: [event traverse]
			ifFalse: [event exit: (view regionAt: lastSelection) in: view]"! !

!MultiSelectionController methodsFor: 'create'!

create: view {Viewer} with: selection {SelectionObject}
	super create.
	myView _ view.
	mySelection _ selection.
	lastSelection _ NULL! !

!MultiSelectionController methodsFor: 'accessing'!

{SelectionObject} fetchSelection
	^ mySelection! !

!MultiSelectionController methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << mySelection << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiSelectionController class
	instanceVariableNames: ''!

(MultiSelectionController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiSelectionController class methodsFor: 'pseudo constructors'!

make: viewer {Viewer} with: selection {SelectionObject}

	^ self create: viewer with: selection! !