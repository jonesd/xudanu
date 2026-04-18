'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:50 pm'!

Abraham subclass: #AgendaItem
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
AgendaItem comment:
'A persistent representation of things that still need to be done.  Can think of it like a persistent process record.  "schedule"ing me ensures that I will be stepped eventually, and repeatedly, until step returns FALSE, even if the process should crash after I am scheduled.  Scheduling me so that I am persistent may happen inside some other consistent block, however I will be stepped while outside of any consistent block (The FakePacker doesn''t do this yet).  Creating an AgendaItem does not imply that it is scheduled, the client must explicitly schedule it as well.  Destroying it *does* ensure that it gets unscheduled, though it is valid & safe to destroy one which isn''t scheduled.

NOTE: Right now there are no fairness guarantees (and there may never be), so all AgendaItems must eventually terminate in order for other things (like the ServerLoop) to be guaranteed of eventually executing'!

(AgendaItem getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!AgendaItem methodsFor: 'accessing'!

{void} forgetYourself
	"forget is protected.  This method exposes it for AgendaItems"

	self forget!

{void} rememberYourself
	"remember is protected.  This method exposes it for AgendaItems"
	
	self remember!

{void} schedule
	"Registers me with the top level Agenda, so that I will eventually get stepped.  Also causes me to be remembered."
	
	[[self step] whileTrue] smalltalkOnly. "for debugging"
	CurrentPacker fluidGet getInitialFlock getAgenda registerItem: self!

{BooleanVar} step
	"Return FALSE when there's nothing left to do (at which time I should usually be unregistered and destroyed, but see Agenda::step())"

	self thingToDo.	"Change to return {AgendaItem (self or other) | NULL} and rename the message to fetchNextStep or the like.  If we do this, we must remember that collapsing items must be just an optimization, because they can be stepped even after returning something else."
	self subclassResponsibility!

{void} unschedule
	"Unregisters me with the top level Agenda, so that I am no longer scheduled to get stepped.  Also causes me to be forgotten."
	
	CurrentPacker fluidGet getInitialFlock getAgenda unregisterItem: self! !

!AgendaItem methodsFor: 'protected: creation'!

create
	"Not so special constructor for not becoming this class"

	super create!

create: hash {UInt32}
	"Special constructor for becoming this class"

	super create: hash!

{void} dismantle
	
	DiskManager consistent: 2 with: 
		[self unschedule.
		super dismantle]!

{void} newShepherd
	"All AgendaItems use explicit deletion semantics."
	"?????"
	super newShepherd.! !

!AgendaItem methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !