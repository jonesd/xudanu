'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:20 pm'!

Abraham subclass: #Fossil
	instanceVariableNames: '
		myGrandMap {GrandMap}
		myIObject {IObject | NULL}
		myWorkType {PackOBits}
		myClubsAndFilters {ImmuTable of: ID and: Filter}
		myUserID {ID}
		myWaldo {Waldo NOCOPY | NULL}
		myWaldoCount {IntegerVar NOCOPY}
		myAgendaCount {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
Fossil comment:
'A Fossil is a persistent analogue of a Hand or a Foot and whatever is attached to it (i.e. the chain of Waldos). Less punfully, since Waldos are purely session-level objects, they cannot be stored on disk. Whenever a Waldo needs to be stored on disk, such as a HopRecorder on a Bert, the Waldo`s client must instead create a Fossil corresponding to it. The Fossil knows the IObject it is attached to, along with the kind of Waldo it uses and the permissions with which it is grabbing it.

To use the Waldo, the client sends reanimate to the Fossil, which returns the Waldo itself.  The waldo should not be passed out of the reanimate block, because the fossil will be deanimated at the end of the block.'!

(Fossil getOrMakeCxxClassDescription)
	friends:
'/* friends for class Fossil */
friend class WaldoSocket;';
	attributes: ((Set new) add: #DEFERRED.LOCKED; add: #OBSOLETE; add: #EQ; add: #COPY; add: #DEFERRED; add: #SHEPHERD.ANCESTOR; yourself)!

!Fossil methodsFor: 'create'!

create: gm {GrandMap}
	with: iObject {IObject}
	with: workType {PackOBits}
	with: clubsAndFilters {ImmuTable of: ID and: Filter}
	with: user {ID}
	
	super create.
	myGrandMap := gm.
	myIObject := iObject.
	myWorkType := workType.
	myClubsAndFilters := clubsAndFilters.
	myUserID := user.
	myAgendaCount _ Int32Zero.
	self restartFossil: NULL.
	self newShepherd!

{void} destruct

	(Heaper isDestructed: myWaldo) ifFalse:
		[myWaldo destroy].
	super destruct! !

!Fossil methodsFor: 'accessing'!

{void} addItem: item {AgendaItem unused}

	DiskManager insistent: 1 with:
		[myAgendaCount _ myAgendaCount + 1.
		self diskUpdate.
		self memoryCheck]!

{void} extinguish: iObj {IObject}
	"Should only be called from IObject::fossilRelease().  Results in my becoming extinct."
	
	myIObject == NULL
		ifTrue: [Heaper BLAST: #AlreadyExtinct].
	(myIObject isEqual: iObj) not
		ifTrue: [Heaper BLAST: #WhoSays].
	myWaldoCount ~= Int32Zero
		ifTrue: [Heaper BLAST: #WaldosStillOutstanding].
	myWaldo ~~ NULL
		ifTrue:
			[myWaldo destroy.
			myWaldo _ NULL].
	DiskManager insistent: 1 with:
		[myIObject _ NULL.
		self diskUpdate.
		self memoryCheck]!

{void} releaseWaldo
	"As a premature optimization, we don't destroy the waldo when the count goes to zero, but rather when we consider purging while the count is zero."
	
	(myWaldoCount >= 1) assert.
	myWaldoCount _ myWaldoCount - 1!

{void} removeItem: item {AgendaItem unused}

	(myAgendaCount >= 1) assert.
	DiskManager insistent: 1 with:
		[myAgendaCount _ myAgendaCount - 1.
		self diskUpdate.
		self memoryCheck]!

{Waldo} secretWaldo
	"The Waldo of which this Fossil is the imprint. If necessary, reconstruct it using the information stored in the imprint.
	Should only be called if I am not extinct
	Should only be called from the reanimate macro."
	| |
	
	"If I'm extinct, somebody goofed.
		Blow 'em up.
	If we haven't already reanimated a waldo (because this is the outermost reanimate for this fossil)
		make a KeyMaster (recovering the fossilized permissions)
		make a waldo holding a Foot (which was born with a grab on the myIObject stamp)
	bump the refcount on myWaldo
	return myWaldo"
	
	self isExtinct
		ifTrue: [Heaper BLAST: #FossilExtinct].
	myWaldo == NULL ifTrue:
		[ | km {KeyMaster} |
		km := self makeKeyMaster.
		myWaldo := self makeWaldo: km
			with: (myIObject reconstructGrab: self with: km)].
	myWaldoCount _ myWaldoCount + 1.
	^myWaldo!

{PackOBits} workType

	^myWorkType! !

!Fossil methodsFor: 'private: accessing'!

{KeyMaster} makeKeyMaster
	"Make a KeyMaster with the authority stored in the imprint.
	(Will change when the eviction bug {MB10} is fixed.)"
	
	| clubs {MuTable of: ID and: GateKeeper} |
	
	"Make and empty MuTable of IDs
	For each club imprint (with its corresponding filter imprint)
		Fill in a table entry with a GateKeeper made from the imprint
	Return a composite gatekeeper made from the table."
	
	clubs := MuTable make: IDSpace make.
	myClubsAndFilters stepper forPositions: [ :id {ID} :filter {Filter} |
		clubs at: id introduce: (ActualGateKeeper
			clubGateKeeper: id with: filter with: myGrandMap)].
	^ActualGateKeeper compositeGateKeeper: clubs asImmuTable
		with: myUserID! !

!Fossil methodsFor: 'smalltalk: reanimation'!

{void} reanimate: aBlock {BlockClosure of: Waldo}
	"Should only be called if I am not extinct.
	
	f reanimate: [:w {BackFollowRecorder} | ...]
		should translate to
	BEGIN_REANIMATE(f,BackFollowRecorder,w) {
		...
	} END_REANIMATE;"
	
	[aBlock value: self secretWaldo]
		valueNowOrOnUnwindDo: (Fossil bomb.ReleaseWaldo: self)! !

!Fossil methodsFor: 'testing'!

{UInt32} contentsHash

	"This may not all be necessary, because at the moment the object is immutable. It doesn't really matter, though, since contentsHash is only used for debugging."
	^super contentsHash
		bitXor: (myGrandMap hashForEqual
		bitXor: ((myIObject == NULL ifTrue: [Int32Zero] ifFalse: [myIObject hashForEqual])
		bitXor: (myWorkType hashForEqual
		bitXor: (myClubsAndFilters hashForEqual
		bitXor: myUserID hashForEqual))))!

{BooleanVar} isExtinct
	"A Fossil (unlike a Grabber or an Orgl) does not prevent the grabbed IObject from being dismantled.  Instead, if the IObject does get dismantled, then the Fossil is considered extinct.  A waldo may not be gotten from an extinct fossil (if the species is really extinct, then it cannot be revived from its remaining fossils)."
	
	^myIObject == NULL!

{BooleanVar} isPurgeable
	"I can`t go to disk while someone has my WaldoSocket and might be doing 
	something with the Waldo in it."
	
	(super isPurgeable and: [myWaldoCount == Int32Zero])
		ifTrue: 
			[myWaldo ~~ NULL
				ifTrue: 
					[myWaldo destroy.
					myWaldo _ NULL].
			^true]
		ifFalse: [^false]! !

!Fossil methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartFossil: rcvr {Rcvr unused default: NULL}

	myWaldo _ NULL.
	myWaldoCount _ Int32Zero! !

!Fossil methodsFor: 'protected: destruction'!

{void} dismantle

	(myWaldoCount = Int32Zero) assert.
	(myAgendaCount = Int32Zero) assert.
	myWaldo ~~ NULL
		ifTrue:
			[myWaldo destroy.
			myWaldo _ NULL].
	DiskManager consistent: 2 with:
		[(myIObject == NULL or: [Heaper isDestructed: myIObject]) ifFalse:
			[myIObject fossilRelease: self].
		(myIObject == NULL) assert.
		super dismantle]! !

!Fossil methodsFor: 'protected: accessing'!

{Waldo} makeWaldo: km {KeyMaster} with: tip {Manipulator}
	"Reconstruct the old Waldo using the given KeyMaster and Hand/Foot"
	
	self subclassResponsibility!

{void} memoryCheck

	(myIObject == NULL and: [myAgendaCount = Int32Zero])
		ifTrue: [self forget]
		ifFalse: [self remember]! !

!Fossil methodsFor: 'smalltalk: passe'!

{void} emptyWaldoSocket
	"The WaldoSocket has been destructed, so set the pointer to NULL.
	This means that I can go back out to disk."
	
	self passe!

{Grabber} makeGrabber: km {KeyMaster}
	"Grab the IObject with the appropriate kind of grabber"
	
	self passe!

{Waldo} waldo
	"The Waldo of which this Fossil is the imprint. If necessary, reconstruct it using the information stored in the imprint.
	Should only be called if I am not extinct"
	
	self passe.	"Should have called secretWaldo, but only from the reanimate method/macro"!

{WaldoSocket} waldoSocket
	"Get or make a socket holding onto the Waldo"
	
	self passe! !

!Fossil methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myGrandMap _ receiver receiveHeaper.
	myIObject _ receiver receiveHeaper.
	myWorkType _ receiver receiveInt32.
	myClubsAndFilters _ receiver receiveHeaper.
	myUserID _ receiver receiveHeaper.
	myAgendaCount _ receiver receiveIntegerVar.
	self restartFossil: receiver.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myGrandMap.
	xmtr sendHeaper: myIObject.
	xmtr sendInt32: myWorkType.
	xmtr sendHeaper: myClubsAndFilters.
	xmtr sendHeaper: myUserID.
	xmtr sendIntegerVar: myAgendaCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Fossil class
	instanceVariableNames: ''!

(Fossil getOrMakeCxxClassDescription)
	friends:
'/* friends for class Fossil */
friend class WaldoSocket;';
	attributes: ((Set new) add: #DEFERRED.LOCKED; add: #OBSOLETE; add: #EQ; add: #COPY; add: #DEFERRED; add: #SHEPHERD.ANCESTOR; yourself)!

!Fossil class methodsFor: 'pseudo constructors'!

make: waldo {Waldo}
	"Make a persistent representation of the given waldo.
	WARNING: Destroys the supplied waldo; once the Fossil is created, you must get the waldo from it, through its WaldoSocket.
	Implementation note: Right now, it handles BackfollowRecorders as a special case, since they store additional information in the Waldo. This should really be handled using a generic middlement facility.
	Note: Fossils are born remembered"
	
	| workType {PackOBits} 
	  tip {Manipulator} 
	  iObject {IObject} 
	  result {Fossil}
	  p {Filter of: ID} 
	  e {Filter of: ID} 
	  clubsAndFilters {MuTable of: ID and: Filter} |
	  
	waldo cast: BackfollowRecorder into: [ :rec |
		p := rec permissionsFilter.
		e := rec endorsementsFilter]
	others: 
		[p := e := NULL].
	workType := waldo workType.
	tip := waldo.
	[tip isKindOf: Waldo] whileTrue:
		[tip := (tip cast: Waldo) unwrapped].
	tip cast: Foot into: [ :foot |
			iObject := foot stamp]
		cast: ActualHand into: [ :hand |
			iObject := hand bert].
	clubsAndFilters := MuTable make: IDSpace make.
	[ImmuSet] USES.
	tip keyMaster componentClubIDs stepper forEach: [ :club {ID} |
		clubsAndFilters at: club
			store: ((tip keyMaster cast: ActualGateKeeper) superClubFilterFor: club)].
	DiskManager consistent: 2 with:
		[p == NULL ifTrue:
			[result := OrdinaryFossil create: CurrentGrandMap fluidGet
				with: iObject
				with: workType
				with: clubsAndFilters asImmuTable
				with: tip keyMaster userID]
		ifFalse:
			[result := BackfollowRecorderFossil create: CurrentGrandMap fluidGet
				with: iObject
				with: workType
				with: clubsAndFilters asImmuTable
				with: tip keyMaster userID
				with: p
				with: e].
		iObject fossilReGrab: (tip cast: Grabber)
			with: result.
		^result]! !

!Fossil class methodsFor: 'exceptions: exceptions'!

bomb.ReleaseWaldo: CHARGE {Fossil}

	^[CHARGE releaseWaldo]! !