'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:36 pm'!

FlockLocation subclass: #FlockInfo
	instanceVariableNames: '
		myFlockHash {UInt4}
		myToken {Int32}
		myFlags {UInt32}
		myOldSize {Int32}'
	classVariableNames: 'TheFlockCategoryTable {PrimPtrTable smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
FlockInfo comment:
'Contains all the information the packer needs to know about the flock on disk (except forwarder stuff).  The packer knows about forwarders by having several FlockInfo objects for the same flock.  We should consider having a separate class for forward information that does not contain the flags and the oldSize.

myOldSize - this is the size of the flock on disk as of the last commit.  If this is zero, it is uninitialized.  This is used to refitting without bringing in the snarf for this flock.

myFlags - keeps track of whether the receive is a new flock (isn''t on disk yet), is forgotten, is in the process is fchanging its forggten state (isChanging), and is Update (contents have changed).'!

(FlockInfo getOrMakeCxxClassDescription)
	friends:
'	friend UInt4  contentsDirty ();
	friend UInt4  forgottenMask ();
	friend UInt4  forgottenStateDirty ();
	friend UInt4  isNewMask ();
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FlockInfo methodsFor: 'testing'!

{BooleanVar} isContentsDirty
	"Return true if my shepherd has changed and informed the SnarfPacker."
	
	^(myFlags bitAnd: FlockInfo contentsDirty) ~~ UInt32Zero!

{BooleanVar} isDestroyed
	"Return true if our shepherd has received destroy"
	
	^(myFlags bitAnd: FlockInfo destroyed) ~~ UInt32Zero.!

{BooleanVar} isDirty
	"Return true if anything about my flock is changing (including if the flock is new)."
	
	^(myFlags bitAnd: ((FlockInfo isNewMask bitOr: FlockInfo contentsDirty) bitOr: FlockInfo forgottenStateDirty)) ~~ UInt32Zero!

{BooleanVar} isDismantled
	"Return true if our shepherd has been dismantled"
	
	^(myFlags bitAnd: FlockInfo dismantled) ~~ UInt32Zero.!

{BooleanVar} isForgotten
	"Return true if my Shepherd's new state is it should be forgotten."
	
	^self wasForgotten ~~ self isForgottenStateDirty!

{BooleanVar} isForgottenStateDirty
	"Return true if the shepherd I describe is changing between being forgotten and being remembered."
	
	^(myFlags bitAnd: FlockInfo forgottenStateDirty) ~~ UInt32Zero!

{BooleanVar} isForwarded
	"Return true if my shepherd has been forwarded."
	
	^(myFlags bitAnd: FlockInfo forwarded) ~~ UInt32Zero!

{BooleanVar} isNew
	"Return true if the associated flock is new.  If so, myIndex
	 is an offset into the new flocks table inside the SnarfPacker."
	
	^(myFlags bitAnd: FlockInfo isNewMask) ~~ UInt32Zero!

{BooleanVar} wasForgotten
	"Return true if my shepherd was forgotten after the last commit."
	
	^(myFlags bitAnd: FlockInfo forgottenMask) ~~ UInt32Zero!

{BooleanVar} wasShepNullInPersistent
	"Return true if our shepherd pointer was NULL in makePersistent"
	
	^(myFlags bitAnd: FlockInfo shepNullInPersistent) ~~ UInt32Zero.! !

!FlockInfo methodsFor: 'accessing'!

{void} clearContentsDirty
	"Reset my contentsDirty flag.  This is primarily used to know when a flock has
	 changed again after some info has been computed from it."
	
	myFlags _ myFlags bitAnd: FlockInfo contentsDirty bitInvert!

{void} commitFlags
	"A write to the disk has happened.  Commit all the changes in the flags."
	
	self isForgottenStateDirty ifTrue: [myFlags _ myFlags bitXor: FlockInfo forgottenMask].
	myFlags _ myFlags bitAnd: FlockInfo forgottenMask!

{Int32} flags
	^myFlags!

{UInt4} flockHash
	^myFlockHash!

{void} forward: index {Int32}
	"As a freshly forwarded flock, I'll be treated as new for a while."
	
	myFlags _ myFlags bitOr: FlockInfo forwarded.
	self index: index.!

{BooleanVar} markContentsDirty
	"Set my contentsDirty flag.  Return false if I was already dirty (in either way)."
	
	| flag {BooleanVar} |
	flag _ self isDirty not.
	myFlags _ myFlags bitOr: FlockInfo contentsDirty.
	^flag!

{void} markDestroyed
	"Set my shepNull flag."
	
	myFlags _ myFlags bitOr: FlockInfo destroyed.!

{void} markDismantled
	"Set my Dismantled flag.  BLAST if already set."
	
	self isDismantled not assert: 'Already dismantled'.
	myFlags _ myFlags bitOr: FlockInfo dismantled.!

{BooleanVar} markForgotten
	"Set my Forgotten flag.  Return false if I was already dirty."
	
	| flag {BooleanVar} |
	flag _ self isDirty not.
	self isForgotten not ifTrue: [myFlags _ myFlags bitXor: FlockInfo forgottenStateDirty].
	^flag!

{BooleanVar} markRemembered
	"Clear my Forgotten flag.  Return false if I was already dirty."
	
	| flag {BooleanVar} |
	flag _ self isDirty not.
	self isForgotten ifTrue: [myFlags _ myFlags bitXor: FlockInfo forgottenStateDirty].
	^flag!

{void} markShepNull
	"Set my shepNull flag."
	
	myFlags _ myFlags bitOr: FlockInfo shepNullInPersistent.!

{Int32} oldSize
	^myOldSize!

{void} setSize: size {Int32}
	myOldSize _ size! !

!FlockInfo methodsFor: 'tokens'!

{Abraham} fetchShepherd
	myToken == -1
		ifTrue: [ ^ NULL ]
		ifFalse: [ ^Abraham fetchShepherd: myToken]!

{Abraham} getShepherd
	| shep {Abraham} |
	shep := self fetchShepherd.
	shep == NULL ifTrue: [ Heaper BLAST: #NullShepherd ].
	^ shep!

{void} registerInfo
	"Register this info as the best known informatino about the flock."
	
	CurrentPacker fluidGet flockInfoTable at: myToken store: self.
	[| cat shep |
	shep _ self getShepherd.
	shep isStub ifTrue: [cat _ shep getCategoryFromStub] ifFalse: [cat _ shep getCategory].
	TheFlockCategoryTable at: myToken store: cat] smalltalkOnly!

{Int32} token
	^myToken! !

!FlockInfo methodsFor: 'create'!

create: shep {Abraham} with: snarfID {SnarfID} with: index {Int32} with: flags {Int32} with: size {Int32}
	super create: snarfID with: index.
	myFlockHash _ shep hashForEqual.
	myToken _ shep token.
	myFlags _ flags.
	myOldSize _ size! !

!FlockInfo methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('.
	self isContentsDirty ifTrue: [oo << 'D'].
	self isNew ifTrue: [oo << 'N'].
	self isDestroyed ifTrue: [oo << 'X' "X for Xtinct"].
	self isDismantled ifTrue: [oo << 'Z' "Z for zapped"].
	self wasForgotten ifTrue: [oo << '-'] ifFalse: [oo << '+'].
	self isForgotten ifTrue: [oo << '-'] ifFalse: [oo << '+'].
	oo << ', ' << self snarfID << ', ' << self index << ', ' << myOldSize << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FlockInfo class
	instanceVariableNames: ''!

(FlockInfo getOrMakeCxxClassDescription)
	friends:
'	friend UInt4  contentsDirty ();
	friend UInt4  forgottenMask ();
	friend UInt4  forgottenStateDirty ();
	friend UInt4  isNewMask ();
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FlockInfo class methodsFor: 'creation'!

{FlockInfo} forgotten: shep {Abraham} with: snarfID {SnarfID} with: index {Int32} 
	^ self create: shep
		with: snarfID
		with: index 
		with: FlockInfo forgottenMask
		with: Int32Zero.!

make: shep {Abraham} with: index {IntegerVar} 
	"Make a ShepherdLocation for a new shepherd. Index is the index into 
	the new flocks table in the snarfPacker. The newmask indicates 
	that the index is into the newFlocks table rather than a snarf."

	^ self create: shep 
		with: Int32Zero
		with: index DOTasLong 
		with: (((FlockInfo contentsDirty bitOr: FlockInfo forgottenStateDirty)
				bitAnd: FlockInfo forgottenMask bitInvert)
				bitOr: FlockInfo isNewMask)
		with: Int32Zero.!

make: info {FlockInfo} with: snarfID {SnarfID} with: index {Int32} 
	"Make a flockInfo to a new location for the same shepherd.  Clear the new flag, and keep the rest the same."

	^self create: info getShepherd
		with: snarfID
		with: index
		with: (info flags bitAnd: FlockInfo isNewMask bitInvert)
		with: info oldSize!

{FlockInfo} remembered: shep {Abraham} with: snarfID {SnarfID} with: index {Int32} 
	^ self create: shep
		with: snarfID 
		with: index 
		with: UInt32Zero
		with: Int32Zero.! !

!FlockInfo class methodsFor: 'debugging tools'!

{BooleanVar} testContentsDirty: info {FlockInfo}
	^info isContentsDirty!

{BooleanVar} testForgotten: info {FlockInfo}
	^info isForgotten! !

!FlockInfo class methodsFor: 'testing flags'!

{UInt32 INLINE} contentsDirty
	^ 4!

{UInt32 INLINE} destroyed
	^ 16!

{UInt32 INLINE} dismantled
	^ 32!

{UInt32 INLINE} forgottenMask
	^ 1!

{UInt32 INLINE} forgottenStateDirty
	^ 2!

{UInt32 INLINE} forwarded
	^ 128!

{UInt32 INLINE} isNewMask
	^ 8!

{UInt32 INLINE} shepNullInPersistent
	^ 64! !

!FlockInfo class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited
	[TheFlockCategoryTable _ PrimPtrTable make: 2048] smalltalkOnly! !

!FlockInfo class methodsFor: 'flock tables'!

{FlockInfo} getInfo: index {Int32}
	[DiskManager] USES.
	^ (CurrentPacker fluidGet flockInfoTable get: index) cast: FlockInfo!

{void} removeInfo: token {Int32}
	CurrentPacker fluidGet flockInfoTable remove: token.
	"Abraham returnToken: token"! !