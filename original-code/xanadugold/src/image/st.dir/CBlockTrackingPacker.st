'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:34 pm'!

DiskManager subclass: #CBlockTrackingPacker
	instanceVariableNames: '
		myPacker {DiskManager}
		myTracker {CBlockTracker | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(CBlockTrackingPacker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CBlockTrackingPacker methodsFor: 'transactions'!

{void} beginConsistent: dirty {IntegerVar}

	myTracker _ CBlockTracker make: dirty with: myTracker.
	myPacker beginConsistent: dirty!

{void} consistentBlockAt: fileName {char star} with: lineNo {Int32}
	
	self checkTracker ifTrue:
		[myTracker track: fileName with: lineNo.
		myPacker consistentBlockAt: fileName with: lineNo]!

{void} endConsistent: dirty {IntegerVar} 
	
	self checkTracker ifTrue:
		[myTracker _ myTracker fetchUnwrapped.
		myPacker endConsistent: dirty]!

{BooleanVar} insideCommit
	^ myPacker insideCommit!

{void} purge

	myPacker purge!

{void} purgeClean: noneLocked {BooleanVar default: false}


	myPacker purgeClean: noneLocked! !

!CBlockTrackingPacker methodsFor: 'shepherds'!

{void} destroyFlock: info {FlockInfo} 
	"Queue destroy of the given flock.  The destroy will probably happen later."
	
	myPacker destroyFlock: info!

{void} diskUpdate: info {FlockInfo | NULL} 
	
	self checkTracker ifTrue:
		[myTracker dirty: info.
		myPacker diskUpdate: info]!

{void} dismantleFlock: info {FlockInfo} 
	"The flock designated by info has completed all dismantling actions; throw it off the disk."
	
	myPacker dismantleFlock: info!

{void} dropFlock: token {Int32} 

	myPacker dropFlock: token!

{void} forgetFlock: info {FlockInfo} 

	self checkTracker ifTrue:
		[myTracker dirty: info.
		myPacker forgetFlock: info]!

{Turtle} getInitialFlock
	 
	^myPacker getInitialFlock!

{UInt32} nextHashForEqual
	
	^myPacker nextHashForEqual!

{void} rememberFlock: info {FlockInfo} 
	
	self checkTracker ifTrue:
		[myTracker dirty: info.
		myPacker rememberFlock: info]!

{void} storeAlmostNewShepherd: shep {Abraham} 

	myPacker storeAlmostNewShepherd: shep!

{void} storeInitialFlock: turtle {Abraham} with: protocol {XcvrMaker} with: cookbook {Cookbook}
	myPacker storeInitialFlock: turtle with: protocol with: cookbook!

{void} storeNewFlock: shep {Abraham} 

	self checkTracker ifTrue:
		[myPacker storeNewFlock: shep.
		myTracker dirty: shep getInfo]! !

!CBlockTrackingPacker methodsFor: 'stubs'!

{Abraham} fetchCanonical: hash {UInt32} with: snarfID {SnarfID} with: index {Int32}
	
	^myPacker fetchCanonical: hash with: snarfID with: index!

{void} makeReal: info {FlockInfo}
	
	myPacker makeReal: info!

{void} registerStub: shep {Abraham} with: snarfID {SnarfID} with: index {Int32}

	myPacker registerStub: shep with: snarfID with: index! !

!CBlockTrackingPacker methodsFor: 'smalltalk: testing'!

consistentCount
	^myPacker consistentCount! !

!CBlockTrackingPacker methodsFor: 'create'!

create: subPacker {DiskManager} 

	super create.
	myPacker _ subPacker.
	myTracker _ NULL.
	self flockTable: myPacker flockTable.
	self flockInfoTable: myPacker flockInfoTable.! !

!CBlockTrackingPacker methodsFor: 'protected: destruction'!

{void} destruct
	
	(myTracker == NULL) assert.
	myPacker destroy.
	super destruct! !

!CBlockTrackingPacker methodsFor: 'testing'!

{BooleanVar} isFake
	^ myPacker isFake! !

!CBlockTrackingPacker methodsFor: 'private:'!

{BooleanVar} checkTracker 
	
	myTracker ~~ NULL ifTrue:
		[^true].
	[Logger] USES.
	ErrorLog << 'Must be inside consistent block
'!

{void} commitState: flag {BooleanVar}
	"Used by ResetCommit bomb"
	
	(myPacker cast: SnarfPacker) commitState: flag! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CBlockTrackingPacker class
	instanceVariableNames: ''!

(CBlockTrackingPacker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CBlockTrackingPacker class methodsFor: 'creation'!

{DiskManager} make: subPacker {DiskManager} 
	
	^CBlockTrackingPacker create: subPacker! !