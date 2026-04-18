'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:47 pm'!

Heaper subclass: #SnarfInfoHandler
	instanceVariableNames: '
		mySnarfs {MuTable of: SnarfHandle}
		myTotal {Int4}
		myCurrentHandle {SnarfHandle}
		myCurrentStart {Int4}
		myCurrentIndex {IntegerVar}'
	classVariableNames: '
		ForgottenFlag {Int4 const} 
		SizeMask {Int4 const} '
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!
SnarfInfoHandler comment:
'The SnarfInfoHandler is an interface to the first few snarfs in an urdi that tells how much space is unallocated in each of the remaining snarfs, and keeps a bit as to whether any forgotten objects are in each snarf.

The data is kept packed in the first few snarfs with 4 bytes per snarf recorded.  The forgotten bit is the high bit of each entry.

mySnarfs is a table of SnarfHandles onto the snarfInfo snarfs (the first few snarfs in the Urdi).  You release those snarfs by destroying the snarfInfoHandler and creating a new one when you want the information again.

myTotal is the total number of snarfs in the Urdi.'!

(SnarfInfoHandler getOrMakeCxxClassDescription)
	friends:
'/* friends for class SnarfInfoHandler */
friend class SnarfInfoStepper;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SnarfInfoHandler methodsFor: 'accessing'!

{BooleanVar} getForgottenFlag: snarfID {SnarfID} 
	"Return the forgotten bit for the snarf at snarfID."
	
	| offset {Int32} |
	offset _ self locate: snarfID.
	^((myCurrentHandle get32: offset) bitAnd: ForgottenFlag) ~~ Int32Zero!

{Int32} getSpaceLeft: snarfID {SnarfID}
	"Return the spaceLeft for the snarf at snarfID."
	
	| offset {Int32} |
	offset _ self locate: snarfID.
	^(myCurrentHandle get32: offset) bitAnd: SizeMask!

{void} setForgottenFlag: snarfID {SnarfID} with: flag {BooleanVar}
	"Set or clear the forgotten bit for the snarf at snarfID."
	
	| offset {Int32} |
	offset _ self locate: snarfID.
	myCurrentHandle makeWritable.
	flag ifTrue: [myCurrentHandle at: offset put32: ((myCurrentHandle get32: offset) bitOr: ForgottenFlag)]
		ifFalse: [myCurrentHandle at: offset put32: ((myCurrentHandle get32: offset) bitAnd: ForgottenFlag bitInvert)]!

{void} setSpaceLeft: snarfID {SnarfID} with: space {Int32}
	"Set the space for the snarf at snarfID."
	
	| offset {Int32} |
	offset _ self locate: snarfID.
	myCurrentHandle makeWritable.
	myCurrentHandle at: offset put32: space + ((myCurrentHandle get32: offset) bitAnd: SizeMask bitInvert)!

{Int32} snarfCount
	"Return the total number of snarfs in the urdi."
	
	^myTotal!

{Int32} snarfInfoCount
	"Return the number of snarfs that the snarf info information takes 
	up. This is used to know what snarf to get the first object from."

	^mySnarfs count DOTasLong! !

!SnarfInfoHandler methodsFor: 'private:'!

{void} initializeSpaceLeft: snarfID {SnarfID} with: space {Int32} 
	"Se the spaceLeft to a certain amount, and clear all the flags. This is used 
	when initializing the snarfInfo so we don't get confused by the flags."

	| offset {Int32} |
	offset _ self locate: snarfID.
	myCurrentHandle makeWritable.
	myCurrentHandle at: offset put32: space!

{Int32} locate: snarfID {SnarfID}
	"Return the snarfHandle for the snarfInfo snarf that contains the spaceLeft and forgotten flag for the snarf at snarfID."

	(myCurrentHandle ~~ NULL
		and: [snarfID >= myCurrentStart 
		and: [snarfID < (myCurrentStart + (myCurrentHandle getDataSize // 4))]]) 
		ifTrue: [^(snarfID - myCurrentStart) * 4].
	(snarfID < myCurrentStart or: [myCurrentHandle == NULL]) ifTrue:
		[myCurrentIndex _ IntegerVar0.
		myCurrentHandle _ (mySnarfs intGet: myCurrentIndex) cast: SnarfHandle.
		myCurrentStart _ Int32Zero].
	[myCurrentHandle ~~ NULL] whileTrue:
		[| count {Int32} |
		count _ myCurrentHandle getDataSize // 4.
		snarfID < (count + myCurrentStart) ifTrue: [^(snarfID - myCurrentStart) * 4].
		myCurrentIndex _ myCurrentIndex + 1.
		myCurrentHandle _ (mySnarfs intFetch: myCurrentIndex) cast: SnarfHandle.
		myCurrentStart _ myCurrentStart + count].
	Heaper BLAST: #NoSnarfInfo.
	^Int32Zero! !

!SnarfInfoHandler methodsFor: 'protected: destruct'!

{void} destruct
	"Release all my handles before going away."
	myCurrentHandle _ NULL.
	mySnarfs getCategory ~= Heaper ifTrue:
		[mySnarfs stepper forEach:
			 [:handle {SnarfHandle} |
			 handle destroy]].
	mySnarfs _ NULL.
	super destruct! !

!SnarfInfoHandler methodsFor: 'create'!

create.Urdi: urdi {Urdi} with: view {UrdiView}
	"This constructor is for a newly created urdi with no existing snarfInfo 
	information. Set the spaceLeft for each snarf to its maximum and clear the 
	forgotten flag. Note that this figures out how many snarfInfo snarfs to use on 
	the fly by allocating as many snarfInfo cells as it can in the first snarf, then 
	going on to the second snarf, until enough snarfInfo snarfs are allocated. Then 
	it goes through all the entries in the snarfInfo for each non-snarfInfo snarf 
	and set the spaceLeft appropriately."
	
 	| snarfID {SnarfID} total {Int32} |
	super create.
	snarfID _ Int32Zero.
	myTotal _ urdi usableSnarfs.
	mySnarfs _ MuArray array.
	myCurrentStart _ Int32Zero.
	myCurrentIndex _ IntegerVar0.
	myCurrentHandle _ NULL.
	total _ Int32Zero.
	"Initialize enough snarfInfo snarfs for all snarfs in the Urdi."
	[total < myTotal] whileTrue:
		[| handle {SnarfHandle} |
		handle _ view makeErasingHandle: snarfID.
		mySnarfs atInt: snarfID introduce: handle.
		self initializeSpaceLeft: snarfID with: Int32Zero.
		total _ total + (handle getDataSize // 4).
		snarfID _ snarfID + 1].
	"Initialize the entries for all non-snarfInfo snarfs."
	snarfID almostTo: myTotal do: 
		[:dataSnarfID {SnarfID} |
		self initializeSpaceLeft: dataSnarfID with: (urdi getDataSizeOfSnarf: dataSnarfID)]!

create.UrdiView: view {UrdiView} with: urdi {Urdi}
	"This constructor is for reopening an existing urdi and using its existing snarfInfo.
	 Read snarfs until it has enough cells for all snarfs in fthe urdi."

	| snarfID {SnarfID} total {Int32} |
	super create.
	snarfID _ Int32Zero.
	myTotal _ urdi usableSnarfs.
	mySnarfs _ MuArray array.
	myCurrentStart _ Int32Zero.
	myCurrentIndex _ IntegerVar0.
	myCurrentHandle _ NULL.
	total _ UInt32Zero.
	[total < myTotal] whileTrue:
		[| handle {SnarfHandle} |
		handle _ view makeReadHandle: snarfID.
		mySnarfs atInt: snarfID introduce: handle.
		total _ total + (handle getDataSize // 4).
		snarfID _ snarfID + 1]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SnarfInfoHandler class
	instanceVariableNames: ''!

(SnarfInfoHandler getOrMakeCxxClassDescription)
	friends:
'/* friends for class SnarfInfoHandler */
friend class SnarfInfoStepper;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SnarfInfoHandler class methodsFor: 'pcreate'!

{void} initializeSnarfInfo: urdi {Urdi} with: view {UrdiView}
	| handler {SnarfInfoHandler} |
	handler _ self create.Urdi: urdi with: view.
	handler destroy!

make: urdi {Urdi} with: view {UrdiView}
	^self create.UrdiView: view with: urdi! !

!SnarfInfoHandler class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited

	"self hack."	"These don't use the full 32 bits so that we don't start manipulating LargeIntegers."
	ForgottenFlag _ 1 bitShift: 24.
	SizeMask _ "ForgottenFlag - 1"(1 bitShift: 24) - 1.! !

!SnarfInfoHandler class methodsFor: 'smalltalk: create'!

create.Urdi: urdi {Urdi} with: view {UrdiView}
	^self new create.Urdi: urdi with: view!

create.UrdiView: view {UrdiView} with: urdi {Urdi}
	^self new create.UrdiView: view with: urdi! !