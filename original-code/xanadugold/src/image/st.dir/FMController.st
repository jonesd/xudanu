'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:44 pm'!

Heaper subclass: #FMController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
FMController comment:
'The controller tree will likely have a different topology from the view tree.  The view hierarchy represents spatial inclusion.  The controller hierarchy represents event gating and ordering.  A controller contains another controller iff it determines whether the other controller receives events, or if it must receive events before the other controller.

The two event handling message are requestEvents: and handleEvent:.

requestEvents: event - returns true if the controller reacts to event.  The event should be tested using the transition testing methods defined for events.  Later, the tests will be recorded and used to cache the target for particular event types (since interest tends to be local).  The set of events to which a controller reacts must only change at redisplays.

handleEvent: event - actually handles the event.  Controllers should avoid asking for the event point if at all possible, and should instead use enter/exit tests to see if the event traversed out of a local region.  This message will only be called for events that passed the requestEvents: filter (simplifying the structure of these handlers).

Note that this class should should simulate the compile-time type dispatch for diffferent types of events.

How do I construct a collectionView with independently organized controllers?  
How do I construct a collectionView with the same type of controller on each branch?
How do I construct a tree of views with independently operating controllers (as in the text manipulation hierarchy)?

My definitions of controllers is really moving towards my earlier notion of event sequences.  Should I use (and define) event sequences?  Singular events simply represent an entire sequence.  Event sequences are related to iterationVars:  an event sequence is stepped through, co-routining between all controllers consuming the event sequence.

Controllers supply a pattern to match event sequences.  The controllManager uses this to determine which sequences of events go to which controllers.  They then step the controllers through those sequences.  The semantics of event sequences must require no look-ahead.  An example for the selection controllers, bitEditors, etc.:  selectDown (traverse)* selectUp.

MultiControllers combine the eventRequests of several controllers into a cingle event request.  If any of the controllers want the event, then the multiController gets the event and dispatches it efficiently.  There are some obvious clever implementations to go along with listMutliViews.'!

(FMController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMController methodsFor: 'control'!

{void} handle: anEvent {FMEvent} 
	"handle an incoming event."

	(self requestEvents: anEvent)
		ifTrue: [self handleEvent: anEvent]!

{void} handleEvent: anEvent {FMEvent unused} 
	"handle an incoming event."!

{BooleanVar} requestEvents: anEvent {FMEvent unused} 
	"Inform the handler if event is desired."

	^false! !

!FMController methodsFor: 'testing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!FMController methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMController class
	instanceVariableNames: ''!

(FMController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMController class methodsFor: 'pseudo constructors'!

make
	^ self create! !