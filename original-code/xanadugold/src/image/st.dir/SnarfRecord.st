'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:42 pm'!

Heaper subclass: #SnarfRecord
	instanceVariableNames: '
		mySnarfID {SnarfID}
		myPacker {SnarfPacker}
		mySpaceLeft {Int32}
		myOccupied {IntegerRegion | NULL}
		myChangedFlocks {PrimPtrTable of: Abraham}
		myDestroyCount {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
SnarfRecord comment:
'Manage retrieval, refitting, and rewriting of existing flocks.  Assign indices for new flocks.  

SnarfRecords can go away after their contents have been flushed.  We might keep it around if we expect to be assigning new flocks to the snarf again, just to keep myOccupied.  The snarfRecord will be recreated when another object is read in.'!

(SnarfRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!SnarfRecord methodsFor: 'writing'!

{Int32} allocate: size {Int32} with: shep {Abraham}
	"Shep is being newly added to this snarf.  Allocate enough space for it and return the newly assigned index for it."
	"The spaceLeft that we compute includes the size of the cells, otherwise we couldn't keep the number up to date."
	
	| index {IntegerVar} |
	size <= mySpaceLeft assert: 'Must have space left'.
	(shep isEqual: Pumpkin make) not assert: 'Only allocate real shepherds'. 
	shep isStub not assert: 'Must be instantiated'.
	self thingToDo.  "A hash check to see if shep is being forwarded back to this snarf from elsewhere."
	index _ self allocateIndex.
	shep getInfo setSize: size - SnarfHandler mapCellOverhead.
	self setSpaceLeft: mySpaceLeft - size.
	myChangedFlocks at: index store: shep.
	^index DOTasLong!

{void} changedFlock: index {Int32} with: shep {Abraham}
	"Remember that the flock at index must be written to the snarf on the next update."
	
	(shep isEqual: Pumpkin make) not assert: 'Record changes for real objects only'.
	"We don't return the flock's space to the pool here because it might be a forwarded flock."
	(Heaper isDestructed: shep) not assert: 'Must not be destructed'.
	shep isStub not assert: 'Must be instantiated'.
	myChangedFlocks at: index store: shep!

{void} dismantleFlock: info {FlockInfo}
	"Remove the flock from the disk.  Replace it with a Pumpkin so that the 
	 routine that flushes to disk knows to remove whatever's there already."

	"Remove the flocks space allocation now so that we can reallocate from the newly created pool."
	[|tmp {Abraham}|
	tmp _ myChangedFlocks fetch: info index.
	(tmp ~~ NULL and: [info fetchShepherd ~~ tmp]) ifTrue: [self halt]] smalltalkOnly.
	self setSpaceLeft: mySpaceLeft + info oldSize.
	myChangedFlocks at: info index store: Pumpkin make.
	myDestroyCount _ myDestroyCount + 1! !

!SnarfRecord methodsFor: 'transactions'!

{void} flushChanges
	"Rewrite all flocks that have changed in this snarf."

	| highest {Int32} handler {SnarfHandler} newHighest {IntegerVar} stepper {PrimPtrTableStepper} shep {Abraham} |
	handler _ self getWriteHandler.
	highest _ handler mapCount.
	newHighest _ self wipeBelowHighest: highest with: handler.
	"mySpaceLeft also has the size of the cells taken out of it."
	self thingToDo. 
		"Depending on tests, this might also preclear the total space for all
		of the flocks to be written.  Then we will only compact once, and do
		it before writing any flocks."
	self hack.  "This should get the highest index from myOccupied, except that it might not be computed."
	handler allocateCells: newHighest - highest.
	stepper := myChangedFlocks stepper.
	[(shep := stepper fetch cast: Abraham) ~~ NULL] whileTrue: 
		[| index {IntegerVar} |
		index := stepper index.
		(shep isEqual: Pumpkin make) ifFalse:
			[shep getInfo snarfID == mySnarfID	 
				ifTrue:
					["Not forwarded."
					| xmtr {Xmtr} stream {XnWriteStream} |
					shep isStub not assert: 'Must be instantiated'.
					handler at: index allocate: shep getInfo oldSize.
					stream _ handler writeStream: index.
					xmtr _ myPacker makeXmtr: stream.
					xmtr sendHeaper: shep.
					xmtr destroy.
					stream destroy.
					handler at: index DOTasLong storeForget: shep getInfo isForgotten.
					shep getInfo commitFlags.
					shep getInfo clearContentsDirty]
				ifFalse:
					["We only get here for forwarded flocks."
					handler forward: index to: shep getInfo snarfID with: shep getInfo index]].
		stepper step].
	stepper destroy.
	myChangedFlocks clearAll.
	handler destroy!

{void} refitFlocks
	"Recompute size information for all changed shepherds and see if they still fit.
	 Any that don't get handed to the SnarfPacker to treat as new flocks.   The 
	 old space changed and dismantled flocks has been returned to the pool.  
	 Reallocate space for the changed flocks out of the pool.  Any that don't fit 
	 are handed back to myPacker to go in other snarfs."
	
	myChangedFlocks stepper forEach: 
		[:shep {Abraham} |
		self setSpaceLeft: mySpaceLeft + shep getInfo oldSize.
 		mySpaceLeft >= Int32Zero assert: 'Must have space left'].
	myChangedFlocks stepper forEach: 
		[:shep {Abraham} |
		"Leave Pumpkins here so they will be seen by flushChanges."
		(shep isEqual: Pumpkin make) not ifTrue: 
			[|  size {Int32} |
			size _ myPacker computeSize: shep.
			shep getInfo setSize: size.
			size <= mySpaceLeft 
				ifTrue: [self setSpaceLeft: mySpaceLeft - size]
				ifFalse: [myPacker forwardFlock: shep]].
 		mySpaceLeft >= Int32Zero assert: 'Must have space left'.]!

{Int32} spaceLeft
	"Return the amount of space currently left in the snarf."
	
	^mySpaceLeft! !

!SnarfRecord methodsFor: 'protected: destruct'!

{void} destruct
	"Destroy all objects imaged from this snarf."
	
	myChangedFlocks destroy.
	myOccupied ~~ NULL ifTrue: [myOccupied destroy].
	super destruct.! !

!SnarfRecord methodsFor: 'private: private'!

{IntegerVar} allocateIndex
	"Return the first unoccupied index in the snarf.  Compute the lowest
	 element >= 0 that is not already in the occupied region by subtracting 
	 the occupied region from the region >= 0."
	
	| index {IntegerVar} |
	self readOccupied.
	index _ myOccupied nearestIntHole: IntegerVar0.
	myOccupied _ (myOccupied withInt: index) cast: IntegerRegion.
	^index!

{SnarfHandler} getWriteHandler
	"Get the handler for my snarf so that I can send or receive data from it."

	| handler {SnarfHandler} flag {BooleanVar} |
	flag := myOccupied ~~ NULL and: [myOccupied count == myChangedFlocks count].
	"We also need to compare regions in case as many things are dismantled as are unchanged."
	"Change this to iterate myOCcupied and check the presence of each element. 
	 Either that or use an IntegerTable for myChangedFlocks."
	"myChangedFlocks really wants to be an optimizing representation."
	flag ifTrue: [
		| stepper {PrimPtrTableStepper} |
		"calculate myOccupied isSuperSetOf: myChangedFlocks domain"
		stepper := myChangedFlocks stepper.
		[flag and: [stepper hasValue]] whileTrue: [
			(myOccupied hasIntMember: stepper index) ifFalse: [flag := false].
			stepper step].
		flag := flag and: [stepper hasValue not].
		stepper destroy].
	
	flag	
		ifTrue:
			[handler _ SnarfHandler make: (myPacker currentView makeErasingHandle: mySnarfID).
			handler initializeSnarf]
		ifFalse:
			[handler _ SnarfHandler make: (myPacker currentView makeReadHandle: mySnarfID)].
	handler makeWritable.
	^handler!

{void} readOccupied
	"Create an array with the sizes of every flock in the snarf."
	
	| handler {SnarfHandler} count {Int32} |
	myOccupied ~~ NULL ifTrue: [^VOID].
	mySpaceLeft >= (myPacker currentView getDataSizeOfSnarf: mySnarfID) ifTrue:
		[myOccupied _ IntegerRegion make.
		^VOID].
	handler _ SnarfHandler make: (myPacker currentView makeReadHandle: mySnarfID).
	count _ handler mapCount.
	myOccupied _ IntegerRegion make: IntegerVar0 with: count.
	Int32Zero almostTo: count do:
		[:i {Int32} |
		| shep {Abraham | NULL} |
		shep _ (myChangedFlocks fetch: i) cast: Abraham.
		((handler isOccupied: i) not or: [shep ~~ NULL and: [shep isEqual: Pumpkin make]])
			ifTrue: [myOccupied _ (myOccupied without: i integer) cast: IntegerRegion]].
	handler destroy!

{void} setSpaceLeft: spaceLeft {Int32}
	spaceLeft >= Int32Zero assert: 'Space is positive'.
	mySpaceLeft _ spaceLeft.!

{IntegerVar} wipeBelowHighest: highest {Int32} with: handler {SnarfHandler}
	| newHighest {IntegerVar} stepper {PrimPtrTableStepper} |
	"(myChangedFlocks domain intersect: (IntegerRegion before: highest)) stepper forEach: 
		[:key {XnInteger} | handler wipeFlock: key asIntegerVar]. ----  too inefficient.  also compute the upper bound for later." 
	newHighest _ highest.
	stepper _ myChangedFlocks stepper.
	[stepper hasValue] whileTrue: 
		[| index {IntegerVar} |
		index := stepper index.
		index < highest ifTrue: [handler wipeFlock: index].
		index >= newHighest ifTrue: [newHighest _ index+1   "Must be above the new key."].
		stepper step].
	stepper destroy.
	^ newHighest! !

!SnarfRecord methodsFor: 'create'!

create: snarfID {SnarfID} with: packer {SnarfPacker} with: spaceLeft {Int32}
	super create.
	mySnarfID _ snarfID.
	myPacker _ packer.
	myChangedFlocks _ PrimPtrTable make: 128.
	self setSpaceLeft: spaceLeft.
	myOccupied _ NULL.
	mySpaceLeft >= (myPacker currentView getDataSizeOfSnarf: mySnarfID) ifTrue: 
		[mySpaceLeft _ (myPacker currentView getDataSizeOfSnarf: mySnarfID) - SnarfHandler mapOverhead.
		myOccupied _ IntegerRegion make].
	myDestroyCount _ Int32Zero! !

!SnarfRecord methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << mySnarfID << ')'! !

!SnarfRecord methodsFor: 'smalltalk: passe'!

{FlockLocation} fetchForward: index {Int32}
	"If the location specified by info has been forwarded, return a flockInfo
	 describing its new location."
	
	self passe!

{MuSet of: IntegerPos} forgottenFlocks
	"Return the set of indices to locations that are forgotten."
	
	self passe!

{BooleanVar} isForgotten: index {Int32} 
	"Return true if the flock at that location is forgotten. Higher level routines 
	should make sure this doesn't get done very often because it requires bringing 
	in the snarf if it's not already there."

	self passe!

{BooleanVar} isPurgeable
	"Return true if everything in this snarfRecord is purged. 
	 If so, then this snarfRecord can be thrown away."
	
	self passe!

{void} makeReal: index {Int32} with: stub {Abraham}
	"We know that the object wasn't imaged.  Read the real shepherd into
	 the memory occupied by stub.  If the location is a forwarder, then 
	 register a new flockInfo with the stub and just return."
	
	| handler {SnarfHandler} loc {FlockLocation | NULL} |
	stub isStub assert: 'Only stubs can be made real'.
	handler _ self getReadHandler.
	self readOccupied.
	loc _ handler fetchForward: index.
	loc == NULL
		ifTrue: 
			[| info {FlockInfo} oldHash {UInt32} |
			info _ stub getInfo.
			oldHash _ stub hashForEqual.
			(myPacker makeRcvr: (handler readStream: index) with: mySnarfID with: index)
					receiveInto: stub.
			stub hashForEqual == oldHash assert: 'Hash must not change'.
			info setSize: (handler flockSize: index).
			stub flockInfo: info]
		ifFalse:
			["Forwarded.  Register stub at the new location." 
			stub flockInfo: (FlockInfo make: stub getInfo with: loc snarfID with: loc index).
			myPacker addInfo: stub getInfo with: stub].
	self releaseReadHandler!

{Abraham} originateFlock: index {IntegerVar}
	"This will get a flock that we know the location of
	 without a stub.  The flock must not already be imaged,
	 and it must not be forwarded."
	
	| result {Abraham} rcvr {Rcvr} |
	rcvr _ myPacker makeRcvr: (self getReadHandler readStream: index DOTasLong)
					with: mySnarfID 
					with: index.
	result _ rcvr receiveHeaper cast: Abraham.
	self readOccupied.
	self releaseReadHandler. 
	^result! !

!SnarfRecord methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SnarfRecord class
	instanceVariableNames: ''!

(SnarfRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!SnarfRecord class methodsFor: 'pcreate'!

make: snarfID {SnarfID} with: packer {SnarfPacker} with: spaceLeft {Int32}
	^self create: snarfID with: packer with: spaceLeft! !