'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:18 pm'!

XuRangeElement subclass: #XuWork
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuWork comment:
'A persistent identity for a changeable object.'!

(XuWork getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWork methodsFor: 'grab status'!

{XuIntValue} canRead

	"Return whether you have read permission.  If grabbed, returns TRUE (because a grabber can always read); if released, then returns whether the CurrentKeyMaster has sufficient permission to read the work.  (Read or Edit permission is required.)  Does not check any other KeyMasters you may be holding.
	Note: Be careful of synchronization problems, since the permissions may change between when you ask this question and when you try to actually read the Work."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeWork canRead)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} canRevise

	"Return whether the BeWork is grabbed by you through this FeWork.
	Note: Be careful of synchronization problems, since the permissions may change before you try to actually revise it, causing you to lose your grab."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeWork canRevise)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} grab

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
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork grab)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuID} grabber

	"Essential.  If you have edit authority, and someone has the BeWork grabbed, then return the Club ID that was the value of his CurrentAuthor when he grabbed it; otherwise blast.
	Requiring edit authority is appropriate here, because it is exactly editors who are affected by competing grabs, and need to know who has the grab.  Once the BeWork is revised, anyone who can read the current trail can see the revision, but the grab state doesn't necessarily imply that the BeWork will be revised soon, or ever."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeWork grabber)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} release

	"Essential.  Release the grab on this Work; if a requestGrab had been pending, remove it. Does nothing if it is already unlocked."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork release)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} requestGrab

	"Essential.  Registers a request so that the next time this Work would have been released and no other grab requests are outstanding the CurrentKeyMaster (as of making the request) has edit permission, and has signature authority of the CurrentAuthor (as of making the request), it will be grabbed by this FeWork.  If this FeWork already has the Work grabbed, then the request has no effect.  To find out when the grab succeeds, place Status Detectors on the Work.  (If there are competing requestGrabs for a BeWork, the queueing of the requests may not be FIFO, but is starvation-free.)  Note that if you have a requestGrab outstanding on a BeWork through one FeWork, and release a grab you have through another, your requestGrab has no special priority over those of other users."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork requestGrab)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStatusDetector} statusDetector

	"Essential.  Return a detector which will be notified whenever the locking status of this Work changes.
	See FeStatusDetector::grabbed (Work *, ID *) / released (Work *)."
	
	| retVal {XuStatusDetector} |
	(self isBroken) ifTrue:
		[^XuStatusDetector makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStatusDetector makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStatusDetector make: (self getActualFeWork statusDetector)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuWork methodsFor: 'promise access'!

{FeWork} getActualFeWork
	self isBroken
		ifFalse: [^super actualThing cast: FeWork.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuWork methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeWork {FeWork}
	super create: anFeWork.! !

!XuWork methodsFor: 'endorsing'!

{XuVoid} endorse: additionalEndorsements {XuCrossRegion} 

	"Essential.  Adds to the endorsements on this Work. The set of endorsements must be a finite number of (club ID, token ID) pairs. This requires the signature authority of all of the Clubs used to endorse; will blast and do nothing if any of the required authority is lacking. The token IDs must not be named IDs."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(additionalEndorsements isBroken) ifTrue:
		[^XuVoid makeBrokenBy: additionalEndorsements].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork endorse: ((XuPromise getActual: additionalEndorsements) cast: CrossRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} endorsements

	"Essential.  Return all of the endorsements which have been placed on this Work and are not currently retracted.
	(Endorsements are used to filter various operations which return sets of Works.  See FeEdition::rangeTranscluders() for one way to find this work by filtering for its endorsements.)"
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualFeWork endorsements)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} retract: removedEndorsements {XuCrossRegion} 

	"Essential.  Removes endorsements from this Work. This requires the signature authority of all of the Clubs whose endorsements are in the list; will blast and do nothing if any of the required authority is lacking. Ignores all endorsements which you could have removed, but which don't happen to be there right now."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(removedEndorsements isBroken) ifTrue:
		[^XuVoid makeBrokenBy: removedEndorsements].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork retract: ((XuPromise getActual: removedEndorsements) cast: CrossRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuWork methodsFor: 'history'!

{XuID} lastRevisionAuthor

	"The ID of the author of the last revision of this Work to its current Edition, or its creation if it hasn't been revised since. The Work must be grabbed, or the CurrentKeyMaster must be able to exercise the authority of the Read, Edit, or History Club."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeWork lastRevisionAuthor)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} lastRevisionNumber

	"The sequence number of the last revision of this Work to its current Edition, or its creation if it hasn't been revised since. The Work must be grabbed, or the CurrentKeyMaster must be able to exercise the authority of the Read, Edit, or History Club."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeWork lastRevisionNumber)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} lastRevisionTime

	"The time of the last revision of this Work to its current Edition, or its creation if it hasn't been revised since. The Work must be grabbed, or the CurrentKeyMaster must be able to exercise the authority of the Read, Edit, or History Club."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeWork lastRevisionTime)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRevisionDetector} revisionDetector

	"Essential. Return a detector tht will trigger whenever there is a revision to the Work which the CurrentKeyMaster can see.
	See RevisionDetector::revised (Edition * contents,
		ID * author,
		IntegerVar sequence,
		IntegerVar time)."
	
	| retVal {XuRevisionDetector} |
	(self isBroken) ifTrue:
		[^XuRevisionDetector makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRevisionDetector makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRevisionDetector make: (self getActualFeWork revisionDetector)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} revisions

	"Return the revision trail of the receiver.  The trail will be empty if no revisions have been recorded. The trail is updated immediately when the Work is revised.
	In order to get the trail, either the Work must be grabbed, or you must be a member of the Read, Edit, or History Clubs."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeWork revisions)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuWork methodsFor: 'permissions'!

{XuID} editClub

	"Essential.  Return the club which has permission to revise this Work.  Blasts if noone can (i.e. editor has been removed)."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeWork editClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuID} historyClub

	"Essential. Return the club which will be recorded as the initial club for frozen Works in the history trail.  Blasts if there is no trail being generated."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeWork historyClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuID} readClub

	"Essential.  Return the club which has permission to read this Work.  Blasts if the read Club has been removed (in that case, only those who have edit permission can read the Work)."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeWork readClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} removeEditClub

	"Essential.  Irrevocably remove edit permission. Requires ownership authority."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork removeEditClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} removeReadClub

	"Essential.  Irrevocably remove read permission (although you should note that editors are still able to read, if there are any). Requires ownership authority."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork removeReadClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} setEditClub: club {XuID} 

	"Essential.  Change who has edit permission. Requires ownership authority.
	 Aborts if the Work doesn't have an edit Club."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(club isBroken) ifTrue:
		[^XuVoid makeBrokenBy: club].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork setEditClub: ((XuPromise getActual: club) cast: ID))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} setHistoryClub: club {XuID} 

	"Essential.  Change the initial read Club for frozen Works in the trail. Requires ownership authority. Setting it to NULL turns off the recording of history."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(club isBroken) ifTrue:
		[^XuVoid makeBrokenBy: club].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork setHistoryClub: ((XuPromise getActual: club) cast: ID))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} setReadClub: club {XuID} 

	"Essential.  Change who has read permission. Requires ownership authority.
	 Aborts if the works doesn't have a read Club."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(club isBroken) ifTrue:
		[^XuVoid makeBrokenBy: club].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork setReadClub: ((XuPromise getActual: club) cast: ID))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuWork methodsFor: 'sponsoring'!

{XuVoid} sponsor: clubs {XuIDRegion} 

	"Essential.  Add to the list of sponsors of this Work. Requires signature authority of all of the Clubs in the set."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(clubs isBroken) ifTrue:
		[^XuVoid makeBrokenBy: clubs].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork sponsor: ((XuPromise getActual: clubs) cast: IDRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIDRegion} sponsors

	"Essential.  All of the Clubs which are sponsoring this Work to keep it from being discarded.
	What sort of permissions does this require?"
	
	| retVal {XuIDRegion} |
	(self isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIDRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIDRegion make: (self getActualFeWork sponsors)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} unsponsor: clubs {XuIDRegion} 

	"Essential.  End sponsorship of this Work by all of the listed Clubs. Requires signature authority of all of the Clubs in the set, even if they are not currently sponsors.
	Should this use the CurrentKeyMaster? Or the internal KeyMaster if it is grabbed?"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(clubs isBroken) ifTrue:
		[^XuVoid makeBrokenBy: clubs].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork unsponsor: ((XuPromise getActual: clubs) cast: IDRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuWork methodsFor: 'contents'!

{XuEdition} edition

	"Essential.  Return the current Edition.  Succeeds if the Work is already grabbed, or if the CurrentKeyMaster has either Read or Edit permission.
	Note: If this is an unsponsored Work, the Edition might have been discarded, in which case this operation will blast."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeWork edition)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} revise: newEdition {XuEdition} 

	"Essential.  Change the current Edition of this work to newEdition. The Work must be grabbed  The grabber is recorded as the author who made the revision.
	 (This is the fundamental write operation.)"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(newEdition isBroken) ifTrue:
		[^XuVoid makeBrokenBy: newEdition].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWork revise: ((XuPromise getActual: newEdition) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuWork class
	instanceVariableNames: ''!

(XuWork getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWork class methodsFor: 'pseudo-constructors'!

make: anFeWork {FeWork}
	^self create: anFeWork!

{XuWork} makeBroken: problem {Problem star}
	| broke {XuWork} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuWork} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !