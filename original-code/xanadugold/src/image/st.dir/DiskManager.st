'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:35 pm'!

Heaper subclass: #DiskManager
	instanceVariableNames: '
		myFluidSpace {char star}
		myFlockInfoTable {PrimPtrTable}
		myFlockTable {WeakPtrArray}'
	classVariableNames: 'SecretEmulsion {Emulsion star} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
DiskManager comment:
'This is the public interface for managing objects that should go to disk.
This is also the anchor for the so-called Backend emulsion, but I''ll call it
the DiskManager emulsion for simplicity.'!

(DiskManager getOrMakeCxxClassDescription)
	friends:
'/* friends for class DiskManager */
friend class Abraham;
';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DiskManager methodsFor: 'shepherds'!

{void} destroyFlock: info {FlockInfo} 
	"Queue destroy of the given flock.  The destroy will probably happen later."
	 
	self subclassResponsibility!

{void} diskUpdate: info {FlockInfo | NULL} 
	"The flock described by info is Dirty!! On the next commit, rewrite it to the disk."

	self subclassResponsibility!

{void} dismantleFlock: info {FlockInfo} 
	"The flock designated by info has completed all dismantling actions; throw it off the disk."
	 
	self subclassResponsibility!

{void} dropFlock: token {Int32}
	"The flock identified by token is being removed from memory. For now, this is an 
	error if the flock has been updated. If the flock has been forgotten, then it will 
	be dismantled when next it comes in from disk."

	self subclassResponsibility!

{void} forgetFlock: info {FlockInfo} 
	"Remember that there are no more persistent pointers to the shepherd 
	described by info. If it gets garbage collected, remember to dismantle it 
	when it comes back in from the disk."

	self subclassResponsibility!

{Turtle} getInitialFlock
	"Return the starting object for the entire backend. This will be the 0th 
	flock in the first snarf following the snarfInfo tables. This will eventually 
	always be a shepherd that describes the protocol of the rest of the disk."

	self subclassResponsibility!

{UInt32} nextHashForEqual
	"Shepherds use a sequence number for their hash. The most trivial (reasonable) 
	implementation just uses a BatchCounter. This will not be persistent till we get 
	Turtles."

	self subclassResponsibility!

{void} rememberFlock: info {FlockInfo} 
	"There are now persistent pointers to the shepherd described by info.  See forgetFlock."
	 
	self subclassResponsibility!

{void} setHashCounter: aCounter {Counter unused}!

{void} storeAlmostNewShepherd: shep {Abraham} 
	"Shep has been created, but is not consistent yet. storeNewFlock must be called on it before the next makeConsistent."
	 
	self subclassResponsibility!

{void} storeInitialFlock: turtle {Abraham} with: protocol {XcvrMaker} with: cookbook {Cookbook}
	"A turtle just got created!! Remember it as the initial flock."
	self subclassResponsibility!

{void} storeNewFlock: shep {Abraham} 
	"Shep just got created!! On some later commit, assign it to a snarf 
	and write it to the disk."
	 
	self subclassResponsibility! !

!DiskManager methodsFor: 'stubs'!

{Abraham} fetchCanonical: hash {UInt32} with: snarfID {SnarfID} with: index {Int32}
	"If something is already imaged at that location, then return it. If there is already
	 an existing stub with the same hash at a different location, follow them both till we 
	 know that they are actually different objects."

	self subclassResponsibility!

{void} makeReal: info {FlockInfo}
	"Retrieve from the disk the flock at index within the specified snarf.  Since
	 stubs are canonical, and this only gets called by stubs, the existing stub will 
	 *become* the shepherd for the flock."

	self subclassResponsibility!

{void} registerStub: shep {Abraham} with: snarfID {SnarfID} with: index {Int32}
	"Called to register a newly created stub (by the diskSpecialist) in the internal 
	tables. The diskSpecialist in particular calls this when it couldn't find an 
	already existing stub (with fetchCacnonical) representing the flock at the 
	particular location."

	self subclassResponsibility! !

!DiskManager methodsFor: 'transactions'!

{void} beginConsistent: dirty {IntegerVar}
	"This is called before entering consistent block.  'dirty' is the block's declaration of the maximum number of shepherds which it can dirty.  If this is a top level consistent block, the virtual image in memory is now in a consistent state. It may be written to the disk if necessary.  "
	
	self subclassResponsibility!

{void} consistentBlockAt: fileName {char star unused} with: lineNo {Int32 unused}
	"This is called after beginConsistent, but before entering a consistent block, for debugging purposes.  Default is to do nothing"!

{void} endConsistent: dirty {IntegerVar}
	"This is called after exiting a consistent block."
	
	self subclassResponsibility!

{BooleanVar} insideCommit
	self subclassResponsibility!

{void} purge
	"Flush everything out to disk and remove all purgeable imaged objects from memory. "
	 
	self subclassResponsibility!

{void} purgeClean: noneLocked {BooleanVar default: false}
	"purge all shepherds that are currently clean, not locked, not dirty, and 
	purgeable. Purging just turns them into stubs, freeing the rest of their flocks. 
	Garbage collection can clean up the flocks and any stubs no longer pointed to 
	by something in memory."

	self subclassResponsibility! !

!DiskManager methodsFor: 'smalltalk: passe'!

{void} consistent: aBlock {BlockClosure}
	"Execute the block inside a pseudo-transaction."

	self passe!

{void} consistent: dirty {IntegerVar} with: aBlock {BlockClosure}
	"Execute the block inside a pseudo-transaction."

	self passe!

{void} makeConsistent
	"The virtual image in memory is now in a consistent state. It may be written to 
	the disk if necessary."
	
	self passe!

{void} makeConsistentBegin: dirty {IntegerVar}
	"The virtual image in memory is now in a consistent state. It may be written to the disk if necessary.  This is called before entering a top level consistent block.  'dirty' is the block's declaration of the maximum number of shepherds which it can dirty."
	
	self passe!

{void} makeConsistentEnd
	"This is called after exiting a top level consistent block."
	
	self passe! !

!DiskManager methodsFor: 'testing'!

{BooleanVar} isFake
	self subclassResponsibility! !

!DiskManager methodsFor: 'protected: accessing'!

{void INLINE} flockInfoTable: table{PrimPtrTable}
	myFlockInfoTable := table!

{void INLINE} flockTable: table {WeakPtrArray}
	myFlockTable := table.! !

!DiskManager methodsFor: 'accessing'!

{PrimPtrTable INLINE} flockInfoTable
	^ myFlockInfoTable!

{WeakPtrArray INLINE} flockTable
	^ myFlockTable! !

!DiskManager methodsFor: 'protected: creation'!

create
	super create.
	myFluidSpace _ NULL.
	myFlockInfoTable _ PrimPtrTable make: 2048.
	myFlockTable _ WeakPtrArray make: (Cattleman make: self) with: 2048.!

{void} destruct

	(myFluidSpace ~~ NULL) ifTrue: [
		CurrentPacker fluidBind: self during:
			[DiskManager emulsion destructAll]]. 
	super destruct.! !

!DiskManager methodsFor: 'emulsion accessing'!

{char star} fluidSpace

	^myFluidSpace.!

{char star} fluidSpace: aFluidSpace {char star}

	^myFluidSpace _ aFluidSpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DiskManager class
	instanceVariableNames: ''!

(DiskManager getOrMakeCxxClassDescription)
	friends:
'/* friends for class DiskManager */
friend class Abraham;
';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DiskManager class methodsFor: 'creation'!

{DiskManager} initializeDisk: fname {char star}
	"This builds the disk managing structure."

	CurrentPacker fluidSet: (SnarfPacker initializeUrdiOnDisk: fname).
	^CurrentPacker fluidGet!

make: fname {char star}

	CurrentPacker fluidSet: (SnarfPacker make: fname).
	^CurrentPacker fluidGet! !

!DiskManager class methodsFor: 'emulsion accessing'!

{Emulsion} emulsion
	[SecretEmulsion == nil ifTrue: [SecretEmulsion _ NULL]] smalltalkOnly.
	(SecretEmulsion == NULL) ifTrue: [
		SecretEmulsion _ DiskManagerEmulsion make].
	^SecretEmulsion.! !

!DiskManager class methodsFor: 'smalltalk: initialization'!

{void} cleanupGarbage
	DiskCuisine _ NULL.
	SecretEmulsion _ NULL.!

{void} exitTimeNonInherited
	CurrentPacker fluidFetch ~~ NULL
		ifTrue:
			[CurrentPacker fluidGet destroy.
			CurrentPacker fluidSet: NULL]!

linkTimeNonInherited
	Recipe star defineGlobal: #DiskCuisine with: NULL.
	SecretEmulsion _ NULL.!

staticTimeNonInherited
	DiskManager defineFluid: #CurrentPacker with: Emulsion globalEmulsion with: [NULL].
	BooleanVar defineFluid: #InsideAgenda with: DiskManager emulsion with: [false].! !

!DiskManager class methodsFor: 'exceptions: exceptions'!

bomb.ConsistentBlock: CHARGE {IntegerVar}

	^[CurrentPacker fluidGet endConsistent: CHARGE]! !

!DiskManager class methodsFor: 'smalltalk: transactions'!

{void} consistent: aBlock {BlockClosure}
	"Execute the block inside a pseudo-transaction."

	DiskManager consistent: -1 with: aBlock with: thisContext sender!

{void} consistent: dirty {IntegerVar} with: aBlock {BlockClosure} 
	"Execute the block inside a pseudo-transaction."
	
	self knownBug. "there are still unbounded consistent bugs which need to be broken up"
	self consistent: dirty with: aBlock with: thisContext sender!

{void} consistent: dirty {IntegerVar default: -1} with: aBlock {BlockClosure} with: context {Context}
	
	| fileName {String} |
	CurrentPacker fluidGet beginConsistent: dirty.
	"(context isKindOf: MethodContext)
		ifTrue: [fileName _ context printString]
		ifFalse: [fileName _ '[] in ', context mclass name, '>>', context selector].
	CurrentPacker fluidGet consistentBlockAt: fileName with: context pc."
	[InsideTransactionFlag fluidBind: true 
			during: aBlock] 
		valueNowOrOnUnwindDo: (DiskManager bomb.ConsistentBlock: dirty)!

{void} insistent: aBlock {BlockClosure}
	"Execute the block inside a pseudo-transaction."

	DiskManager insistent: -1 with: aBlock with: thisContext sender!

{void} insistent: dirty {IntegerVar} with: aBlock {BlockClosure} 
	"Execute the block inside a pseudo-transaction."
	
	self insistent: dirty with: aBlock with: thisContext sender!

{void} insistent: dirty {IntegerVar default: -1} with: aBlock {BlockClosure} with: context {Context}
	
	InsideTransactionFlag fluidFetch assert: 'Must be inside a transaction'.
	DiskManager consistent: dirty with: aBlock with: context! !