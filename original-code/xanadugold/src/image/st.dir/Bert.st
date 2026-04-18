'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:42 pm'!

IObject subclass: #Bert
	instanceVariableNames: '
		myStamp {Stamp}
		myHopRecorders {ImmuSet of: (Fossil of: HopRecorder)}
		myActiveHopRecorders {ImmuSet of: (Fossil of: HopRecorder)}
		myWaitForGrabSensors {ImmuSet NOCOPY of: XnSensor}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(Bert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!Bert methodsFor: 'accessing'!

{void} checkRecorders: stamp {Stamp unused} 
	with: finder {PropFinder unused} 
	with: scrum {SensorCrum unused | NULL}
	
	self unimplemented!

{void} hop: orgl {ActualOrgl} 
	
	| oldStamp {Stamp} |
	DiskManager consistent: 350 with:
		[oldStamp _ myStamp.
		myStamp _ orgl stamp.
		myStamp introduceBert: self.
		oldStamp removeBert: self.
		self recordInto: myActiveHopRecorders.
		self diskUpdate]!

{Orgl} orgl
	"the orgl associated with this IObject"
	^ myStamp orgl!

{OrglRoot} orglRoot
	^myStamp orglRoot!

{void} propChanged: change {PropChange} 
	with: old {Prop} 
	with: nw {Prop}
	"update props"
	| active {SetAccumulator} |
	self setProp: self localProp.
	myStamp propChanged: change with: old with: nw.
	active _ SetAccumulator make.
	myHopRecorders stepper forEach: [ :hopper {Fossil of: HopRecorder} |
		hopper isExtinct ifFalse:
			[hopper reanimate: [:waldo {HopRecorder} |
				(waldo match: self prop) ifTrue:
					[active step: hopper]]]].
		
		"NOTE:  This needs to destroy Fossil's that are going 
		 away!!!!?  Can they be pointed to by anything else?"
		
	self recordInto: ((active value cast: ImmuSet) minus: myActiveHopRecorders).
	myActiveHopRecorders _ active value cast: ImmuSet.
	self diskUpdate!

{void} record: recorder {HopRecorder} 
	"Install a new hop recorder. This destroys the HopRecorder that it is passed, so 
	you shouldn`t do anything more with it."
	
	DiskManager consistent: 3 with:
		[| fossilized {Fossil of: HopRecorder} |
		fossilized := Fossil make: recorder.
		myHopRecorders _ myHopRecorders with: fossilized.
		fossilized reanimate: [:waldo {HopRecorder} |	"Can't be extinct"
			(waldo match: self prop)
				ifTrue: [myActiveHopRecorders _ myActiveHopRecorders with: fossilized]].
		self diskUpdate]!

{Stamp} stamp
	"return the current stamp"
	^ myStamp! !

!Bert methodsFor: 'protected: protected'!

{void} dismantle
	"Disconnect me and remove me from disk."
	
	DiskManager consistent: 280 with:
		[self propChange: PropChange bertPropChange with: BertProp make.
		myWaitForGrabSensors ~~ NULL ifTrue:
			[myWaitForGrabSensors destroy].
		super dismantle]! !

!Bert methodsFor: 'create'!

create: orgl {ActualOrgl} with: iD {ID | NULL}
	super create: iD with: orgl grandMap.
	myStamp _ orgl stamp.
	myStamp introduceBert: self.
	myHopRecorders _ myActiveHopRecorders _ ImmuSet make.
	self restartBert: NULL.
	self newShepherd! !

!Bert methodsFor: 'smalltalk: gc'!

{void} markChildren: count {IntegerVar}
	super markChildren: count.
	myStamp markInstances: count.
	self thingToDo. "One of these should be weak, I think."
	myHopRecorders markInstances: count.
	myActiveHopRecorders markInstances: count.
	myWaitForGrabSensors markInstances: count.! !

!Bert methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myStamp hashForEqual!

{BooleanVar} isPurgeable
	"Return false only if the object cannot be flushed to disk. This will probably 
	only be false for Stamps and the like that contain session level pointers."

	^myWaitForGrabSensors isEmpty and: [super isPurgeable]! !

!Bert methodsFor: 'grabbing'!

{void} release: oldGrabber {Grabber}
	| sensor {WaitForGrabSensor} ringer {Heaper} |
	self mutex critical:
		[ringer _ NULL.
		[myWaitForGrabSensors isEmpty] whileFalse:
			[sensor _ myWaitForGrabSensors stepper get cast: WaitForGrabSensor.
			myWaitForGrabSensors _ myWaitForGrabSensors without: sensor.
			(sensor gateKeeper canEdit: self iD) ifTrue:
				[self grabber: (Hand
						make.ActualGateKeeper: sensor gateKeeper
						with.Bert: self).
				ringer _ self getGrabber]].
		ringer == NULL ifTrue:
			[self getGrabber == NULL ifTrue:
				[Heaper BLAST: #NotGrabbed]
			ifFalse: [self getGrabber ~~ oldGrabber ifTrue:
				[Heaper BLAST: #WhoIsReleasingMe]
			ifFalse: [myWaitForGrabSensors isEmpty ifTrue:
				[self grabber: NULL]]]]].
	ringer ~~ NULL ifTrue:
		[sensor ring: ringer]!

{void} storeWaitForGrab: sensor {WaitForGrabSensor}
	| ringer {Heaper} |
	self mutex critical:
		[self getGrabber == NULL ifTrue:
			[myWaitForGrabSensors isEmpty assert: 'One of the grab sensors should have been rung'.
			(sensor gateKeeper canEdit: self iD) ifTrue:
				[self grabber: (Hand	
						make.ActualGateKeeper: sensor gateKeeper
						with.Bert: self).
				ringer _ self getGrabber]]
		ifFalse:
			[myWaitForGrabSensors _ myWaitForGrabSensors with: sensor.
			ringer _ NULL]].
	ringer ~~ NULL ifTrue:
		[sensor ring: ringer]!

{void} wipeWaitForGrab: sensor {WaitForGrabSensor}
	self mutex critical:
		[myWaitForGrabSensors _ myWaitForGrabSensors without: sensor]! !

!Bert methodsFor: 'receiver'!

{void RECEIVE.HOOK} restartBert: rcvr {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"

	[myWaitForGrabSensors == nil assert: 'bert should not be initialized yet.'] smalltalkOnly.
	myWaitForGrabSensors _ ImmuSet make.
	self thingToDo. "do the right stuff for weak pointers to work here"! !

!Bert methodsFor: 'protected: grabbing'!

{Grabber} privateReconstructGrab: gk {ActualGateKeeper}

	^Hand make.ActualGateKeeper: gk with.Bert: self! !

!Bert methodsFor: 'private'!

{void} recordInto: hoppers {ScruSet of: (Fossil of: HopRecorder)}
	"Must create a separate HopRecord for every active recorder, so it can be permitted
	to each respective recorder owner"
	hoppers isEmpty ifFalse:
		[hoppers stepper forEach: [ :hopper {Fossil of: HopRecorder} |
			 | km {KeyMaster} 
			   record {ActualHopRecord} | 
			 
			hopper isExtinct ifFalse:
				[hopper reanimate: [:waldo {HopRecorder} |
					km _ waldo keyMaster.
					record _ ActualHopRecord 
						make: km
						with: (self getGrabber cast: Hand) keyMaster userID
						with: self orgl
						with: Sequence currentTime.
			
					waldo record: record]]]].! !

!Bert methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myStamp _ receiver receiveHeaper.
	myHopRecorders _ receiver receiveHeaper.
	myActiveHopRecorders _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myStamp.
	xmtr sendHeaper: myHopRecorders.
	xmtr sendHeaper: myActiveHopRecorders.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Bert class
	instanceVariableNames: ''!

(Bert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!Bert class methodsFor: 'instance creation'!

{Bert} make: orgl {Orgl} with: iD {ID | NULL}
	^ self create: (orgl cast: ActualOrgl) with: iD! !