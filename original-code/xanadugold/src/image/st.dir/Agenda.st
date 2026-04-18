'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:49 pm'!

AgendaItem subclass: #Agenda
	instanceVariableNames: 'myToDoList {MuSet of: AgendaItem}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
Agenda comment:
'An AgendaItem composed of other AgendaItems.  My stepping action consists of stepping one of my component items.  When I exhaust a component item, I unregister and destroy it.

Note: The order in which I select a component item is currently unspecified and uncontrolled (depending on "MuSet::stepper()").  Eventually, it may make sense for me to use the Escalator Algorithm to do prioritized scheduling.

Empty Agendas are also made as do-nothing AgendaItems.  The currently get duely get scheduled, stepped, and unscheduled.  A possible optimization would be to avoid scheduling do-nothing AgendaItems.'!

(Agenda getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Agenda methodsFor: 'accessing'!

{void} registerItem: item {AgendaItem}
	"By registering the item, we ensure that if we crash and reboot, the item will be eventually and repeatedly stepped until step returns FALSE, provided we are registered up through the Turtle.  Do NOT multiply register the same item."
	
	DiskManager consistent: 2 with:
		[myToDoList introduce: item.	"Why did we once have a 'bug?' annotation that this introduce needs to preceed the rememberYourself?"
		item rememberYourself.
		self diskUpdate]!

{BooleanVar} step
	"'step' one of my component items.  If I return FALSE, that means there's nothing currently left to do.  However, since more AgendaItems may get registered later, there may later be something more for me to do, so I shouldn't necessarily be destroyed.  This creates a composition problem: If an Agenda is stored as an item within another Agenda, then when the outer Agenda is stepped and it in turn steps the inner Agenda, if the inner Agenda returns FALSE, the outer Agenda will destroy it.  This is all legal and shouldn't be a problem as long as one is aware of this behavior"
	
	| item {AgendaItem | NULL} stomp {Stepper} |
	
	"fetch some one item from myToDOList by creating a stepper, fetching with it, and
	destroying the stepper.
	If there were no items left
		return, telling the caller that there is nothing left to do.  (We may do this repeatedly...)
	step the item.
		if it returned false
			unregister the item
			atomically
				destroy it  (nuke it?)
	return whether there are any more things to do."
	
	item _ (stomp _ myToDoList stepper) fetch cast: AgendaItem.
	stomp destroy.
	self thingToDo.	"The above code is n-squared.  It should probably be fixed up during tuning."
	item == NULL
		ifTrue: [^false].
	item step
		ifFalse: 
			[self unregisterItem: item.
			DiskManager consistent: 2 with:
				[item destroy.
				self thingToDo.	"find out if the consistent block is necessary/appropriate"]].
	^myToDoList isEmpty not!

{void} unregisterItem: item {AgendaItem}
	"An item should be unregistered either when it is done (when 'step' returns FALSE) or when it no longer represents something that needs to be done should we crash and reboot.  Unregistering an item which is not registered and already forgotten is legal and has no effect."
	
	DiskManager consistent: 2 with:
		[myToDoList wipe: item.
		item forgetYourself.
		self diskUpdate]! !

!Agenda methodsFor: 'creation'!

create

	super create.
	myToDoList _ MuSet make.
	self knownBug.	"A MuSet may become too big to fit within a snarf.  However, GrandHashSets spawn AgendaItems and force propogating consistent block counts up through anything else that uses them."
	self newShepherd!

{void} dismantle
	
	myToDoList stepper forEach: [:each {AgendaItem} |
		self unregisterItem: each.
		each destroy].
	DiskManager consistent: 2 with: 
		[myToDoList destroy.
		super dismantle]! !

!Agenda methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myToDoList _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myToDoList.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Agenda class
	instanceVariableNames: ''!

(Agenda getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Agenda class methodsFor: 'creation'!

make

	self thingToDo. "see class comment for optimization possibility"
	DiskManager consistent: 1 with:
		[^self create]! !