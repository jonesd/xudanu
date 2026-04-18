'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:05 pm'!

Counter subclass: #SingleCounter
	instanceVariableNames: '
		myCount {IntegerVar}
		myMutex {Sema4 NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-counter'!
SingleCounter comment:
'This counter separates a very simple state change into another flock so that big objects like GrandMaps and GrandHashTables don''t ned to flush their entirety to disk.  It localizes the state change of a counter.'!

(SingleCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SingleCounter methodsFor: 'accessing'!

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
		[DiskManager consistent: 1 with:
			[myCount _ myCount + 1.
			self diskUpdate]].
	^myCount!

{IntegerVar} incrementBy: count {IntegerVar}
	
	count >= IntegerVarZero ifFalse:
		[Heaper BLAST: #InvalidRequest].
	myMutex critical: 
		[DiskManager consistent: 1 with:
			[myCount _ myCount + count.
			self diskUpdate]].
	^myCount!

{void} setCount: count {IntegerVar} 
	
	myMutex critical: 
		[DiskManager consistent: 1 with:
			[myCount _ count.
			self diskUpdate]]! !

!SingleCounter methodsFor: 'receiver: restart'!

{void RECEIVE.HOOK} restartSingleCounter: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	myMutex _ Sema4 make: 1.! !

!SingleCounter methodsFor: 'protected: create'!

create
	super create.
	myCount _ IntegerVar0.
	self restartSingleCounter: NULL.
	self newShepherd.
	self remember!

create: count {IntegerVar}
	super create.
	myCount _ count.
	self restartSingleCounter: NULL.
	self newShepherd.
	self remember! !

!SingleCounter methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: (IntegerPos integerHash: myCount)! !

!SingleCounter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCount _ receiver receiveIntegerVar.
	self restartSingleCounter: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SingleCounter class
	instanceVariableNames: ''!

(SingleCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SingleCounter class methodsFor: 'pseudo-constructors'!

{Counter} make
	^self create.!

{Counter} make: count {IntegerVar}
	^self create: count! !