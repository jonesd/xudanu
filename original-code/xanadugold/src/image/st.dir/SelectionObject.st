'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:08 pm'!

XnModel subclass: #SelectionObject
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!
SelectionObject comment:
'There are two general types of subclasses.  Selection subclasses represent some selection information that gets set and modified by the begin/continue/end Select operations (and the alternates to begin: extend/multi Select).  Such objects represent ranges of text, single item selections, selections in an outline view, etc.

The other kind of subclass are action objects.  These do some arbitrary action when the mouse goes up or down.  These need to become aware of double clicks and such, how do I do that?

Action objects should really be the superclass.'!

(SelectionObject getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SelectionObject methodsFor: 'accessing'!

{void} select: region {XnRegion}
	self subclassResponsibility!

{XnRegion} selection
	self subclassResponsibility!

{Position} selectionPoint
	"the active point in the selection"
	self subclassResponsibility! !

!SelectionObject methodsFor: 'selecting'!

{void} beginSelect: key {Position}
	"This is the basic start selection operation. 
	 Clear the old selection and start a new one."

	self subclassResponsibility!

{void} continueSelect: key {Position}
	"These are sent after one of the selection start
	 operations to continually update the selection as
	 the user moves the mouse."

	self subclassResponsibility!

{void} endSelect: key {Position}
	"End the current selection action.  Action subclasses
	 will typically start their action now."

	self continueSelect: key!

{void} extendSelect: key {Position}
	"Begin a new selection action that extends the pre-existing selection. 
	 The default just starts a new selection.  A better default might be to
	 'continue' the old selection."

	self beginSelect: key!

{void} multiSelect: key {Position}
	"Start an additional selection without upsetting
	 the pre-exinsting selections.  The default just
	 starts a normal selection.."

	self beginSelect: key! !

!SelectionObject methodsFor: 'printing'!

{void}printOn: oo {ostream reference}
	oo << self getCategory name << $( << self selection << $)! !