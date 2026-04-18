'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:00 pm'!

Heaper subclass: #FeKeyMaster
	instanceVariableNames: '
		myLoginAuthority {IDRegion}
		myActualAuthority {IDRegion}
		myRegisteredWorks {PrimSet | NULL of: FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeKeyMaster comment:
'A KeyMaster provides the authority, or "holds the keys", for a client`s activities on the BackEnd. A client can have any number of different KeyMasters, each with different authority. FeServer_login (if successful) gives you back a KeyMaster with the authority of a single Club (along with all the Clubs of which it is a member, directly or indirectly). This will give you appropriate authority to do anything permitted to that Club. You can incorporate the authority of other KeyMasters into it, so that it will additionally enable you to do anything the other KeyMasters would have enabled.'!

(FeKeyMaster getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeKeyMaster methodsFor: 'authority'!

{IDRegion CLIENT} actualAuthority
	"Essential.  The Clubs whose authority is actually being held right now. This may change asynchronously when you or others change the membership lists of clubs.  It is my loginAuthority plus all clubs that list any of these clubs as members, transitively."
	
	^myActualAuthority!

{FeKeyMaster CLIENT} copy
	"Essential.  A different KeyMaster with the same login and actual authority as this one."
	
	^FeKeyMaster make: myLoginAuthority
		with: myActualAuthority!

{BooleanVar CLIENT} hasAuthority: clubID {ID}
	"Whether this KeyMaster is currently holding the authority of the given Club. Equivalent to
		this->actualAuthority ()->hasMember (clubID)"
		
	^myActualAuthority hasMember: clubID!

{void CLIENT} incorporate: other {FeKeyMaster}
	"Essential.  Add the other KeyMaster's login and actual authorities to my own respective authorities."
	
	| newLogins {XnRegion} |
	newLogins := other loginAuthority minus: myLoginAuthority.
	myLoginAuthority := (myLoginAuthority unionWith: other loginAuthority) cast: IDRegion.
	myActualAuthority := (myActualAuthority unionWith: other actualAuthority) cast: IDRegion.
	"Tell all my Works"
	self authorityChanged.
	"Register with the new login Clubs to find out when their super clubs change"
	newLogins stepper forEach: [ :login {ID} |
		((CurrentGrandMap fluidGet get: login) cast: BeClub) registerKeyMaster: self]!

{IDRegion CLIENT} loginAuthority
	"Essential.  The Clubs whose authority was obtained directly, by logging in to them. They are the ones from which all other authority is derived."
	
	^myLoginAuthority!

{void CLIENT} removeLogins: oldLogins {IDRegion}
	"Essential.  Remove the listed IDs from the set of Clubs whose login authority I exercise.  All authority derived from them that cannot be derived from the remaining login authority will also disappear.  Listed Clubs for which I do not hold login authority will be silently ignored."
	
	| removed {IDRegion} |
	removed := (oldLogins intersect: myLoginAuthority) cast: IDRegion.
	myLoginAuthority := (myLoginAuthority minus: removed) cast: IDRegion.
	"Figure out the new transitive authority"
	self updateAuthority.
	"Unregister with the new IDs"
	removed stepper forEach: [ :login {ID} |
		((CurrentGrandMap fluidGet get: login) cast: BeClub) unregisterKeyMaster: self]! !

!FeKeyMaster methodsFor: 'private: create'!

create: loginAuthority {IDRegion}
	with: actualAuthority {IDRegion}

	super create.
	myLoginAuthority := loginAuthority.
	myActualAuthority := actualAuthority.
	myRegisteredWorks := NULL.! !

!FeKeyMaster methodsFor: 'server accessing'!

{BooleanVar} hasSignatureAuthority: club {ID}
	"Whether this KeyMaster has signature authority for the given Club"
	
	| sig {ID} cgm {BeGrandMap} |
	cgm := CurrentGrandMap fluidGet.
	^(sig := (cgm getClub: club) fetchSignatureClub) ~~ NULL
		and: [self hasAuthority: sig]!

{void} registerWork: work {FeWork}
	"Notify the Work whenever my authority changes"
	
	myRegisteredWorks == NULL ifTrue:
		[myRegisteredWorks := PrimSet weak].
	myRegisteredWorks introduce: work!

{void} unregisterWork: work {FeWork}
	"Notify the Work whenever my authority changes"
	
	(myRegisteredWorks == NULL or: [myRegisteredWorks isEmpty]) ifTrue:
		[Heaper BLAST: #NeverAddedWatcher]. 
	myRegisteredWorks remove: work.
	myRegisteredWorks isEmpty ifTrue:
		[myRegisteredWorks := NULL].!

{void} updateAuthority
	"Recompute the actual authority of this KeyMaster based on the set of login Clubs"
	
	myActualAuthority := (IDSpace global emptyRegion cast: IDRegion).
	myLoginAuthority stepper forEach: [ :login {ID} |
		myActualAuthority := (myActualAuthority
			unionWith: ((CurrentGrandMap fluidGet get: login) cast: BeClub) transitiveSuperClubIDs) cast: IDRegion].
	self authorityChanged.! !

!FeKeyMaster methodsFor: 'private:'!

{void} authorityChanged
	"Notify all my dependents of a change in authority"
	
	myRegisteredWorks ~~ NULL ifTrue:
		[myRegisteredWorks stepper forEach: [ :work {FeWork} |
			work updateStatus]]! !

!FeKeyMaster methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'KeyMaster(' << self loginAuthority << ')'! !

!FeKeyMaster methodsFor: 'obsolete:'!

{Filter} permissionsFilter
	"A filter for things which can be read by this KeyMaster"
	
	self thingToDo. "have all callers use 'actualAuthority' instead"
	^CurrentGrandMap fluidGet globalIDFilterSpace anyFilter: myActualAuthority! !

!FeKeyMaster methodsFor: 'smalltalk: passe'!

{void} removeAuthority: oldLogins {IDRegion}

	self passe.	"renamed removeLogins:"! !

!FeKeyMaster methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeKeyMaster class
	instanceVariableNames: ''!

(FeKeyMaster getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeKeyMaster class methodsFor: 'creation'!

make: clubID {ID}
	"Make a KeyMaster initially logged in to the given Club"
	
	^self make: (clubID asRegion cast: IDRegion) "login authority"
		with: (CurrentGrandMap fluidGet getClub: clubID) transitiveSuperClubIDs!

{FeKeyMaster} makeAll: clubIDs {IDRegion}
	"Make a KeyMaster initially logged in to the given Clubs"
	
	| actuals {IDRegion} gm {BeGrandMap} |
	gm := CurrentGrandMap fluidGet.
	actuals := gm globalIDSpace emptyRegion cast: IDRegion.
	clubIDs stepper forEach: [:iD {ID} |
		actuals := (actuals unionWith: (gm getClub: iD) transitiveSuperClubIDs) cast: IDRegion].
	^self make: clubIDs with: actuals!

{FeKeyMaster} makePublic
	"Make a KeyMaster logged in to the Universal Public Club."
	
	^FeKeyMaster make: FeServer publicClubID! !

!FeKeyMaster class methodsFor: 'private: pseudo constructors'!

make: loginAuthority {IDRegion}
	with: actualAuthority {IDRegion}
	
	| result {FeKeyMaster} |
	result := self create: loginAuthority with: actualAuthority.
	"Register with all the login Clubs to find out when their permissions change"
	loginAuthority stepper forEach: [ :loginClubID {ID} |
		((CurrentGrandMap fluidGet get: loginClubID) cast: BeClub)
			registerKeyMaster: result].
	^result! !

!FeKeyMaster class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IDRegion CLIENT} actualAuthority
{FeKeyMaster CLIENT} copy
{BooleanVar CLIENT} hasAuthority: clubID {ID}
{void CLIENT} incorporate: other {FeKeyMaster}
{IDRegion CLIENT} loginAuthority
{void CLIENT} removeLogins: oldLogins {IDRegion}
"! !

!FeKeyMaster class methodsFor: 'assertions'!

{void} assertAdminAuthority
	"Blast if the CurrentKeyMaster doesn't have Admin authority."

	(CurrentKeyMaster fluidGet hasAuthority: CurrentGrandMap fluidGet adminClubID)
		ifFalse: [Heaper BLAST: #MustHaveAdminAuthority].!

{void} assertSignatureAuthority
	"Blast if the CurrentKeyMaster doesn't have signature authority for the CurrentAuthor."
	(CurrentKeyMaster fluidGet hasSignatureAuthority: CurrentAuthor fluidGet) ifFalse:
		[Heaper BLAST: #MustHaveAuthorSignatureAuthority].!

{void} assertSponsorship
	"If there is a currentSponsor, then the CurrentKeyMaster must have authority for it."
	| ckm {FeKeyMaster} cgm {BeGrandMap} |
	ckm := CurrentKeyMaster fluidGet.
	cgm := CurrentGrandMap fluidGet.
	(InitialSponsor fluidGet == cgm emptyClubID
		or: [ckm hasAuthority: InitialSponsor fluidFetch])
		ifFalse: [Heaper BLAST: #MustHaveSponsorAuthority]! !