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

AgendaItem subclass: #PropChanger
	instanceVariableNames: 'myCrum {CanopyCrum | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
PropChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(PropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!PropChanger methodsFor: 'protected: accessing'!

{CanopyCrum | NULL} fetchCrum

	^myCrum!

{void} setCrum: aCrum {CanopyCrum | NULL}
	"Move our placeholding finger to a new crum, updating refcounts accordingly"
	
	| |
	
	"atomically (though we've probably already gone nuclear)
		If there is a new crum
			bump its refcount.
		If there is an old crum
			unbump its refcount.
		Remember the new crum."
		
	DiskManager consistent: 3 with:
		[aCrum ~~ NULL ifTrue:
			[aCrum addPointer: self].
		myCrum ~~ NULL ifTrue:
			[myCrum removePointer: self].
		myCrum := aCrum.
		self diskUpdate].! !

!PropChanger methodsFor: 'accessing'!

{BooleanVar} step
	"propagate some prop(erty) change one step parentwards, until it gets to a local root or no further propagation in necessary."
	
	self subclassResponsibility! !

!PropChanger methodsFor: 'creation'!

create: crum {CanopyCrum | NULL}

	super create.
	myCrum _ crum.
	myCrum == NULL ifTrue:
		[myCrum addPointer: self].!

create: crum {CanopyCrum | NULL} with: hash {UInt32}
	"Special constructor for becoming this class"

	super create: hash.
	myCrum _ crum.
	"I don't 'myCrum addPointer: self' because, in becoming, my old self is presumed to already have pointed at the crum"!

{void} dismantle

	DiskManager consistent: 2 with:
		[myCrum ~~ NULL
			ifTrue:
				[myCrum removePointer: self.
				myCrum _ NULL].
		super dismantle]! !

!PropChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropChanger class
	instanceVariableNames: ''!

(PropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!PropChanger class methodsFor: 'creation'!

{PropChanger} height: crum {CanopyCrum | NULL}
	
	DiskManager consistent: 3 with:
		[^HeightChanger create: crum]!

make: crum {CanopyCrum | NULL}
	
	DiskManager consistent: 2 with:
		[^ActualPropChanger create: crum]! !

!PropChanger class methodsFor: 'smalltalk: suspended'!

make: crum {CanopyCrum | NULL} with: change {PropChange}

	self suspended.
	self thingToDo. " Separate out different things to be propagatated into different PropChanger-like classes."
	
	DiskManager consistent: 3 with:
		[^ActualPropChanger create: crum with: change]! !

PropChanger subclass: #ActualPropChanger
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
ActualPropChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(ActualPropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!ActualPropChanger methodsFor: 'creation'!

create: crum {CanopyCrum}

	super create: crum.
	self newShepherd.!

create: crum {CanopyCrum | NULL} with: hash {UInt32} with: info {FlockInfo}
	"Special constructor for becoming this class"

	super create: crum with: hash.
	self flockInfo: info.
	self diskUpdate.! !

!ActualPropChanger methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of property changing.
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"

	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[(self fetchCrum changeCanopy)
			ifTrue: [self setCrum: self fetchCrum fetchParent]
			ifFalse: [self setCrum: NULL]].
	^self fetchCrum ~~ NULL! !

!ActualPropChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !

PropChanger subclass: #HeightChanger
	instanceVariableNames: 'myChange {PropChange}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
HeightChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(HeightChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!HeightChanger methodsFor: 'creation'!

create: crum {CanopyCrum}

	super create: crum.
	self newShepherd.!

create: crum {CanopyCrum | NULL} with: hash {UInt32} with: info {FlockInfo}
	"Special constructor for becoming this class"

	super create: crum with: hash.
	self flockInfo: info.
	self diskUpdate.! !

!HeightChanger methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of height recalculation.
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"
	
	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[self fetchCrum changeHeight
			ifTrue: [self setCrum: self fetchCrum fetchParent]
			ifFalse: [self setCrum: NULL]].
	^self fetchCrum ~~ NULL! !

!HeightChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myChange _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myChange.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeightChanger class
	instanceVariableNames: ''!

(HeightChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!HeightChanger class methodsFor: 'creation'!

make: crum {CanopyCrum} with: change {PropChange unused}
	
	self knownBug.	"BOGUS"
	DiskManager consistent: 3 with:
		[^self create: crum]! !

PropChanger subclass: #RecorderHoister
	instanceVariableNames: 'myCargo {MuSet of: TransclusionFossil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
RecorderHoister comment:
' NOT.A.TYPE I exist to hoist myCargo (a set of recorder fossils) up the Sensor canopy as far as it needs to go, as well as to propogate the props resulting from the planting of these recorders.  When I no longer have any cargo to hoist, I devolve into an ActualPropChanger

I assume that RecorderCheckers do their southward walk in a single step, so I can hoist recorders by an algorithm that would occasionally cause a recorder to be missed if RecorderCheckers were incremental.'!

(RecorderHoister getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #(MAY.BECOME ActualPropChanger ); add: #CONCRETE; yourself)!

!RecorderHoister methodsFor: 'creation'!

create: crum {CanopyCrum} with: aSetOfRecorders {MuSet of: RecorderFossil}

	super create: crum.
	myCargo _ aSetOfRecorders.
	self newShepherd.! !

!RecorderHoister methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"See class comment for a constraint I impose on another class.
	
	If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of property changing (and/or height recalculation until that's moved to HeightChanger). 
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"

	self thingToDo.	"update comment after we move height calculation to HeightChanger>>step"	
	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[ | crum {CanopyCrum | NULL} propsChangedFlag {BooleanVar} |
		crum := self fetchCrum fetchParent.
		propsChangedFlag := self fetchCrum changeCanopy.
		"All the updating of myPropJoint that's needed even though I hoist recorders into my parent below, since hoisting cannot change what myPropJoint needs to be."
		self setCrum: crum.
		crum == NULL ifTrue:
			[^false].
		myCargo restrictTo: (crum fetchChild1 cast: SensorCrum) recorders;
			       restrictTo: (crum fetchChild2 cast: SensorCrum) recorders.
		self diskUpdate.
		myCargo isEmpty ifTrue:
			[| hash {UInt32} 
			   info {FlockInfo} |
			propsChangedFlag ifFalse:
				[self setCrum: NULL.
				^false].
			myCargo destroy.
			"Normally done by destruct, but here we do it directly because we're about to become something"
			hash _ self hashForEqual.
			info _ self fetchInfo.
			(ActualPropChanger new.Become: self)
				create: crum
				with: hash
				with: info.
			"the special purpose constructor will not do a 'crum->addPointer(this)' so we don't have to undo it"
			^true].
		"If we reach this point, we have cargo to hoist."
		(crum fetchChild1 cast: SensorCrum) removeRecorders: myCargo asImmuSet.
		(crum fetchChild2 cast: SensorCrum) removeRecorders: myCargo asImmuSet.
		myCargo wipeAll: (crum cast: SensorCrum) recorders.
		myCargo isEmpty ifTrue:
			[propsChangedFlag ifFalse:
				[self setCrum: NULL].
			^propsChangedFlag]
		ifFalse:
			[(crum cast: SensorCrum) installRecorders: myCargo asImmuSet.
			crum diskUpdate]].
	^true! !

!RecorderHoister methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCargo _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCargo.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RecorderHoister class
	instanceVariableNames: ''!

(RecorderHoister getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #(MAY.BECOME ActualPropChanger ); add: #CONCRETE; yourself)!

!RecorderHoister class methodsFor: 'creation'!

{AgendaItem} make: crum {CanopyCrum} with:  aSetOfRecorders {ScruSet of: RecorderFossil}
	"Create a RecorderHoister."
	
	aSetOfRecorders isEmpty ifTrue:
		[^Agenda make].
	DiskManager consistent: 1 with:
		[^self create: crum with: aSetOfRecorders asMuSet]! !

AgendaItem subclass: #Matcher
	instanceVariableNames: '
		myOrglRoot {OrglRoot | NULL}
		myFinder {PropFinder}
		myFossil {RecorderFossil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
Matcher comment:
'This is a one-shot agenda item.

When doing a delayed backFollow, after the future is taken care of (by posting recorders in the Sensor Canopy), the past needs to be checked (by walking the HTree northwards filtered by the Bert Canopy).  This AgendaItem is a one-shot used to remember to backFollow thru the past.  (myOrglRoot == NULL when the shot has been done.)'!

(Matcher getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Matcher methodsFor: 'accessing'!

{BooleanVar} step
	| |

	"If myStamp is NULL
		We've already shot once.  Do nothing.
	walk the HTree northwards filtered by the Bert Canopy, scheduling RecorderTriggers to record already-existing matching stamps.  ('past' part of backfollow)
		Remember that we're done."
		
	
	myOrglRoot == NULL
		ifTrue: [^false].
	myFossil reanimate: [ :recorder {ResultRecorder} |
		myOrglRoot delayedFindMatching: myFinder
			with: myFossil
			with: recorder].
	DiskManager consistent: 1 with:
		[myOrglRoot _ NULL.
		self thingToDo. "stop making sure the stamp sticks around"
		self diskUpdate.
		^false]! !

!Matcher methodsFor: 'creation'!

create: oroot {OrglRoot} 
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	
	super create.
	myOrglRoot _ oroot.
	self thingToDo. "make sure the stamp sticks around.  Do something like what's being done with myFossil>>addItem"
	myFinder _ finder.
	myFossil _ fossil.
	myFossil addItem: self.	"bump refcount on myFossil"
	self newShepherd.!

{void} dismantle
	
	DiskManager consistent: 3 with:
		[myFossil removeItem: self.	"Unbump refcount on myFossil."
		self thingToDo. "stop making sure the OrglRoot sticks around.  AgendaItems may be aborted by the enclosing algorithm, so can't assume I dropped my reference by stepping."
		super dismantle]! !

!Matcher methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOrglRoot _ receiver receiveHeaper.
	myFinder _ receiver receiveHeaper.
	myFossil _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOrglRoot.
	xmtr sendHeaper: myFinder.
	xmtr sendHeaper: myFossil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Matcher class
	instanceVariableNames: ''!

(Matcher getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Matcher class methodsFor: 'creation'!

make: oroot {OrglRoot} 
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	
	DiskManager consistent: 2 with:
		[^self create: oroot with: finder with: fossil]! !

AgendaItem subclass: #NorthRecorderChecker
	instanceVariableNames: '
		myEdition {BeEdition}
		myFinder {PropFinder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
NorthRecorderChecker comment:
'This is a one-shot agenda item.

See comment in SouthRecorderChecker for constraints and relationships to other pieces of the algorithm.

Looks for and triggers WorkRecorders lying northward of this Edition up to the next Edition. The Finder should only be carrying around Works.'!

(NorthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!NorthRecorderChecker methodsFor: 'accessing'!

{BooleanVar} step

	Ravi knownBug. "if my WorkRecorders have been hoisted they will not be found; there needs to be a way to walk north in the sensor canopy until we pass an edition boundary"
	
	myEdition == NULL ifFalse:
		[Ravi thingToDo. "Make this work"
		"myEdition sensorCrum fetchNextAfterTriggeringRecorders: myFinder with: NULL."
		DiskManager consistent: 1 with:
			[myEdition := NULL.
			self thingToDo. "stop making sure the edition sticks around"
			self diskUpdate]].
	^false! !

!NorthRecorderChecker methodsFor: 'create'!

create: edition {BeEdition} with: finder {PropFinder}

	super create.
	myEdition := edition.
	myFinder := finder.
	self newShepherd.! !

!NorthRecorderChecker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myEdition _ receiver receiveHeaper.
	myFinder _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myEdition.
	xmtr sendHeaper: myFinder.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NorthRecorderChecker class
	instanceVariableNames: ''!

(NorthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!NorthRecorderChecker class methodsFor: 'create'!

{AgendaItem} make: edition {BeEdition} with: finder {PropFinder}

	^self create: edition with: finder! !

AgendaItem subclass: #SouthRecorderChecker
	instanceVariableNames: '
		myORoot {OrglRoot | NULL}
		myFinder {PropFinder}
		mySCrum {SensorCrum | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
SouthRecorderChecker comment:
'This is a one-shot agenda item.

When changing the prop(ertie)s of a Stamp, we need to first take care of the future backFollow requests (by updating the Bert Canopy so the filtered HTree walk will find this Stamp) before taking care of the past (the Recorders that were looking for this Stamp in their future).  This AgendaItem is to remember to take care of the past (by doing a southwards o-walk filtered by the Sensor Canopy) after the future is properly dealt with.

The RecorderHoister assumes that this southward walk is done in a single-step, so it is free to make changes in a way that, if it were interleaved with an incremental southward walk by a RecorderChecker looking for the recorder(s) being hoisted, might cause the hoisted recorder to be missed.

This is also used recursively by this very o-walk to schedule a further o-walk on appropriate sub-Stamps.

Keeping track of whether persistent objects are garbage-on-disk during AgendaItem processing only remains open for Stamps, except here where it also arises for an OrglRoot.  The OrglRoot is itself held by a persistent Stamp, from which it can be easily obtained, so we should probably just hold onto two Stamps instead of a Stamp and an OrglRoot (so I only have to solve the "how to keep it around" problem for Stamps).'!

(SouthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SouthRecorderChecker methodsFor: 'creation'!

create: oroot {OrglRoot}  
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	
	super create.
	myORoot _ oroot.
	myFinder _ finder.
	self knownBug. "make sure these objects stick around.  mySCrum has add/removePointer already.  myStamp and myORoot need something similar.  myFinder is one of my sheep and is already OK."
	mySCrum _ scrum.
	mySCrum ~~ NULL
		ifTrue: [mySCrum addPointer: self].
	self newShepherd.!

{void} dismantle
	
	DiskManager consistent: 3 with:
		[mySCrum ~~ NULL
			ifTrue: 
				[mySCrum removePointer: self.
				mySCrum _ NULL].
		self thingToDo. "stop making sure these objects stick around"
		super dismantle]! !

!SouthRecorderChecker methodsFor: 'accessing'!

{BooleanVar} step
	| |
	
	"See class comment for a constraint on this method.
	
	If empty ORoot
		We've already shot once.  Do nothing.
	Check for any recorders in the sensor canopy that need to be rung.
		Remember that we're done."
	myORoot == NULL
		ifTrue: [^false].
	myORoot checkRecorders: myFinder with: mySCrum.
	DiskManager consistent: 1 with:
		[myORoot _ NULL.
		self thingToDo. "stop making sure these objects stick around"
		self diskUpdate.
		^false]! !

!SouthRecorderChecker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myORoot _ receiver receiveHeaper.
	myFinder _ receiver receiveHeaper.
	mySCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myORoot.
	xmtr sendHeaper: myFinder.
	xmtr sendHeaper: mySCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SouthRecorderChecker class
	instanceVariableNames: ''!

(SouthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SouthRecorderChecker class methodsFor: 'creation'!

make: oroot {OrglRoot} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	DiskManager consistent: 2 with: 
		[^self
			create: oroot
			with: finder
			with: scrum]! !

!SouthRecorderChecker class methodsFor: 'smalltalk: passe'!

make: oroot {OrglRoot} 
	with: stamp {BeEdition} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	self passe "fewer args"! !

AgendaItem subclass: #Sequencer
	instanceVariableNames: '
		myFirst {AgendaItem | NULL}
		myRest {AgendaItem}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
Sequencer comment:
'An AgendaItem composed of two other AgendaItems.  Used for when all of the first needs to be done before any of the second may be done.

My stepping action consists of stepping myFirst.  When it is exhausted, I destroy it and then start stepping myRest'!

(Sequencer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!Sequencer methodsFor: 'protected: creation'!

create: first {AgendaItem} with: rest {AgendaItem}

	super create.
	myFirst _ first.
	myRest _ rest.
	first rememberYourself.
	rest rememberYourself.
	self newShepherd.! !

!Sequencer methodsFor: 'accessing'!

{BooleanVar} step
	
	myFirst == NULL
		ifTrue: [^myRest step]
		ifFalse: 
			[myFirst step
				ifFalse: 
					[DiskManager consistent: 2 with: 
						[myFirst destroy.
						myFirst _ NULL.
						self diskUpdate]].
			^true]! !

!Sequencer methodsFor: 'creation'!

{void} dismantle
	
	DiskManager consistent: 3 with: 
		[myFirst ~~ NULL 
			ifTrue:
				[myFirst destroy].
		myRest destroy.
		super dismantle]! !

!Sequencer methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myFirst _ receiver receiveHeaper.
	myRest _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myFirst.
	xmtr sendHeaper: myRest.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sequencer class
	instanceVariableNames: ''!

(Sequencer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!Sequencer class methodsFor: 'creation'!

{AgendaItem} make: first {AgendaItem} with: rest {AgendaItem}

	DiskManager consistent: 3 with:
		[^self create: first with: rest]! !

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