'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:29 pm'!

Thunk subclass: #WorksIniter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
WorksIniter comment:
'The purpose of WorksIniter is to do the one-time initialization of clubs and homedocs to prepare a backend for ordinary client use. It is pretty sparse right now, but will eventually have much more stuff'!

(WorksIniter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WorksIniter methodsFor: 'initialization'!

{void} initializeClubs
	
	| testClub {FeClub} testID {ID} |
	"Make an autonomous Test club"
	testClub := FeClub make: (FeClubDescription make: FeSet make with: FeBooLockSmith make) edition.
	testID := FeServer iDOf: testClub.
	testClub setReadClub: testID.
	testClub setEditClub: testID.
	testClub setSignatureClub: testID.
	testClub setOwner: testID.
	FeServer nameClub: (Sequence string: 'Test') with: testID.
	FeServer enableAccess: testID.!

{void} initializeSystem

	|  aConnection {Connection}  adminID {ID} wwd {FeWaitDetector} |
	[Transcript nextPutAll: 'creating connection'; cr; endEntry] smalltalkOnly.
	aConnection := Connection make: FeServer.
	CurrentKeyMaster fluidSet: ((FeServer
		loginByName: (Sequence string: 'System Admin')) cast: BooLock) boo.
	CurrentKeyMaster fluidGet incorporate: FeKeyMaster makePublic.
	adminID := FeServer clubID: (Sequence string: 'System Admin').
	InitialOwner fluidSet: adminID.
	InitialReadClub fluidSet: adminID.
	InitialEditClub fluidSet: adminID.
	InitialSponsor fluidSet: adminID.
	CurrentAuthor fluidSet: adminID.

	self initializeClubs.
	wwd := WorksWaitDetector create: cerr with: 'WorksInit done!!'.
	FeServer waitForWrite: wwd.
	[DiskManager] USES.
	CurrentPacker fluidGet purge.
	[Transcript nextPutAll: 'exiting'; cr; endEntry] smalltalkOnly.
	aConnection destroy! !

!WorksIniter methodsFor: 'execute'!

{void} execute

	self initializeSystem! !

!WorksIniter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !