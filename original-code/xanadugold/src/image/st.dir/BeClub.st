'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:36 pm'!

BeWork subclass: #BeClub
	instanceVariableNames: '
		mySignatureClub {ID | NULL}
		myMembers {MuSet of: BeClub}
		myImmediateSuperClubs {MuSet of: BeClub}
		mySponsored {MuSet of: BeWork}
		myWallFlag {BooleanVar}
		myTransitiveSuperClubIDs {IDRegion}
		myTransitiveMemberIDs {IDRegion}
		myKeyMasters {MuSet NOCOPY | NULL of: NuKeyMaster}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(BeClub getOrMakeCxxClassDescription)
	friends:
'/* friends for class BeClub */
friend class UpdateTransitiveMemberIDs;
friend class UpdateTransitiveSuperClubIDs;
friend class UpdateClubKeyMasterAuthorities;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeClub methodsFor: 'dependents'!

{void} registerKeyMaster: km {FeKeyMaster}
	"Notify the KeyMaster when the transitive super Clubs of this Club change"
	
	myKeyMasters == NULL ifTrue:
		[myKeyMasters := MuSet make.
		ActiveClubs fluidGet introduce: self].
	myKeyMasters introduce: km!

{void} unregisterKeyMaster: km {FeKeyMaster}
	"Unregister a previously registered KeyMaster"
	
	myKeyMasters == NULL ifTrue:
		[Heaper BLAST: #NeverRegisteredKeyMaster].
	myKeyMasters remove: km.
	myKeyMasters isEmpty ifTrue:
		[myKeyMasters := NULL.
		ActiveClubs fluidGet remove: self]! !

!BeClub methodsFor: 'accessing'!

{void} addSponsored: work {BeWork}
	"Add a sponsored Work (sent from the Work)"
	
	DiskManager insistent: 1 with:
		[mySponsored store: work.
		self diskUpdate]!

{ID | NULL} fetchSignatureClub
	"The Club who can endorse and sponsor with this Club"
	
	^mySignatureClub!

{BooleanVar} isPurgeable
	^super isPurgeable and: [myKeyMasters == NULL]!

{FeRangeElement} makeFe: label {BeLabel | NULL}

	^FeClub on: self!

{BooleanVar} membershipIncludes: club {BeClub}
	"Whether the direct membership includes the given Club"
	
	^myMembers hasMember: club!

{void} removeSponsored: work {BeWork}
	"Add a sponsored Work (sent from the Work)"
	
	DiskManager insistent: 1 with:
		[mySponsored wipe: work.
		self diskUpdate]!

{void} setSignatureClub: clubID {ID | NULL}
	"Change the Club who can endorse and sponsor with this Club"
	
	mySignatureClub := clubID!

{ImmuSet of: BeWork} sponsored

	^mySponsored asImmuSet!

{IDRegion} transitiveMemberIDs
	^myTransitiveMemberIDs!

{IDRegion} transitiveSuperClubIDs
	^myTransitiveSuperClubIDs! !

!BeClub methodsFor: 'private: propagating'!

{void} updateKeyMasters
	
	myKeyMasters ~~ NULL ifTrue:
		["notify any KeyMasters who care that my transitive super clubs have changed"
		myKeyMasters stepper forEach: [ :km {FeKeyMaster} |
			km updateAuthority]]! !

!BeClub methodsFor: 'private: accessing'!

{MuSet of: BeClub} immediateSuperClubs
	^ myImmediateSuperClubs!

{MuSet of: BeClub} members
	^ myMembers! !

!BeClub methodsFor: 'contents'!

{void} revise: contents {FeEdition}
	"Update cached information"
	
	| oldMembers {MuSet of: BeClub} oldMembership {FeEdition} newMembership {FeEdition} memberTest {BooleanVar} |
	(FeClubDescription check: contents) ifFalse:
		[Heaper BLAST: #MustBeClubDescription].
	DiskManager consistent:
		[oldMembership := (self edition
			fetch: (Sequence string: 'ClubDescription:Membership')) cast: FeEdition.
		super revise: contents. "Do this first so that permissions will change after the revision"
		newMembership := (contents
			fetch: (Sequence string: 'ClubDescription:Membership')) cast: FeEdition.
		"Update cached info if membership changes"
		(oldMembership == NULL or: [oldMembership isEmpty])
				ifTrue: [memberTest _ newMembership == NULL or: [newMembership isEmpty]]
				ifFalse: [memberTest _ newMembership ~~ NULL and: [newMembership isIdentical: oldMembership]].
		memberTest ifFalse:
			[oldMembers := myMembers.
			myMembers := MuSet make.
			newMembership stepper forEach: [ :mem {FeWork} |
				myMembers introduce: (mem getOrMakeBe cast: BeClub)].
			"Update all new members"
			(myMembers asImmuSet minus: oldMembers) stepper forEach: [ :newMem {BeClub} |
				newMem addImmediateSuperClub: self].
			"Update all lost members"
			(oldMembers asImmuSet minus: myMembers) stepper forEach: [ :lostMem {BeClub} |
				lostMem removeImmediateSuperClub: self].
			"Update self and all parents with new membership list"
			self updateTransitiveMemberIDs.
			self diskUpdate]]! !

!BeClub methodsFor: 'propagating'!

{void} addImmediateSuperClub: parent {BeClub}
	"Add an immediate super Club and update my cached information, and those of my members"
	
	myImmediateSuperClubs store: parent.
	self updateTransitiveSuperClubIDs.!

{void} removeImmediateSuperClub: parent {BeClub}
	"Add an immediate super Club and update my cached information, and those of my members"
	
	myImmediateSuperClubs remove: parent.
	self updateTransitiveSuperClubIDs.!

{void} updateTransitiveMemberIDs
	"Figure out result of changes in membership, then propagate upwards"
	
	| result {XnRegion} |
	result := IDSpace global emptyRegion.
	myMembers stepper forEach: [ :mem {BeClub} |
		result := (result unionWith: mem transitiveMemberIDs)].
	result := (result with: (CurrentGrandMap fluidGet iDOf: self)).
	(result isEqual: myTransitiveMemberIDs) ifFalse:
		[DiskManager insistent: 4 with: 
			[myTransitiveMemberIDs := result cast: IDRegion.
			self diskUpdate.
			myImmediateSuperClubs isEmpty ifFalse:
				[(UpdateTransitiveMemberIDs make: myImmediateSuperClubs copy asMuSet) schedule]]]!

{void} updateTransitiveSuperClubIDs
	"Figure out result of changes in membership, then propagate upwards"
	
	| result {XnRegion} |
	result := IDSpace global emptyRegion.
	myImmediateSuperClubs stepper forEach: [ :sup {BeClub} |
		result := (result unionWith: sup transitiveSuperClubIDs)].
	result := (result with: (CurrentGrandMap fluidGet iDOf: self)).
	(result isEqual: myTransitiveSuperClubIDs) ifFalse:
		[DiskManager insistent: 4 with:
			[myTransitiveSuperClubIDs := result cast: IDRegion.
			self diskUpdate.
			myMembers isEmpty ifFalse:
				[(UpdateTransitiveSuperClubIDs make: myMembers copy asMuSet with: CurrentGrandMap fluidGet) schedule]].
		"notify any KeyMasters who care that my transitive super clubs have changed"
		myKeyMasters ~~ NULL ifTrue:
			[myKeyMasters stepper forEach: [ :km {FeKeyMaster} |
				km updateAuthority]]]! !

!BeClub methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartClub: rcvr {Rcvr}
	myKeyMasters _ NULL! !

!BeClub methodsFor: 'creation'!

create: contents {FeEdition}
	
	| membership {FeEdition} |
	super create: contents with: true.
	mySignatureClub := InitialOwner fluidGet.
	myMembers := MuSet make.
	membership := (contents fetch: (Sequence
		string: 'ClubDescription:Membership')) cast: FeEdition.
	membership ~~ NULL ifTrue:
		[membership stepper forEach: [ :club {FeClub} |
			myMembers introduce: club beClub]].
	myImmediateSuperClubs := MuSet make.
	mySponsored := MuSet make.
	self knownBug. "wall flag"
	myWallFlag := false.
	myTransitiveSuperClubIDs := IDSpace global emptyRegion cast: IDRegion.
	myTransitiveMemberIDs := IDSpace global emptyRegion cast: IDRegion.
	myMembers stepper forEach: [ :mem {BeClub} |
		myTransitiveMemberIDs := (myTransitiveMemberIDs
			unionWith: mem transitiveMemberIDs) cast: IDRegion].
	self restartClub: NULL.
	self finishCreation.! !

!BeClub methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySignatureClub _ receiver receiveHeaper.
	myMembers _ receiver receiveHeaper.
	myImmediateSuperClubs _ receiver receiveHeaper.
	mySponsored _ receiver receiveHeaper.
	myWallFlag _ receiver receiveBooleanVar.
	myTransitiveSuperClubIDs _ receiver receiveHeaper.
	myTransitiveMemberIDs _ receiver receiveHeaper.
	self restartClub: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySignatureClub.
	xmtr sendHeaper: myMembers.
	xmtr sendHeaper: myImmediateSuperClubs.
	xmtr sendHeaper: mySponsored.
	xmtr sendBooleanVar: myWallFlag.
	xmtr sendHeaper: myTransitiveSuperClubIDs.
	xmtr sendHeaper: myTransitiveMemberIDs.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeClub class
	instanceVariableNames: ''!

(BeClub getOrMakeCxxClassDescription)
	friends:
'/* friends for class BeClub */
friend class UpdateTransitiveMemberIDs;
friend class UpdateTransitiveSuperClubIDs;
friend class UpdateClubKeyMasterAuthorities;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeClub class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	BeClub defineFluid: #CurrentOwner with: ServerChunk emulsion with: [NULL].
	MuSet defineFluid: #ActiveClubs with: DiskManager emulsion with: [MuSet make]! !

!BeClub class methodsFor: 'creation'!

make: contents {FeEdition}
	DiskManager consistent:
		[^BeClub create: contents]! !