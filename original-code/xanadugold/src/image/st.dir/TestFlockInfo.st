'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:42 pm'!

FlockInfo subclass: #TestFlockInfo
	instanceVariableNames: '
		myOldHash {UInt32}
		myPreviousHash {UInt32}
		myOldContents {UInt8Array}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
TestFlockInfo comment:
'Used in conjunction with the TestPacker. Keeps a hash of the last contents that were written to disk.'!

(TestFlockInfo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestFlockInfo methodsFor: 'create'!

create: shep {Abraham} 
	with: snarfID {SnarfID} 
	with: index {Int32} 
	with: flags {UInt32} 
	
	super
		create: shep
		with: snarfID
		with: index
		with: flags
		with: Int32Zero.
	myOldHash := UInt32Zero.
	myPreviousHash := UInt32Zero.
	myOldContents := NULL!

create: shep {Abraham} 
	with: snarfID {SnarfID} 
	with: index {Int32} 
	with: flags {Int32} 
	with: size {Int32} 
	
	super
		create: shep
		with: snarfID
		with: index
		with: flags
		with: size.
	myOldHash := UInt32Zero.
	myPreviousHash := UInt32Zero.
	myOldContents := NULL! !

!TestFlockInfo methodsFor: 'accessing'!

{void} setContents: bits {UInt8Array}
	myOldContents := bits!

{BooleanVar} updateContentsInfo
	"Update the contents hash and other information from the current state of the shepherd. Return true if the HASH only has changed since the last time."
	
	myPreviousHash := myOldHash.
	self fetchShepherd == NULL
		ifTrue: [myOldHash := UInt32Zero]
		ifFalse: [myOldHash := (CurrentPacker fluidGet cast: TestPacker) computeHash: self getShepherd].
	^myPreviousHash ~= myOldHash! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TestFlockInfo class
	instanceVariableNames: ''!

(TestFlockInfo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestFlockInfo class methodsFor: 'pseudo constructors'!

{FlockInfo} forgotten: shep {Abraham} with: snarfID {SnarfID} with: index {Int32} 

	"index = UInt32Zero assert: 'Should have index 0'."
	^self create: shep
		with: snarfID
		with: index
		with: FlockInfo forgottenMask!

{FlockInfo} make: shep {Abraham} with: index {IntegerVar} 
	"index = UInt32Zero assert: 'Should have index 0'."
	^self create: shep
		with: Int32Zero
		with: index DOTasLong 
		with: (((FlockInfo contentsDirty bitOr: FlockInfo forgottenStateDirty)
				bitAnd: FlockInfo forgottenMask bitInvert)
				bitOr: FlockInfo isNewMask)!

{FlockInfo} make: info {FlockInfo} with: snarfID {SnarfID} with: index {Int32} 
	"index = UInt32Zero assert: 'Should have index 0'."
	^self create: info getShepherd
		with: snarfID
		with: index
		with: (info flags bitAnd: FlockInfo isNewMask bitInvert)
		with: info oldSize!

{FlockInfo} remembered: shep {Abraham} with: snarfID {SnarfID} with: index {Int32} 

	index = UInt32Zero assert: 'Should have index 0'.
	^self create: shep
		with: snarfID 
		with: index 
		with: UInt32Zero! !