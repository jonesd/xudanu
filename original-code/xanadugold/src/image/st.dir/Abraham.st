'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:33 pm'!

Heaper subclass: #Abraham
	instanceVariableNames: '
		myHash {UInt32}
		myToken {Int32 NOCOPY}
		myInfo {FlockInfo NOCOPY}'
	classVariableNames: '
		DismantleStatistics {IdentityDictionary smalltalk of: Category and: IntegerVar} 
		TheTokenSource {TokenSource} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(Abraham getOrMakeCxxClassDescription)
	friends:
'friend class SnarfPacker;
friend class TestPacker;
friend class FakePacker;
friend class SnarfRecord;
friend class SnarfHandler;
friend void  unlockFunctionAvoidingDestroy (Abraham *);
friend class RecorderHoister;
';
	attributes: ((Set new) add: #DEFERRED.LOCKED; add: #DEFERRED; add: #COPY; yourself)!

!Abraham methodsFor: 'protected: destruction'!

{void} becomeStub
	"Replace the shepherd in memory with a type compatible stub
	 instance that shares the same hash and flockInfo."
	 
	 "NOTE: Should this ensure that the flock is not dirty?"
	
	"Each subclass of Abraham will have an implementation of the form: 
		new (this) MyStubClass()' or:
		'this->changeClassToThatOf(ProtoStubClass)'"

	[| theHash {UInt32} info {FlockInfo} theCategory {Category} |
	theHash _ myHash.
	info _ myInfo.
	theCategory _ self getCategory.
	(ShepherdStub new.Become: self) create: theHash with: info with: theCategory] smalltalkOnly.
	[self unimplemented] translateOnly!

{void NOFAULT NOLOCK} destruct
	"Called when an object is leaving RAM.  Additional behavior for subclasses of Abraham:
	Tell the snarfPacker that I am leaving RAM and should be removed from its tables."
	
	myInfo ~~ NULL
		ifTrue: [CurrentPacker fluidGet dropFlock: myToken].
	super destruct!

{void} dismantle
	"Disconnect me from the universe and throw me off the disk. 
	
	For GC safety, we keep a strongptr to ourself -- is this still necessary?"

	| spt {Abraham} packer {DiskManager} |
	spt _ self.
	[| pos {Category} |
	pos _ self getCategory.
	DismantleStatistics at: pos put: (DismantleStatistics at: pos ifAbsent: [0]) + 1] smalltalkOnly.

	"Tell the disk the flock is dismantled."
	packer _ CurrentPacker fluidGet.
	packer dismantleFlock: myInfo.
	packer flockTable at: myToken store: NULL.
	myInfo ~~ NULL
		ifTrue: [packer dropFlock: myToken].! !

!Abraham methodsFor: 'protected: disk'!

{void} diskUpdate
	"The receiver has changed and so must eventually be rewritten to disk."

	myInfo == NULL
		ifTrue: ["Before a newShepherd." 
				CurrentPacker fluidGet storeAlmostNewShepherd: self]
		ifFalse: [CurrentPacker fluidGet diskUpdate: myInfo]!

{void NOFAULT} forget
	"Record on disk that there are no more persistent pointers to the receiver.  When the in core pointers go away, the receiver can be dismantled from disk.  That will happen eventually."

	CurrentPacker fluidGet forgetFlock: myInfo!

{void NOFAULT} newShepherd
	"The receiver has just been created. Put it on disk."
 
	CurrentPacker fluidGet storeNewFlock: self!

{void NOFAULT} remember
	"Record that there are now persistent pointers to the receiver."

	CurrentPacker fluidGet rememberFlock: myInfo! !

!Abraham methodsFor: 'destruction'!

{void} destroy
	"Tell the packer I want to go away. It will mark me 
	as forgotten and actually dismantle me when it next 
	exits a consistent block. This avoids Jackpotting 
	when destroying a tree of objects."

	"[myToken < CurrentPacker fluidGet flockTable count 
		ifTrue: [CurrentPacker fluidGet flockTable at: myToken store: NULL]] smalltalkOnly."
	CurrentPacker fluidGet destroyFlock: myInfo! !

!Abraham methodsFor: 'testing'!

{UInt32 NOFAULT} actualHashForEqual
	^myHash!

{UInt32} contentsHash
	"A hash of the contents of this flock"
	^self getCategory hashForEqual!

{BooleanVar NOFAULT} isEqual: other {Heaper}
	^self == other!

{BooleanVar} isPurgeable
	"Return false only if the object cannot be flushed to disk. This will probably 
	only be false for Stamps and the like that contain session level pointers."

	^true!

{BooleanVar NOFAULT} isShepherd
	"This should be replaced with an isKindOf: that first checks to see
	  if you're asking about Abraham, and then otherwise possible faults."
	
	self hack.
	^true!

{BooleanVar NOFAULT} isStub 
	"Distinguish between stubs and shepherds."
	
	^false!

{BooleanVar} isUnlocked
	"All manually generated subclasses are locked.  Automatically
	 defined unlocked classes will reimplement this."
	
	^false! !

!Abraham methodsFor: 'accessing'!

{FlockInfo NOFAULT} fetchInfo
	"Return the object that describes the state of this flock wrt disk."
	 
	 "This should be made protected."
	^myInfo!

{void NOFAULT} flockInfo: info {FlockInfo}
	"Set the object that knows where this flock is on disk.  Change it when the object moves."

	| flocks {WeakPtrArray} |
	[info class == DeletedHeaper ifTrue: [self halt]] smalltalkOnly.
	myInfo _ info.
	info token ~~ myToken ifTrue: [Abraham returnToken: myToken].
	myToken _ myInfo token.
	
	"Register when a flockInfo has been assigned."
	flocks _ CurrentPacker fluidGet flockTable.
	myToken >= flocks count ifTrue:
		["Grow if necessary."
		CurrentPacker fluidGet flockTable: ((flocks copyGrow: myToken) cast: WeakPtrArray).
		flocks destroy.
		flocks _ CurrentPacker fluidGet flockTable].
	flocks at: myToken store: self.
	myInfo registerInfo!

{FlockInfo NOFAULT} getInfo
	"Return the object that describes the state of this flock wrt disk."
	 
	myInfo == NULL ifTrue: [Heaper BLAST: #MustBeInitialized].
	[(myInfo class == DeletedHeaper) ifTrue: [self error: 'info was deleted']] smalltalkOnly.
	^myInfo!

{Category NOFAULT} getShepherdStubCategory
	"Return the category of stubs used for the receiver. Shepherd Patriarch classes reimplement this to use more specific Stub types."

	[^ShepherdStub] smalltalkOnly.
	'
	BLAST(SHEPHERD_HAS_NO_STUB_DEFINED);
	return NULL;' translateOnly!

{Int32 NOFAULT} token
	"Return the object that describes the state of this flock wrt disk."
	 
	^myToken! !

!Abraham methodsFor: 'protected: create'!

create
	"New Shepherds must be stored to disk."
	
	super create.
	myHash _ CurrentPacker fluidGet nextHashForEqual.
	"Start out remembered, changing to forgotten.  They also start out as
	 if they were on disk (newShepherd must be called to make it so.  This
	 prevents intermediate diskUpdates from forcing a new object to disk 
	 before creation is finished."
	
	self restartAbraham!

create.ShepFlag: ignored {ShepFlag var unused} with: hash {UInt32} with: info {FlockInfo}
	"This is the root of the automatically generated constructors for creating Stubs."
	
	super create.
	myHash _ hash.
	[info class == DeletedHeaper ifTrue: [self halt]] smalltalkOnly.
	self restartAbraham.
	info ~~ NULL ifTrue: [self flockInfo: info]!

{INLINE} create: hash {UInt32}
	"This is for shepherds that are becoming from another shepherd."
	
	super create.
	self thingToDo. "Change my callers to use Abraham::Abraham(UInt32,APTR(FlockInfo)).  The flockInfo should be restored at the Abraham level instead of below.  This also more likely causes the type checker to catch inappropriate become-constructor use"
	
	myHash _ hash.
	
	self restartAbraham! !

!Abraham methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartAbraham: trans {Rcvr unused default: NULL}

	myToken _ TheTokenSource takeToken.
	myInfo _ NULL.! !

!Abraham methodsFor: 'smalltalk: only'!

create: hash {UInt32} with: info {FlockInfo}
	"This is for ShepherdStubs that use the hash and forgetFlag from the object for which they are stubbing."
	
	super create.
	myHash _ hash.
	[info class == DeletedHeaper ifTrue: [self halt]] smalltalkOnly.
	self flockInfo: info.!

{BooleanVar} isKindOf: cat {Category} 
	"Optimized for Abraham because xcvrs use it so much."

	^cat == Abraham or: [super isKindOf: cat]!

{void} restartAbraham

	self restartAbraham: NULL! !

!Abraham methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHash _ receiver receiveUInt32.
	self restartAbraham: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: myHash.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Abraham class
	instanceVariableNames: ''!

(Abraham getOrMakeCxxClassDescription)
	friends:
'friend class SnarfPacker;
friend class TestPacker;
friend class FakePacker;
friend class SnarfRecord;
friend class SnarfHandler;
friend void  unlockFunctionAvoidingDestroy (Abraham *);
friend class RecorderHoister;
';
	attributes: ((Set new) add: #DEFERRED.LOCKED; add: #DEFERRED; add: #COPY; yourself)!

!Abraham class methodsFor: 'smalltalk: utilities'!

dismantleStatistics
	^DismantleStatistics! !

!Abraham class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage

	self linkTimeNonInherited! !

!Abraham class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	[DismantleStatistics _ IdentityDictionary new] smalltalkOnly.
	[self mayBecome: ShepherdStub] smalltalkOnly.
	TheTokenSource _ TokenSource make.!

linkTimeNonInherited
	TheTokenSource _ NULL!

staticTimeNonInherited
	BooleanVar defineFluid: #InsideTransactionFlag with: DiskManager emulsion with: [false].! !

!Abraham class methodsFor: 'global: functions'!

{BooleanVar INLINE} isConstructed: obj {Heaper}
	^obj ~~ NULL and: [obj getCategory ~~ DeletedHeaper]!

{BooleanVar INLINE} isDestructed: obj {Heaper}
	^obj == NULL or: [obj getCategory == DeletedHeaper]! !

!Abraham class methodsFor: 'tokens'!

{Abraham} fetchShepherd: token {Int32}
	| table {PtrArray} |
	table := CurrentPacker fluidGet flockTable.
	token < table count
		ifTrue: [^(table fetch: token) cast: Abraham]
		ifFalse: [^NULL]!

{void} returnToken: token {Int32}
	TheTokenSource returnToken: token! !