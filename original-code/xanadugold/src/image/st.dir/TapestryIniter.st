'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:27 pm'!

Thunk subclass: #TapestryIniter
	instanceVariableNames: '
		myRefutes {ID NOCOPY}
		mySupports {ID NOCOPY}
		myRelates {ID NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
TapestryIniter comment:
'The purpose of TapestryIniter is to do the one-time initialization of clubs and homedocs to prepare a BootMakered Urdi partition for Tapestry use'!

(TapestryIniter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!TapestryIniter methodsFor: 'initialization'!

{KeyMaster} adminKM
	| adminID {ID} booLock {BooLock} anAdmin {KeyMaster} |
	[Transcript nextPutAll: 'creating admin keymaster'; cr; endEntry] smalltalkOnly.
	adminID _ XuDirectory userDirectory
		getClubID: (Sequence string: 'System Admin').
	booLock _ (XuServer currentServer login: adminID)
				cast: BooLock.
	anAdmin _ booLock boo.
	^anAdmin!

{void} initializeClubs: anAdminKM {KeyMaster} 
	
	| directory {XuDirectory} aClub {ClubManager} xanID {ID} aKM {KeyMaster} |
	
	[Transcript nextPutAll: 'building initial clubs'; endEntry] smalltalkOnly.

	directory _ XuDirectory userDirectory: anAdminKM
		with: NULL with: NULL with: OpenOriginalDocument.
	
	self userList stepper forEach:
		[:userName {PackOBits} | | tClub {ClubManager} |
	[Transcript nextPutAll: '.'; endEntry] smalltalkOnly.
		tClub _ self makeClub: userName with: directory with: anAdminKM.
		tClub destroy].
	
	self groupList stepper forEach: [:groupName {PackOBits} | | tClub {ClubManager} |
	[Transcript nextPutAll: '.'; endEntry] smalltalkOnly.
		tClub _ self makeClub: groupName with: directory with: anAdminKM.
		tClub addMember: anAdminKM userID.
		tClub destroy].

	[Transcript cr; nextPutAll: 'setting up homedocs'; endEntry] smalltalkOnly.
	directory stepper forEach: [:userID {ID} |
	[Transcript nextPutAll: '.'; endEntry] smalltalkOnly.
		self setupHomeDocFor: userID with: directory].

	[Transcript cr; nextPutAll: 'setting up permissions'; cr; endEntry] smalltalkOnly.
	aClub _ (anAdminKM open: (directory getClubID: (Sequence string: 'Xanadu'))
		with: (Sequence string: 'ClubManager')) cast: ClubManager.
	self addMembers: aClub with: self userList with: directory.
	xanID _ aClub getID.
	aClub removeMember: anAdminKM userID.
	aClub destroy.
	aClub _ (anAdminKM open: (directory getClubID: (Sequence string: 'Autodesk'))
		with: (Sequence string: 'ClubManager')) cast: ClubManager.
	aClub addMember: xanID.
	aClub removeMember: anAdminKM userID.
	aClub destroy.
	
	aKM _ ((XuServer currentServer login: 
			(directory getClubID: (Sequence string: 'Hugh Hoover')))
		 cast: BooLock) boo.
	aClub _ (aKM open: (directory getClubID: (Sequence string: 'Hugh Hoover'))
				with: (Sequence string: 'ClubManager')) cast: ClubManager.
	aClub lockSmith: (MatchLockSmith make: aKM 
						with: (Sequence string: 'NoScrambler') 
						with: (Sequence string: 'Hugh Hoover')).
	aClub destroy.
	aKM destroy.
	directory destroy!

{void} initializeSystem
	| km {KeyMaster} aConnection {Connection} |
	[Transcript nextPutAll: 'creating connection'; cr; endEntry] smalltalkOnly.
	aConnection _ Connection make: XuServer.
	km _ (aConnection bootHeaper cast: XuServer) publicKeyMaster.
	km _ self adminKM.
	self initializeTestInternals: km.
	self initializeClubs: km.
	[Transcript nextPutAll: 'purging'; cr; endEntry] smalltalkOnly.
	XuServer currentServer purge.
	[Transcript nextPutAll: 'exiting'; cr; endEntry] smalltalkOnly.
	aConnection destroy.!

{void} initializeTestInternals: anAdminKM {KeyMaster}
	
	| aClub {ClubManager} aHome {IndexedWaldo} aPublic {KeyMaster} |
	
	"even though the admin club is created, it does not have a homedoc.  
	This creates the basic home doc, which will be initialized with the rest 
	of the homedocs in initializeClubs."
	
	[Transcript nextPutAll: 'initializing tester'; cr; endEntry] smalltalkOnly.
	aClub _ (anAdminKM open: anAdminKM userID with: (Sequence string: 'ClubManager')) cast: ClubManager.
	aHome _ (anAdminKM makeEmptyWaldo: (Sequence string:  'DirectRecord')
		with: FeServer current globalIDSpace
		with: true) cast: IndexedWaldo.
	
	aClub homeDocID: aHome getID.
	aHome destroy.
	aClub destroy.
	
	[Transcript nextPutAll: 'building link types'; cr; endEntry] smalltalkOnly.
	"Make a bunch of link types which are accessible to everybody"
	aPublic _ XuServer currentServer publicKeyMaster.
	myRefutes _ LinkTypeDescription linkType: aPublic
		with.Waldo: (XuText make: aPublic with.charVector: 'Refutes')
		with.Waldo: (XuText make: aPublic with.charVector: 'Refuted by').
	myRelates _ LinkTypeDescription linkType: aPublic
		with.Waldo: (XuText make: aPublic with.charVector: 'Related to')
		with.Waldo: (XuText make: aPublic with.charVector: 'Related to').
	mySupports _ LinkTypeDescription linkType: aPublic
		with.Waldo: (XuText make: aPublic with.charVector: 'Supports')
		with.Waldo: (XuText make: aPublic with.charVector: 'Supported by').! !

!TapestryIniter methodsFor: 'club setup'!

{void} addMembers: toClub {ClubManager} with: nameList {ScruSet} with: directory {XuDirectory}

	nameList stepper forEach: [:userName {PackOBits} |
		toClub addMember: (directory getClubID: userName)].
	^ VOID!

{ScruSet of: PackOBits} groupList
	
	| aSet {MuSet} |
	
	aSet _ MuSet make.
	aSet introduce: (Sequence string: 'Xanadu').
	aSet introduce: (Sequence string: 'Autodesk').
	^ aSet asImmuSet!

{ClubManager} makeClub: clubName {PackOBits} with: directory {XuDirectory} with: anAdmin {KeyMaster}
	| km {KeyMaster} dClub {ClubManager} home {IndexedWaldo} newDir {XuDirectory}
	 rClub {ClubManager} linkID {ID} aPublic {KeyMaster} |
	dClub _ anAdmin makeClub.
	aPublic _ XuServer currentServer publicKeyMaster.
	dClub lockSmith: (LockSmith booLockSmith: aPublic).
	km _ ((XuServer currentServer login: dClub getID) cast: BooLock) boo combine: aPublic.
	directory at: clubName store: dClub getID.
	home _ (km makeEmptyWaldo: (Sequence string: 'DirectRecord')
				with: FeServer current globalIDSpace
				with: true) cast: IndexedWaldo.
	dClub homeDocID: home getID.
	home destroy.
	newDir _ (km makePersistentWaldo: (Sequence string: 'XuDirectory'))
				cast: XuDirectory.
	linkID _ XuDirectory addUserDirectory: km
				with: km userID
				with: newDir getID.
	rClub _ (km open: (XuServer currentServer readClubIDFor: linkID)
				with: (Sequence string: 'ClubManager')) cast: ClubManager.
	rClub addMember: aPublic userID.
	rClub destroy.
	newDir destroy.
	^dClub!

{void} setupHomeDocFor: club {ID} with: directory {IndexedWaldo}
	| km {KeyMaster} cm {ClubManager} home {IndexedWaldo} users {TableAccumulator}
	 linktypes {MuTable} filters {MuTable} theLock {Lock} aPublic {KeyMaster} |
	
	aPublic _ XuServer currentServer publicKeyMaster.
	(club isEqual: (directory get: (Sequence string: 'System Public'))) ifTrue: [^ VOID].
	theLock _ XuServer currentServer login: club.
	(theLock isKindOf: BooLock) not ifTrue: [^ VOID].
	km _ (theLock cast: BooLock) boo combine: aPublic.
	cm _ (km open: club with: (Sequence string: 'ClubManager')) cast: ClubManager.
	home _ (km open: cm getHomeDocID with: (Sequence string: 'DirectRecord') with: OpenOriginalDocument)
		cast: IndexedWaldo.
	
	users _ TableAccumulator make.
	directory asTable stepper forEach: [ :id {ID} |
		users step: id].
	home at: (ID key: 'Directory') store: 
		(km makeWaldoFromTable: (Sequence string: 'SimpleRecord') with: (users value cast: ScruTable)).
	
	linktypes _ MuTable make: IntegerSpace make.
	linktypes atInt: IntegerVar0 store: myRelates.
	linktypes atInt: 1 store: myRefutes.
	linktypes atInt: 2 store: mySupports.
	home at: (ID key: 'LinkTypes') store: 
		(km makeWaldoFromTable: (Sequence string: 'SimpleRecord') with: linktypes).
	
	home at: (ID key: 'DefaultLinkType') store: myRelates.
	
	filters _ MuTable make: IntegerSpace make.
	filters at: Integer0 store: (ReferenceFilter variantFilter: km
		with: (MuWordArray make.charVector: 'All Variants')
		with: (XuServer currentServer waldoFilter: (Sequence string: 'XuText'))).
	filters at: 1 integer store: (ReferenceFilter linkFilter: km
		with: (MuWordArray make.charVector: 'All Links')
		with: (Filter openFilter: FeServer current endorsementFilterSpace)).
	home at: (ID key: 'Filters') store: 
		(km makeWaldoFromTable: (Sequence string: 'MappedRecord') with: filters).
	
	home at: (ID key: 'DefaultFilter') store: (ReferenceFilter linkFilter: km
		with: (MuWordArray make.charVector: 'All Links')
		with: (Filter openFilter: FeServer current endorsementFilterSpace)).
	
	home destroy.
	cm destroy.
	km destroy.!

{ScruSet of: PackOBits} userList
	
	| aSet {MuSet} |
	
	aSet _ MuSet make.
	aSet introduce: (Sequence string: 'Ravi Pandya').
	aSet introduce: (Sequence string: 'Hugh Hoover').
	aSet introduce: (Sequence string: 'Mark Miller').
	"aSet introduce: (Sequence string: 'Dean Tribble').
	aSet introduce: (Sequence string: 'Eric Hill').
	aSet introduce: (Sequence string: 'Chris Hibbert').
	aSet introduce: (Sequence string: 'Roger Gregory').
	aSet introduce: (Sequence string: 'Michael McClary').
	aSet introduce: (Sequence string: 'Roland King')."
	^ aSet asImmuSet! !

!TapestryIniter methodsFor: 'execute'!

{void} execute

	self initializeSystem! !

!TapestryIniter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !