'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:52 pm'!

AgendaItem subclass: #RecorderTrigger
	instanceVariableNames: '
		myFossil {RecorderFossil | NULL}
		myElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
RecorderTrigger comment:
'This is a one-shot agenda item.

Asks myFossil to record myElement.

When an answer to a delayed backFollow is found, whether thru a northwards h-walk (filtered by the Bert Canopy) of a southwards o-walk (filtered by the Sensor Canopy), instead of actually recording the answer into the backFollow trail immediately, we shedule a RecorderTrigger to do the job.'!

(RecorderTrigger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!RecorderTrigger methodsFor: 'accessing'!

{BooleanVar} step
	||
	
	"If null pointer to myFossil
		We've already shot once.  Do nothing.
	If myFossil is still in suspension
		Inform myFossil with myElement
	Atomically
		Remove refcount from ourself on myFossil.
		Remember that we're done."
		
	myFossil == NULL
		ifTrue: [^false].
	myFossil isExtinct ifFalse: 
		[myFossil reanimate: [:recorder {ResultRecorder} |
			recorder record: myElement]].
	DiskManager consistent: 2 with:
		[myFossil removeItem: self.
		myFossil _ NULL.
		self thingToDo. "stop making sure the Edition doesn't go away; it needs a refcount or something like it."
		self diskUpdate.
		^false].! !

!RecorderTrigger methodsFor: 'creation'!

create: fossil {RecorderFossil} with: element {BeRangeElement}

	super create.
	myFossil _ fossil.
	myFossil addItem: self.
	myElement _ element.
	self thingToDo. "make sure the RangeElement doesn't go away"
	self newShepherd.!

{void} dismantle

	DiskManager consistent: 2 with:
		[myFossil ~~ NULL
			ifTrue:
				[myFossil removeItem: self.
				myFossil _ NULL].
		self thingToDo. "stop making sure the stamp doesn't go away"
		super dismantle]! !

!RecorderTrigger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myFossil _ receiver receiveHeaper.
	myElement _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myFossil.
	xmtr sendHeaper: myElement.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RecorderTrigger class
	instanceVariableNames: ''!

(RecorderTrigger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!RecorderTrigger class methodsFor: 'creation'!

make: fossil {RecorderFossil} with: element {BeRangeElement}

	DiskManager consistent: 2 with:
		[^self create: fossil with: element]! !