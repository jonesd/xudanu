'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:49 pm'!

Heaper subclass: #EventQueue
	instanceVariableNames: '
		firstEvent {UNKNOWN}
		moreEvents {UNKNOWN}
		doBefore {UNKNOWN}
		doAfter {UNKNOWN}
		generator {UNKNOWN}
		debug {UNKNOWN}
		myDsp {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
EventQueue comment:
'An EventQueue iteratively generates events, then feeds them to a top level viewer to propagate down the hierarchy.  After each event is interpreted by the viewer, the view hierarchy must be redisplayed.  Some operations done during the interpretation (in response to events) must change the state of the view hierarchy.  To avoid conflicts, these operations must be scheduled as blocks to occur before or after the redisplay using (Events doFirst: aBlock) or (Events doLast: aBlock), respectively.  The event queue is a SharedQueue so that any process can asynchronously schedule events.

Instance Variables:
	stateEvent	<Event>  "holds the last polled state of the sensor"
	events	<SharedQueue of: Event>
	doBefore	<OrderedCollection of: BlockContext>
	doAfter	<OrderedCollection of: BlockContext>
'!

(EventQueue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EventQueue methodsFor: 'create/delete'!

create: withDsp {Dsp}
	firstEvent _ NULL.
	moreEvents _ NULL.
	doBefore _ TableAccumulator make.
	doAfter _ doBefore copy.
	generator _ EventGenerator create.
	debug _ false.
	myDsp _ withDsp!

destruct
	firstEvent _ NULL.
	moreEvents _ NULL.
	doBefore _ NULL.
	doAfter _ NULL.
	generator _ NULL.
	debug _ false.
	myDsp _ NULL.
	super destruct! !

!EventQueue methodsFor: 'accessing'!

{void} doFirst: aBlock {Thunk} 
	doBefore step: aBlock!

{void} doLast: aBlock {Thunk} 
	doAfter step: aBlock!

{Dsp} dsp
	^ myDsp!

{BooleanVar} isEmpty

	^ firstEvent == NULL!

{FMEvent} nextEvent
	"Return the currently available event or NULL if there is none."

	| next {FMEvent} |
	firstEvent == NULL ifTrue: [^NULL].
	next _ firstEvent.
	moreEvents == NULL
		ifTrue: [firstEvent _ NULL]
		ifFalse: 
			[| index {IntegerVar} |
			index _ moreEvents domain start.
			firstEvent _ (moreEvents intGet: index) cast: FMEvent.
			moreEvents intWipe: index.
			moreEvents isEmpty ifTrue: [moreEvents _ NULL]].
	^next!

{void} queue: anEvent {Event}
	"Transcript print: anEvent; cr; endEntry."

	firstEvent == NULL
		ifTrue: [firstEvent _ anEvent]
		ifFalse: [moreEvents == NULL
				ifTrue: [moreEvents _ IntegerTable make.
					moreEvents atInt: 0 introduce: anEvent]
				ifFalse: [moreEvents atInt: moreEvents domain stop introduce: anEvent]]!

{void} queue: anEvent {Event} for: aController {FMController} 
	"Transcript print: anEvent; cr; endEntry."

	| pair {Pair} |
	pair _ Pair make: anEvent with: aController.
	firstEvent == NULL
		ifTrue: [firstEvent _ pair]
		ifFalse: [moreEvents == NULL
				ifTrue: [moreEvents _ IntegerTable make.
					moreEvents atInt: 0 introduce: pair]
				ifFalse: [moreEvents atInt: moreEvents domain stop introduce: pair]]!

{void} setDsp: newDsp
	myDsp _ newDsp.
	self flushEvents! !

!EventQueue methodsFor: 'control'!

{void} checkEvents 
	"This should avoid mucking with the event queue 
	when only a single event is available (frequently)."

	generator queueEvents: self with: myDsp.!

{void} flushEvents
	firstEvent _ NULL.
	moreEvents _ NULL!

{void}runNextFor: rootController{XController} on: aWarp {Warp}
	"This should avoid mucking with the event queue 
	when only a single event is available (frequently)."

	| pair {Pair of: Event and: Controller} event {Event} controller {Controller} tab {MuTable} |
	[(pair _ self nextEvent) == NULL] 
		whileTrue: 
			[generator queueEvents: rootController with: aWarp on: self].
	event _ pair left.
	controller _ pair right.
	debug ifTrue: [Transcript print: event; cr; endEntry].
	controller handle: event.
	tab _ doBefore value cast: ScruTable.
	tab isEmpty
		ifFalse: 
			[tab stepper forEach: [:block{Thunk} | block value].
			doBefore _ TableAccumulator make].
	"rootController view updateOn: aWarp."
	tab _ doAfter value cast: ScruTable.
	tab isEmpty
		ifFalse: 
			[tab stepper forEach: [:block{Thunk} | block value].
			doBefore _ TableAccumulator make].! !

!EventQueue methodsFor: 'smalltalk: smalltalk testing'!

test: building
	"EventQueue create testEvents"
	
	| ctrl warp |
	debug _ false.
	ctrl _ building controller.
	warp _ Display warp.
	[Sensor ctrlDown] whileFalse: 
		[self runNextFor: ctrl on: warp.
		building view displayOn: warp].
	ScheduledControllers restore!

testEvents
	"EventQueue create testEvents"
	
	| ctrl warp |
	debug _ true.
	ctrl _ FMController create.
	warp _ Display warp.
	[Sensor ctrlDown]
		whileFalse: [self runNextFor: ctrl on: warp]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EventQueue class
	instanceVariableNames: ''!

(EventQueue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EventQueue class methodsFor: 'pseudo constructors'!

make
	^ self create: PointTranslateDsp make!

make: withDsp {Dsp}
	^ self create: withDsp! !