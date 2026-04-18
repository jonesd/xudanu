'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:21 pm'!

Thunk subclass: #FebeIniter
	instanceVariableNames: '
		myHomeDoc {IndexedWaldo NOCOPY}
		myAdmin {KeyMaster NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
FebeIniter comment:
'The purpose of FebeIniter is to do the one-time initialization of clubs and homedocs to prepare a backend for ordinary client use. It is pretty sparse right now, but will eventually have much more stuff'!

(FebeIniter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!FebeIniter methodsFor: 'initialization'!

{KeyMaster} adminKM

	myAdmin == NULL ifTrue:
		[myAdmin := ((XuServer currentServer login: XuServer currentServer adminClubID)
					cast: BooLock) boo].
	^myAdmin!

create
	super create.
	myAdmin := NULL.!

{void} initializeClubs
	
	| directory {XuDirectory}    |
	
	[Transcript nextPutAll: 'building initial clubs'; endEntry] smalltalkOnly.

	directory _ XuDirectory userDirectory: self adminKM
		with: NULL with: NULL with: OpenOriginalDocument.
	
	self userList stepper forPositions:
		[ :userName {PackOBits} :userPassword {PackOBits} |
		| tClub {ClubManager} |
		[Transcript nextPutAll: '.'; endEntry] smalltalkOnly.
		tClub _ self makeClub: userName with: userPassword with: directory.
		tClub destroy].
	
	self groupList stepper forPositions:
		[ :groupName {PackOBits} :members {ScruSet of: PackOBits} | | tClub {ClubManager} |
		[Transcript nextPutAll: '.'; endEntry] smalltalkOnly.
		tClub _ self makeClub: groupName
			with: (Sequence string: '')
			with: directory.
		members stepper forEach: [ :member {PackOBits} |
			tClub addMember: (directory getClubID: member)].
		tClub destroy].

	[Transcript cr; nextPutAll: 'setting up homedocs'; endEntry] smalltalkOnly.
	directory stepper forEach: [:userID {ID} |
		[Transcript nextPutAll: '.'; endEntry] smalltalkOnly.
		self setupHomeDocFor: userID with: directory].

	directory destroy!

{void} initializeSystem
	|  aConnection {Connection} |
	[Transcript nextPutAll: 'creating connection'; cr; endEntry] smalltalkOnly.
	aConnection _ Connection make: XuServer.
	(aConnection bootHeaper cast: XuServer) publicKeyMaster.
	self initializeTestInternals.
	self initializeClubs.
	[Transcript nextPutAll: 'purging'; cr; endEntry] smalltalkOnly.
	XuServer currentServer purge.
	[Transcript nextPutAll: 'exiting'; cr; endEntry] smalltalkOnly.
	aConnection destroy.
	GrandConnection fluidSet: NULL.!

{void} initializeTestInternals
	
	| t {Waldo} aclub {ClubManager} aPublic {KeyMaster} refutes {ID} relates {ID} supports {ID} 
		linkTypes {MuTable} filters {MuTable}  home {XuHomeDocument} |
	
	"make a home document for the public club"
	t := self adminKM makeEmptyWaldo: (Sequence string: 'DirectRecord')
		with: NULL with: true.
	aclub := (self adminKM open: self adminKM userID
		with: (Sequence string: 'ClubManager')
		with: OpenOriginalDocument) cast: ClubManager.
	aclub homeDocID: t getID.
	aclub destroy.
	t destroy.
	
	[Transcript nextPutAll: 'building link types'; cr; endEntry] smalltalkOnly.
	"Make a bunch of link types which are accessible to everybody"
	aPublic _ XuServer currentServer publicKeyMaster.
	refutes _ LinkTypeDescription linkType: aPublic
		with.Waldo: (XuText make: aPublic with.charVector: 'Refutes')
		with.Waldo: (XuText make: aPublic with.charVector: 'Refuted by').
	relates _ LinkTypeDescription linkType: aPublic
		with.Waldo: (XuText make: aPublic with.charVector: 'Related to')
		with.Waldo: (XuText make: aPublic with.charVector: 'Related to').
	supports _ LinkTypeDescription linkType: aPublic
		with.Waldo: (XuText make: aPublic with.charVector: 'Supports')
		with.Waldo: (XuText make: aPublic with.charVector: 'Supported by').
	
	home := (aPublic makeEmptyWaldo: (Sequence string: 'XuHomeDocument')) cast: XuHomeDocument.

	linkTypes _ MuTable make: IntegerSpace make.
	linkTypes atInt: IntegerVar0 store: relates.
	linkTypes atInt: 1 store: refutes.
	linkTypes atInt: 2 store: supports.
	home setLinkTypes: ((aPublic
		makeWaldoFromTable: (Sequence string: 'SimpleRecord')
		with: linkTypes) cast: IndexedWaldo).

	home setDefaultLinkType: relates.
	
	filters := MuTable make: IntegerSpace make.
	filters atInt: IntegerVar0
		store: (ReferenceFilter linkFilter: aPublic
			with: (MuWordArray make.charVector: 'Related Links')
			with: (FeServer current endorsementFilterSpace fullRegion cast: Filter)).
	filters atInt: 1
		store: (ReferenceFilter linkFilter: aPublic
			with: (MuWordArray make.charVector: 'All Links')
			with: (Filter intersectionFilter: FeServer current endorsementFilterSpace
				with: (IDRegion make: relates))).
	home setFilters: ((aPublic
		makeWaldoFromTable: (Sequence string: 'SimpleRecord')
		with: filters) cast: IndexedWaldo).
	
	home setDefaultFilter: (ReferenceFilter linkFilter: aPublic
			with: (MuWordArray make.charVector: 'Related Links')
			with: (FeServer current endorsementFilterSpace fullRegion cast: Filter)).
	
	myHomeDoc := (XuServer currentServer wrap: (Sequence string: 'SimpleRecord')
		with: home) cast: IndexedWaldo.! !

!FebeIniter methodsFor: 'club setup'!

{void} addMembers: toClub {ClubManager} with: nameList {ScruSet} with: directory {XuDirectory}

	nameList stepper forEach: [:userName {PackOBits} |
		toClub addMember: (directory getClubID: userName)].
	^ VOID!

{ScruTable of: PackOBits and: PackOBits} groupList
	
	| result {MuTable} |
	
	result := MuTable make: SequenceSpace make.
	result at: (Sequence string: 'Guests')
		introduce: ((ImmuSet make
			with: (Sequence string: 'Guest'))
			with: (Sequence string: 'Visitor')).
	^result asImmuTable!

{ClubManager} makeClub: clubName {PackOBits}
	with: password {PackOBits | NULL}
	with: directory {XuDirectory}

	| km {KeyMaster} result {ClubManager} home {IndexedWaldo} 
	   aPublic {KeyMaster} |
	"make a club"
	result _ self adminKM makeClub.
	aPublic _ XuServer currentServer publicKeyMaster.
	"put on a boo lock smith and login"
	result lockSmith: (LockSmith booLockSmith: aPublic).
	km _ ((XuServer currentServer login: result getID) cast: BooLock) boo combine: aPublic.
	"change the password if requested"
	(password isEqual: (Sequence string: '')) ifFalse:
		[MatchLockSmith make: aPublic 
			with: (Sequence string: 'NoScrambler') 
			with: password].
	"put it in the directory and give it a home doc"
	directory at: clubName store: result getID.
	home _ (km makeEmptyWaldo: (Sequence string: 'DirectRecord')
				with: IDSpace make
				with: true) cast: IndexedWaldo.
	result homeDocID: home getID.
	home destroy.
	^result!

{void} setupHomeDocFor: club {ID} with: directory {XuDirectory}
	| km {KeyMaster}  home {IndexedWaldo} theLock {Lock}  |
	
	theLock _ XuServer currentServer login: club.
	theLock cast: BooLock into: [ :b |
		km _ b boo]
	cast: MatchLock into: [ :m |
		km _ m password: ((self userList get: (directory getClubName: club)) cast: Sequence)]
	others:
		[^VOID].
	km := (km combine: XuServer currentServer publicKeyMaster) combine: self adminKM.
	home _ (km open: km getHomeDocID with: (Sequence string: 'DirectRecord') with: OpenOriginalDocument)
		cast: IndexedWaldo.
	home introduceAll: myHomeDoc.
	home destroy!

{ScruTable of: PackOBits and: PackOBits} userList
	
	| result {MuTable} |
	
	result _ MuTable make: SequenceSpace make.
	result at: (Sequence string: 'Guest')
		introduce: (Sequence string: '').
	result at: (Sequence string: 'Visitor')
		introduce: (Sequence string: 'Welcome').
	^ result asImmuTable! !

!FebeIniter methodsFor: 'execute'!

{void} execute

	self initializeSystem! !

!FebeIniter methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartFebeIniter: rcvr {Rcvr unused default: NULL}

	myAdmin := NULL! !

!FebeIniter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartFebeIniter: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !