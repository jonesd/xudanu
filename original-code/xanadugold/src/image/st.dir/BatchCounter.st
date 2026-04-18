'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:04 pm'!

Counter subclass: #BatchCounter
	instanceVariableNames: '
		myCount {IntegerVar NOCOPY}
		myPersistentCount {IntegerVar}
		myMutex {Sema4 NOCOPY}
		myBatchCount {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-counter'!
BatchCounter comment:
'Instances preallocate a bunch of numbers and record the preallocations to disk.  It then increments purely in memory until the preallocated counts are used up.  It then preallocates another bunch of numbers.  If the system crashes, all numbers between the in-memory count and the on-disk count simply never get used.  This reduces the access to disk for shepherd hashes and GrandMap IDs.'!

(BatchCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BatchCounter methodsFor: 'accessing'!

{IntegerVar} count
	^myCount!

{IntegerVar} decrement
	
	myMutex critical: 
		[DiskManager consistent: 1 with:
			[myCount _ myCount - 1.
			self diskUpdate]].
	^myCount!

{IntegerVar} decrementBy: count {IntegerVar}
	
	count >= IntegerVarZero ifFalse:
		[Heaper BLAST: #InvalidRequest].
	myMutex critical: 
		[DiskManager consistent: 1 with:
			[myCount _ myCount - count.
			self diskUpdate]].
	^myCount!

{IntegerVar} increment
	myMutex critical:
	[myCount _ myCount + 1.
	myCount > myPersistentCount ifTrue:
		[DiskManager consistent: 1 with:
		[myPersistentCount _ myCount + myBatchCount.
		self diskUpdate]]].
	^myCount!

{IntegerVar} incrementBy: count {IntegerVar}

	count >= IntegerVarZero ifFalse:
		[Heaper BLAST: #InvalidRequest].
	myMutex critical:
	[myCount _ myCount + count.
	myCount > myPersistentCount ifTrue:
		[DiskManager consistent: 1 with:
		[myPersistentCount _ myCount + myBatchCount.
		self diskUpdate]]].
	^myCount!

{void} setCount: count {IntegerVar} 
	
	myMutex critical: 
		[DiskManager consistent: 1 with:
			[myCount _ count.
			self diskUpdate]]! !

!BatchCounter methodsFor: 'receiver: stubble'!

{void RECEIVE.HOOK} restartBatchCounter: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	myCount _ myPersistentCount.
	myMutex _ Sema4 make: 1.! !

!BatchCounter methodsFor: 'protected: create'!

create: count {IntegerVar} with: batchCount {IntegerVar}
	super create.
	DiskManager consistent: 1 with:
		[myPersistentCount _ myCount _ count.
		myBatchCount _ batchCount.
		self restartBatchCounter: NULL.
		self newShepherd.
		self remember]!

create: count {IntegerVar} with: batchCount {IntegerVar} with: hash {UInt32}
	super create: hash.
	myPersistentCount _ myCount _ count.
	myBatchCount _ batchCount.
	self restartBatchCounter: NULL.! !

!BatchCounter methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: (IntegerPos integerHash: myPersistentCount)! !

!BatchCounter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPersistentCount _ receiver receiveIntegerVar.
	myBatchCount _ receiver receiveIntegerVar.
	self restartBatchCounter: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myPersistentCount.
	xmtr sendIntegerVar: myBatchCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BatchCounter class
	instanceVariableNames: ''!

(BatchCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BatchCounter class methodsFor: 'pseudo-constructors'!

{Counter} make: count {IntegerVar} with: batchCount {IntegerVar}
	^self create: count with: batchCount!

{Counter} makeFakeCounter: count {IntegerVar} with: batchCount {IntegerVar} with: hash {UInt32}
	^self create: count with: batchCount with: hash! !