'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:21 pm'!

FebeTester subclass: #ClubTester
	instanceVariableNames: 'myAdminKM {KeyMaster NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Permissions'!

(ClubTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ClubTester methodsFor: 'creation'!

create
	super create.
	myAdminKM _ NULL.! !

!ClubTester methodsFor: 'tests'!

{KeyMaster} adminKM

	myAdminKM == NULL ifTrue:
		[self keyMaster.
		myAdminKM := ((XuServer currentServer
				loginByName: (Sequence string: 'System Admin'))
			cast: BooLock) boo].
	^myAdminKM.!

{void} allTestsOn: oo {ostream reference} 
	"ClubTester runTest"

	self test1On: oo.
	self test2On: oo.
	self test3On: oo.!

{void} test1On: oo {ostream reference}
	"ClubTester tryTest: #test1On:"

	oo << self adminKM << '
'.
	oo << self keyMaster << '
'.
	oo << (self keyMaster combine: self adminKM) << '
'.!

{void} test2On: oo {ostream reference}
	"ClubTester tryTest: #test2On:"
	| clubMarkM {ClubManager}
	  markMID {ID} |
	  
	clubMarkM _ self newClub: 'Mark Samuel Miller'.
	markMID _ clubMarkM getID.
	
	self dumpClubInfo: clubMarkM on: oo.

	oo << 'should be wall: ' << (XuServer currentServer login: markMID) << '
'.
	clubMarkM lockSmith: (LockSmith booLockSmith: self keyMaster).
	clubMarkM removeMember: self adminKM userID.
	self dumpClubInfo: clubMarkM on: oo.
	oo << 'markM''s KeyMaster again: ' 
		<< ((XuServer currentServer login: markMID) cast: BooLock) boo << '
'.
	clubMarkM destroy.!

{void} test3On: oo {ostream reference}
	"ClubTester tryTest: #test3On:"
	| adminer {Adminer} |
	self keyMaster fetchAdminer = NULL
		ifTrue: [oo << 'Public can''t administrate
']
		ifFalse: [Heaper BLAST: #ShouldntBeAllowed].
		
	adminer _ self adminKM getAdminer.
	adminer consistencyCheck.
	oo << adminer << ' says much is consistent
'.! !

!ClubTester methodsFor: 'accessing'!

{void} dumpClubInfo: cm {ClubManager} on: oo {ostream reference}
	| clubID {ID}
	  members {XnRegion of: ID} |
	
	clubID _ cm getID.
	oo << 'Info about club '.
	self printClubName: clubID on: oo.
	oo << '
'.
	cm fetchEditClubID == NULL
		ifTrue: [oo << 'self edit']
		ifFalse: [oo << 'edit club is: '.
			self printClubName: cm fetchEditClubID on: oo].
	oo << '
'.
	cm fetchReadClubID == NULL
		ifTrue: [oo << 'self read']
		ifFalse: [oo << 'read club is: '.
			self printClubName: cm fetchReadClubID on: oo].
	oo << '
'.
	members _ cm members domain.
	oo << 'members: {'.
	members stepper forEach: [:iD {ID} |
		self printClubName: iD on: oo.
		oo << ', '].
	oo << '}
'.
	oo << 'locksmith: ' << cm fetchLockSmith << '

'.!

{ClubManager} newClub: cName {char star}

	| result {ClubManager} directory {XuDirectory} |
	result := self adminKM makeClub.
	directory := XuDirectory userDirectory: self adminKM
		with: NULL with: NULL with: OpenOriginalDocument.
	directory at: (Sequence string: cName) store: result getID.
	directory destroy.
	^result.!

{void} printClubName: clubID {ID} on: oo {ostream reference}

	| name {PackOBits} |
	name := XuDirectory userDirectory fetchClubName: clubID.
	name == NULL
		ifTrue: [oo << clubID]
		ifFalse: [oo << name]! !

!ClubTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartCLubTester: rcvr {Rcvr unused default: NULL}
	myAdminKM _ NULL! !

!ClubTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartCLubTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !