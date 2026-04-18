'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:43 pm'!

BeRangeElement subclass: #BeWork
	instanceVariableNames: '
		myEdition {BeEdition}
		myEditionLabel {BeLabel}
		myReadClub {ID | NULL}
		myEditClub {ID | NULL}
		myOwnProp {BertProp}
		myHistory {BeEdition | NULL}
		myHistoryClub {ID | NULL}
		myRevisionCount {IntegerVar}
		myRevisionTime {IntegerVar}
		myReviser {ID}
		mySponsors {IDRegion}
		myLockingWork {WeakPtrArray NOCOPY of: FeWork}
		myRevisionWatchers {PrimSet NOCOPY | NULL of: FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!
BeWork comment:
'This is the actual representation on disk; the Fe versions of these classes hide the actual representation.ó'!

(BeWork getOrMakeCxxClassDescription)
	friends:
'/* friends for class BeWork */
friend class BeWorkLockExecutor;';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeWork methodsFor: 'locking'!

{BooleanVar} canBeEditedBy: km {FeKeyMaster}
	"Answer whether the KeyMaster has the authority to edit this work."

	^myEditClub ~~ NULL and: [km hasAuthority: myEditClub]!

{BooleanVar} canBeReadBy: km {FeKeyMaster}
	"Return true if the KeyMaster has the authority to read this Work."
	
	^(myReadClub ~~ NULL and: [km hasAuthority: myReadClub])
		or: [self canBeEditedBy: km]!

{FeWork INLINE | NULL} fetchLockingWork
	"The Work which has this locked, or NULL if noone does."
	
	^(myLockingWork fetch: Int32Zero) cast: FeWork!

{FeWork} makeLockedFeWork
	"Make a frontend Work on me and lock it if possible."
	
	| result {FeWork} ckm {FeKeyMaster} |
	result := (self makeFe: NULL) cast: FeWork.
	ckm := CurrentKeyMaster fluidGet.
	(self fetchLockingWork == NULL and: [self canBeEditedBy: ckm])
		ifTrue: [result grab].
	^result!

{BooleanVar} tryLock: work {FeWork}
	"Try to lock with the give FE Work. Return TRUE if successful"
	| curLock {FeWork} |
	curLock := self fetchLockingWork.
	(curLock == NULL or: [curLock isEqual: work]) ifTrue:
		[myLockingWork at: Int32Zero store: work.
		^true]
	ifFalse:
		[^false]!

{BooleanVar} tryUnlock: work {FeWork}
	"If the given FE Work is locking, then unlock and return TRUE; else return FALSE with no change in lock state"
	
	self fetchLockingWork == work ifTrue:
		["Unlock and tell everyone about the change"
		myLockingWork at: Int32Zero store: NULL.
		self updateFeStatus.
		^true]
	ifFalse:
		[^false]! !

!BeWork methodsFor: 'contents'!

{void} addRevisionWatcher: work {FeWork}
	"Tell the FE Work whenever this Work is revised"
	
	myRevisionWatchers == NULL ifTrue:
		[myRevisionWatchers := PrimSet weak: 7 with: (RevisionWatcherExecutor make: self)].
	myRevisionWatchers introduce: work!

{FeEdition} edition
	"The current Edition.
	Note: If this is an unsponsored Work, the Edition might have been discarded, and this operation will blast."
	
	self thingToDo. "Cache this"
	^FeEdition on: myEdition with: (FeLabel on: myEditionLabel)!

{ID} lastRevisionAuthor
	"The Club who made the last revision"
	
	^myReviser!

{IntegerVar} lastRevisionNumber
	"The sequence number of the last revision of this Work."
	
	^myRevisionCount!

{IntegerVar} lastRevisionTime
	"The time of the last revision of this Work."
	
	^myRevisionTime!

{void} recordHistory
	"Change the current edition and notify anyone who cares about the revision"
	
	| gm {BeGrandMap} |
	myHistoryClub == NULL ifTrue: [^VOID].
	gm _ CurrentGrandMap fluidGet.
	"Bind all these because they not be set."
	InitialReadClub fluidBind: myHistoryClub during:
	[InitialEditClub fluidBind: gm emptyClubID during:
	[InitialOwner fluidBind: self owner during:
	[InitialSponsor fluidBind: gm emptyClubID during:  "Don't sponsor the history."
		[| legacy {BeWork} |
		legacy _ gm newWork: self edition.
		legacy setEditClub: NULL.
		self thingToDo.   "legacy endorse: (CurrentAuthor fluidGet with: #revised)."
		myHistory _ self revisions with: myRevisionCount integer with: (gm carrier: legacy)].
	]]]!

{void} removeLastRevisionWatcher
	"Inform the work that its last revision watcher is gone."
	
	myRevisionWatchers := NULL!

{void} removeRevisionWatcher: work {FeWork}
	"Remove a previously added RevisionWatcher"
	
	myRevisionWatchers == NULL ifTrue:
		[Heaper BLAST: #NeverAddedRevisionWatcher].
	myRevisionWatchers remove: work.
	myRevisionWatchers isEmpty ifTrue:
		[myRevisionWatchers := NULL].!

{void} revise: edition {FeEdition}
	"Change the current edition and notify anyone who cares about the revision"
	
	DiskManager consistent:
		[self knownBug. "this may not be the right thing to do when not grabbed - it only happens during booting anyway"
		self fetchLockingWork == NULL
			ifTrue: [myReviser := CurrentAuthor fluidGet]
			ifFalse: [myReviser _ self fetchLockingWork getAuthor].
		myEdition removeWork: self.
		myEdition := edition beEdition.
		myEditionLabel _ edition label getOrMakeBe cast: BeLabel.
		myEdition introduceWork: self.
		myRevisionCount _ myRevisionCount + 1.
		myRevisionTime := BeGrandMap xuTime.
		"Trigger immediate revisionDetectors"
		myRevisionWatchers ~~ NULL ifTrue:
			[myRevisionWatchers stepper forEach: [ :work {FeWork} |
				work triggerRevisionDetectors: edition
					with: myReviser
					with: myRevisionTime
					with: myRevisionCount]].
		"Record result into the trail"
		myHistoryClub ~~ NULL ifTrue: [self recordHistory].
		self diskUpdate]!

{BeEdition} revisions
	"If there isn't already a shared Trail on this Work, create a new one. Return it"
	
	myHistory == NULL ifTrue: 
		[DiskManager consistent: 
			[myHistory _ CurrentGrandMap fluidGet newEmptyEdition: IntegerSpace make.
			self diskUpdate]].
	^myHistory! !

!BeWork methodsFor: 'permissions'!

{ID | NULL} fetchEditClub

	"The edit Club, or NULL if there is none"
	^myEditClub!

{ID | NULL} fetchHistoryClub
	"The history Club, or NULL if there is none"
	^myHistoryClub!

{ID | NULL} fetchReadClub
	"The read Club, or NULL if there is none"
	^myReadClub!

{void} setEditClub: club {ID | NULL}
	"Change the edit Club (or remove it if NULL)."
	
	DiskManager consistent: 1 with:
		[myEditClub := club.
		self knownBug. "props"
		self diskUpdate].
	self updateFeStatus.!

{void} setHistoryClub: club {ID | NULL}
	"Change the history Club (or remove it if NULL)."
	
	DiskManager consistent:
		[| oldClub {ID | NULL} |
		oldClub _ myHistoryClub.
		myHistoryClub := club.
		self knownBug.  "What happens when you change the club."
		(oldClub == NULL and: [myHistoryClub ~~ NULL])
			ifTrue: [self recordHistory].
		self diskUpdate].!

{void} setReadClub: club {ID | NULL}
	"Change the read Club (or remove it if NULL)."
	
	DiskManager consistent:
		[myReadClub := club.
		self knownBug. "props"
		self diskUpdate].
	self updateFeStatus.! !

!BeWork methodsFor: 'props'!

{void} endorse: endorsements {CrossRegion}
	"Adds to the endorsements on this Work. The set of endorsements must be a finite number of (club ID, token ID) pairs. This requires the authority of all of the Clubs used to endorse. The token IDs must not be named IDs."
	
	endorsements isEmpty
		ifTrue: [^VOID].
	DiskManager consistent: 8 with:
		[self 
			propChange: PropChange endorsementsChange 
			with: (BertProp endorsementsProp: (endorsements unionWith: myOwnProp endorsements))]!

{CrossRegion} endorsements
	"All endorsements which have been placed on this Work. The Edition::transclusions () operation will be able to find the current Edition of this Work by filtering for these endorsements; they are also used to filter various other operations which directly return sets of Works."
	
	^myOwnProp endorsements cast: CrossRegion!

{BertProp} localProp

	^myOwnProp!

{BertProp} prop

	^myOwnProp!

{void} propChange: change {PropChange} with: nw {Prop} 
	
	| old {Prop} |
	old _ myOwnProp.
	(change areEqualProps: old with: nw) not
		ifTrue: 
			[myOwnProp _ (change changed: old with: nw) cast: BertProp.
			self diskUpdate.
			myEdition propChanged: change
				with: old
				with: nw
				with: (change fetchFinder: old
					with: nw
					with: self
					with: NULL)]!

{void} retract: endorsements {CrossRegion}
	"Removes endorsements from this Work. This requires the authority of all of the Clubs whose endorsements are in the list. Ignores all endorsements which you could have removed, but which don't happen to be there right now."
	
	endorsements isEmpty
		ifTrue: [^VOID].
	DiskManager consistent: 5 with:
		[self 
			propChange: PropChange endorsementsChange 
			with: (BertProp endorsementsProp: (myOwnProp endorsements minus: endorsements))]! !

!BeWork methodsFor: 'accessing'!

{BooleanVar} isPurgeable
	^super isPurgeable and: [self fetchLockingWork == NULL and: [myRevisionWatchers == NULL]]!

{FeRangeElement} makeFe: label {BeLabel | NULL}

	^FeWork on: self!

{void} sponsor: clubs {IDRegion}
	"Add new sponsors to the Work, and notify the Clubs"
	
	| newClubs {IDRegion} |
	newClubs := (clubs minus: mySponsors) cast: IDRegion.
	newClubs isEmpty ifFalse:
		[DiskManager consistent: newClubs count + 1 with: 
			[newClubs stepper forEach: [ :clubID {ID} |
				(CurrentGrandMap fluidGet getClub: clubID)
					addSponsored: self].
			mySponsors := (mySponsors unionWith: newClubs) cast: IDRegion.
			self diskUpdate]]!

{IDRegion} sponsors

	^mySponsors!

{void} unsponsor: clubs {IDRegion}
	"Remove sponsors from the Work, and notify the Clubs"
	
	| lostClubs {IDRegion} |
	self thingToDo.  "Remove unsponsored clubs from the grandmap."
	self thingToDo. "When Clubs can have multiple IDs, then it might still be in the set"
	lostClubs := (clubs intersect: mySponsors) cast: IDRegion.
	lostClubs isEmpty ifFalse:
		[DiskManager consistent: lostClubs count + 1 with:
			[lostClubs stepper forEach: [ :clubID {ID} |
				(CurrentGrandMap fluidGet getClub: clubID) removeSponsored: self].
			mySponsors := (mySponsors minus: clubs) cast: IDRegion.
			self diskUpdate]]! !

!BeWork methodsFor: 'private:'!

{void} updateFeStatus
	"Tell all the FeWorks on this one to update their status"
	[PrimSet] USES.
	self feRangeElements stepper forEach: [ :work {FeWork} | work updateStatus]! !

!BeWork methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartWork: rcvr {Rcvr unused}
	myLockingWork _ WeakPtrArray make: (BeWorkLockExecutor make: self) with: 1.
	myRevisionWatchers _ NULL! !

!BeWork methodsFor: 'smalltalk: passe'!

{void} addSponsors: clubs {IDRegion}

	self passe "sponsor"!

{void} removeSponsors: clubs {IDRegion}

	self passe!

{void} unendorse: endorsements {CrossRegion}

	self passe! !

!BeWork methodsFor: 'creation'!

create: contents {FeEdition} with: isClub {BooleanVar}
	
	| permissions {XnRegion} |
	super create.
	myEdition := contents beEdition.
	myEditionLabel _ contents label getOrMakeBe cast: BeLabel.
	myReadClub := InitialReadClub fluidFetch.
	myReadClub == NULL
		ifTrue: [permissions := CurrentGrandMap fluidGet globalIDSpace emptyRegion]
		ifFalse: [permissions := myReadClub asRegion].
	myEditClub := InitialEditClub fluidFetch.
	myEditClub ~~ NULL ifTrue:
		[permissions := permissions with: myEditClub].
	myOwnProp := BertProp permissionsProp: permissions.
	myRevisionCount _ IntegerVarZero.
	myRevisionTime _ Time xuTime.
	myReviser _ CurrentAuthor fluidGet.
	myHistory _ NULL.
	myHistoryClub _ NULL.
	self knownBug.  "Should public shut off sponsorship?"
	InitialSponsor fluidGet == CurrentGrandMap fluidGet emptyClubID
		ifTrue: [mySponsors := IDSpace global emptyRegion cast: IDRegion]
		ifFalse: [mySponsors := InitialSponsor fluidFetch asRegion cast: IDRegion].
	self restartWork: NULL.
	myEdition introduceWork: self.
	
	self knownBug.  "Is the above all right?"
	isClub ifFalse: [self finishCreation.]!

{void} finishCreation
	"Gets called once the object is created, to finish up"
	
	mySponsors stepper forEach: [ :iD {ID} |
		(CurrentGrandMap fluidGet getClub: iD) addSponsored: self].
	self newShepherd.! !

!BeWork methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << (CurrentGrandMap fluidGet iDsOf: self) << ')'! !

!BeWork methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myEdition _ receiver receiveHeaper.
	myEditionLabel _ receiver receiveHeaper.
	myReadClub _ receiver receiveHeaper.
	myEditClub _ receiver receiveHeaper.
	myOwnProp _ receiver receiveHeaper.
	myHistory _ receiver receiveHeaper.
	myHistoryClub _ receiver receiveHeaper.
	myRevisionCount _ receiver receiveIntegerVar.
	myRevisionTime _ receiver receiveIntegerVar.
	myReviser _ receiver receiveHeaper.
	mySponsors _ receiver receiveHeaper.
	self restartWork: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myEdition.
	xmtr sendHeaper: myEditionLabel.
	xmtr sendHeaper: myReadClub.
	xmtr sendHeaper: myEditClub.
	xmtr sendHeaper: myOwnProp.
	xmtr sendHeaper: myHistory.
	xmtr sendHeaper: myHistoryClub.
	xmtr sendIntegerVar: myRevisionCount.
	xmtr sendIntegerVar: myRevisionTime.
	xmtr sendHeaper: myReviser.
	xmtr sendHeaper: mySponsors.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeWork class
	instanceVariableNames: ''!

(BeWork getOrMakeCxxClassDescription)
	friends:
'/* friends for class BeWork */
friend class BeWorkLockExecutor;';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeWork class methodsFor: 'creation'!

make: edition {FeEdition}
	DiskManager consistent:
		[^self create: edition with: false]! !