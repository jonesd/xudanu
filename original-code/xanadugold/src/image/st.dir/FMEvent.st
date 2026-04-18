'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:50 pm'!

Heaper subclass: #FMEvent
	instanceVariableNames: 'clockInternal {TimeVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
FMEvent comment:
'The only thing all events share is the time they happened.  This assumes a global clock, of course....

The other obvious event Types are:  

KeyEvents - for keyboard activity.
ButtonEvent - for button transitions.
Traverse - my special way of handling mouse movement.  
A Traverse has some representation of the entire path taken 
by the mouse.  It can also answer queries about entering and 
exiting regions.  It should also deal with visible flags.
DelayEvents - programmed to alert a controller at specific intervals.
SelectionEvents - used by Menus.  They return a controller supplied token.
[De]ActivateEvents - sent by controllers to awaken subControllers.

Most event types can be tested for with a message to any event.  
This will allow us to later replace the event that controllers test 
with a cache manager that determines which controllers want which 
events, and so only generates the minimum set of events.

There is currently a major compatibility problem with the time used.  The {timeval} type does not exist on the mac (and maybe other operating systems).  Something else must be used here to allow system independence.'!

(FMEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMEvent methodsFor: 'accessing'!

{TimeVar} eventTime
	^clockInternal!

{PointPos} pointIn: aView {Viewer} 
	self subclassResponsibility! !

!FMEvent methodsFor: 'creation'!

create: eventTime {TimeVar}
	super create.
	clockInternal _ eventTime! !

!FMEvent methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' time: ' << clockInternal! !

!FMEvent methodsFor: 'transition testing'!

{BooleanVar} activate
	"This is not an activate event."

	^false!

{BooleanVar} deactivate
	"This is not a deactivate event."

	^false!

{BooleanVar} enter: aRegion {XnRegion unused} in: view
{Viewer unused} 
	"Event is not the correct class for this enter or exit. A 
	TraverseEvent is used for this. This is not a traverse
event."

	^false!

{BooleanVar} exit: aRegion {XnRegion unused} in: view
{Viewer unused} 
	"This is not a traverse event."

	^false!

{BooleanVar} keystroke
	"This is not a keystoke event."

	^false!

{BooleanVar} menuDownFn
	"This is not a button event."

	^false!

{BooleanVar} menuUpFn
	"This is not a button event."

	^false!

{BooleanVar} requestIn: subController {FMController} 
	"Move down the controller hierarchy and test a
subController."

	^subController requestEvents: self!

{BooleanVar} selectDownFn
	"This is not a button event."

	^false!

{BooleanVar} selectUpFn
	"This is not a button event."

	^false!

{BooleanVar} traverse
	"This is not a traverse event."

	^false!

{BooleanVar} windowDownFn
	"This is not a button event."

	^false!

{BooleanVar} windowUpFn
	"This is not a button event."

	^false! !

!FMEvent methodsFor: 'testing'!

{UInt32} hashForEqual
	[^self asOop >> 5] translateOnly.
	[^self asOop] smalltalkOnly!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !