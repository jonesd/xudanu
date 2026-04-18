'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:45 pm'!

Abraham subclass: #IObject
	instanceVariableNames: '
		myID {ID}
		myProp {BertProp}
		myOwnProp {BertProp}
		myEditClub {FastClub}
		myReadClub {FastClub}
		myHRoot {HRoot}
		haveIDHRoot {BooleanVar}
		myGrandMap {GrandMap}
		myMutex {Sema4 NOCOPY}
		myGrabber {Grabber NOCOPY}
		myGrabbersFossil {Fossil | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(IObject getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.ANCESTOR; add: #DEFERRED.LOCKED; add: #OBSOLETE; yourself)!

!IObject methodsFor: 'protected: protected accessing'!

{Fossil} fetchFossil

	^myGrabbersFossil!

{Grabber} fetchGrabber
	^myGrabber!

{Fossil} getFossil

	myGrabbersFossil == NULL ifTrue:
		[Heaper BLAST: #FossilShouldNotBeNull].
	^myGrabbersFossil!

{Grabber} getGrabber
	myGrabber == NULL ifTrue: [Heaper BLAST: #NoGrabber].
	^myGrabber!

{void} grabber: grabber {Grabber}
	myGrabber _ grabber!

{Sema4} mutex
	^myMutex!

{void} setProp: newProp {BertProp}
	myProp _ newProp.
	self diskUpdate! !

!IObject methodsFor: 'deferred'!

{Orgl} orgl
	"the orgl associated with this IObject"
	self subclassResponsibility!

{OrglRoot} orglRoot
	self subclassResponsibility!

{void} propChanged: change {PropChange} 
	with: old {Prop} 
	with: nw {Prop}
	"Propagate changes in props"
	self subclassResponsibility! !

!IObject methodsFor: 'accessing'!

{void} addEndorsements: endorsementIDs {XnRegion of: ID} 
	
	endorsementIDs isEmpty
		ifTrue: [^VOID].
	DiskManager consistent: 8 with:
		[self 
			propChange: PropChange endorsementsChange 
			with: (BertProp endorsementsProp: (endorsementIDs unionWith: self prop endorsements))]!

{void} checkRecorders: stamp {Stamp} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	"check any recorders that might be triggered by a change in the stamp"
	
	self subclassResponsibility!

{void} clubConsistencyCheck
	(myEditClub ~= NULL and: [myEditClub isPermanentlyBlocked not])
		ifTrue: [(myEditClub editables hasMember: self) assert].
	(myReadClub ~= NULL and: [myReadClub isPermanentlyBlocked not])
		ifTrue: [(myReadClub readables hasMember: self) assert].!

{ID} editClubID
	myEditClub == NULL
		ifTrue: [^myGrandMap nullClubID]
		ifFalse: [^myEditClub iD].!

{HRoot} fetchHRoot
	"current hRoot"
	^ myHRoot!

{GrandMap} grandMap
	^ myGrandMap!

{void} hRoot: hRoot {HRoot}
	"set the HRoot at the bottom of the OTree that refers to the iD this IObject"
	(myHRoot ~~ NULL and: [hRoot ~~ NULL]) ifTrue: [Heaper BLAST: #FatalError].
	myHRoot _ hRoot.
	self remember.
	myHRoot == NULL ifTrue: 
		[Heaper BLAST: #FatalError  "use removeHRoot."].
	self diskUpdate!

{ID} iD
	
	myID == NULL
		ifTrue: 
			[DiskManager consistent: 2 with:
				[myID _ self grandMap newXID.
				self diskUpdate "but not remembered yet"].
			DiskManager consistent: 17 with:
				[self grandMap at: myID introduceIObject: self.
				self remember.
				self diskUpdate]].
	^myID!

{void} iDHRoot: iDHRoot {HRoot unused}
	"Here we just record whether the iobject has an IDHRoot."
	haveIDHRoot ifTrue: [Heaper BLAST: #FatalError].
	haveIDHRoot _ true.
	self remember.
	self diskUpdate!

{BertProp} localProp
	^myOwnProp!

{void} permissionsChanged
	"recompute permissions. Leave endorsements alone"
	| newClubIDs {XnRegion of: ID} |
	myReadClub == NULL
		ifTrue: [newClubIDs _ IDRegion make]
		ifFalse: [newClubIDs _ myReadClub permittedClubIDs].
	myEditClub ~= NULL
		ifTrue: [newClubIDs _ newClubIDs unionWith: myEditClub permittedClubIDs].
		
	self propChange: PropChange permissionsChange
		with: (BertProp permissionsProp: newClubIDs)!

{BertProp} prop
	^ myProp!

{void} propChange: change {PropChange} with: nw {Prop} 
	
	| old {Prop} |
	old _ myOwnProp.
	(change areEqualProps: old with: nw) not
		ifTrue: 
			[myOwnProp _ (change changed: old with: nw) cast: BertProp.
			self diskUpdate.
			self propChanged: change with: old with: nw]!

{ID} readClubID
	myReadClub == NULL
		ifTrue: [^myGrandMap nullClubID]
		ifFalse: [^myReadClub iD].!

{void} removeEndorsement: endorsementID {ID unused}
	self unimplemented
	"CurrentPacker fluidVar consistent:
		[self prop: (self prop without: (BertProp endorsementsProp: endorsementID))]"!

{void} removeHRoot
	"remove the ORoot at the bottom of the OTree that referes to this 
	object."
	
	myHRoot == NULL
			ifTrue: [Heaper BLAST: #FatalError].
	DiskManager consistent: 1 with:
		[myHRoot _ NULL.
		self canForget
			ifTrue: [self forget]
			ifFalse: [self diskUpdate]]!

{void} removeIDHRoot
	"My ID's HRoot was just removed from the GrandMap."
	
	haveIDHRoot not ifTrue: [Heaper BLAST: #FatalError].
	haveIDHRoot _ false.
	self canForget ifTrue: [self forget]!

{void} setEditClubID: clubID {ID}
	"WARNING: This doesn't do a 'self permissionsChanged', so its caller must"

	myEditClub ~= NULL ifTrue:
		[myEditClub removeEditable: self].
	(myGrandMap nullClubID isEqual: clubID)
		ifTrue: [myEditClub _ NULL]
		ifFalse: [myEditClub _ myGrandMap getClub: clubID].
	myEditClub ~= NULL ifTrue:
		[myEditClub addEditable: self].!

{void} setReadClubID: clubID {ID}
	"WARNING: This doesn't do a 'self permissionsChanged', so its caller must"

	myReadClub ~= NULL ifTrue:
		[myReadClub removeReadable: self].
	(myGrandMap nullClubID isEqual: clubID)
		ifTrue: [myReadClub _ NULL]
		ifFalse: [myReadClub _ myGrandMap getClub: clubID].
	myReadClub ~= NULL ifTrue:
		[myReadClub addReadable: self].! !

!IObject methodsFor: 'grabbing'!

{void} fossilReGrab: oldGrabber {Grabber} with: newGrabber {Fossil}
	"Given the grabber on this IObject, regrab it with a fossil.
	NOTE: Releases the old grabber and then DESTROYS it."
	
	myMutex critical:
		[myGrabber == NULL ifTrue:
			[Heaper BLAST: #NotGrabbed]
		ifFalse: [myGrabber ~~ oldGrabber ifTrue:
			[Heaper BLAST: #WhoIsRegrabbingMe]
		ifFalse: [newGrabber == NULL ifTrue:
			[Heaper BLAST: #ShouldReleaseInstead]
		ifFalse:
			[DiskManager consistent: 1 with:
				["The Fossil had better have permission to grab me!!"
				myGrabbersFossil := newGrabber.
				oldGrabber cast: Foot into: [ :foot |
						foot ungrab]
					cast: ActualHand into: [ :hand |
						hand ungrab].
				myGrabber := NULL.
				oldGrabber destroy.
				self diskUpdate]]]]]!

{void} fossilRelease: oldGrabber {Fossil}

	myMutex critical:
		[myGrabbersFossil == NULL ifTrue:
			[Heaper BLAST: #NotGrabbed]
		ifFalse: [myGrabbersFossil ~~ oldGrabber ifTrue:
			[Heaper BLAST: #WhoIsReleasingMe]
		ifFalse:
			[DiskManager consistent: 2 with:
				[myGrabbersFossil := NULL.
				oldGrabber extinguish: self.
				self diskUpdate]]]]!

{BooleanVar} grab: newGrabber {Grabber} 
	myMutex critical:
		[myGrabber ~~ NULL ifTrue:
			[^myGrabber isEqual: newGrabber]
		ifFalse: [((newGrabber keyMaster cast: ActualGateKeeper) canEdit: self iD) not ifTrue:
			[^false]
		ifFalse:
			[myGrabber _ newGrabber.
			^true]]]!

{Grabber} reconstructGrab: fossil {Fossil} with: km {KeyMaster}
	"Make a Grabber for reconstructing the Fossil"
	
	myMutex critical:
		[myGrabbersFossil ~~ fossil ifTrue:
			[Heaper BLAST: #WhoIsReGrabbingMe]
		ifFalse: [((km cast: ActualGateKeeper) canEdit: self iD) not ifTrue:
			[Heaper BLAST: #MustHaveReadPermission]
		ifFalse: [myGrabber ~~ NULL ifTrue:
			[Heaper BLAST: #ShouldNotBeGrabbed]
		ifFalse:
			[myGrabber := self privateReconstructGrab: (km cast: ActualGateKeeper).
			^myGrabber]]]]!

{void} reGrab: oldGrabber {Grabber} with: newGrabber {Grabber} 
	myMutex critical:
		[myGrabber == NULL ifTrue:
			[Heaper BLAST: #NotGrabbed]
		ifFalse: [myGrabber ~~ oldGrabber ifTrue:
			[Heaper BLAST: #WhoIsRegrabbingMe]
		ifFalse: [newGrabber == NULL ifTrue:
			[Heaper BLAST: #ShouldReleaseInstead]
		ifFalse: [((newGrabber keyMaster cast: ActualGateKeeper) canEdit: self iD) not ifTrue:
			[Heaper BLAST: #CantGrab]
		ifFalse:
			[myGrabber _ newGrabber]]]]]!

{void} release: oldGrabber {Grabber} 
	myMutex critical:
		[myGrabber == NULL ifTrue:
			[Heaper BLAST: #NotGrabbed]
		ifFalse: [myGrabber ~~ oldGrabber ifTrue:
			[Heaper BLAST: #WhoIsReleasingMe]
		ifFalse:
			[myGrabber _ NULL]]]! !

!IObject methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myID << ')'! !

!IObject methodsFor: 'testing'!

{UInt32} contentsHash

	^(((((((super contentsHash
		bitXor: myID hashForEqual)
		bitXor: myProp hashForEqual)
		bitXor: myOwnProp hashForEqual)
		bitXor: myEditClub hashForEqual)
		bitXor: myReadClub hashForEqual)
		bitXor: myHRoot hashForEqual)
		bitXor: myGrandMap hashForEqual)
		bitXor: (myGrabbersFossil ~~ NULL
			ifTrue: [myGrabbersFossil hashForEqual]
			ifFalse: [UInt32Zero])!

{BooleanVar} isPurgeable
	"Return false only if the object cannot be flushed to disk. This will probably 
	only be false for Stamps and the like that contain session level pointers."

	^myGrabber == NULL and: [super isPurgeable]! !

!IObject methodsFor: 'receiver'!

{void RECEIVE.HOOK} restartIObject: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	myGrabber _ NULL.
	myMutex _ Sema4 make: 1! !

!IObject methodsFor: 'smalltalk: smalltalk defaults'!

{void} restartIObject

	self restartIObject: NULL! !

!IObject methodsFor: 'protected: instance creation'!

create: iD {ID | NULL} with: grandMap {GrandMap}
	super create.
	myID _ iD.
	myOwnProp _ myProp _ BertProp make.
	myHRoot _ NULL.
	haveIDHRoot _ false.
	myGrandMap _ grandMap.
	myEditClub _ NULL.
	myReadClub _ NULL.
	myID ~~ NULL ifTrue: [self grandMap at: myID introduceIObject: self].
	myGrabbersFossil := NULL.
	self restartIObject.! !

!IObject methodsFor: 'smalltalk: gc'!

{void} markChildren: count {IntegerVar}
	myID markInstances: count.
	myProp markInstances: count.
	myOwnProp markInstances: count.
	myEditClub markInstances: count.
	myReadClub markInstances: count.
	myHRoot markInstances: count.
	myGrandMap markInstances: count.
	myMutex markInstances: count.
	myGrabber markInstances: count.! !

!IObject methodsFor: 'protected: protected'!

{BooleanVar} canForget
	"Return true if there are no more references onto this IObject. 
	 This superclass routine primarily looks for HRoots, and named IDs."
	
	"Right now all EXIDs are named, but we aren't actually ever
	 asking for the names, so ignore the naming issue."
	^myHRoot == NULL and: [myID == NULL or: [haveIDHRoot not]]!

{void} dismantle
	"Disconnect me and remove me from disk."
	
	DiskManager insistent: 5 with:
		[myGrabbersFossil ~~ NULL
			ifTrue: [self fossilRelease: myGrabbersFossil].
		(myID ~~ NULL) 
			ifTrue: [self grandMap removeIObject: myID].
		myID _ NULL.
		super dismantle]! !

!IObject methodsFor: 'protected: grabbing'!

{Grabber} privateReconstructGrab: gk {ActualGateKeeper}
	"Make a grabber for myself using the given GateKeeper. Permissions and mutual exclusion are already taken care of; this is just to polymorph the kind of grabber to produce."
	
	self subclassResponsibility! !

!IObject methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myID _ receiver receiveHeaper.
	myProp _ receiver receiveHeaper.
	myOwnProp _ receiver receiveHeaper.
	myEditClub _ receiver receiveHeaper.
	myReadClub _ receiver receiveHeaper.
	myHRoot _ receiver receiveHeaper.
	haveIDHRoot _ receiver receiveBooleanVar.
	myGrandMap _ receiver receiveHeaper.
	myGrabbersFossil _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myID.
	xmtr sendHeaper: myProp.
	xmtr sendHeaper: myOwnProp.
	xmtr sendHeaper: myEditClub.
	xmtr sendHeaper: myReadClub.
	xmtr sendHeaper: myHRoot.
	xmtr sendBooleanVar: haveIDHRoot.
	xmtr sendHeaper: myGrandMap.
	xmtr sendHeaper: myGrabbersFossil.! !