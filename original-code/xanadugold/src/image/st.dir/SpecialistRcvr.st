'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:33 pm'!

Rcvr subclass: #SpecialistRcvr
	instanceVariableNames: '
		mySpecialist {TransferSpecialist}
		myIbids {PtrArray}
		myNextIbid {Int4}'
	classVariableNames: 'RcvrIbidCache {PtrArray} '
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!
SpecialistRcvr comment:
'myIbids maps from ibid number to already sent objects.  The ibids table is explicitly managed as a PtrArray because it is such a bottleneck.'!

(SpecialistRcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SpecialistRcvr methodsFor: 'receiving'!

{BooleanVar} receiveBooleanVar
	self subclassResponsibility!

{Category} receiveCategory
	"Return a category object using the internal coding that any 
	  rcvr must have to represent categories."
	  
	 self subclassResponsibility!

{void} receiveData: array {UInt8Array}
	"Fill the array with data from the stream."
	
	self subclassResponsibility!

{Heaper} receiveHeaper
	"receive the next heaper"

	| cat {Category} |
	cat _ self fetchStartOfInstance.
	cat == NULL ifTrue: [^NULL]. 
	(cat isEqual: CommIbid) ifTrue:
		[| ibidNum {Int32} result {Heaper} |
		ibidNum _ self receiveInt32. 
		self endOfInstance.
		result _ myIbids fetch: ibidNum.
		result == NULL ifTrue: [Heaper BLAST: #NotInTable].
		^result]
	ifFalse: [| result {Heaper} |
			result _ mySpecialist receiveHeaper: cat from: self.
			self endOfInstance.
			^result]!

{IEEEDoubleVar} receiveIEEEDoubleVar
	self subclassResponsibility!

{Int32} receiveInt32
	self subclassResponsibility!

{Int8} receiveInt8
	self subclassResponsibility!

{IntegerVar} receiveIntegerVar
	self subclassResponsibility!

{void} receiveInto: memory {Heaper}
	"Receive an object into another object."

	| cat {Category} |
	cat _ self fetchStartOfInstance. 
	(cat == NULL or: [cat isEqual: CommIbid]) ifTrue: [Heaper BLAST: #NotBecomable].

	mySpecialist receiveHeaper: cat into: memory from: self.
	self endOfInstance!

{char star} receiveString

	self subclassResponsibility!

{UInt32} receiveUInt32
	self subclassResponsibility!

{UInt8} receiveUInt8
	self subclassResponsibility! !

!SpecialistRcvr methodsFor: 'specialist receiving'!

{Heaper} basicReceive: recipe {Recipe}
	"Pull the contents of the next heaper off the wire."

	recipe cast: CopyRecipe into: [:copy | ^copy parse: self]
		others: [Heaper BLAST: #BadRecipe].
	^NULL!

{void} basicReceive: recipe {Recipe} into: memory {Heaper} 
	"Pull the contents of the next heaper off the wire."

	(memory getCategory canYouBecome: recipe categoryOfDish)
		ifFalse: [Heaper BLAST: #NotBecomable].
	self registerIbid: memory.
	[memory destructor] smalltalkOnly.
	recipe cast: CopyRecipe into: [:copy | copy parse: self into: memory]
		others: [Heaper BLAST: #BadRecipe]!

{Heaper} makeIbid: cat {Category}
	"Create and register a memory slot for an instance of the given category."
	| result {Heaper} |
	'result = (Heaper *)Heaper::operator new (0, xcsj, cat);' translateOnly.
	[result _ DeletedHeaper create] smalltalkOnly.
	self registerIbid: result.
	^result!

{void} registerIbid: obj {Heaper}
 
 	myNextIbid >= myIbids count ifTrue:
 		["Grow the table."
 		| oldIbids {PtrArray} |
 		oldIbids _ myIbids.
 		myIbids _ PtrArray nulls: myNextIbid * 2.
 		1 almostTo: myNextIbid do: [:i {Int32} | myIbids at: i store: (oldIbids fetch: i)].
 		oldIbids destroy].
	myIbids at: myNextIbid store: obj.
	myNextIbid _ myNextIbid + 1.! !

!SpecialistRcvr methodsFor: 'protected: specialist'!

{void} endOfInstance
	
	self subclassResponsibility!

{void} endPacket
	Int32Zero almostTo: myNextIbid do: 
		[:i {Int32} |
		myIbids at: i store: NULL].
	myNextIbid _ Int32Zero!

{Category} fetchStartOfInstance

	self subclassResponsibility!

{TransferSpecialist} specialist
	^mySpecialist! !

!SpecialistRcvr methodsFor: 'protected: creation'!

create: specialist {TransferSpecialist}
	super create.
	mySpecialist _ specialist.
	RcvrIbidCache == NULL
		ifTrue: [myIbids _ PtrArray nulls: 128]
		ifFalse:
			[myIbids _ RcvrIbidCache.
			RcvrIbidCache _ NULL].
	myNextIbid _ Int32Zero!

{void} destruct
	RcvrIbidCache == NULL 
		ifTrue:
			[myIbids storeAll.
			RcvrIbidCache _ myIbids cast: PtrArray.
			myIbids _ NULL]
		ifFalse: [myIbids destroy].
	"mySpecialist destroy"
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecialistRcvr class
	instanceVariableNames: ''!

(SpecialistRcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SpecialistRcvr class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	RcvrIbidCache _ NULL! !