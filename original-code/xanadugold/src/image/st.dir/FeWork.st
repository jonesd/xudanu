'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:05 pm'!

FeRangeElement subclass: #FeWork
	instanceVariableNames: '
		myKeyMaster {FeKeyMaster | NULL}
		myAuthor {ID}
		amWaiting {BooleanVar}
		myBeWork {BeWork}
		myStatusDetectors {PrimSet | NULL of: FeStatusDetector}
		myRevisionDetectors {PrimSet | NULL of: FeRevisionDetector}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeWork comment:
'A persistent identity for a changeable object.'!

(FeWork getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeWork methodsFor: 'grab status'!

{void} addStatusDetector: detector {FeStatusDetector}
	"Essential.  Add a detector which will be notified whenever the locking status of this Work object changes.
	See FeStatusDetector::grabbed (Work *, ID *) / released (Work *)."
	
	myStatusDetectors == NULL ifTrue:
		[myStatusDetectors := PrimSet weak: 7 with: (StatusDetectorExecutor make: self)].
	myStatusDetectors introduce: detector!

{BooleanVar CLIENT} canRead
	"Return whether you have read permission.  If grabbed, returns TRUE (because a grabber can always read); if released, then returns whether the CurrentKeyMaster has sufficient permission to read the work.  (Read or Edit permission is required.)  Does not check any other KeyMasters you may be holding.
	Note: Be careful of synchronization problems, since the permissions may change between when you ask this question and when you try to actually read the Work."
	| ckm {FeKeyMaster} |
	ckm := CurrentKeyMaster fluidFetch.
	^self canRevise
		or: [ckm ~~ NULL
			and: [myBeWork canBeReadBy: ckm]]!

{BooleanVar CLIENT} canRevise
	"Return whether the BeWork is grabbed by you through this FeWork.
	Note: Be careful of synchronization problems, since the permissions may change before you try to actually revise it, causing you to lose your grab."
	
	^(myBeWork fetchLockingWork basicCast: Heaper star) == self!

{void CLIENT} grab
	"Essential.  Grab the Work to prevent other clients from revising it.  Requires edit permission. Snapshots the CurrentKeyMaster and CurrentAuthor (to be used to maintain the grab and report what was done with it). Fails if
		- someone else has it grabbed
		- the CurrentKeyMaster does not have edit permission
		- the CurrentKeyMaster does not have signature authority of the CurrentAuthor
	If this Work was already grabbed by you, then it updates the KeyMaster and Author it holds. (If the regrab fails, the old grab will remain in effect.)
	The grab will be released
		- upon a release request
		- if the KeyMaster loses authority to edit
		- if the KeyMaster loses the signature authority of the Author
		- at the end of the session
		- when the FeWork object is deallocated (if an FeWork was dropped while grabbed, {by destroying the promise for it, or by loss of connection} it will be deallocated 'eventually')"

	| oldAuthor {ID} |
	"Check that I have edit permissions"
	(myBeWork canBeEditedBy: CurrentKeyMaster fluidGet)
		ifFalse: [Heaper BLAST: #MustHaveEditPermission].
	(CurrentKeyMaster fluidGet hasSignatureAuthority: CurrentAuthor fluidGet)
		ifFalse: [Heaper BLAST: #MustHaveAuthorSignatureAuthority].
	oldAuthor := myAuthor.
	myAuthor := CurrentAuthor fluidFetch.
	myKeyMaster ~~ NULL ifTrue:
		[myKeyMaster unregisterWork: self].
	myKeyMaster := CurrentKeyMaster fluidFetch.
	myKeyMaster registerWork: self.
	"Try to gain mutual exclusion"
	(myBeWork tryLock: self) ifFalse:
		[myAuthor := NULL.
		myKeyMaster := NULL.
		Heaper BLAST: #WorkIsLockedBySomeoneElse].
	amWaiting ifTrue:
		["code has been changed in such a way as to allow a race condition"
		Heaper BLAST: #FatalError].
	Ravi thingToDo. "register with author Club to find out when signature authority changes"
	"Notify all the status detectors"
	(myStatusDetectors ~~ NULL and: [oldAuthor == NULL or: [(oldAuthor isEqual: myAuthor) not]]) ifTrue:
		[myStatusDetectors stepper forEach: [ :stat {FeStatusDetector} |
			self thingToDo. "reasons"
			stat grabbed:  self with: myAuthor with: IntegerVarZero]].!

{ID CLIENT} grabber
	"Essential.  If you have edit authority, and someone has the BeWork grabbed, then return the Club ID that was the value of his CurrentAuthor when he grabbed it; otherwise blast.
	Requiring edit authority is appropriate here, because it is exactly editors who are affected by competing grabs, and need to know who has the grab.  Once the BeWork is revised, anyone who can read the current trail can see the revision, but the grab state doesn't necessarily imply that the BeWork will be revised soon, or ever."
	
	| grabber {FeWork} ckm {FeKeyMaster} |
	self canRevise ifTrue:
		[^myAuthor].
	ckm := CurrentKeyMaster fluidGet.
	(myBeWork fetchEditClub ~~ NULL
			and: [ckm hasAuthority: myBeWork fetchEditClub])
		ifFalse: [Heaper BLAST: #MustHaveEditAuthority].
	grabber := myBeWork fetchLockingWork.
	grabber == NULL ifTrue:
		[Heaper BLAST: #NotGrabbed].
	^grabber getAuthor!

{void CLIENT} release
	"Essential.  Release the grab on this Work; if a requestGrab had been pending, remove it. Does nothing if it is already unlocked."
	
	| becameUnlocked {BooleanVar} |
	(amWaiting or: [self canRevise]) ifFalse: [^VOID].
	becameUnlocked := myBeWork tryUnlock: self.
	myKeyMaster unregisterWork: self.
	amWaiting := false.
	myKeyMaster := NULL.
	myAuthor := NULL.
	becameUnlocked ifTrue:
		["Notify all the status detectors"
		myStatusDetectors ~~ NULL ifTrue:
			[myStatusDetectors stepper forEach: [ :stat {FeStatusDetector} |
				stat released: self with: IntegerVarZero]]].!

{void} removeLastStatusDetector
	"Essential.  Last detector has gone away"
	
	myStatusDetectors := NULL!

{void CLIENT} requestGrab
	"Essential.  Registers a request so that the next time this Work would have been released and no other grab requests are outstanding the CurrentKeyMaster (as of making the request) has edit permission, and has signature authority of the CurrentAuthor (as of making the request), it will be grabbed by this FeWork.  If this FeWork already has the Work grabbed, then the request has no effect.  To find out when the grab succeeds, place Status Detectors on the Work.  (If there are competing requestGrabs for a BeWork, the queueing of the requests may not be FIFO, but is starvation-free.)  Note that if you have a requestGrab outstanding on a BeWork through one FeWork, and release a grab you have through another, your requestGrab has no special priority over those of other users."
	
	self canRevise ifTrue: 
		[(myBeWork canBeEditedBy: CurrentKeyMaster fluidGet)
			ifFalse: [Heaper BLAST: #MustHaveEditPermission].
		(CurrentKeyMaster fluidGet hasSignatureAuthority: CurrentAuthor fluidGet)
			ifFalse: [Heaper BLAST: #MustHaveAuthorSignatureAuthority].
		myAuthor := CurrentAuthor fluidFetch.
		myKeyMaster unregisterWork: self.
		myKeyMaster := CurrentKeyMaster fluidFetch.
		myKeyMaster registerWork: self.
		^VOID].
	amWaiting ifTrue:
		[myKeyMaster unregisterWork: self].
	amWaiting := true.
	myKeyMaster := CurrentKeyMaster fluidGet.
	myAuthor := CurrentAuthor fluidGet.
	self updateStatus.
	myKeyMaster registerWork: self.!

{FeStatusDetector CLIENT} statusDetector
	"Essential.  Return a detector which will be notified whenever the locking status of this Work changes.
	See FeStatusDetector::grabbed (Work *, ID *) / released (Work *)."
	
	Dean shouldImplement.
	self addStatusDetector: NULL.
	^NULL "fodder"! !

!FeWork methodsFor: 'contents'!

{FeEdition CLIENT} edition
	"Essential.  Return the current Edition.  Succeeds if the Work is already grabbed, or if the CurrentKeyMaster has either Read or Edit permission.
	Note: If this is an unsponsored Work, the Edition might have been discarded, in which case this operation will blast."
	
	self canRead ifFalse:
		[Heaper BLAST: #MustHaveReadPermission].
	^myBeWork edition!

{void CLIENT} revise: newEdition {FeEdition}
	"Essential.  Change the current Edition of this work to newEdition. The Work must be grabbed  The grabber is recorded as the author who made the revision.
	 (This is the fundamental write operation.)"
	
	self canRevise ifFalse:
		[Heaper BLAST: #WorkMustBeGrabbed].
	CurrentKeyMaster fluidBind: myKeyMaster during:
	[CurrentAuthor fluidBind: myAuthor during:
		[myBeWork revise: newEdition]]! !

!FeWork methodsFor: 'permissions'!

{ID CLIENT} editClub
	"Essential.  Return the club which has permission to revise this Work.  Blasts if noone can (i.e. editor has been removed)."
	
	myBeWork fetchEditClub == NULL ifTrue: [Heaper BLAST: #EditorRemoved].
	^myBeWork fetchEditClub!

{ID CLIENT} historyClub
	"Essential. Return the club which will be recorded as the initial club for frozen Works in the history trail.  Blasts if there is no trail being generated."
	
	| result {ID} |
	result := myBeWork fetchHistoryClub.
	result == NULL ifTrue:
		[Heaper BLAST: #NoHistoryClub].
	^result!

{ID CLIENT} readClub
	"Essential.  Return the club which has permission to read this Work.  Blasts if the read Club has been removed (in that case, only those who have edit permission can read the Work)."
	
	myBeWork fetchReadClub == NULL ifTrue: [Heaper BLAST: #ReadClubRemoved].
	^myBeWork fetchReadClub!

{void CLIENT} removeEditClub
	"Essential.  Irrevocably remove edit permission. Requires ownership authority."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	myBeWork setEditClub: NULL!

{void CLIENT} removeReadClub
	"Essential.  Irrevocably remove read permission (although you should note that editors are still able to read, if there are any). Requires ownership authority."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	myBeWork setReadClub: NULL!

{void CLIENT} setEditClub: club {ID | NULL}
	"Essential.  Change who has edit permission. Requires ownership authority.
	 Aborts if the Work doesn't have an edit Club."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	myBeWork fetchEditClub == NULL
		ifTrue: [Heaper BLAST: #EditClubIrrevocablyRemoved].
	myBeWork setEditClub: club!

{void CLIENT} setHistoryClub: club {ID | NULL}
	"Essential.  Change the initial read Club for frozen Works in the trail. Requires ownership authority. Setting it to NULL turns off the recording of history."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	myBeWork setHistoryClub: club!

{void CLIENT} setReadClub: club {ID | NULL}
	"Essential.  Change who has read permission. Requires ownership authority.
	 Aborts if the works doesn't have a read Club."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	myBeWork fetchReadClub == NULL
		ifTrue: [Heaper BLAST: #ReadClubIrrevocablyRemoved].
	myBeWork setReadClub: club! !

!FeWork methodsFor: 'endorsing'!

{void CLIENT} endorse: additionalEndorsements {CrossRegion}
	"Essential.  Adds to the endorsements on this Work. The set of endorsements must be a finite number of (club ID, token ID) pairs. This requires the signature authority of all of the Clubs used to endorse; will blast and do nothing if any of the required authority is lacking. The token IDs must not be named IDs."
	
	FeRangeElement validateEndorsement: additionalEndorsements with: CurrentKeyMaster fluidGet.
	myBeWork endorse: additionalEndorsements!

{CrossRegion CLIENT} endorsements
	"Essential.  Return all of the endorsements which have been placed on this Work and are not currently retracted.
	(Endorsements are used to filter various operations which return sets of Works.  See FeEdition::rangeTranscluders() for one way to find this work by filtering for its endorsements.)"
	
	^myBeWork endorsements!

{void CLIENT} retract: removedEndorsements {CrossRegion}
	"Essential.  Removes endorsements from this Work. This requires the signature authority of all of the Clubs whose endorsements are in the list; will blast and do nothing if any of the required authority is lacking. Ignores all endorsements which you could have removed, but which don't happen to be there right now."
	
	FeRangeElement validateEndorsement: removedEndorsements with: CurrentKeyMaster fluidGet.
	myBeWork retract: removedEndorsements! !

!FeWork methodsFor: 'sponsoring'!

{void CLIENT} sponsor: clubs {IDRegion}
	"Essential.  Add to the list of sponsors of this Work. Requires signature authority of all of the Clubs in the set."
	
	FeRangeElement validateSignature: clubs with: CurrentKeyMaster fluidGet.
	myBeWork sponsor: clubs!

{IDRegion CLIENT} sponsors
	"Essential.  All of the Clubs which are sponsoring this Work to keep it from being discarded.
	What sort of permissions does this require?"
	
	^myBeWork sponsors!

{void CLIENT} unsponsor: clubs {IDRegion}
	"Essential.  End sponsorship of this Work by all of the listed Clubs. Requires signature authority of all of the Clubs in the set, even if they are not currently sponsors.
	Should this use the CurrentKeyMaster? Or the internal KeyMaster if it is grabbed?"
	
	FeRangeElement validateSignature: clubs with: CurrentKeyMaster fluidGet.
	myBeWork unsponsor: clubs! !

!FeWork methodsFor: 'server grab status'!

{void} updateStatus
	"The authority of my KeyMaster has changed and I need to update my status"
	
	"If I was grabbing and lost permission to edit, or signature authority for the author,
		evict myself
	else if I was waiting for a grab and gained permission to do so
		and the Work is ungrabbed
			grab it"
	Ravi knownBug. "Add mechanism to notify when signature Club of Author is changed"
	self canRevise ifTrue:
		[((myBeWork canBeEditedBy: myKeyMaster)
				and: [myKeyMaster hasSignatureAuthority: myAuthor])
			ifFalse: [self release]]
	ifFalse: [(amWaiting
			and: [myKeyMaster ~~ NULL
			and: [(myBeWork canBeEditedBy: myKeyMaster)
			and: [myKeyMaster hasSignatureAuthority: myAuthor]]])
		ifTrue:
			[(myBeWork tryLock: self) ifTrue:
				[amWaiting := false.
				myStatusDetectors ~~ NULL ifTrue:
					[myStatusDetectors stepper forEach:
						[ :stat {FeStatusDetector} |
						self thingToDo. "reasons"
						stat grabbed: self with: myAuthor with: IntegerVarZero]]]]]! !

!FeWork methodsFor: 'server contents'!

{void} triggerRevisionDetectors: contents {FeEdition}
	with: author {ID}
	with: time {IntegerVar}
	with: sequence {IntegerVar}
	"Trigger all my immediate RevisionDetectors who can read the Work"
	
	myRevisionDetectors stepper forEach:
		[ :pair {Pair of: FeKeyMaster and: FeRevisionDetector} |
		(myBeWork canBeReadBy: (pair left cast: FeKeyMaster)) ifTrue:
			[(pair right cast: FeRevisionDetector)
				revised: self with: contents with: author with: time with: sequence]]! !

!FeWork methodsFor: 'server accessing'!

{ID | NULL} fetchAuthor

	^myAuthor!

{BeRangeElement | NULL} fetchBe

	^myBeWork!

{ID} getAuthor

	myAuthor == NULL ifTrue:
		[Heaper BLAST: #NoAuthor].
	^myAuthor!

{BeRangeElement} getOrMakeBe
	
	^myBeWork! !

!FeWork methodsFor: 'protected: create'!

create: be {BeWork}

	super create.
	myBeWork := be.
	myKeyMaster := NULL.
	myAuthor _ NULL.
	amWaiting := false.
	myStatusDetectors := NULL.
	myRevisionDetectors := NULL.
	myKeyMaster := NULL.! !

!FeWork methodsFor: 'destruct'!

{void} destruct

	myBeWork removeFeRangeElement: self.
	myBeWork tryUnlock: self.
	myKeyMaster ~~ NULL ifTrue:
		[myKeyMaster unregisterWork: self].
	super destruct.! !

!FeWork methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'Work('
		<< 'ids: ' << (FeServer iDsOf: self).
	self canRead ifTrue:
		[oo << ' contents: ' << self edition].
	self canRevise ifTrue:
		[oo << ' (grabbed)'].
	oo << ')'! !

!FeWork methodsFor: 'accessing'!

{FeRangeElement} again
	
	self thingToDo. "deal with work consolidation"
	^self!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement} 
	
	self unimplemented. "deal with work consolidation"! !

!FeWork methodsFor: 'smalltalk: passe'!

{void} addSponsors: clubs {IDRegion}

	self passe "sponsor"!

{ID} currentAuthor

	self passe "grabber"!

{void} lock

	self passe!

{ID} lockingClub
	
	self passe.!

{void} removeSponsors: clubs {IDRegion}

	self passe!

{void} requestLock
	"Essential.  Registers a request so that the next time this Work would have been unlocked and the KeyMaster has edit permission, it will be locked by this client. If this client already has it locked, then it has no effect. To find out when this happens, place Status Detectors on the Work."
	
	self passe.
	amWaiting := true.
	self updateStatus.!

{void} setKeyMaster: km {FeKeyMaster | NULL}
	"Essential.  Change the authority through which the Work is being read and revised. Blasts if the Work is locked and the new authority is insufficient to maintain the lock."
	
	self passe.  "Subsumed by grab"
	"Check that the new authority can maintain existing lock"
	(self canRevise and: [km == NULL or: [(myBeWork canBeEditedBy: km) not]])
		ifTrue: [Heaper BLAST: #MustHaveEditPermission].
	self knownBug.  "check the CurrentAuthor."
	"Change the km and check for change in read permission"
	myAuthor _ CurrentAuthor fluidGet.
	myKeyMaster ~~ NULL ifTrue: [myKeyMaster unregisterWork: self].
	myKeyMaster := km.
	myKeyMaster ~~ NULL ifTrue: [myKeyMaster registerWork: self].
	"Update Detectors and cached information"
	self updateStatus!

{void} unendorse: removedEndorsements {CrossRegion}

	self passe "retract"!

{void} unlock
	"Essential.  Release the lock on this Work. Does nothing if it is already unlocked."
	
	self passe.
	(myBeWork tryUnlock: self) ifTrue:
		["Notify all the status detectors"
		myStatusDetectors ~~ NULL ifTrue:
			[myStatusDetectors stepper forEach: [ :stat {FeStatusDetector} |
				stat canRevise: self with: false]]]! !

!FeWork methodsFor: 'history'!

{void} addRevisionDetector: detector {FeRevisionDetector}
	"Essential. Trigger a Detector whenever there is a revision to the Work which the CurrentKeyMaster can see. If this detector has already been added, then the old KeyMaster associated with it is replaced with the CurrentKeyMaster.
	See RevisionDetector::revised (Edition * contents,
		ID * author,
		IntegerVar sequence,
		IntegerVar time)."
	
	myRevisionDetectors == NULL ifTrue:
		[myRevisionDetectors := PrimSet weak: 7 with: (RevisionDetectorExecutor make: self).
		myBeWork addRevisionWatcher: self]
	ifFalse:
		[myRevisionDetectors stepper forEach: [ :pair {Pair} |
			(detector isEqual: pair right) ifTrue:
				[myRevisionDetectors remove: pair]]].
	myRevisionDetectors introduce: (Pair make: CurrentKeyMaster fluidGet with: detector)!

{ID CLIENT} lastRevisionAuthor
	"The ID of the author of the last revision of this Work to its current Edition, or its creation if it hasn't been revised since. The Work must be grabbed, or the CurrentKeyMaster must be able to exercise the authority of the Read, Edit, or History Club."
	
	self canReadHistory ifFalse:
		[Heaper BLAST: #MustHaveReadPermission].
	^myBeWork lastRevisionAuthor!

{IntegerVar CLIENT} lastRevisionNumber
	"The sequence number of the last revision of this Work to its current Edition, or its creation if it hasn't been revised since. The Work must be grabbed, or the CurrentKeyMaster must be able to exercise the authority of the Read, Edit, or History Club."
	
	self canReadHistory ifFalse:
		[Heaper BLAST: #MustHaveReadPermission].
	^myBeWork lastRevisionNumber!

{IntegerVar CLIENT} lastRevisionTime
	"The time of the last revision of this Work to its current Edition, or its creation if it hasn't been revised since. The Work must be grabbed, or the CurrentKeyMaster must be able to exercise the authority of the Read, Edit, or History Club."
	
	self canReadHistory ifFalse:
		[Heaper BLAST: #MustHaveReadPermission].
	^myBeWork lastRevisionTime!

{void} removeLastRevisionDetector
	"Essential. Inform the work that its last revision detector has gone away."
	
	myRevisionDetectors := NULL.
	myBeWork removeRevisionWatcher: self!

{FeRevisionDetector CLIENT} revisionDetector
	"Essential. Return a detector tht will trigger whenever there is a revision to the Work which the CurrentKeyMaster can see.
	See RevisionDetector::revised (Edition * contents,
		ID * author,
		IntegerVar sequence,
		IntegerVar time)."
	
	Dean shouldImplement.
	self addRevisionDetector: NULL.
	^NULL "fodder"!

{FeEdition CLIENT} revisions
	"Return the revision trail of the receiver.  The trail will be empty if no revisions have been recorded. The trail is updated immediately when the Work is revised.
	In order to get the trail, either the Work must be grabbed, or you must be a member of the Read, Edit, or History Clubs."
	
	self knownBug.  "This needs a label."
	self canReadHistory ifFalse:
		[Heaper BLAST: #MustHaveReadPermission].
	^FeEdition on: myBeWork revisions! !

!FeWork methodsFor: 'private:'!

{BooleanVar} canReadHistory
	"self canRead or CurrentKeyMaster has authority of the historyClub"
	| ckm {FeKeyMaster} |
	ckm := CurrentKeyMaster fluidFetch.
	^self canRead
		or: [ckm ~~ NULL
		and: [myBeWork fetchHistoryClub ~~ NULL
		and: [ckm hasAuthority: myBeWork fetchHistoryClub]]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWork class
	instanceVariableNames: ''!

(FeWork getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeWork class methodsFor: 'exceptions: exceptions'!

bomb.ReleaseWork: CHARGE {FeWork wimpy}
	^[(CHARGE quickCast: FeWork) release]! !

!FeWork class methodsFor: 'creation'!

{FeWork CLIENT} make: contents {FeEdition}
	"Essential.  Create a new Work whose initial contents are the given Edition. The reader, editor, owner, sponsor, and KeyMaster come from the fluid environment. If the KeyMaster has edit permission, then the Work is initially grabbed by it.
	Note: This does not assign it a global ID; that must be done separately (see Server::assignID)."
	
	FeKeyMaster assertSponsorship.
	FeKeyMaster assertSignatureAuthority.
	^(CurrentGrandMap fluidGet newWork: contents) makeLockedFeWork!

{FeWork} on: be {BeWork}

	| result {FeWork} |
	result := self create: be.
	be addFeRangeElement: result.
	^result! !

!FeWork class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} addRevisionDetector: detector {PrRevisionDetector}
{void CLIENT} addStatusDetector: detector {PrStatusDetector}
{BooleanVar CLIENT} canRead
{BooleanVar CLIENT} canRevise
{ID CLIENT} editClub
{FeEdition CLIENT} edition
{void CLIENT} endorse: added {CrossRegion}
{CrossRegion CLIENT} endorsements
{void CLIENT} grab
{ID CLIENT} grabber
{ID CLIENT} historyClub
{ID CLIENT} lastRevisionAuthor
{IntegerVar CLIENT} lastRevisionNumber
{IntegerVar CLIENT} lastRevisionTime
{ID CLIENT} readClub
{void CLIENT} release
{void CLIENT} removeEditClub
{void CLIENT} removeReadClub
{void CLIENT} removeRevisionDetector: detector {PrRevisionDetector}
{void CLIENT} removeStatusDetector: detector {PrStatusDetector}
{void CLIENT} requestGrab
{void CLIENT} retract: removed {CrossRegion}
{void CLIENT} revise: newEdition {FeEdition}
{FeEdition CLIENT} revisions
{void CLIENT} setEditClub: club {ID}
{void CLIENT} setHistoryClub: club {ID | NULL}
{void CLIENT} setReadClub: club {ID}
{void CLIENT} sponsor: clubs {IDRegion}
{IDRegion CLIENT} sponsors
{void CLIENT} unsponsor: clubs {IDRegion}
"! !