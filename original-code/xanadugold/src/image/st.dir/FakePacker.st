'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:36 pm'!

DiskManager subclass: #FakePacker
	instanceVariableNames: '
		myTurtle {Turtle | NULL}
		myCount {UInt4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
FakePacker comment:
'Most of the disk operations are just no-ops.'!

(FakePacker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FakePacker methodsFor: 'transactions'!

{void} beginConsistent: dirty {IntegerVar unused}!

{void} endConsistent: dirty {IntegerVar unused}
	
	| agenda {Agenda | NULL} |
	InsideTransactionFlag fluidFetch
		ifFalse: 
			[agenda _ myTurtle fetchAgenda.
			(agenda ~~ NULL and: [InsideAgenda fluidFetch not])
				ifTrue: 
					[InsideAgenda fluidBind: true during:
						[[agenda step] whileTrue]]]!

{BooleanVar} insideCommit
	^ false!

{void} purge
	"Flush everything out to disk and remove all purgeable imaged
	 objects from memory.  This doesn't clear the ShepherdMap table.  
	 This will have to be a weak table, and then the destruction of a 
	 shepherd or shepherdStub should remove it from myShepherdMap."!

{void} purgeClean: noneLocked {BooleanVar unused default: false}
	"No shepherds are clean, so no-op."! !

!FakePacker methodsFor: 'shepherds'!

{void} destroyFlock: info {FlockInfo} 
	"Queue destroy of the given flock.  dismantle it immediately in the FakePacker."
	
	self knownBug.  "This needs to stack shepherds for deletion after all agenda items."
	info markDestroyed.
	info getShepherd dismantle!

{void} diskUpdate: info {FlockInfo | NULL} 
	"The flock identified by token is Dirty!! On some later commit, write it to the disk."!

{void} dismantleFlock: info {FlockInfo} 
	"Tehre are no local data-structures."
	"info markDismantled."!

{void} dropFlock: token {Int32}
	"No prob."!

{void} forgetFlock: info {FlockInfo} 
	"Yeah. Right."!

{Turtle} getInitialFlock

	^ myTurtle!

{UInt32} nextHashForEqual
	"Shepherds use a sequence number for their hash.  Return the next one
	 and increment.  This should actually spread the hashes."
	"This actually needs to roll over the UInt32 limit."
	myCount _ myCount + 1.
	^ myCount!

{void} rememberFlock: info {FlockInfo} 
	"There are now persistent pointers to the shepherd represented by token."!

{void} storeAlmostNewShepherd: shep {Abraham unused} 

	"Do nothing"!

{void} storeInitialFlock: turtle {Abraham unused}
	with: protocol {XcvrMaker unused}
	with: cookbook {Cookbook unused}

	Heaper BLAST: #MustBeRealDiskManager!

{void} storeNewFlock: shep {Abraham} 
	"Shep just got created!! On some later commit, assign it to a snarf 
	and write it to the disk."

	| info {FlockInfo} |
	shep fetchInfo == NULL assert: 'Must not have an info yet'.
	"Create a FlockInfo to make the FlockTable registration happy."
	info _ FlockInfo make: shep with: myCount negated.
	shep flockInfo: info.!

{void} storeTurtle: turtle {Turtle}
	myTurtle _ turtle! !

!FakePacker methodsFor: 'stubs'!

{Abraham} fetchCanonical: hash {UInt32 unused} with: snarfID {SnarfID unused} with: index {Int32 unused}
	"If something is already imaged at that location, then return it. If there is already
	 an existing stub with the same hash at a different location, follow them till we 
	 know that they are actually different objects."

	self unimplemented.
	^NULL!

{void} makeReal: info {FlockInfo unused}
	"Retrieve from the disk the flock at index within the specified snarf.  Since
	 stubs are canonical, and this only gets called by stubs, the existing stub will 
	 *become* the shepherd for the flock."

	self unimplemented!

{void} registerStub: shep {Abraham unused} with: snarfID {SnarfID unused} with: index {Int32 unused}

	self unimplemented! !

!FakePacker methodsFor: 'protected: create'!

create
	super create.
	myTurtle _ NULL.
	myCount _ UInt32Zero.! !

!FakePacker methodsFor: 'testing'!

{BooleanVar} isFake
	^ true! !

!FakePacker methodsFor: 'internals'!

{void} destroyAbandoned! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FakePacker class
	instanceVariableNames: ''!

(FakePacker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FakePacker class methodsFor: 'creation'!

{DiskManager} make
	
	| packer {DiskManager} |
	packer _ FakePacker create.
	CurrentPacker fluidSet: packer.
	^packer! !