'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:03 pm'!

Heaper subclass: #FeServer
	instanceVariableNames: '
		myEncrypterName {Sequence}
		myEncrypter {Encrypter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeServer comment:
'The fundamental Server object. Used for managing the global name space, creating Works, Editions, and Clubs, and other general server management operations.

Many operations in the protocol use fluidly bound parameters. The possible parameters are:
	FeServer defineClientFluid: #CurrentServer with: Listener emulsion with: [NULL].

CurrentKeyMaster - a KeyMaster for providing authority to read and/or edit
CurrentAuthor - the ID of the Club under whose name Work revisions are being done; requires signature authority
InitialReadClub - the ID of the initial read Club of all newly created Works and Clubs
InitialEditClub - the ID of the initial edit Club of all newly created Works and Clubs
InitialOwner - the ID of the Club which owns newly created RangeElements
InitialSponsor - the ID of the Club which sponsors newly created Works and Clubs; requires signature authority'!

(FeServer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeServer methodsFor: 'miscellaneous'!

{PrimPointerSpec} pointerSpec
	"Essential. A specification for arrays of pointers."
	
	^PrimSpec pointer! !

!FeServer methodsFor: 'create'!

create: encrypterName {Sequence}
	with: encrypter {Encrypter}
	
	super create.
	myEncrypterName _ encrypterName.
	myEncrypter _ encrypter! !

!FeServer methodsFor: 'security'!

{Encrypter} encrypter
	"Return the Encrypter used for sending sensitive parameters to the Server. (e.g. MatchLock::encryptedPassword ())"
	
	^myEncrypter!

{Sequence} getEncrypterName
	"Essential. The encryption scheme to be used for sending sensitive parameters to the Server. (e.g. MatchLock::encryptedPassword ())"
	
	^myEncrypterName! !

!FeServer methodsFor: 'smalltalk: defaults'!

{FeClubDescription} newClubDescription: membership {(FeSet of: FeClub) | NULL}

	^self newClubDescription: membership with: NULL! !

!FeServer methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeServer class
	instanceVariableNames: ''!

(FeServer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeServer class methodsFor: 'smalltalk: init'!

cleanupGarbage

	self linkTimeNonInherited!

exitTimeNonInherited

	CurrentServer fluidSet: NULL!

linkTimeNonInherited
	Recipe star defineGlobal: #FebeCuisine with: NULL.!

staticTimeNonInherited

	FeServer defineFluid: #CurrentServer with: ServerChunk emulsion with: [NULL].
	FeKeyMaster defineFluid: #CurrentKeyMaster with: ServerChunk emulsion with: [NULL].
	ID defineFluid: #CurrentAuthor with: ServerChunk emulsion with: [NULL].
	ID defineFluid: #InitialReadClub with: ServerChunk emulsion with: [NULL].
	ID defineFluid: #InitialEditClub with: ServerChunk emulsion with: [NULL].
	ID defineFluid: #InitialOwner with: ServerChunk emulsion with: [NULL].
	ID defineFluid: #InitialSponsor with: ServerChunk emulsion with: [NULL].! !

!FeServer class methodsFor: 'smalltalk: defaults'!

{ID CLIENT} assignID: range {FeRangeElement}
	"Essential.  Assign a new global ID to a RangeElement. If NULL, then a new unique ID is generated for it, and this requires no permissions. If an ID is supplied, the CurrentKeyMaster must have been granted authority to assign this ID by the Adminer. Returns the newly assigned ID."
	 
	^self assignID: range with: NULL! !

!FeServer class methodsFor: 'smalltalk: passe'!

{FeServer} current
	"The Server object for the current connection to Xanadu"
	"All messages should now be static, or go through the fluid variable."
	
	self passe!

{ID} nullClubID

	self passe "emptyClubID"! !

!FeServer class methodsFor: 'server library'!

{ID} clubID: clubName {Sequence}
	"Looks up the ID of a named Club in the directory maintained by the System Admin Club. Requires read permission on the directory. Blasts if there is no Club with that name."
	
	^FeServer iDOf: (((FeServer
		get: FeServer clubDirectoryID) cast: FeWork)
			edition get: clubName)!

{Sequence} clubName: iD {ID}
	"Finds the name of a Club in the global directory maintained by the System Admin Club. Blasts if there is no name for that Club, or if there is more than one. Requires read permission on the clubDirectory Work"
	
	| club {FeWork} |
	club := (FeServer get: iD) cast: FeClub.
	^(((FeServer
		get: FeServer clubDirectoryID) cast: FeWork)
			edition keysOf: club) theOne cast: Sequence!

{SequenceRegion} clubNames
	"The names of all global Clubs. Requires read permission on the clubDirectory Work"
	
	^((FeServer get: FeServer clubDirectoryID) cast: FeWork) edition domain cast: SequenceRegion!

{void} disableAccess: clubID {ID}
	"Disable login access to a Club, by revoking its direct membership of the System Access Club"
	
	| club {FeClub} desc {FeClubDescription} |
	Ravi thingToDo. "kill outstanding KeyMasters"
	club := (FeServer get: FeServer accessClubID) cast: FeClub.
	desc := (FeClubDescription spec wrap: club edition) cast: FeClubDescription.
	club grab.
	club revise: (desc withMembership: (desc membership
		without: ((FeServer get: clubID) cast: FeClub))) edition.
	club release!

{void} enableAccess: clubID {ID}
	"Enable login access to a Club, by listing it as a direct member of the System Access Club"
	
	| club {FeClub} desc {FeClubDescription} |
	club := (FeServer get: FeServer accessClubID) cast: FeClub.
	desc := (FeClubDescription spec wrap: club edition) cast: FeClubDescription.
	club grab.
	club revise: (desc withMembership: (desc membership
		with: ((FeServer get: clubID) cast: FeClub))) edition.
	club release!

{FilterSpace} endorsementFilterSpace
	"The CoordinateSpace used for filtering endorsements on this Server. Equivalent to
		this->filterSpace (this->endorsementSpace ())"
	
	self thingToDo.  "This should go in CrossSpace"
	^CurrentGrandMap fluidGet endorsementFilterSpace!

{CrossRegion of: IDRegion and: IDRegion}
	endorsementRegion: clubs {IDRegion | NULL}
	with: tokens {IDRegion | NULL}
	"A set of endorsements for each Club endorsing with each token"
	
	self thingToDo.  "This should go in CrossSpace"
	^FeServer endorsementSpace crossOfRegions: ((PrimSpec pointer
		arrayWithTwo: clubs with: tokens) cast: PtrArray)!

{CrossSpace of: IDSpace and: IDSpace} endorsementSpace
	"A set of endorsements for each Club endorsing with each token"
	
	self thingToDo.  "This should go in CrossSpace"
	^CurrentGrandMap fluidGet endorsementSpace!

{FeWork} globalClubs
	"The Work mapping names to global Club Works"
	
	^(FeServer get: FeServer clubDirectoryID) cast: FeWork!

{BooleanVar} isAdmitted
	"Return true if the current session has successfully logged into the Server yet."
	
	[Dean thingToDo] translateOnly.
	^true!

{void} nameClub: clubName {Sequence} with: clubID {ID}
	"Add a Club to the global list of club names. Blasts if there is already a Club by that name."
	
	| clubNames {FeWork} club {FeWork} |
	clubNames := FeServer globalClubs.
	clubNames grab.
		[(clubNames edition includesKey: clubName) ifTrue:
			[Heaper BLAST: #ClubNameInUse].
		club := (FeServer get: clubID) cast: FeClub.
		(clubNames edition keysOf: club) isEmpty ifFalse:
			[Heaper BLAST: #ClubAlreadyNamed].
		clubNames revise: (clubNames edition with: clubName with: club)]
	valueNowOrOnUnwindDo:
		(FeWork bomb.ReleaseWork: clubNames)!

{void} renameClub: oldName {Sequence} with: newName {Sequence}
	"Changes the name of an existing Club. Blasts if there is no Club with the old name, or there already is a Club with the new name."
	
	| names {FeWork} |
	names := FeServer globalClubs.
	names grab.
		[(names edition includesKey: oldName) ifFalse:
			[Heaper BLAST: #NoSuchClub].
		(names edition includesKey: newName) ifTrue:
			[Heaper BLAST: #ClubNameInUse].
		names revise: ((names edition without: oldName)
			with: newName with: (names edition get: oldName))]
	valueNowOrOnUnwindDo:
		(FeWork bomb.ReleaseWork: names)!

{void} unnameClub: clubName {Sequence}
	"Removes a naming for a Club. Blasts if there is no Club by that clubName."
	
	| clubNames {FeWork} |
	clubNames := FeServer globalClubs.
	clubNames grab.
		[(clubNames edition includesKey: clubName) ifTrue:
			[Heaper BLAST: #NoSuchClub].
		clubNames revise: (clubNames edition without: clubName)]
	valueNowOrOnUnwindDo:
		(FeWork bomb.ReleaseWork: clubNames)! !

!FeServer class methodsFor: 'create'!

{FeServer} implicitReceiver
	"Get the receiver for wire requests."
	^CurrentServer fluidGet!

make
	| encrypter {Encrypter}  result {FeServer} |
	Ravi thingToDo. "use a real Encrypter"
	Ravi hack. "to force wrappers to be initialized"
	FeWrapperSpec get: (Sequence string: 'Wrapper').
	encrypter := Encrypter make: (Sequence string: 'NoEncrypter').
	encrypter randomizeKeys: (UInt8Array string: 'hello').
	result _ self create: (Sequence string: 'NoEncrypter') with: encrypter.
	CurrentServer fluidSet: result.
	^CurrentServer fluidGet! !

!FeServer class methodsFor: 'smalltalk: system'!

info.stProtocol
"{ID CLIENT} accessClubID
{ID CLIENT} adminClubID
{FeAdminer CLIENT} adminer
{ID CLIENT} archiveClubID
{FeArchiver CLIENT} archiver
{ID CLIENT} assignID: range {FeRangeElement} with: iD {ID default: NULL}
{ID CLIENT} clubDirectoryID
{CrossSpace CLIENT} crossSpace: subSpaces {PtrArray of: CoordinateSpace}
{IntegerVar CLIENT} currentTime
{FilterSpace CLIENT} endorsementFilterSpace
{CrossRegion CLIENT of: IDRegion and: IDRegion} endorsementRegion: clubs {IDRegion | NULL} with: tokens {IDRegion | NULL}
{CrossSpace CLIENT of: IDSpace and: IDSpace} endorsementSpace
{FilterSpace CLIENT} filterSpace: baseSpace {CoordinateSpace}
{FeRangeElement CLIENT} get: iD {ID}
{Sequence CLIENT} identifier
{ID CLIENT} iDOf: value {FeRangeElement}
{IDRegion CLIENT} iDsOf: value {FeRangeElement}
{IDRegion CLIENT} iDsOfRange: edition {FeEdition}
{PrimFloatSpec CLIENT} iEEESpec: precision {Int32}
{ID CLIENT} importID: data {UInt8Array}
{IDRegion CLIENT} importIDRegion: data {UInt8Array}
{IDSpace CLIENT} importIDSpace: data {UInt8Array}
{IntegerSpace CLIENT} integerSpace
{FeBooLockSmith CLIENT} newBooLockSmith
{FeChallengeLockSmith CLIENT} newChallengeLockSmith: publicKey {UInt8Array} with: encrypterName {PrimIntegerArray}
{FeClub CLIENT} newClub: description {FeEdition}
{FeClubDescription CLIENT} newClubDescription: membership {(FeSet of: FeClub)
		| NULL} with: lockSmith {FeLockSmith default: NULL}
{FeClubDescription CLIENT} newClubDescription: members {FeWorkSet} with: lockSmith {FeLockSmith} with: home {FeWork | NULL}
{FeDataHolder CLIENT} newDataHolder: value {PrimValue}
{FeEdition CLIENT} newEdition: values {PrimArray of: FeRangeElement} with: positions {XuRegion default: NULL} with: ordering {OrderSpec default: NULL}
{FeEdition CLIENT} newEditionWith: position {Position} with: value {FeRangeElement}
{FeEdition CLIENT} newEditionWithAll: domain {XuRegion} with: value {FeRangeElement}
{FeEdition CLIENT} newEmptyEdition: cs {CoordinateSpace}
{FeHyperLink CLIENT} newHyperLink: types {(FeSet of: FeWork)
		default: NULL} with: leftEnd {FeHyperRef default: NULL} with: rightEnd {FeHyperRef default: NULL}
{ID CLIENT} newID
{FeIDHolder CLIENT} newIDHolder: iD {ID}
{IDSpace CLIENT} newIDSpace
{FeLabel CLIENT} newLabel
{FeMatchLockSmith CLIENT} newMatchLockSmith: scrambledPassword {UInt8Array} with: scramblerName {PrimIntegerArray}
{FeMultiLockSmith CLIENT} newMultiLockSmith
{FeMultiRef CLIENT} newMultiRef: refs {(PtrArray of: FeHyperRef)
		default: NULL} with: workContext {FeWork default: NULL} with: originalContext {FeWork default: NULL} with: pathContext {FePath default: NULL}
{FePath CLIENT} newPath: labels {(PtrArray of: FeLabel)
		default: NULL}
{FeRangeElement CLIENT} newPlaceHolder
{FeEdition CLIENT} newPlaceHolders: domain {XuRegion}
{FeSet CLIENT} newSet: values {(PtrArray of: FeRangeElement)
		default: NULL}
{FeSingleRef CLIENT} newSingleRef: excerpt {FeEdition | NULL} with: workContext {FeWork default: NULL} with: originalContext {FeWork default: NULL} with: pathContext {FePath default: NULL}
{FeText CLIENT} newText: data {PrimArray.X default: NULL}
{FeWallLockSmith CLIENT} newWallLockSmith
{FeWork CLIENT} newWork: contents {FeEdition}
{ID CLIENT} nullClubID
{PrimPointerSpec CLIENT} pointerSpec
{ID CLIENT} publicClubID
{FeKeyMaster CLIENT} publicKeyMaster
{RealSpace CLIENT} realSpace
{FeSession CLIENT} session
{void CLIENT} waitForConsequences: detector {PrWaitDetector}
{void CLIENT} waitForWrite: detector {PrWaitDetector}
{FeWrapperSpec CLIENT} wrapperSpec: name {Sequence}
"! !

!FeServer class methodsFor: 'managing clubs'!

{ID CLIENT} accessClubID
	"Essential.  The ID of the System Access Club."

	^CurrentGrandMap fluidGet accessClubID!

{ID CLIENT} adminClubID
	"Essential.  The ID of the System Admin Club."

	^CurrentGrandMap fluidGet adminClubID!

{ID CLIENT} archiveClubID
	"Essential.  The ID of the System Archive Club."

	self knownBug. "logging into this Club does not actually give you full read/edit authority"
	^CurrentGrandMap fluidGet archiveClubID!

{ID CLIENT} emptyClubID
	"Essential.  The ID of the Universal Empty Club."

	^CurrentGrandMap fluidGet emptyClubID!

{Sequence CLIENT login} encrypterName
	"Essential. The encryption scheme to be used for sending sensitive parameters to the Server. (e.g. MatchLock::encryptedPassword ())"
	
	^CurrentServer fluidGet getEncrypterName!

{Lock CLIENT login} login: clubID {ID}
	"Essential.  Return a lock which, if satisfied, will give a KeyMaster logged in to that Club. It will be able to exercise the authority of all of its superClubs.
	 The club must be in the System Access Club or another club must have been logged in during this session.
	 If that doesn't hold, or there is no such club, returns the gateLockSpec chosen by the Administrator if there is no such Club"
	
	| club {BeClub} cgm {BeGrandMap} |
	Ravi thingToDo.  "Check this please."
	cgm := CurrentGrandMap fluidGet.
	club _ cgm fetchClub: clubID.
	(club ~~ NULL
		and: [FeSession current isLoggedIn
			or: [(cgm getClub: FeServer accessClubID) membershipIncludes: club]])
		ifTrue: [^((FeClubDescription spec wrap: club edition) cast: FeClubDescription)
						lockSmith newLock: clubID]
		ifFalse: [^FeServer gateLockSmith newLock: NULL]!

{Lock CLIENT login} loginByName: clubName {Sequence}
	"Essential.  Return a lock which, if satisfied, will give a KeyMaster logged in to the named Club. It will be able to exercise the authority of all of its superClubs.
		 The club must be in the System Access Club or another club must have been logged in during this session.
	 If that doesn't hold, or there is no such club, returns the gateLockSpec chosen by the Administrator if there is no such Club"

	| club {BeClub} cgm {BeGrandMap} |
	Ravi thingToDo.  "Check this please."
	cgm := CurrentGrandMap fluidGet.
	(((cgm get: cgm clubDirectoryID) 
			cast: BeWork) edition fetch: clubName) 
		cast: FeClub into: [:feclub | club _ feclub beClub] others: [club _ NULL].
	(club ~~ NULL
		and: [FeSession current isLoggedIn
			or: [(cgm getClub: FeServer accessClubID) membershipIncludes: club]])
		ifTrue: [^((FeClubDescription spec wrap: club edition) cast: FeClubDescription)
						lockSmith newLock: (cgm iDOf: club)]
		ifFalse: [^FeServer gateLockSmith newLock: NULL]!

{ID CLIENT} publicClubID
	"Essential.  The ID of the Universal Public Club."

	^CurrentGrandMap fluidGet publicClubID!

{UInt8Array CLIENT login} publicKey
	"Essential. The public key to be used for sending sensitive parameters to the Server. (e.g. MatchLock::encryptedPassword ())"
	
	^CurrentServer fluidGet encrypter publicKey! !

!FeServer class methodsFor: 'comm requests'!

{NOACK CLIENT login} force
	"Flush the Server's output buffers."
	
	Dean shouldImplement!

{NOACK CLIENT} setCurrentAuthor: iD {ID}
	"Set the Server side fluid for the CurrentAuthor."
	
	CurrentAuthor fluidSet: iD!

{NOACK CLIENT} setCurrentKeyMaster: km {FeKeyMaster}
	"Set the Server side fluid for the CurrentKeyMaster."
	
	CurrentKeyMaster fluidSet: km!

{NOACK CLIENT} setInitialEditClub: iD {ID}
	"Set the Server side fluid for the InitialEditClub."
	
	InitialEditClub fluidSet: iD!

{NOACK CLIENT} setInitialOwner: iD {ID}
	"Set the Server side fluid for the InitialOwner."
	
	InitialOwner fluidSet: iD!

{NOACK CLIENT} setInitialReadClub: iD {ID}
	"Set the Server side fluid for the InitialReadClub."
	
	InitialReadClub fluidSet: iD!

{NOACK CLIENT} setInitialSponsor: iD {ID}
	"Set the Server side fluid for the InitialSponsor."
	
	InitialSponsor fluidSet: iD! !

!FeServer class methodsFor: 'global ids'!

{ID CLIENT} assignID: range {FeRangeElement} with: iD {ID default: NULL}
	"Essential.  Assign a new global ID to a RangeElement. If NULL, then a new unique ID is generated for it, and this requires no permissions. If an ID is supplied, the CurrentKeyMaster must have been granted authority to assign this ID by the Adminer. Returns the newly assigned ID."
	 
	| gm {BeGrandMap} |
	gm _ CurrentGrandMap fluidGet.
	iD == NULL ifTrue:
		[^gm assignID: range getOrMakeBe].
	(CurrentKeyMaster fluidGet hasAuthority: (gm grantAt: iD)) ifFalse:
		[Heaper BLAST: #MustHaveBeenGrantedAuthority].
	(gm at: iD tryIntroduce: range getOrMakeBe) ifFalse:
		[Heaper BLAST: #IDAlreadyAssigned].
	^iD!

{ID CLIENT} clubDirectoryID
	"The ID of a Work mapping Club names to FeClubs"
	
	^CurrentGrandMap fluidGet clubDirectoryID!

{FeRangeElement CLIENT} get: iD {ID}
	"Essential.  Get the object associated with the given global ID. Typically, it will be a Work. Blast if there is nothing there"
	
	^CurrentGrandMap fluidGet getFe: iD!

{ID CLIENT} iDOf: value {FeRangeElement}
	"Find the unique global ID on this Server that has been assigned to this RangeElement. Blast if there is none, or more than one.
	Equivalent to
		CAST(ID, this->iDsOf (value)->theOne ())"
	
	| be {BeRangeElement} |
	be := value fetchBe.
	be == NULL 
		ifTrue: [Heaper BLAST: #DoesNotHaveAnID.  ^NULL]
		ifFalse: [^CurrentGrandMap fluidGet iDOf: be]!

{IDRegion CLIENT} iDsOf: value {FeRangeElement}
	"Essential.  Find all the global IDs on this Server that have been assigned to this RangeElement"
	
	| be {BeRangeElement} |
	be := value fetchBe.
	be == NULL 
		ifTrue: [^(IDSpace global emptyRegion cast: IDRegion)]
		ifFalse: [^CurrentGrandMap fluidGet iDsOf: be]!

{IDRegion CLIENT} iDsOfRange: edition {FeEdition}
	"Find all the global IDs on this Server that have been assigned to any of the RangeElements in an Edition"
	
	| result {XnRegion} |
	self thingToDo. "fix this grossly inefficient algorithm so that at least it doesn't check every single virtual object in the range"
	edition isFinite ifFalse:
		[Heaper BLAST: #MustBeFinite].
	result := IDSpace global emptyRegion.
	edition stepper forEach: [ :value {FeRangeElement} | | be {BeRangeElement} |
		be := value fetchBe.
		be ~~ NULL ifTrue:
			[result := result unionWith: (CurrentGrandMap fluidGet iDsOf: be)]].
	^result cast: IDRegion! !

!FeServer class methodsFor: 'accessing'!

{IntegerVar CLIENT} currentTime
	"The current clock time on the Server, in seconds since the 'beginning of time'"
	
	^Time xuTime!

{FeLockSmith} gateLockSmith
	"The LockSmith which hands out locks when a client tries to login through the GateKeeper with an invalid Club ID or name."
	
	^(FeLockSmith spec wrap: CurrentGrandMap fluidGet gateLockSmithEdition) cast: FeLockSmith!

{Sequence CLIENT} identifier
	"Essential. A sequence of numbers uniquely identifying this Server"
	
	^CurrentGrandMap fluidGet identifier!

{void} removeWaitDetector: detector {FeWaitDetector}
	"This is currently a no-op."!

{FeWaitDetector CLIENT} waitForConsequences
	"Essential.  The Detector will be triggered when the consequences of all previous local requests have finished propagating through this Server. (e.g. Edition::transclusions may take a while to collect all of the results.)
	If you want to remove the Detector before it is triggered, destroy it.
	Note that this is NOT a request to speed up the completion of the outstanding requests.
	See WaitDetector::done ()"
	
	MarkM shouldImplement.
	FeServer waitForConsequences: NULL.
	^NULL "fodder"!

{void} waitForConsequences: detector {FeWaitDetector}
	"Essential.  The Detector will be triggered when the consequences of all previous local requests have finished propagating through this Server. (e.g. Edition::transclusions may take a while to collect all of the results.)
	If you want to remove the Detector before it is triggered, destroy it.
	Note that this is NOT a request to speed up the completion of the outstanding requests.
	See WaitDetector::done ()"
	
	MarkM shouldImplement!

{FeWaitDetector CLIENT} waitForWrite
	"Essential.  The Detector will be triggered when the current state of the Server has been reliably written to disk.
	If you want to remove the Detector before it is triggered, destroy it.
	See WaitDetector::done ()"
	
	Dean shouldImplement.
	FeServer waitForWrite: NULL.
	^NULL "fodder"!

{void} waitForWrite: detector {FeWaitDetector}
	"Essential.  The Detector will be triggered when the current state of the Server has been reliably written to disk.
	If you want to remove the Detector before it is triggered, destroy it.
	See WaitDetector::done ()"
	[DiskManager] USES.
	CurrentPacker fluidGet purge.
	detector done! !