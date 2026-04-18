'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:42 pm'!

DiskManager subclass: #TestPacker
	instanceVariableNames: '
		myNextHash {UInt32}
		myInitialFlock {Abraham}
		myFlocks {IntegerTable of: FlockInfo}
		myChangedFlocks {IntegerTable of: Abraham}
		myDestroyedFlocks {IntegerTable of: Abraham}
		myAlmostNewFlocks {MuSet of: Abraham}
		myNewFlocks {IntegerTable of: FlockInfo}
		myXcvrMaker {XcvrMaker}
		myCountDown {IntegerVar}
		myPersistInterval {IntegerVar}
		myDisk {IntegerTable of: UInt8Array}
		myBook {Cookbook}
		amCommitting {BooleanVar}
		blastOnError {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
TestPacker comment:
'Does not actually go to disk, but just tests that the protocol is being followed correctly. Some of these tests may make it into the real SnarfPacker, but some of them will remain debugging tools. Most operations only do enough real stuff to be able to check that they work.


The TestPacker holds onto an IntegerTable of UInt8Arrays that contain the disk representations of all the flocks.  It also holds 

myDisk contains a UInt8Array for every flock that made it to disk.  They are assigned sequential numbers.
myNewFlocks contains the flockInfos for new flocks, and thus contains the new flocks wimpily.
myAlmostNewFlocks contains flocks that are under construction but have not yet finished.
myDestroyedFlocks contains flocks that will be destroyed upon exiting the current consistent block.
myChangedFlocks points strongly at flocks that must be rewritten to disk.
'!

(TestPacker getOrMakeCxxClassDescription)
	friends:
'friend class EndCommit_Bomb;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestPacker methodsFor: 'shepherds'!

{void} destroyFlock: info {FlockInfo} 
	"Queue destroy of the given flock.  The destroy will probably happen later."

	| flock {Abraham} |
	flock _ info getShepherd cast: Abraham. "Check for destructed essentially"
	self mustKnowShepherd: info.
	self mustBeInsideTransaction.
	self mustNotBeCommitting.
	self countDown.
	
	info markDestroyed.
	info markForgotten ifTrue: [self recordUpdate: info].
	myDestroyedFlocks atInt: myDestroyedFlocks count introduce: flock!

{void} diskUpdate: info {FlockInfo} 
	info == NULL ifTrue: [^VOID].  "noop for new shepherds."
	self mustKnowShepherd: info.
	self mustBeInsideTransaction.
	self mustNotBeCommitting.
	self countDown.
	info markContentsDirty
		ifTrue: [self recordUpdate: info]
		ifFalse: 
			["sanity check"
			info isNew
				ifTrue: [(myNewFlocks includesIntKey: info index) assert: 'Something is wrong']
				ifFalse: [(myChangedFlocks includesIntKey: info index) assert: 'Something is wrong']]!

{void} dismantleFlock: info {FlockInfo} 
	"The flock designated by info has completed all dismantling actions; throw it off the disk."

	| flock {Abraham} |
	flock _ info getShepherd cast: Abraham. "Check for destructed essentially"
	self mustKnowShepherd: info.
	self mustNotBeCommitting.
	self countDown.
	
	info markDismantled.
	info isNew ifFalse:
		[myChangedFlocks atInt: info index store: Pumpkin make].!

{void} dropFlock: token {Int32}
	| info {FlockInfo} |
	info := FlockInfo getInfo: token.
	info isNew
		ifTrue: 
			[myNewFlocks intRemove: info index]
		ifFalse: 
			[info isForgotten ifFalse: [Heaper BLAST: #OnlyRemoveUnchangedFlocks].
			myChangedFlocks intWipe: info index.
			myFlocks intRemove: info index].
	FlockInfo removeInfo: token!

{void} forgetFlock: info {FlockInfo} 

	self mustKnowShepherd: info.
	self mustBeInsideTransaction.
	self mustNotBeCommitting.
	self countDown.
	info markForgotten ifTrue: [self recordUpdate: info]!

{Turtle} getInitialFlock

	^myInitialFlock cast: Turtle!

{UInt32} nextHashForEqual
	 
	myNextHash _ myNextHash + 1.
	"This actually needs to roll over the UInt32 limit."
	^myNextHash!

{void} rememberFlock: info {FlockInfo} 

	self mustBeInsideTransaction.
	self countDown.
	info markRemembered ifTrue: [self recordUpdate: info]!

{void} storeAlmostNewShepherd: shep {Abraham} 

	myAlmostNewFlocks store: shep!

{void} storeInitialFlock: turtle {Abraham}
	with: protocol {XcvrMaker}
	with: cookbook {Cookbook}
	
	myInitialFlock := turtle.
	myXcvrMaker := protocol.
	myBook := cookbook.
	self storeNewFlock: turtle.!

{void} storeNewFlock: shep {Abraham} 
	"Shep just got created!! On some later commit, assign it to a snarf 
	and write it to the disk."

	| info {FlockInfo} |
	shep fetchInfo == NULL ifFalse:
		[Heaper BLAST: #NewShepherdMustNotHaveInfo].
	self countDown.
	myAlmostNewFlocks wipe: shep.
	info _ TestFlockInfo make: shep with: myNewFlocks highestIndex + 1.
	myNewFlocks atInt: myNewFlocks highestIndex + 1 introduce: info.
	shep flockInfo: info! !

!TestPacker methodsFor: 'private: testing'!

{void} checkNewFlockIndices

	myNewFlocks stepper forIndices: [ :index {IntegerVar} :value {FlockInfo} |
		index DOTasLong = value index ifFalse:
			[Heaper BLAST: #NewFlockIndexDoesNotMatch]]!

{void} committing: flag {BooleanVar}

	amCommitting := flag!

{IntegerVar} countDown
	"Decrement the countdown and return its new value"
	
	myCountDown := myCountDown - 1.
	^myCountDown!

{void} mustBeInsideTransaction

	InsideTransactionFlag fluidFetch
		ifFalse: [blastOnError ifTrue:
				[Heaper BLAST: #MustBeInsideTransaction].
			[cerr << 'Method '<< thisContext sender sender selector << ' must call ' << thisContext sender selector << ' inside a transaction
'] smalltalkOnly.
			cerr << 'A consistent block is missing
']!

{void} mustKnowShepherd: info {FlockInfo} 
	"Check that I know about this shepherd"

	| t {Heaper} |
	info isNew
		ifTrue: [t := myNewFlocks intFetch: info index]
		ifFalse: [t := myFlocks intFetch: info index].
	(t ~~ NULL and: [t isEqual: info])
		ifFalse: [Heaper BLAST: #IncorrectFlockInfo]!

{void} mustNotBeCommitting

	amCommitting ifTrue:
		[Heaper BLAST: #MustNotChangeDuringCommit]!

{void} resetCountDown

	myCountDown := myPersistInterval.! !

!TestPacker methodsFor: 'stubs'!

{Abraham} fetchCanonical: hash {UInt32 unused} with: snarfID {SnarfID unused} with: index {Int32}

	^(myFlocks intFetch: index) cast: Abraham!

{void} makeReal: info {FlockInfo}

	| stub {Abraham} oldHash {UInt32} stream {XnReadStream} rcvr {Rcvr} |
	stub := info getShepherd.
	stub isStub ifFalse:
		[Heaper BLAST: #MustBeAStub].
	oldHash := stub hashForEqual.
	(rcvr _ self makeRcvr: (stream _ self readStream: info)) receiveInto: stub.
	rcvr destroy.
	stream destroy.
	stub hashForEqual == oldHash
		ifFalse: [Heaper BLAST: #HashMustNotChange].
	info setSize: (self computeSize: info getShepherd).
	"Receiving the flock will have cleared its info, so put it back."
	stub flockInfo: info!

{void} registerStub: shep {Abraham} with: snarfID {SnarfID} with: index {Int32}
	| info {FlockInfo} |
	shep isStub assert: 'Must be stub'.
	info _ TestFlockInfo remembered: shep with: snarfID with: index.
	shep flockInfo: info.
	myFlocks atInt: index introduce: info! !

!TestPacker methodsFor: 'private: streams'!

{Int32} computeSize: flock {Abraham}
	"Send the snarf over a transmitter into a stream that just counts the bytes put into it."
	
	| counter {XnWriteStream} xmtr {Xmtr} size {Int32} | 
	counter := CountStream make.
	xmtr _ self makeXmtr: counter.
	xmtr sendHeaper: flock.
	size _ (counter cast: CountStream) size.
	xmtr destroy.
	counter destroy.
	^size!

{SpecialistRcvr} makeRcvr: readStream {XnReadStream}

	^myXcvrMaker makeRcvr: (DiskSpecialist make: myBook with: self) with: readStream!

{SpecialistXmtr} makeXmtr: writeStream {XnWriteStream}

	^myXcvrMaker makeXmtr: (DiskSpecialist make: myBook with: self) with: writeStream!

{XnReadStream} readStream: info {FlockInfo}
	"Get a read stream on the disk contents of the info"
	
	^XnReadStream make: ((myDisk intGet: info index) cast: UInt8Array)!

{XnWriteStream} writeStream: info {FlockInfo}
	"Get a write stream on the disk contents of the info"
	
	| result {UInt8Array} |
	result := UInt8Array make: (self computeSize: info getShepherd).
	myDisk atInt: info index store: result.
	self hack.  "You can't use gutsOf in something that will do an allocation."
	^XnWriteStream make: result! !

!TestPacker methodsFor: 'private: disk'!

{void} assignSnarf: shep {Abraham}

	| oldInfo {FlockInfo} snarf {SnarfID} |
	oldInfo := shep getInfo.
	snarf := myDisk highestIndex DOTasLong + 1.
	myDisk atInt: snarf store: (UInt8Array make: UInt32Zero).
	shep flockInfo: (TestFlockInfo make: oldInfo with: snarf with: snarf).
	"Destroy the old location if it is for a new flock (rather than forwarded)."
	oldInfo isNew ifTrue:
		[myNewFlocks intWipe: oldInfo index.
		oldInfo destroy.
		(shep getInfo cast: TestFlockInfo) updateContentsInfo].
	oldInfo := NULL.
	myFlocks atInt: snarf introduce: shep getInfo.
	myChangedFlocks atInt: snarf store: shep!

{void} flushChanges
	"Rewrite all flocks that have changed in this snarf."

	"check that all changed flocks are in fact in myChangedFlocks"
	| flocks {TableStepper} |
	myFlocks stepper forEach: [:info {TestFlockInfo} | 
		(info fetchShepherd ~~ NULL
			and: [(info isNew not)
			and: [(info updateContentsInfo or: [info isContentsDirty])
			and: [(myChangedFlocks includesIntKey: info snarfID) not]]])
			ifTrue: 
				[blastOnError ifTrue: [Heaper BLAST: #ShouldHaveDoneDiskUpdateOnChangedShepherd].
				cerr << 'Shepherd ' << info fetchShepherd << ' with info ' << info << ' should have done a diskUpdate
'.
				self recordUpdate: info]].
	"actually write changed flocks to disk"
	(flocks := myChangedFlocks stepper) forEach: [:thing {Heaper} | thing
		cast: Pumpkin into: [:pumpkin |
			myDisk intWipe: flocks index]
		cast: Abraham into: [:shep | | inf {FlockInfo} |
			inf := shep fetchInfo.
			inf == NULL ifTrue: [Heaper BLAST: #ShepherdMustNotHaveNullFlockInfo].
			inf index == flocks index DOTasLong ifTrue: 
				[| xmtr {Xmtr} stream {XnWriteStream} |
				"Not forwarded."
				shep isStub ifTrue: [Heaper BLAST: #MustBeInstantiated].
				(xmtr _ self makeXmtr: (stream _ self writeStream: inf)) sendHeaper: shep.
				xmtr destroy.
				stream destroy.
				(inf cast: TestFlockInfo) setContents: ((myDisk intFetch: inf index) cast: UInt8Array).
				inf commitFlags]
			ifFalse:
				["We only get here for forwarded flocks."
				Heaper BLAST: #TestPackerDoesNotForward]]].
	myChangedFlocks destroy.
	myChangedFlocks := IntegerTable make!

{void} recordUpdate: info {FlockInfo} 
	"The flock represented by info has changed.  Record it in the
	 bookkeeping data-structures.  This must be called by all things 
	 that affect whether the flock gets rewritten to disk."
	| shep {Abraham} |
	
	info isNew not ifTrue: 
		[(shep _ info fetchShepherd) ~~ NULL ifTrue:
			[(shep isEqual: Pumpkin make)
				ifTrue: 
					[blastOnError ifTrue: [Heaper BLAST: #MustNotRecordChangesForPumpkins].
					cerr << 'Pumpkin ' << info << ' tried to diskUpdate
'.
					^VOID]].
		myChangedFlocks atInt: info index store: shep]!

{void} refitFlocks

	"do nothing for now"! !

!TestPacker methodsFor: 'create'!

create: blast {BooleanVar} with: persistInterval {IntegerVar}

	super create.
	myNextHash := UInt32Zero.
	myInitialFlock := NULL.
	myFlocks := IntegerTable make.
	myChangedFlocks := IntegerTable make.
	myDestroyedFlocks _ MuArray array.
	myAlmostNewFlocks := MuSet make.
	myNewFlocks := IntegerTable make.
	myXcvrMaker := NULL.
	myBook := NULL.
	myPersistInterval := persistInterval.
	self resetCountDown.
	myDisk := IntegerTable make.
	amCommitting := false.
	blastOnError := blast.! !

!TestPacker methodsFor: 'internals'!

{UInt32} computeHash: flock {Abraham}
	"Compute a hash on the contents"
	| hasher {XnWriteStream} hash {UInt32} xmtr {SpecialistXmtr} |
	hasher := HashStream make.
	xmtr := self makeXmtr: hasher.
	xmtr sendHeaper: flock.
	hash := (hasher cast: HashStream) hash.
	xmtr destroy.
	hasher destroy.
	^hash! !

!TestPacker methodsFor: 'smalltalk: defaults'!

{void} purgeClean
	self purgeClean: false! !

!TestPacker methodsFor: 'transactions'!

{void} beginConsistent: dirty {IntegerVar unused}
	InsideTransactionFlag fluidFetch
		ifFalse: 
			[self countDown < IntegerVar0
				ifTrue: 
					[self makePersistent.
					self resetCountDown]]!

{void} endConsistent: dirty {IntegerVar unused} 
	| agenda {Agenda | NULL} |
	
	InsideTransactionFlag fluidFetch ifTrue: [^VOID].
	myAlmostNewFlocks isEmpty
		ifFalse: 
			[blastOnError
				ifTrue: [Heaper BLAST: #MustDoNewShepherdAfterDiskUpdate].
			cerr << 'These flocks should have done a newShepherd: ' << myAlmostNewFlocks << '
'.
			myAlmostNewFlocks stepper forEach: [:each {Abraham} | 
				each newShepherd]].
		
	InsideAgenda fluidFetch ifTrue: [^VOID].
	agenda _ (myInitialFlock cast: Turtle) fetchAgenda.
	agenda ~~ NULL ifTrue: 
		[InsideAgenda fluidBind: true during:
			[[agenda step] whileTrue]].

	myDestroyedFlocks isEmpty ifTrue: [^VOID].
	InsideAgenda fluidBind: true during:
		[[myDestroyedFlocks isEmpty]
			whileFalse:
				[| flock {Abraham} |
				flock _ (myDestroyedFlocks intGet: myDestroyedFlocks count - 1) cast: Abraham.
				myDestroyedFlocks intRemove: myDestroyedFlocks count - 1.
				flock getInfo isForgotten ifTrue: [flock dismantle]]]!

{BooleanVar} insideCommit
	^ amCommitting!

{void} makePersistent

	[amCommitting := true.
	self refitFlocks.
	myNewFlocks stepper forEach: [:info {FlockInfo} | | shep {Abraham} |
		(shep _ info fetchShepherd) ~~ NULL ifTrue:
			[self assignSnarf: shep]].
	self flushChanges.
	myNewFlocks destroy.
	myNewFlocks := IntegerTable make: 500]
		valueNowOrOnUnwindDo:
			(TestPacker bomb.EndCommit: self)!

{void} purge

	InsideTransactionFlag fluidFetch ifFalse:
		[self makePersistent.
		self purgeClean: true]!

{void} purgeClean: noneLocked {BooleanVar default: false}
	
	 | stackPtrs {PrimPtrTable} |
	[Transcript show: 'Starting purge...'] smalltalkOnly.
	noneLocked
		ifTrue: [stackPtrs _ PrimPtrTable make: 1]
		ifFalse: [stackPtrs _ StackExaminer pointersOnStack].
	myFlocks stepper forEach:
		[ :info {FlockInfo} |
		| shep {Abraham} |
		shep := info fetchShepherd.
		[(shep ~~ NULL
				and: [shep isStub not
				and: [(stackPtrs fetch: shep asOop) == NULL
				and: [shep isPurgeable
				and: [info isDirty not]]]])
			ifTrue: [shep becomeStub]] smalltalkOnly.
		'if (shep && shep->fetchInfo() == info && !!shep->isStub() && (stackPtrs->fetch((Int32)(void*)shep) == NULL) && shep->isPurgeable() && !!info->isDirty()) {
			shep->becomeStub();
			}' translateOnly.].
	[Transcript show: 'done.'; cr] smalltalkOnly! !

!TestPacker methodsFor: 'smalltalk: passe'!

{void} makeConsistent

	self passe.
	myAlmostNewFlocks isEmpty ifFalse:
		[blastOnError ifTrue:
			[Heaper BLAST: #MustDoNewShepherdAfterDiskUpdate].
		cerr << 'These flocks should have done a newShepherd: ' << myAlmostNewFlocks << '
'.
		myAlmostNewFlocks stepper forEach: [ :each {Abraham} |
			each newShepherd]].
	self countDown < IntegerVar0 ifTrue: 
		[self makePersistent.
		self resetCountDown]! !

!TestPacker methodsFor: 'testing'!

{BooleanVar} isFake
	^ false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TestPacker class
	instanceVariableNames: ''!

(TestPacker getOrMakeCxxClassDescription)
	friends:
'friend class EndCommit_Bomb;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestPacker class methodsFor: 'exceptions: private:'!

bomb.EndCommit: CHARGE {TestPacker star}

	^[CHARGE committing: false]! !

!TestPacker class methodsFor: 'pseudo constructors'!

{DiskManager} make: blast {BooleanVar} with: persistInterval {IntegerVar}

	| result {DiskManager} |
	result := self create: blast with: persistInterval.
	CurrentPacker fluidSet: result.
	^result! !