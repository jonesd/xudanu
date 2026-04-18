XuPromise subclass: #XuRangeElement
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuRangeElement comment:
'The kinds of objects which can be in the range of Editions.'!

(XuRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRangeElement methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeRangeElement {FeRangeElement}
	super create: anFeRangeElement.! !

!XuRangeElement methodsFor: 'accessing'!

{XuRangeElement} again

	"Essential.  An object reflecting the current identity of this object, in case it is a PlaceHolder that has become something else since it was received from the Server."
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeRangeElement again)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} canMakeIdentical: newIdentity {XuRangeElement} 

	"Essential.  Whether the identity of this object could be changed to the other.
	Does not check whether the CurrentKeyMaster has authority to do it.
	The restrictions on this operation depend on which subclass this is, but in general (except for PlaceHolders) an object can only become another of the same type with the same content."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(newIdentity isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: newIdentity].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeRangeElement canMakeIdentical: ((XuPromise getActual: newIdentity) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuFillDetector} fillDetector

	"Essential.  Return a FillDetector that will be triggered when this RangeElement becomes something other than a PlaceHolder, or immeditely if this RangeElement is not currently a PlaceHolder.
	See FillRangeDetector::filled (RangeElement * newIdentity)."
	
	| retVal {XuFillDetector} |
	(self isBroken) ifTrue:
		[^XuFillDetector makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFillDetector makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFillDetector make: (self getActualFeRangeElement fillDetector)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isIdentical: other {XuRangeElement} 

	"Essential.  Return whether two objects have the same identity on the Server.  Note that this can change over time, if makeIdentical is used.  However, for a given pair of FeRangeElements, it can only change from not being the same to being the same while you are holding onto them."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeRangeElement isIdentical: ((XuPromise getActual: other) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} makeIdentical: newIdentity {XuRangeElement} 

	"Essential.  Change the identity of this object to the other. BLAST if unsuccessful.
	Requires authority of the current owner; if the operation is successful, the owner will appear to change to that of the other object.
	Also requires enough permission on newIdentity to determine, by comparing content, whether the operation would succeed.
	The restrictions on this operation depend on which subclass this is, but in general (except for PlaceHolders) an object can only become another of the same type with the same content."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(newIdentity isBroken) ifTrue:
		[^XuVoid makeBrokenBy: newIdentity].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeRangeElement makeIdentical: ((XuPromise getActual: newIdentity) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuID} owner

	"Essential.  The Club which owns this RangeElement, and has the authority to make it become something else, and to transfer ownership to someone else."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeRangeElement owner)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} setOwner: clubID {XuID} 

	"Essential.  Change the owner; must have the authority of the current owner."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(clubID isBroken) ifTrue:
		[^XuVoid makeBrokenBy: clubID].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeRangeElement setOwner: ((XuPromise getActual: clubID) cast: ID))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} transcluders: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} with: otherTranscluders {XuEdition default: DefaultNull} 

	"All Editions which the CurrentKeyMaster can see, which transclude this RangeElement.
	If a directFilter is given, then the visibleEndorsements on a Edition must match the filter.
	If an indirectFilter is given, then a resulting Edition must be contained in some readable Edition whose visibleEndorsements match the filter.
	If the directContainersOnly flag is set, then a resulting Edition must contain this directly as a RangeElement; otherwise, indirect containment through Editions is allowed.
	If the localPresentOnly flag is set, then only Editions currently known to this Server are guaranteed to end up in the result; otherwise, Editions which come to satisfy the conditions in the future, and those on other Servers, may also be found.
	Equivalent to
		FeServer::current ()->newEditionWith (<any position>, this)
			->rangeTranscluders (NULL, directFilter, indirectFilter, flags, otherTranscluders)."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(directFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: directFilter].
	(indirectFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: indirectFilter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].
	(otherTranscluders isBroken) ifTrue:
		[^XuEdition makeBrokenBy: otherTranscluders].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeRangeElement transcluders: ((XuPromise getActual: directFilter) cast: Filter) with: ((XuPromise getActual: indirectFilter) cast: Filter) with:flags getActualInt32 with: ((XuPromise getActual: otherTranscluders) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} works: filter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} with: otherTranscluders {XuEdition default: DefaultNull} 

	"Essential.  Works which contain this RangeElement and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If localPresentOnly flag is set, then only Works currently known to this Server are returned; otherwise, as new Works come to be known to the Server, they are filled into the resulting Edition.
	If directContainersOnly is set, and this is an Edition, then only Works which are directly on this Edition are returned (and not Works which are on Editions which have this one as sub-Editions).
	{ <k,l,w> | w's contains self, w passes filter}"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].
	(otherTranscluders isBroken) ifTrue:
		[^XuEdition makeBrokenBy: otherTranscluders].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeRangeElement works: ((XuPromise getActual: filter) cast: Filter) with:flags getActualInt32 with: ((XuPromise getActual: otherTranscluders) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRangeElement methodsFor: 'smalltalk: defaults'!

{XuEdition} transcluders

	^self  transcluders: DefaultNull with: DefaultNull with: DefaultZero!

{XuEdition} transcluders: directFilter {XuFilter default: DefaultNull} 

	^self  transcluders: directFilter with: DefaultNull with: DefaultZero!

{XuEdition} transcluders: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} 

	^self  transcluders: directFilter with: indirectFilter with: DefaultZero!

{XuEdition} works

	^self  works: DefaultNull with: DefaultZero with: DefaultNull!

{XuEdition} works: filter {XuFilter default: DefaultNull} 

	^self  works: filter with: DefaultZero with: DefaultNull!

{XuEdition} works: filter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	^self  works: filter with: flags with: DefaultNull! !

!XuRangeElement methodsFor: 'promise access'!

{FeRangeElement} getActualFeRangeElement
	self isBroken
		ifFalse: [^super actualThing cast: FeRangeElement.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuRangeElement methodsFor: 'labelling'!

{XuLabel} label

	"Essential. Return the label attached to this FeRangeElement. (An FeRangeElement holds a BeRangeElement and a label.)  All FeRangeElements have a label attached to them when they are created (in the various Server::newRangeElement operations).  Derived Editions have the same the label as the Edition they were derived from (e.g. the receiver of copy, combine, replace, transformedBy, etc.)  Labels may be available only on Editions in 1.0.  (While this is in force, label() will blast if sent to other kinds of FeEditions.)"
	
	| retVal {XuLabel} |
	(self isBroken) ifTrue:
		[^XuLabel makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuLabel makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuLabel make: (self getActualFeRangeElement label)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRangeElement} relabelled: label {XuLabel} 

	"Essential. Return a new FeRangeElement with the same identity and contents (i.e. holding the same BeRangeElement), but with a different label.  (Get new labels from FeServer::newLabel())"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].
	(label isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: label].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeRangeElement relabelled: ((XuPromise getActual: label) cast: FeLabel))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRangeElement methodsFor: 'smalltalk:'!

{XuEdition} transcluders: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(directFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: directFilter].
	(indirectFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: indirectFilter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeRangeElement transcluders: ((XuPromise getActual: directFilter) cast: Filter) with: ((XuPromise getActual: indirectFilter) cast: Filter) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuRangeElement class
	instanceVariableNames: ''!

(XuRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRangeElement class methodsFor: 'pseudo-constructors'!

make: anFeRangeElement {FeRangeElement}
	^self create: anFeRangeElement!

{XuRangeElement} makeBroken: problem {Problem star}
	| broke {XuRangeElement} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuRangeElement} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

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

XuWork subclass: #XuClub
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuClub comment:
'A persistent Club on the Server.'!

(XuClub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuClub methodsFor: 'promise access'!

{FeClub} getActualFeClub
	self isBroken
		ifFalse: [^super actualThing cast: FeClub.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuClub methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeClub {FeClub}
	super create: anFeClub.! !

!XuClub methodsFor: 'signing'!

{XuVoid} removeSignatureClub

	"Essential.  Irrevocably remove signature authority for this Club. Requires ownership authority."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeClub removeSignatureClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} setSignatureClub: club {XuID} 

	"Essential.  Change who has signature authority for this Club. Requires ownership authority.
	 Aborts if the Work doesn't have a signature Club."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(club isBroken) ifTrue:
		[^XuVoid makeBrokenBy: club].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeClub setSignatureClub: ((XuPromise getActual: club) cast: ID))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuID} signatureClub

	"Essential. The Club which has 'signature authority' for this Club. Members of this Club are allowed to endorse with the ID of this Club, and are allowed to use it to sponsor resources. BLASTs if it has been removed"
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeClub signatureClub)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuClub methodsFor: 'managing storage'!

{XuEdition} sponsoredWorks: filter {XuFilter default: DefaultNull} 

	"Essential.  All of the Works sponsored by this Club. If a Filter is given, then restricts the result to Works which pass the filter. The result can be wrapped with a Set. This does not require any permissions."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeClub sponsoredWorks: ((XuPromise getActual: filter) cast: Filter))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuClub methodsFor: 'smalltalk: defaults'!

{XuEdition} sponsoredWorks

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeClub sponsoredWorks)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuClub class
	instanceVariableNames: ''!

(XuClub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuClub class methodsFor: 'pseudo-constructors'!

make: anFeClub {FeClub}
	^self create: anFeClub!

{XuClub} makeBroken: problem {Problem star}
	| broke {XuClub} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuClub} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuRangeElement subclass: #XuDataHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuDataHolder comment:
'The kind of FeRangeElement that represents a piece of data in the Server, along with its identity.'!

(XuDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuDataHolder methodsFor: 'promise access'!

{FeDataHolder} getActualFeDataHolder
	self isBroken
		ifFalse: [^super actualThing cast: FeDataHolder.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuDataHolder methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeDataHolder {FeDataHolder}
	super create: anFeDataHolder.! !

!XuDataHolder methodsFor: 'client accessing'!

{XuValue} value

	"Essential.  The actual data value"
	
	| retVal {XuValue} |
	(self isBroken) ifTrue:
		[^XuValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuValue make: (self getActualFeDataHolder value)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuDataHolder class
	instanceVariableNames: ''!

(XuDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuDataHolder class methodsFor: 'pseudo-constructors'!

make: anFeDataHolder {FeDataHolder}
	^self create: anFeDataHolder!

{XuDataHolder} makeBroken: problem {Problem star}
	| broke {XuDataHolder} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuDataHolder} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuRangeElement subclass: #XuLabel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuLabel comment:
'An identity attached to a RangeElement within an Edition.'!

(XuLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLabel methodsFor: 'promise access'!

{FeLabel} getActualFeLabel
	self isBroken
		ifFalse: [^super actualThing cast: FeLabel.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuLabel methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeLabel {FeLabel}
	super create: anFeLabel.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuLabel class
	instanceVariableNames: ''!

(XuLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLabel class methodsFor: 'pseudo-constructors'!

make: anFeLabel {FeLabel}
	^self create: anFeLabel!

{XuLabel} makeBroken: problem {Problem star}
	| broke {XuLabel} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuLabel} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuRangeElement subclass: #XuEdition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuEdition comment:
'The kind of FeRangeElement that consists of an immutable organization of RangeElements, indexed by Positions in some CoordinateSpace.
 R1 prohibits cyclic containment.

Set notation is used in the comments documenting some of the methods of this class.  In each case the cleartext explanation stands alone, and the set notation is a separate, more formal, expression of the actions of the method, in terms of key(position)/label/value triples ("<k,l,v>").'!

(XuEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuEdition methodsFor: 'accessing'!

{XuCoordinateSpace} coordinateSpace

	"Return the space in which the positions of this Edition are positions. Equivalent to
		this->domain ()->coordinateSpace ()"
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualFeEdition coordinateSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} cost: method {XuIntValue} 

	"Essential. Retiurn how much space this Edition is taking up on the disk, in bytes (but the precision may exceed the accuracy; it's simply a well-known unit). The method determines how material shared with other Editions is treated: if omitShared, it is not counted at all; if prorateShared, then it is divided evenly among the Editions sharing it; if totalShared, its entire cost is counted. This figure is only approximate, and may vary with time.
	(No permissions are required to obtain this informiation, even though it exposes sharing by Editions you can't read to traffic analysis.)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(method isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: method].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeEdition cost:method getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} count

	"Return the number of positions in this Edition. Blasts if infinite. Equivalent to
		this->domain ()->count ()"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeEdition count)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} domain

	"Essential.  Return the region consisting of all the positions in this Edition. May be infinite, or empty.
	
	{ k | <k,l,v> in self }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition domain)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRangeElement} get: position {XuPosition} 

	"Return the value at the given position, or blast if there is no such position (i.e. if !! this->domain ()->hasMember (position)).
	
	v : <position,l,v> in self
	requires: <position,l,v> in self"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: position].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeEdition get: ((XuPromise getActual: position) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} hasPosition: position {XuPosition} 

	"Return whether the given position is in the Edition. Equivalent to
		this->domain ()->hasMember (position)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: position].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition hasPosition: ((XuPromise getActual: position) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isEmpty

	"Return whether there are any positions in this Edition. Equivalent to
		this->domain ()->isEmpty ()"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isEmpty)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isFinite

	"Return whether there are a finite number of positions in this Edition. Equivalent to
		this->domain ()->isFinite ()"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isFinite)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} retrieve: region {XuRegion default: DefaultNull} with: order {XuOrderSpec default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	"Essential.  This is the fundamental retrieval operation.  Return a stepper of bundles.  Each bundle is an association between a region in the domain and the range elements associated with that region.  Where the region is associated with data, for instance, the bundle contains a PrimArray of the data elements.
	If a region is given, only that subset of the Edition's contents will be returned.  If it is not given, the entire content of the Edition will be returned.
	if the ignoreTotalOrdering flag is set, then the operation can group non-contiguous regions, and can supply the bundles in any order.
	if the ignoreArrayOrdering flag is set, then ArrayBundles returned by the operation can be ordered differently from the supplied order.
	If an OrderSpec is not supplied, then the ordering will be the default order for the coordinate space, if one exists, and if none exists the returned data will be completely unordered and the Ordering flags will be ignored."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuStepper makeBrokenBy: region].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].
	(flags isBroken) ifTrue:
		[^XuStepper makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeEdition retrieve: ((XuPromise getActual: region) cast: XnRegion) with: ((XuPromise getActual: order) cast: OrderSpec) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} stepper: region {XuRegion default: DefaultNull} with: ordering {XuOrderSpec default: DefaultNull} 

	"Return a stepper for iterating over the positions and RangeElements of this Edition. If a region is specified, then it only iterates over the domain positions which are in the given region. If no ordering is specified, then the default ascending full ordering of the CoordinateSpace is used, or a random order chosen if there is no default."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: region].
	(ordering isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: ordering].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeEdition stepper: ((XuPromise getActual: region) cast: XnRegion) with: ((XuPromise getActual: ordering) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRangeElement} theOne

	"If this Edition has a single position, then return the RangeElement at that position; if not, blasts. Equivalent to
		this->get (this->domain ()->theOne ())"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeEdition theOne)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'smalltalk: defaults'!

{XuRegion} canMakeRangeIdentical: newIdentities {XuEdition} 

	^self  canMakeRangeIdentical: newIdentities with: DefaultNull!

{XuIntValue} isRangeIdentical: other {XuEdition} 

	"This method has no comment."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isRangeIdentical: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} makeRangeIdentical: newIdentities {XuEdition} 

	^self  makeRangeIdentical: newIdentities with: DefaultNull!

{XuEdition} notSharedWith: other {XuEdition} 

	^self  notSharedWith: other with: DefaultZero!

{XuIDRegion} rangeOwners

	^self  rangeOwners: DefaultNull!

{XuEdition} rangeTranscluders

	^self  rangeTranscluders: DefaultNull with: DefaultNull with: DefaultNull!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} 

	^self  rangeTranscluders: positions with: DefaultNull with: DefaultNull!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} 

	^self  rangeTranscluders: positions with: filter with: DefaultNull!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} with: transitiveFilter {XuFilter default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(transitiveFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: transitiveFilter].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeTranscluders: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: filter) cast: Filter) with: ((XuPromise getActual: transitiveFilter) cast: Filter))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	^self  rangeTranscluders: positions with: directFilter with: indirectFilter with: flags with: DefaultNull!

{XuEdition} rangeWorks

	^self  rangeWorks: DefaultNull with: DefaultNull with: DefaultZero!

{XuEdition} rangeWorks: region {XuRegion default: DefaultNull} 

	^self  rangeWorks: region with: DefaultNull with: DefaultZero!

{XuEdition} rangeWorks: region {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} 

	^self  rangeWorks: region with: filter with: DefaultZero!

{XuEdition} rangeWorks: region {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuEdition makeBrokenBy: region].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeWorks: ((XuPromise getActual: region) cast: XnRegion) with: ((XuPromise getActual: filter) cast: Filter) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} retrieve

	^self  retrieve: DefaultNull!

{XuStepper} retrieve: positions {XuRegion default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuStepper makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeEdition retrieve: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} retrieve: positions {XuRegion default: DefaultNull} with: order {XuOrderSpec default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuStepper makeBrokenBy: positions].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeEdition retrieve: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} setRangeOwners: newOwner {XuID} 

	^self  setRangeOwners: newOwner with: DefaultNull!

{XuRegion} sharedRegion: other {XuEdition} 

	^self  sharedRegion: other with: DefaultZero!

{XuEdition} sharedWith: other {XuEdition} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition sharedWith: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} stepper

	"This method has no comment."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeEdition stepper)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} stepper: region {XuRegion default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeEdition stepper: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'operations'!

{XuEdition} combine: other {XuEdition} 

	"Essential.  Return a new FeEdition containing the contents of boththe receiver and the argument Editions, and with the label of the receiving edition; where they share positions, they must have the same RangeElement.  Currently the two may not share positions.  It is unclear whether to elevate this from an implementation restriction to a specification.  The advantage of so specifying is that 'combine' becomes timing independent, i.e. a failing combine could otherwise succeed after the differing range elements were unified (by FeRangeElement::makeIdentical()).  See FeEdition::mapSharedOnto and FeEdition::transformedBy.
	
	{ <k,l,v> | <k,l,v> in self or <k,l,v> in other }
	requires:
		currently: { k | <k,la,v1> in self and <k,lb,v2> in other } is empty
		eventually maybe: { k | v1 not same as v2 
									and <k,la,v1> in self and <k,lb,v2> in other } is empty"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition combine: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} copy: positions {XuRegion} 

	"Return a new FeEdition which is the subset of this Edition with the domain restricted to the given set of positions  The new edition has the same label as this edition.
	
	{ <k,l,v> | k in positions and <k,l,v> in self }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition copy: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} replace: other {XuEdition} 

	"Return a new FeEdition with the label of the current Edition and the contents of both Editions; where they share positions, use the contents and labels of the other Edition. Equivalent to
		this->copy (other->domain ()->complement ())->combine (other).
		
	{ <k,l,v> | <k,l,v> in other or (<k,l,v> in self and <k,l2,v2> not in other }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition replace: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} transformedBy: mapping {XuMapping} 

	"Essential.  Return a new FeEdition containing the contents and label of the current Edition with the positions transformed according to the given Mapping. Where the Mapping takes several positions in the domain to a single position in the range, this Edition must have the same RangeElement and label at all the domain positions.  Currently the mapping must be 'onto', i.e., no more that one domain position may map onto any given range position.  It is unclear whether to elevate this from an implementation restriction to a specification.  See FeEdition::mapSharedOnto and FeEdition::combine.
	
	{ <k2,l1,v1> | <k1,l1,v1> in self and <k1,k2> in mapping }
	requires:
		Currently: not exists k1a, k1b : k1a !!= k1b and <k1a,k2> in mapping and <k1b,k2> in mapping.
		Maybe eventually: for all v1, v2 : <k,l1,v1> in result and <k,l2,v2> in result, v1 is same as v2"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(mapping isBroken) ifTrue:
		[^XuEdition makeBrokenBy: mapping].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition transformedBy: ((XuPromise getActual: mapping) cast: Mapping))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} with: position {XuPosition} with: value {XuRangeElement} 

	"Return a new FeEditionwith the same contents and label as this Edition, except for the addition or substitution of a RangeElement at a specified position.
	(The difference between with() and rebind() is exactly that rebind() preserves the old label at position, while with() installs the label attached to the value argument.)
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWith (position, value))"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuEdition makeBrokenBy: position].
	(value isBroken) ifTrue:
		[^XuEdition makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition with: ((XuPromise getActual: position) cast: Position) with: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} withAll: positions {XuRegion} with: value {XuRangeElement} 

	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are superceded by the value argument.
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWithAll (positions, value))"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(value isBroken) ifTrue:
		[^XuEdition makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition withAll: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} without: position {XuPosition} 

	"Return a new FeEdition with the same contents and label as this Edition, except at a specified position, where the old value and label, if there is one, is removed.
	Equivalent to:
		this->copy (position->asRegion ()->complement ())"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuEdition makeBrokenBy: position].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition without: ((XuPromise getActual: position) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} withoutAll: positions {XuRegion} 

	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are removed.
	Equivalent to
		this->copy (positions->complement ())"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition withoutAll: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'comparing'!

{XuIntValue} isRangeIdentical: other {XuEdition} with: region {XuRegion default: DefaultNull} 

	"Whether the two Editions have the same domains, and each RangeElement isIdentical to the corresponding RangeElement in the other Edition."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].
	(region isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isRangeIdentical: ((XuPromise getActual: other) cast: FeEdition) with: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} mapSharedOnto: other {XuEdition} 

	"Return a mapping such that for each range element that appears in both editions, the mapping maps each of its appearances in the argument edition to some appearance in this one.  (Some of the appearances in this edition may be unmapped or mapped to multiple appearances in the argument edition.)  Like 'mapSharedTo' except that the resulting mapping is 'onto'.  This means that each range position of the resulting mapping inverse maps to at most one domain position.  Such a mapping is suitable as an argument to 'transformedBy', and represents the minimal transformation needed to make the shared part of 'other' from self.  Note that there is no unique answer.
	
	result = { <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2
							and not exists k11 : k11 !!= k1 and <k11,k2> in result }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMapping makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualFeEdition mapSharedOnto: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} mapSharedTo: other {XuEdition} 

	"Essential.  Return a Mapping from each of the positions in this Edition to all of the positions in the other Edition which have the same RangeElement.
	
	{ <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMapping makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualFeEdition mapSharedTo: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} notSharedWith: other {XuEdition} with: flags {XuIntValue default: DefaultZero} 

	"Return a new FeEdition containing exactly the subset of this Edition whose RangeElements are not in the other Edition.
	Equivalent to:
		this->copy (this->sharedRegion (other)->complement ()).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition notSharedWith: ((XuPromise getActual: other) cast: FeEdition) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} positionsOf: value {XuRangeElement} 

	"Return the region consisting of all the positions in this Edition at which the given RangeElement can be found.
	Equivalent to:
		this->sharedRegion (theServer ()->makeEditionWith (some position, value)).
		
	{ k | <k,l,v> in self and v is same as value }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuRegion makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition positionsOf: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} with: otherTranscluders {XuEdition default: DefaultNull} 

	"Essential.  Return a new FeEdition containing all Editions which can be read with the authority of the CurrentKeyMaster, and which transclude RangeElements in this Edition. Immediately returns with an Edition full of PlaceHolders, which will be filled in as results appear; the lookup proceeds asynchronously.
	The Server will attempt to avoid placing duplicate copies in the result, but it may still happen.
	If a Region is given, then the request only considers the subset at those positions (i.e. equivalent to this->copy (positions)->rangeTransclusions (...))
	If a directFilter is given, then the endorsements on the resulting Editions, unioned with the endorsements on any Works directly on those Editions to which the CurrentKeyMaster has read permission, must pass the filter.
	If an indirectFilter is given, then the resulting Editions must be contained, directly or indirectly, by an Edition whose endorsements (unioned with its readable Works endorsements) pass the filter. (Giving a non-NULL indirectFilter will probably not be supported in version 1.0.)
	If the directContainersOnly flag is set, then the result only includes Editions which have the material as RangeElements; otherwise, the result includes Editions which indirectly contain the material through other Editions. (Setting this flag will probably not be supported in version 1.0.)
	If the fromTransitiveContents flag is set, then the result includes transclusions of RangeElements of sub-Editions of this one, in addition to the RangeElements in this Edition. (Setting ths flag will probably not be supported in version 1.0.)
	If localPresentOnly flag is clear, a persistent request will be created, and the new FeEdition will continue to be filled in in the future.  If it is set, only those Editions which are currently known to transclude by this Backend are sure to be recorded into the Trail.  (Some, but not all, Editions which come to transclude while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Editions which come to transclude after the wait completes will be recorded.)
	If otherTranscluders is given, then the results will be recorded into it. (This may increase the chance of the same Edition being recorded twice.)
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(directFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: directFilter].
	(indirectFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: indirectFilter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].
	(otherTranscluders isBroken) ifTrue:
		[^XuEdition makeBrokenBy: otherTranscluders].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeTranscluders: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: directFilter) cast: Filter) with: ((XuPromise getActual: indirectFilter) cast: Filter) with:flags getActualInt32 with: ((XuPromise getActual: otherTranscluders) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rangeWorks: positions {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} with: otherTranscluders {XuEdition default: DefaultNull} 

	"Essential.  Return a new FeEdition containing all Works which contain RangeElements of this Edition and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If the localPresentOnly flag is clear, a persistent request will be created, and as new Works come to be known to the Server, they will be filled into the resulting Edition.  If it is set, only Works currently known to this Server are sure to be recorded into the Trail.  (Some, but not all, Works which become known while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Works which become known after the wait completes will be recorded.)
	If the fromTransitiveContents flag is set, then the result includes Works which contain RangeElements transitively contained in this Edition. (This may not be supported in 1.0)
	If directContainersOnly is set, then only Works which are directly on Editions which are RangeElements of this Edition are returned (and not Works which are on Editions which have them as sub-Editions).
	If otherTranscluders is given, this records works into that trail.
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)
	
	{ <k,l,w> | w's contains self, w passes filter}"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].
	(otherTranscluders isBroken) ifTrue:
		[^XuEdition makeBrokenBy: otherTranscluders].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeWorks: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: filter) cast: Filter) with:flags getActualInt32 with: ((XuPromise getActual: otherTranscluders) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} sharedRegion: other {XuEdition} with: flags {XuIntValue default: DefaultZero} 

	"Return the subset of the positions of this Edition which  have RangeElements that are in the other Edition.
	If nestThis flag is set, then returns not only positions of RangeElements which are in the other, but also positions of Editions which have RangeElements which are in the other, or which have other such Editions, recursively.  (This searches down to, but not across, work boundaries.)
	If nestOther flag is set, then looks not only for RangeElements which are values of the other Edition, but also those which are values of sub-Editions of the other Edition. (This option will probably not be supported in version 1.0).
	If both flags are false, then equivalent to:
		this->mapSharedTo (other)->domain ()
	
	{ k1 | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuRegion makeBrokenBy: other].
	(flags isBroken) ifTrue:
		[^XuRegion makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition sharedRegion: ((XuPromise getActual: other) cast: FeEdition) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} sharedWith: other {XuEdition} with: flags {XuIntValue default: DefaultZero} 

	"Essential.  Return a new FeEdition consisting of the subset of this Edition whose RangeElements are in the other Edition. If the same RangeElement is in this Edition at several different positions, all positions will be in the result (provided the RangeElement is also in the other Edition).
	Equivalent to:
		this->copy (this->sharedRegion (other, flags)).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition sharedWith: ((XuPromise getActual: other) cast: FeEdition) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'endorsing'!

{XuVoid} endorse: additionalEndorsements {XuCrossRegion} 

	"Essential.  Adds to the endorsements on this Edition.  The region of additionalEndorsements must consist of a finite number of (club ID, token ID) pairs.  CurrentKeyMaster must hold the signature authority of all the Clubs used to endorse; the request will blast and do nothing if any of the required authority is lacking.  (Redoing an endorse() undoes a retract())"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(additionalEndorsements isBroken) ifTrue:
		[^XuVoid makeBrokenBy: additionalEndorsements].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeEdition endorse: ((XuPromise getActual: additionalEndorsements) cast: CrossRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} endorsements

	"Essential.  Return all of the endorsements which have been placed on this Edition and not retracted."
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualFeEdition endorsements)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} retract: endorsements {XuCrossRegion} 

	"Essential.  Removes endorsements from this Edition.  This requires that the CurrentKeyMaster hold signature authority for all of the Clubs whose endorsements are in the list; will blast and do nothing if any of the required authority is lacking, even if the endorsements weren't there to be retracted.  Ignores all endorsements which you could have removed, but which don't happen to be there right now.
	
	In the current release removed endorsements aren't preserved, so they vanish forever.  Beginning in some future release removed endorsements will become inactive, but it will be possible to detect that they once had been present.  The intent is for a removed endorsement to be analogous to a signature that has been struck out.  You can express that you changed your mind, but you can't undo the past."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(endorsements isBroken) ifTrue:
		[^XuVoid makeBrokenBy: endorsements].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeEdition retract: ((XuPromise getActual: endorsements) cast: CrossRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} visibleEndorsements

	"Essential.  Return all the unretracted endorsements on this Edition along with those on any Works directly on it which the CurrentKeyMaster has permission to read."
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualFeEdition visibleEndorsements)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'becoming'!

{XuRegion} canMakeRangeIdentical: newIdentities {XuEdition} with: positions {XuRegion default: DefaultNull} 

	"Essential.  Return the region consisting of all locations at which my RangeElements can NOT be made identical to the corresponding RangeElements in the other Edition. (This seems like the opposite of what you want, but in fact it makes it easy to check for success.)
	Does not check whether you have permissions to do so, just whether it could be done by someone with the appropriate permissions. See rangeOwners."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(newIdentities isBroken) ifTrue:
		[^XuRegion makeBrokenBy: newIdentities].
	(positions isBroken) ifTrue:
		[^XuRegion makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition canMakeRangeIdentical: ((XuPromise getActual: newIdentities) cast: FeEdition) with: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuFillRangeDetector} fillRangeDetector

	"Essential.  Return a FillRangeDetector so that when any of the PlaceHolders in this Edition become any other kind of RangeElement, then the Detector will be triggered with an Edition containing the new RangeElements (but not necessarily at the same positions, or even in the same CoordinateSpace). If there already are non-PlaceHolders, then the Detector is triggered immediately with those RangeElements.
	See FillRangeDetector::allFilled (Edition * newIdentities)."
	
	| retVal {XuFillRangeDetector} |
	(self isBroken) ifTrue:
		[^XuFillRangeDetector makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFillRangeDetector makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFillRangeDetector make: (self getActualFeEdition fillRangeDetector)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} makeRangeIdentical: newIdentities {XuEdition} with: positions {XuRegion default: DefaultNull} 

	"Essential.  Try to change the identity of each RangeElements of this Edition which are in the Region (or all if no Region supplied) to that of the RangeElement at the same position in the other Edition. Returns the subset of this Edition which did not end up with the new identities, because of
		- lack of ownership authority
		- different contents
		- contents of other edition unreadable
		- incompatible types
		- no corresponding new identity
		
Note that the labels on the RangeElements need not match and will NOT be changed."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(newIdentities isBroken) ifTrue:
		[^XuEdition makeBrokenBy: newIdentities].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition makeRangeIdentical: ((XuPromise getActual: newIdentities) cast: FeEdition) with: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIDRegion} rangeOwners: positions {XuRegion default: DefaultNull} 

	"The owners of all the RangeElements in the given Region, or in the entire 
	Edition if no Region is specified."
	
	| retVal {XuIDRegion} |
	(self isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIDRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIDRegion make: (self getActualFeEdition rangeOwners: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} setRangeOwners: newOwner {XuID} with: region {XuRegion default: DefaultNull} 

	"Changes the owner of all RangeElements in the Edition (but not the Edition itself!!); requires the authority of the current owner of each range element. If a Region is supplied, then only sets those in the region.
	Returns the subset of this Edition which is in the Region whose owners did not end up being the new Owner because of lack of authority."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(newOwner isBroken) ifTrue:
		[^XuEdition makeBrokenBy: newOwner].
	(region isBroken) ifTrue:
		[^XuEdition makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition setRangeOwners: ((XuPromise getActual: newOwner) cast: ID) with: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'promise access'!

{FeEdition} getActualFeEdition
	self isBroken
		ifFalse: [^super actualThing cast: FeEdition.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuEdition methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeEdition {FeEdition}
	super create: anFeEdition.! !

!XuEdition methodsFor: 'labelling'!

{XuRegion} positionsLabelled: label {XuLabel} 

	"Return a region consisting of exactly the positions in this Edition which are associated with the given label.
	
	{ k | <k,label,v> in self }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(label isBroken) ifTrue:
		[^XuRegion makeBrokenBy: label].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition positionsLabelled: ((XuPromise getActual: label) cast: FeLabel))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rebind: position {XuPosition} with: edition {XuEdition} 

	"Return a new FeEdition which is a copy of this Edition with the contained Edition at the given position replaced by the given Edition, but with the Label at that position unchanged.  Equivalent to
		this->with (position, edition->relabelled (this->get (position)->label ())).

	Note that rebind() is useless (and blasts) when a non-edition RangeElement is at the given position.
		
	{ <k,l,v> | ((k isEqual: position) and (v is same as edition)) 
				or (<k,l,v> in self and k !!= position) }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuEdition makeBrokenBy: position].
	(edition isBroken) ifTrue:
		[^XuEdition makeBrokenBy: edition].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rebind: ((XuPromise getActual: position) cast: Position) with: ((XuPromise getActual: edition) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuEdition class
	instanceVariableNames: ''!

(XuEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuEdition class methodsFor: 'pseudo-constructors'!

make: anFeEdition {FeEdition}
	^self create: anFeEdition!

{XuEdition} makeBroken: problem {Problem star}
	| broke {XuEdition} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuEdition} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuRangeElement subclass: #XuIDHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuIDHolder comment:
'An object for having an ID in the range of an Edition. Tentative feature.'!

(XuIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIDHolder methodsFor: 'promise access'!

{FeIDHolder} getActualFeIDHolder
	self isBroken
		ifFalse: [^super actualThing cast: FeIDHolder.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIDHolder methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeIDHolder {FeIDHolder}
	super create: anFeIDHolder.! !

!XuIDHolder methodsFor: 'accessing'!

{XuID} iD

	"Essential.  The ID in this holder."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeIDHolder iD)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIDHolder class
	instanceVariableNames: ''!

(XuIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIDHolder class methodsFor: 'pseudo-constructors'!

make: anFeIDHolder {FeIDHolder}
	^self create: anFeIDHolder!

{XuIDHolder} makeBroken: problem {Problem star}
	| broke {XuIDHolder} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIDHolder} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

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

Tester subclass: #VolumeTester
	instanceVariableNames: 'myConnection {Connection NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(VolumeTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #SMALLTALK.ONLY; yourself)!

!VolumeTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	| server file protoArray count chunk result  stepper |
	Dean shouldImplement. "bring this up to date"
	
	myConnection := Connection make: FeServer.
	server _ myConnection bootHeaper.
	
	protoArray _ UInt8Array basicNew.
	file _ (Filename named: 'base.cha') readStream.
	result _ FeEdition empty: IntegerSpace make.
	
	[count _ 0.
	chunk _ 41000.
	50 timesRepeat:
		[| data {UInt8Array} |
		oo << count << '
'.
		data _ file next: chunk.
		data changeClassToThatOf: protoArray.
		result _ result combine: 
			((server newEdition: data) transformedBy: (IntegerMapping make: count)).
		count _ count + chunk].
	result domain.
	stepper _ RandomStepper make: 389.
	
	120 timesRepeat: 
		[| start {IntegerVar} stop {IntegerVar} region {XnRegion} |
		start _ stepper value \\ count.
		stepper step.
		stop _ stepper value \\ count.
		stepper step.
		region _ IntegerRegion make: start with: stop.
		oo << region << '
'.
		result copy: region].
	
	200 timesRepeat: 
		[| start {IntegerVar} stop {IntegerVar} region {XnRegion} |
		start _ stepper value \\ count.
		stepper step.
		stop _ stepper value \\ 30000.
		stop > count ifTrue: [stop _ count].
		stepper step.
		region _ IntegerRegion make: start with: stop.
		oo << region << '
'.
		result retrieve: region with: NULL]]
	valueNowOrOnUnwindDo: [file close]! !

!VolumeTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !

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

FeStatusDetector subclass: #WorksTestStatusDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTestStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestStatusDetector methodsFor: 'triggering'!

{void} grabbed: work {FeWork} with: author {ID} with: reason {IntegerVar}

	[myOutput << myTag << ' canRevise (' << author << ')
'] smalltalkOnly.
	'(*myOutput) << myTag << " canRevise (" << author << ")\n";' translateOnly.!

{void} released: work {FeWork} with: reason {IntegerVar}

	[myOutput << myTag << ' released
'] smalltalkOnly.
	'(*myOutput) << myTag << " released\n";' translateOnly! !

!WorksTestStatusDetector methodsFor: 'private: create'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksTestStatusDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTestStatusDetector class
	instanceVariableNames: ''!

(WorksTestStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestStatusDetector class methodsFor: 'pseudo constructors'!

{FeStatusDetector} make: oo {ostream reference} with: tag {Character star}

	^self create: oo with: tag.! !

XnExecutor subclass: #StatusDetectorExecutor
	instanceVariableNames: 'myWork {FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
StatusDetectorExecutor comment:
'This class informs its work when its last status detector has gone away.'!

(StatusDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!StatusDetectorExecutor methodsFor: 'executing'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myWork removeLastStatusDetector]! !

!StatusDetectorExecutor methodsFor: 'protected: create'!

create: work {FeWork}
	super create.
	myWork := work.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StatusDetectorExecutor class
	instanceVariableNames: ''!

(StatusDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!StatusDetectorExecutor class methodsFor: 'create'!

{XnExecutor} make: work {FeWork}
	^ self create: work! !

XuPromise subclass: #XuKeyMaster
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuKeyMaster comment:
'A KeyMaster provides the authority, or "holds the keys", for a client`s activities on the BackEnd. A client can have any number of different KeyMasters, each with different authority. FeServer_login (if successful) gives you back a KeyMaster with the authority of a single Club (along with all the Clubs of which it is a member, directly or indirectly). This will give you appropriate authority to do anything permitted to that Club. You can incorporate the authority of other KeyMasters into it, so that it will additionally enable you to do anything the other KeyMasters would have enabled.'!

(XuKeyMaster getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuKeyMaster methodsFor: 'promise access'!

{FeKeyMaster} getActualFeKeyMaster
	self isBroken
		ifFalse: [^super actualThing cast: FeKeyMaster.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuKeyMaster methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeKeyMaster {FeKeyMaster}
	super create: anFeKeyMaster.! !

!XuKeyMaster methodsFor: 'authority'!

{XuIDRegion} actualAuthority

	"Essential.  The Clubs whose authority is actually being held right now. This may change asynchronously when you or others change the membership lists of clubs.  It is my loginAuthority plus all clubs that list any of these clubs as members, transitively."
	
	| retVal {XuIDRegion} |
	(self isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIDRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIDRegion make: (self getActualFeKeyMaster actualAuthority)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuKeyMaster} copy

	"Essential.  A different KeyMaster with the same login and actual authority as this one."
	
	| retVal {XuKeyMaster} |
	(self isBroken) ifTrue:
		[^XuKeyMaster makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuKeyMaster makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuKeyMaster make: (self getActualFeKeyMaster copy)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} hasAuthority: clubID {XuID} 

	"Whether this KeyMaster is currently holding the authority of the given Club. Equivalent to
		this->actualAuthority ()->hasMember (clubID)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(clubID isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: clubID].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeKeyMaster hasAuthority: ((XuPromise getActual: clubID) cast: ID))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} incorporate: other {XuKeyMaster} 

	"Essential.  Add the other KeyMaster's login and actual authorities to my own respective authorities."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuVoid makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeKeyMaster incorporate: ((XuPromise getActual: other) cast: FeKeyMaster))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIDRegion} loginAuthority

	"Essential.  The Clubs whose authority was obtained directly, by logging in to them. They are the ones from which all other authority is derived."
	
	| retVal {XuIDRegion} |
	(self isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIDRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIDRegion make: (self getActualFeKeyMaster loginAuthority)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} removeLogins: oldLogins {XuIDRegion} 

	"Essential.  Remove the listed IDs from the set of Clubs whose login authority I exercise.  All authority derived from them that cannot be derived from the remaining login authority will also disappear.  Listed Clubs for which I do not hold login authority will be silently ignored."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(oldLogins isBroken) ifTrue:
		[^XuVoid makeBrokenBy: oldLogins].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeKeyMaster removeLogins: ((XuPromise getActual: oldLogins) cast: IDRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuKeyMaster class
	instanceVariableNames: ''!

(XuKeyMaster getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuKeyMaster class methodsFor: 'pseudo-constructors'!

make: anFeKeyMaster {FeKeyMaster}
	^self create: anFeKeyMaster!

{XuKeyMaster} makeBroken: problem {Problem star}
	| broke {XuKeyMaster} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuKeyMaster} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

FeFillRangeDetector subclass: #WorksTestFillRangeDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTestFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillRangeDetector methodsFor: 'triggering'!

{void} rangeFilled: transclusions {FeEdition}

	[myOutput << myTag << transclusions << '
'] smalltalkOnly.
	'(*myOutput) << myTag << transclusions << "\n";' translateOnly.! !

!WorksTestFillRangeDetector methodsFor: 'private: create'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksTestFillRangeDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTestFillRangeDetector class
	instanceVariableNames: ''!

(WorksTestFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillRangeDetector class methodsFor: 'pseudo constructors'!

{FeFillRangeDetector} make: oo {ostream reference} with: tag {Character star}

	^self create: oo with: tag.! !

Heaper subclass: #FeRangeElement
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeRangeElement comment:
'The kinds of objects which can be in the range of Editions.'!

(FeRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeRangeElement methodsFor: 'smalltalk: defaults'!

{FeEdition CLIENT} works
	
	^self works: NULL with: 0 with: NULL!

{FeEdition CLIENT} works: filter {Filter default: NULL}
	
	^self works: filter with: 0 with: NULL!

{FeEdition CLIENT} works: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self works: filter with: flags with: NULL! !

!FeRangeElement methodsFor: 'accessing'!

{void} addFillDetector: detector {FeFillDetector}
	"Essential.  When this PlaceHolder becomes any other kind of RangeElement, then the Detector will be triggered with the new RangeElement. If this is already not a PlaceHolder, then the Detector is triggered immediately with this RangeElement.
	See FillRangeDetector::filled (RangeElement * newIdentity)."
	
	detector filled: self. "default will be overridden in FePlaceHolder"!

{FeRangeElement CLIENT} again
	"Essential.  An object reflecting the current identity of this object, in case it is a PlaceHolder that has become something else since it was received from the Server."
	
	self subclassResponsibility!

{BooleanVar CLIENT} canMakeIdentical: newIdentity {FeRangeElement}
	"Essential.  Whether the identity of this object could be changed to the other.
	Does not check whether the CurrentKeyMaster has authority to do it.
	The restrictions on this operation depend on which subclass this is, but in general (except for PlaceHolders) an object can only become another of the same type with the same content."
	
	RaviNow shouldImplement.
	^false "fodder"!

{FeFillDetector CLIENT} fillDetector
	"Essential.  Return a FillDetector that will be triggered when this RangeElement becomes something other than a PlaceHolder, or immeditely if this RangeElement is not currently a PlaceHolder.
	See FillRangeDetector::filled (RangeElement * newIdentity)."
	
	Dean shouldImplement.
	self addFillDetector: NULL.
	^NULL "fodder"!

{BooleanVar CLIENT} isIdentical: other {FeRangeElement}
	"Essential.  Return whether two objects have the same identity on the Server.  Note that this can change over time, if makeIdentical is used.  However, for a given pair of FeRangeElements, it can only change from not being the same to being the same while you are holding onto them."
	
	other cast: FeVirtualDataHolder into: [ :vd |
		^vd isIdentical: self]
	cast: FeVirtualPlaceHolder into: [ :vp |
		^vp isIdentical: self]
	others:
		["This should be OK, since virtual subclasses override this anyway"
		^self getOrMakeBe isEqual: other getOrMakeBe].
	^false "fodder"!

{void CLIENT} makeIdentical: newIdentity {FeRangeElement}
	"Essential.  Change the identity of this object to the other. BLAST if unsuccessful.
	Requires authority of the current owner; if the operation is successful, the owner will appear to change to that of the other object.
	Also requires enough permission on newIdentity to determine, by comparing content, whether the operation would succeed.
	The restrictions on this operation depend on which subclass this is, but in general (except for PlaceHolders) an object can only become another of the same type with the same content."
	
	self subclassResponsibility!

{ID CLIENT} owner
	"Essential.  The Club which owns this RangeElement, and has the authority to make it become something else, and to transfer ownership to someone else."
	
	^self getOrMakeBe owner "virtuals should override"!

{void} removeFillDetector: detector {FeFillDetector}
	"Essential.  Remove a Detector which had been added to this RangeElement. You should remove every Detector you add, although they will go away automatically when a client session terminates."
	
	||
	"Do nothing. PlaceHolder overrides"!

{void CLIENT} setOwner: clubID {ID}
	"Essential.  Change the owner; must have the authority of the current owner."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) ifFalse:
		[Heaper BLAST: #MustBeOwner].
	"Need to make it into a reified range element in order to have distinct ownership"
	
	CurrentGrandMap fluidGet getClub: clubID.  "Checks that it is a club."
	self getOrMakeBe setOwner: clubID!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"All Editions which the CurrentKeyMaster can see, which transclude this RangeElement.
	If a directFilter is given, then the visibleEndorsements on a Edition must match the filter.
	If an indirectFilter is given, then a resulting Edition must be contained in some readable Edition whose visibleEndorsements match the filter.
	If the directContainersOnly flag is set, then a resulting Edition must contain this directly as a RangeElement; otherwise, indirect containment through Editions is allowed.
	If the localPresentOnly flag is set, then only Editions currently known to this Server are guaranteed to end up in the result; otherwise, Editions which come to satisfy the conditions in the future, and those on other Servers, may also be found.
	Equivalent to
		FeServer::current ()->newEditionWith (<any position>, this)
			->rangeTranscluders (NULL, directFilter, indirectFilter, flags, otherTranscluders)."
	
	^(FeEdition fromOne: IntegerVarZero integer with: self)
		rangeTranscluders: NULL with: directFilter with: indirectFilter with: flags with: otherTranscluders!

{FeEdition CLIENT} works: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"Essential.  Works which contain this RangeElement and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If localPresentOnly flag is set, then only Works currently known to this Server are returned; otherwise, as new Works come to be known to the Server, they are filled into the resulting Edition.
	If directContainersOnly is set, and this is an Edition, then only Works which are directly on this Edition are returned (and not Works which are on Editions which have this one as sub-Editions).
	{ <k,l,w> | w's contains self, w passes filter}"
	
	| theFilter {Filter} |
	filter == NULL
		ifTrue: [theFilter := CurrentGrandMap fluidGet endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theFilter := filter].
	Dean thingToDo. "avoid reifying"
	^FeEdition on: (self getOrMakeBe
		works: CurrentKeyMaster fluidGet actualAuthority
		with: theFilter
		with: flags)! !

!FeRangeElement methodsFor: 'server accessing'!

{BeCarrier} carrier
	"Return an object that wraps up any run-time state that might be needed inside the Be system.  Right now that means labels."
	
	^BeCarrier make: self getOrMakeBe!

{BeRangeElement | NULL} fetchBe
	"If this has a reified Be object, then return it, else NULL"
	
	self subclassResponsibility!

{BeRangeElement} getOrMakeBe
	"An individual BeRangeElement for this identity. If the object is virtualized, then de-virtualizes it."
	
	self subclassResponsibility! !

!FeRangeElement methodsFor: 'smalltalk:'!

inspect
	"Sensor leftShiftDown" true
		ifTrue: [self basicInspect]
		ifFalse: [EntView openOn: (TreeBarnacle new
					buildOn: self
					gettingChildren: [:elem | (elem respondsTo: #inspectPieces)
							ifTrue: [elem inspectPieces]
							ifFalse: [#()]]
					gettingImage: [:me | DisplayText text: me displayString asText textStyle: (TextStyle styleNamed: #small)]
					at: 0 @ 0
					vertical: true
					separation: 5 @ 10)]!

{FeEdition CLIENT} transcluders
	^self transcluders: NULL with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	
	^self transcluders: directFilter with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	
	^self transcluders: directFilter with: indirectFilter with: Int32Zero with: NULL!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self transcluders: directFilter with: indirectFilter with: flags with: NULL! !

!FeRangeElement methodsFor: 'labelling'!

{FeLabel CLIENT} label
	"Essential. Return the label attached to this FeRangeElement. (An FeRangeElement holds a BeRangeElement and a label.)  All FeRangeElements have a label attached to them when they are created (in the various Server::newRangeElement operations).  Derived Editions have the same the label as the Edition they were derived from (e.g. the receiver of copy, combine, replace, transformedBy, etc.)  Labels may be available only on Editions in 1.0.  (While this is in force, label() will blast if sent to other kinds of FeEditions.)"
	
	self unimplemented. "default"
	^NULL!

{FeRangeElement CLIENT} relabelled: label {FeLabel}
	"Essential. Return a new FeRangeElement with the same identity and contents (i.e. holding the same BeRangeElement), but with a different label.  (Get new labels from FeServer::newLabel())"
	
	self unimplemented. "default"
	^NULL! !

!FeRangeElement methodsFor: 'smalltalk: passe'!

{BooleanVar} becomeOther: newIdentity {FeRangeElement}

	self passe.	"renamed makeIdentical:"!

{BooleanVar} isSameAs: other {FeRangeElement}

	self passe "isIdentical"! !

!FeRangeElement methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeRangeElement class
	instanceVariableNames: ''!

(FeRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeRangeElement class methodsFor: 'protected:'!

{void} validateEndorsement: endorsements {CrossRegion} with: km {FeKeyMaster} 
	"Check whether the endorsements are valid and authorized.
	 Blast appropriately if not."

	endorsements isFinite ifFalse: [Heaper BLAST: #EndorsementMustBeFinite].
	self validateSignature: ((endorsements projection: Int32Zero) cast: IDRegion)
		with: km!

{void} validateSignature: clubs {IDRegion} with: km {FeKeyMaster} 
	"Check whether the signatures are valid and authorized.
	 Blast appropriately if not."

	clubs isFinite ifFalse: [Heaper BLAST: #MustHaveSignatureAuthority].
	clubs stepper forEach: [ :clubID {ID} |
		(km hasSignatureAuthority: clubID)
			ifFalse: [Heaper BLAST: #MustHaveSignatureAuthority]]! !

!FeRangeElement class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} addFillDetector: detector {PrFillDetector}
{FeRangeElement CLIENT} again
{BooleanVar CLIENT} canMakeIdentical: newIdentity {FeRangeElement}
{BooleanVar CLIENT} isIdentical: other {FeRangeElement}
{FeLabel CLIENT} label
{void CLIENT} makeIdentical: newIdentity {FeRangeElement}
{ID CLIENT} owner
{FeRangeElement CLIENT} relabelled: label {FeLabel}
{void CLIENT} removeFillDetector: detector {PrFillDetector}
{void CLIENT} setOwner: clubID {ID}
{FeEdition CLIENT} transcluders
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL}
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL} with: flags {Int32 default: Int32Zero}
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
{FeEdition CLIENT} works: filter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
"! !

!FeRangeElement class methodsFor: 'creation'!

{FeRangeElement CLIENT} placeHolder
	"Make a single PlaceHolder."
	
	^FePlaceHolder on: CurrentGrandMap fluidGet newPlaceHolder! !

FeRangeElement subclass: #FeDataHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeDataHolder comment:
'The kind of FeRangeElement that represents a piece of data in the Server, along with its identity.'!

(FeDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeDataHolder methodsFor: 'client accessing'!

{FeRangeElement} again

	self subclassResponsibility!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}
	
	"Check that it is data with the same value,
		and check permissions,
		and forward the operation after coercing the newIdentity to a persistent RangeElement."
	
	^((newIdentity isKindOf: FeDataHolder)
			and: [((newIdentity cast: FeDataHolder) value isEqual: self value)])!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Allow consolidation of data in 1st product."
	| ckm {FeKeyMaster} |
	"Check that it is data with the same value,
		and check permissions,
		and forward the operation after coercing the newIdentity to a persistent RangeElement."
	
	self thingToDo. "better blast"
	ckm := CurrentKeyMaster fluidGet.
	((newIdentity isKindOf: FeDataHolder)
			and: [((newIdentity cast: FeDataHolder) value isEqual: self value)
			and: [ckm hasAuthority: self owner]])
		ifTrue: [Heaper BLAST: #CantMakeIdentical].
	self getOrMakeBe makeIdentical: newIdentity getOrMakeBe!

{PrimValue CLIENT} value
	"Essential.  The actual data value"
	
	self subclassResponsibility! !

!FeDataHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	self subclassResponsibility!

{BeRangeElement} getOrMakeBe

	self subclassResponsibility! !

!FeDataHolder methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'DataHolder(' << self value << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeDataHolder class
	instanceVariableNames: ''!

(FeDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeDataHolder class methodsFor: 'creation'!

{FeDataHolder} fake: value {PrimValue}
	with: key {Position}
	with: edition {BeEdition}
	
	^FeVirtualDataHolder create: value with: key with: edition.!

{FeDataHolder CLIENT} make: value {PrimValue}
	"Make a single DataHolder with the given value"
	
	^FeDataHolder on: (CurrentGrandMap fluidGet newDataHolder: value)!

{FeDataHolder} on: be {BeDataHolder}

	| result {FeDataHolder} |
	result := FeActualDataHolder create: be.
	be addFeRangeElement: result.
	^result! !

!FeDataHolder class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimValue CLIENT} value
"! !

FeDataHolder subclass: #FeVirtualDataHolder
	instanceVariableNames: '
		myValue {PrimValue}
		myKey {Position}
		myEdition {BeEdition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeVirtualDataHolder comment:
'Fakes a DataHolder by having an Edition and a key.'!

(FeVirtualDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeVirtualDataHolder methodsFor: 'accessing'!

{FeRangeElement} again
	"Fetch from my Edition again, just in case I've been consolidated."
	
	^myEdition fetch: myKey!

{BooleanVar} isIdentical: other {FeRangeElement}

	"This can do a version comparison (which seems a bit extreme)."
	Dean shouldImplement.
	^false "fodder"!

{ID} owner

	^myEdition ownerAt: myKey!

{PrimValue} value
	^myValue! !

!FeVirtualDataHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^NULL!

{BeRangeElement} getOrMakeBe
	"Force the ent to generate a beRangeElement at myKey."
	
	^myEdition getOrMakeBe: myKey! !

!FeVirtualDataHolder methodsFor: 'private: create'!

create: value {PrimValue}
	with: key {Position}
	with: edition {BeEdition}
	
	super create.
	myValue := value.
	myKey := key.
	myEdition := edition.! !

FeDataHolder subclass: #FeActualDataHolder
	instanceVariableNames: 'myBeDataHolder {BeDataHolder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeActualDataHolder comment:
'Actually has a persistent individual DataHolder on the Server'!

(FeActualDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeActualDataHolder methodsFor: 'client accessing'!

{FeRangeElement} again
	"I'm completely reified.  Just return me."
	
	^self!

{PrimValue} value
	"The actual data value"
	
	^myBeDataHolder value! !

!FeActualDataHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myBeDataHolder!

{BeRangeElement} getOrMakeBe

	^myBeDataHolder! !

!FeActualDataHolder methodsFor: 'private: create'!

create: be {BeDataHolder}

	super create.
	myBeDataHolder := be.! !

!FeActualDataHolder methodsFor: 'destruct'!

{void} destruct

	myBeDataHolder removeFeRangeElement: self.
	super destruct.! !

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

FeWork subclass: #FeClub
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeClub comment:
'A persistent Club on the Server.'!

(FeClub getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeClub */

friend class BeClub;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeClub methodsFor: 'signing'!

{void CLIENT} removeSignatureClub
	"Essential.  Irrevocably remove signature authority for this Club. Requires ownership authority."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	self beClub setSignatureClub: NULL!

{void CLIENT} setSignatureClub: club {ID | NULL}
	"Essential.  Change who has signature authority for this Club. Requires ownership authority.
	 Aborts if the Work doesn't have a signature Club."
	
	Ravi knownBug. "need to updateStatus on Works which are designating me as Author"
	club == NULL ifTrue: [Heaper BLAST: #MustNotBeNull].
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	self beClub fetchSignatureClub == NULL
		ifTrue: [Heaper BLAST: #SignatureClubIrrevocablyRemoved].
	self beClub setSignatureClub: club!

{ID CLIENT} signatureClub
	"Essential. The Club which has 'signature authority' for this Club. Members of this Club are allowed to endorse with the ID of this Club, and are allowed to use it to sponsor resources. BLASTs if it has been removed"
	
	| result {ID} |
	result := self beClub fetchSignatureClub.
	result == NULL ifTrue: [Heaper BLAST: #SignatureClubIrrevocablyRemoved].
	^result! !

!FeClub methodsFor: 'server'!

{BeClub} beClub

	^self fetchBe cast: BeClub! !

!FeClub methodsFor: 'smalltalk: defaults'!

{FeEdition CLIENT} sponsoredWorks

	^self sponsoredWorks: NULL! !

!FeClub methodsFor: 'managing storage'!

{FeEdition CLIENT} sponsoredWorks: filter {Filter default: NULL}
	"Essential.  All of the Works sponsored by this Club. If a Filter is given, then restricts the result to Works which pass the filter. The result can be wrapped with a Set. This does not require any permissions."
	
	| iDSpace {IDSpace} array {PtrArray of: FeWork} index {Int32} |
	array := PtrArray nulls: self beClub sponsored count DOTasLong.
	index := Int32Zero.
	self beClub sponsored stepper forEach: [ :be {BeWork} |
		(filter == NULL or: [filter match: be endorsements]) ifTrue:
			[array at: index store: (FeWork on: be).
			index := index + 1]].
	iDSpace := IDSpace unique.
	index < array count ifTrue:
		[array := (array copy: index) cast: PtrArray].
	^FeEdition on: (CurrentGrandMap fluidGet
		newValueEdition: array
		with: (iDSpace newIDs: array count)
		with: iDSpace getAscending)! !

!FeClub methodsFor: 'private: create'!

create: be {BeClub}

	super create: be.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeClub class
	instanceVariableNames: ''!

(FeClub getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeClub */

friend class BeClub;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeClub class methodsFor: 'creation'!

{FeClub CLIENT} make: status {FeEdition}
	"Essential.  Create a new Club whose initial status is described in the given ClubDescription Edition. The reader, editor and owner are taken from the current settings. If the KeyMaster has edit permission, then the Club Work is initially grabbed by it. The Club Work is initially sponsored by the CurrentSponsor.
	Note: Unlike ordinary Works, a newly created Club is assigned a global ID."
	
	FeKeyMaster assertSponsorship.
	FeKeyMaster assertSignatureAuthority.
	^(CurrentGrandMap fluidGet newClub: status) makeLockedFeWork cast: FeClub!

{FeClub} on: be {BeClub}

	| result {FeClub} |
	result := self create: be.
	be addFeRangeElement: result.
	^result! !

!FeClub class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} removeSignatureClub
{void CLIENT} setSignatureClub: club {ID}
{ID CLIENT} signatureClub
{FeEdition CLIENT} sponsoredWorks: filter {Filter default: NULL}
"! !

FeRangeElement subclass: #FePlaceHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FePlaceHolder comment:
'Represents a piece of pure identity in the Server.'!

(FePlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FePlaceHolder methodsFor: 'accessing'!

{void} addFillDetector: detector {FeFillDetector}

	self getOrMakeBe cast: BePlaceHolder into: [ :p |
		p addDetector: detector]
	others:
		["in case it changed behind our backs"
		detector filled: self again]!

{FeRangeElement} again

	self subclassResponsibility!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	self subclassResponsibility!

{void} makeIdentical: newIdentity {FeRangeElement}

	self subclassResponsibility! !

!FePlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	self subclassResponsibility!

{BeRangeElement} getOrMakeBe

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePlaceHolder class
	instanceVariableNames: ''!

(FePlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FePlaceHolder class methodsFor: 'creation'!

{FePlaceHolder} fake: edition {BeEdition} with: key {Position}

	^FeVirtualPlaceHolder create: edition with: key!

{FePlaceHolder} on: be {BeRangeElement}

	| result {FeRangeElement} |
	result := FeActualPlaceHolder create: be.
	be addFeRangeElement: result.
	^result cast: FePlaceHolder! !

!FePlaceHolder class methodsFor: 'smalltalk: passe'!

{FePlaceHolder} grand: iD {ID}

	self passe.! !

FePlaceHolder subclass: #FeGrandPlaceHolder
	instanceVariableNames: 'myID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeGrandPlaceHolder comment:
'Fakes a PlaceHolder in the GrandMap by just remembering the key.'!

(FeGrandPlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #SMALLTALK.ONLY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeGrandPlaceHolder methodsFor: 'client accessing'!

{FeRangeElement} again

	^CurrentGrandMap fluidGet getOrMakeFe: myID!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Consolidate this PlaceHolder to the newIdentity.  Return true if successful."

	"Check permissions
		and then try storing the other guy into the grandMap."
	self thingToDo.  "This doesn't need to force newIdentity into a BeRangeElement."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner)
		ifFalse: [Heaper BLAST: #MustBeOwner].
	(CurrentGrandMap fluidGet at: myID tryIntroduce: newIdentity getOrMakeBe)
		ifFalse: [Heaper BLAST: #CantMakeIdentical]!

{ID} owner

	"Ask the GrandMap who owns this ID"
	^CurrentGrandMap fluidGet placeOwnerID: myID!

{void} removeFillDetector: detector {FeFillDetector}

	Heaper BLAST: #NotInSet! !

!FeGrandPlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^NULL!

{BeRangeElement} getOrMakeBe
	"Create a new persistent PlaceHolder and register it in the GrandMap."

	| result {BeRangeElement} |
	InitialOwner fluidBind: self owner during:
		[result _ CurrentGrandMap fluidGet newPlaceHolder.
		(CurrentGrandMap fluidGet at: myID tryIntroduce: result)
			ifTrue: [^result]
			ifFalse: [^self again getOrMakeBe]]! !

!FeGrandPlaceHolder methodsFor: 'private: create'!

create: iD {ID}

	super create.
	myID := iD! !

FePlaceHolder subclass: #FeActualPlaceHolder
	instanceVariableNames: 'myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeActualPlaceHolder comment:
'Actually has a persistent individual PlaceHolder on the Server, or used to, and now has a pointer to the rangeElement it became.'!

(FeActualPlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeActualPlaceHolder methodsFor: 'client accessing'!

{FeRangeElement} again

Dean shouldImplement.  "This must hold onto an FeRangeElement so that the label is properly maintained."
	myRangeElement cast: BePlaceHolder into: [:pl | ^self  "No change."]
		others: [^myRangeElement makeFe: NULL].
	^NULL "fodder"!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Consolidate this PlaceHolder to the newIdentity.  Return true if successful."
	
	"Check permissions
		and forward the operation after coercing the newIdentity
		 to a persistent RangeElement."
		
	"myRangeElement will tell me to forward to another RangeElement."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) ifFalse:
		[Heaper BLAST: #MustBeOwner].
	myRangeElement makeIdentical: newIdentity getOrMakeBe!

{ID} owner
	"MyBeRangeElement will know it."
	
	^myRangeElement owner!

{void} removeFillDetector: detector {FeFillDetector}

	(Heaper isDestructed: myRangeElement) ifFalse:
		[myRangeElement cast: BePlaceHolder into: [ :p |
			p removeDetector: detector]
		others: []]! !

!FeActualPlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myRangeElement!

{void} forwardTo: element {BeRangeElement}
	"myRangeElement has become something else.  Forward to the new thing."
	
	myRangeElement removeFeRangeElement: self.
	myRangeElement _ element.
	myRangeElement addFeRangeElement: self.!

{BeRangeElement} getOrMakeBe

	^myRangeElement! !

!FeActualPlaceHolder methodsFor: 'private: create'!

create: be {BeRangeElement}

	super create.
	myRangeElement := be.! !

!FeActualPlaceHolder methodsFor: 'destruct'!

{void} destruct

	myRangeElement removeFeRangeElement: self.
	super destruct.! !

FePlaceHolder subclass: #FeVirtualPlaceHolder
	instanceVariableNames: '
		myEdition {BeEdition}
		myKey {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeVirtualPlaceHolder comment:
'Fakes a PlaceHolder by having an Edition and a key.'!

(FeVirtualPlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeVirtualPlaceHolder methodsFor: 'client accessing'!

{FeRangeElement} again

	^myEdition get: myKey!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Consolidate this PlaceHolder to the newIdentity.  Return true if successful."

	"Check permissions
		and coerce both of us and have the BeRangeElements try."
	self thingToDo.  "This doesn't need to force newIdentity into a BeRangeElement."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner)
		ifFalse: [Heaper BLAST: #MustBeOwner].
	self getOrMakeBe makeIdentical: newIdentity getOrMakeBe!

{ID} owner

	^myEdition ownerAt: myKey!

{void} removeFillDetector: detector {FeFillDetector}

	Heaper BLAST: #NotInSet! !

!FeVirtualPlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^NULL!

{BeRangeElement} getOrMakeBe
	"Force the ent to generate a beRangeElement at myKey."
	
	^myEdition getOrMakeBe: myKey! !

!FeVirtualPlaceHolder methodsFor: 'private: create'!

create: edition {BeEdition} with: key {Position}

	super create.
	myEdition := edition.
	myKey := key! !

FeRangeElement subclass: #FeIDHolder
	instanceVariableNames: 'myBeIDHolder {BeIDHolder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeIDHolder comment:
'An object for having an ID in the range of an Edition. Tentative feature.'!

(FeIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeIDHolder methodsFor: 'accessing'!

{FeRangeElement} again

	^self!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{ID CLIENT} iD
	"Essential.  The ID in this holder."
	
	^myBeIDHolder iD!

{void} makeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented]! !

!FeIDHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myBeIDHolder!

{BeRangeElement} getOrMakeBe

	^myBeIDHolder! !

!FeIDHolder methodsFor: 'private: create'!

create: be {BeIDHolder}

	super create.
	myBeIDHolder := be.! !

!FeIDHolder methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'IDHolder(' << self iD << ')'! !

!FeIDHolder methodsFor: 'destruct'!

{void} destruct

	myBeIDHolder removeFeRangeElement: self.
	super destruct.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeIDHolder class
	instanceVariableNames: ''!

(FeIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeIDHolder class methodsFor: 'creation'!

{FeIDHolder CLIENT} make: iD {ID}
	"Essential. Make a single IDHolder with the given ID. Tentative feature."
	
	^FeIDHolder on: (CurrentGrandMap fluidGet newIDHolder: iD)!

{FeIDHolder} on: be {BeIDHolder}

	| result {FeIDHolder} |
	result := self create: be.
	be addFeRangeElement: result.
	^result! !

!FeIDHolder class methodsFor: 'smalltalk: system'!

info.stProtocol
"{ID CLIENT} iD
"! !

FeRangeElement subclass: #FeEdition
	instanceVariableNames: '
		myBeEdition {BeEdition}
		myLabel {FeLabel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeEdition comment:
'The kind of FeRangeElement that consists of an immutable organization of RangeElements, indexed by Positions in some CoordinateSpace.
 R1 prohibits cyclic containment.

Set notation is used in the comments documenting some of the methods of this class.  In each case the cleartext explanation stands alone, and the set notation is a separate, more formal, expression of the actions of the method, in terms of key(position)/label/value triples ("<k,l,v>").'!

(FeEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeEdition methodsFor: 'operations'!

{FeEdition CLIENT} combine: other {FeEdition}
	"Essential.  Return a new FeEdition containing the contents of boththe receiver and the argument Editions, and with the label of the receiving edition; where they share positions, they must have the same RangeElement.  Currently the two may not share positions.  It is unclear whether to elevate this from an implementation restriction to a specification.  The advantage of so specifying is that 'combine' becomes timing independent, i.e. a failing combine could otherwise succeed after the differing range elements were unified (by FeRangeElement::makeIdentical()).  See FeEdition::mapSharedOnto and FeEdition::transformedBy.
	
	{ <k,l,v> | <k,l,v> in self or <k,l,v> in other }
	requires:
		currently: { k | <k,la,v1> in self and <k,lb,v2> in other } is empty
		eventually maybe: { k | v1 not same as v2 
									and <k,la,v1> in self and <k,lb,v2> in other } is empty"
	
	^FeEdition on: (myBeEdition combine: other beEdition) with: myLabel!

{FeEdition CLIENT} copy: positions {XnRegion}
	"Return a new FeEdition which is the subset of this Edition with the domain restricted to the given set of positions  The new edition has the same label as this edition.
	
	{ <k,l,v> | k in positions and <k,l,v> in self }"
	
	^FeEdition on: (myBeEdition copy: positions) with: myLabel!

{FeEdition CLIENT} replace: other {FeEdition}
	"Return a new FeEdition with the label of the current Edition and the contents of both Editions; where they share positions, use the contents and labels of the other Edition. Equivalent to
		this->copy (other->domain ()->complement ())->combine (other).
		
	{ <k,l,v> | <k,l,v> in other or (<k,l,v> in self and <k,l2,v2> not in other }"
		
	^FeEdition on: (myBeEdition replace: other beEdition) with: myLabel!

{FeEdition CLIENT} transformedBy: mapping {Mapping}
	"Essential.  Return a new FeEdition containing the contents and label of the current Edition with the positions transformed according to the given Mapping. Where the Mapping takes several positions in the domain to a single position in the range, this Edition must have the same RangeElement and label at all the domain positions.  Currently the mapping must be 'onto', i.e., no more that one domain position may map onto any given range position.  It is unclear whether to elevate this from an implementation restriction to a specification.  See FeEdition::mapSharedOnto and FeEdition::combine.
	
	{ <k2,l1,v1> | <k1,l1,v1> in self and <k1,k2> in mapping }
	requires:
		Currently: not exists k1a, k1b : k1a !!= k1b and <k1a,k2> in mapping and <k1b,k2> in mapping.
		Maybe eventually: for all v1, v2 : <k,l1,v1> in result and <k,l2,v2> in result, v1 is same as v2"
	
	^FeEdition on: (myBeEdition transformedBy: mapping) with: myLabel!

{FeEdition CLIENT} with: position {Position} with: value {FeRangeElement}
	"Return a new FeEditionwith the same contents and label as this Edition, except for the addition or substitution of a RangeElement at a specified position.
	(The difference between with() and rebind() is exactly that rebind() preserves the old label at position, while with() installs the label attached to the value argument.)
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWith (position, value))"
		
	^FeEdition on: (myBeEdition with: position with: value carrier) with: myLabel!

{FeEdition CLIENT} withAll: positions {XnRegion} with: value {FeRangeElement}
	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are superceded by the value argument.
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWithAll (positions, value))"
		
	^FeEdition on: (myBeEdition withAll: positions with: value carrier) with: myLabel!

{FeEdition CLIENT} without: position {Position}
	"Return a new FeEdition with the same contents and label as this Edition, except at a specified position, where the old value and label, if there is one, is removed.
	Equivalent to:
		this->copy (position->asRegion ()->complement ())"
		
	^FeEdition on: (myBeEdition without: position) with: myLabel!

{FeEdition CLIENT} withoutAll: positions {XnRegion}
	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are removed.
	Equivalent to
		this->copy (positions->complement ())"
		
	^FeEdition on: (myBeEdition withoutAll: positions) with: myLabel! !

!FeEdition methodsFor: 'accessing'!

{CoordinateSpace CLIENT} coordinateSpace
	"Return the space in which the positions of this Edition are positions. Equivalent to
		this->domain ()->coordinateSpace ()"
	^myBeEdition coordinateSpace!

{IntegerVar CLIENT} cost: method {Int32}
	"Essential. Retiurn how much space this Edition is taking up on the disk, in bytes (but the precision may exceed the accuracy; it's simply a well-known unit). The method determines how material shared with other Editions is treated: if omitShared, it is not counted at all; if prorateShared, then it is divided evenly among the Editions sharing it; if totalShared, its entire cost is counted. This figure is only approximate, and may vary with time.
	(No permissions are required to obtain this informiation, even though it exposes sharing by Editions you can't read to traffic analysis.)"
	
	Someone shouldImplement.
	^IntegerVarZero "fodder"!

{IntegerVar CLIENT} count
	"Return the number of positions in this Edition. Blasts if infinite. Equivalent to
		this->domain ()->count ()"
		
	^myBeEdition count!

{XnRegion CLIENT} domain
	"Essential.  Return the region consisting of all the positions in this Edition. May be infinite, or empty.
	
	{ k | <k,l,v> in self }"
	
	^myBeEdition domain!

{FeRangeElement CLIENT} get: position {Position}
	"Return the value at the given position, or blast if there is no such position (i.e. if !! this->domain ()->hasMember (position)).
	
	v : <position,l,v> in self
	requires: <position,l,v> in self"
	
	^myBeEdition get: position!

{BooleanVar CLIENT} hasPosition: position {Position}
	"Return whether the given position is in the Edition. Equivalent to
		this->domain ()->hasMember (position)"
	
	self thingToDo. "rename Be protocol"
	^myBeEdition includesKey: position!

{BooleanVar CLIENT} isEmpty
	"Return whether there are any positions in this Edition. Equivalent to
		this->domain ()->isEmpty ()"
	
	^myBeEdition isEmpty!

{BooleanVar CLIENT} isFinite
	"Return whether there are a finite number of positions in this Edition. Equivalent to
		this->domain ()->isFinite ()"
	
	^myBeEdition isFinite!

{(Stepper of: Bundle) CLIENT} retrieve: region {XnRegion default: NULL}
	with: order {OrderSpec default: NULL}
	with: flags {Int32 default: Int32Zero}
	"Essential.  This is the fundamental retrieval operation.  Return a stepper of bundles.  Each bundle is an association between a region in the domain and the range elements associated with that region.  Where the region is associated with data, for instance, the bundle contains a PrimArray of the data elements.
	If a region is given, only that subset of the Edition's contents will be returned.  If it is not given, the entire content of the Edition will be returned.
	if the ignoreTotalOrdering flag is set, then the operation can group non-contiguous regions, and can supply the bundles in any order.
	if the ignoreArrayOrdering flag is set, then ArrayBundles returned by the operation can be ordered differently from the supplied order.
	If an OrderSpec is not supplied, then the ordering will be the default order for the coordinate space, if one exists, and if none exists the returned data will be completely unordered and the Ordering flags will be ignored."
	
	self thingToDo.  "The above comment is still horribly insufficient."
	
	^myBeEdition retrieve: region with: order with: flags!

{TableStepper CLIENT of: FeRangeElement} stepper: region {XnRegion default: NULL}
	with: ordering {OrderSpec default: NULL}
	"Return a stepper for iterating over the positions and RangeElements of this Edition. If a region is specified, then it only iterates over the domain positions which are in the given region. If no ordering is specified, then the default ascending full ordering of the CoordinateSpace is used, or a random order chosen if there is no default."
	
	| theRegion {XnRegion} |
	theRegion := self domain.
	region ~~ NULL
		ifTrue: [theRegion := theRegion intersect: region].
	^EditionStepper create: (theRegion stepper: ordering) with: self!

{FeRangeElement CLIENT} theOne
	"If this Edition has a single position, then return the RangeElement at that position; if not, blasts. Equivalent to
		this->get (this->domain ()->theOne ())"
		
	^myBeEdition theOne! !

!FeEdition methodsFor: 'comparing'!

{BooleanVar CLIENT} isRangeIdentical: other {FeEdition}
	with: region {XnRegion default: NULL}
	"Whether the two Editions have the same domains, and each RangeElement isIdentical to the corresponding RangeElement in the other Edition."
	
	Someone shouldImplement.
	^false "fodder"!

{Mapping CLIENT} mapSharedOnto: other {FeEdition}
	"Return a mapping such that for each range element that appears in both editions, the mapping maps each of its appearances in the argument edition to some appearance in this one.  (Some of the appearances in this edition may be unmapped or mapped to multiple appearances in the argument edition.)  Like 'mapSharedTo' except that the resulting mapping is 'onto'.  This means that each range position of the resulting mapping inverse maps to at most one domain position.  Such a mapping is suitable as an argument to 'transformedBy', and represents the minimal transformation needed to make the shared part of 'other' from self.  Note that there is no unique answer.
	
	result = { <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2
							and not exists k11 : k11 !!= k1 and <k11,k2> in result }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."

	Someone shouldImplement.
	^NULL "fodder"!

{Mapping CLIENT} mapSharedTo: other {FeEdition}
	"Essential.  Return a Mapping from each of the positions in this Edition to all of the positions in the other Edition which have the same RangeElement.
	
	{ <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	^myBeEdition mapSharedTo: other beEdition!

{FeEdition CLIENT} notSharedWith: other {FeEdition}
	with: flags {Int32 default: Int32Zero}
	"Return a new FeEdition containing exactly the subset of this Edition whose RangeElements are not in the other Edition.
	Equivalent to:
		this->copy (this->sharedRegion (other)->complement ()).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."
		
	^FeEdition on: (myBeEdition
			notSharedWith: other beEdition with: flags)
		with: myLabel!

{XnRegion CLIENT} positionsOf: value {FeRangeElement}
	"Return the region consisting of all the positions in this Edition at which the given RangeElement can be found.
	Equivalent to:
		this->sharedRegion (theServer ()->makeEditionWith (some position, value)).
		
	{ k | <k,l,v> in self and v is same as value }"
	
	self thingToDo. "rename Be protocol"
	^myBeEdition keysOf: value!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"Essential.  Return a new FeEdition containing all Editions which can be read with the authority of the CurrentKeyMaster, and which transclude RangeElements in this Edition. Immediately returns with an Edition full of PlaceHolders, which will be filled in as results appear; the lookup proceeds asynchronously.
	The Server will attempt to avoid placing duplicate copies in the result, but it may still happen.
	If a Region is given, then the request only considers the subset at those positions (i.e. equivalent to this->copy (positions)->rangeTransclusions (...))
	If a directFilter is given, then the endorsements on the resulting Editions, unioned with the endorsements on any Works directly on those Editions to which the CurrentKeyMaster has read permission, must pass the filter.
	If an indirectFilter is given, then the resulting Editions must be contained, directly or indirectly, by an Edition whose endorsements (unioned with its readable Works endorsements) pass the filter. (Giving a non-NULL indirectFilter will probably not be supported in version 1.0.)
	If the directContainersOnly flag is set, then the result only includes Editions which have the material as RangeElements; otherwise, the result includes Editions which indirectly contain the material through other Editions. (Setting this flag will probably not be supported in version 1.0.)
	If the fromTransitiveContents flag is set, then the result includes transclusions of RangeElements of sub-Editions of this one, in addition to the RangeElements in this Edition. (Setting ths flag will probably not be supported in version 1.0.)
	If localPresentOnly flag is clear, a persistent request will be created, and the new FeEdition will continue to be filled in in the future.  If it is set, only those Editions which are currently known to transclude by this Backend are sure to be recorded into the Trail.  (Some, but not all, Editions which come to transclude while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Editions which come to transclude after the wait completes will be recorded.)
	If otherTranscluders is given, then the results will be recorded into it. (This may increase the chance of the same Edition being recorded twice.)
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)"
	
	| theOther {BeEdition} theDirectFilter {Filter} theIndirectFilter {Filter} |
	otherTranscluders == NULL
		ifTrue: [theOther := NULL]
		ifFalse: [theOther := otherTranscluders beEdition].
	directFilter == NULL
		ifTrue: [theDirectFilter := FeServer endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theDirectFilter := directFilter].
	indirectFilter == NULL
		ifTrue: [theIndirectFilter := FeServer endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theIndirectFilter := indirectFilter].
	^FeEdition on: 
		(myBeEdition
			rangeTranscluders: positions
			with: theDirectFilter
			with: theIndirectFilter
			with: flags
			with: theOther)!

{FeEdition CLIENT} rangeWorks: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"Essential.  Return a new FeEdition containing all Works which contain RangeElements of this Edition and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If the localPresentOnly flag is clear, a persistent request will be created, and as new Works come to be known to the Server, they will be filled into the resulting Edition.  If it is set, only Works currently known to this Server are sure to be recorded into the Trail.  (Some, but not all, Works which become known while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Works which become known after the wait completes will be recorded.)
	If the fromTransitiveContents flag is set, then the result includes Works which contain RangeElements transitively contained in this Edition. (This may not be supported in 1.0)
	If directContainersOnly is set, then only Works which are directly on Editions which are RangeElements of this Edition are returned (and not Works which are on Editions which have them as sub-Editions).
	If otherTranscluders is given, this records works into that trail.
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)
	
	{ <k,l,w> | w's contains self, w passes filter}"
		
	| theOther {BeEdition} theFilter {Filter} |
	otherTranscluders == NULL
		ifTrue: [theOther := NULL]
		ifFalse: [theOther := otherTranscluders beEdition].
	filter == NULL
		ifTrue: [theFilter := FeServer endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theFilter := filter].
	^FeEdition on: 
		(myBeEdition
			rangeWorks: positions
			with: theFilter
			with: flags
			with: theOther)!

{XnRegion CLIENT} sharedRegion: other {FeEdition}
	with: flags {Int32 default: Int32Zero}
	"Return the subset of the positions of this Edition which  have RangeElements that are in the other Edition.
	If nestThis flag is set, then returns not only positions of RangeElements which are in the other, but also positions of Editions which have RangeElements which are in the other, or which have other such Editions, recursively.  (This searches down to, but not across, work boundaries.)
	If nestOther flag is set, then looks not only for RangeElements which are values of the other Edition, but also those which are values of sub-Editions of the other Edition. (This option will probably not be supported in version 1.0).
	If both flags are false, then equivalent to:
		this->mapSharedTo (other)->domain ()
	
	{ k1 | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	^myBeEdition sharedRegion: other beEdition with: flags!

{FeEdition CLIENT} sharedWith: other {FeEdition}
	with: flags {Int32 default: Int32Zero}
	"Essential.  Return a new FeEdition consisting of the subset of this Edition whose RangeElements are in the other Edition. If the same RangeElement is in this Edition at several different positions, all positions will be in the result (provided the RangeElement is also in the other Edition).
	Equivalent to:
		this->copy (this->sharedRegion (other, flags)).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
		
	^FeEdition on: (myBeEdition
			sharedWith: other beEdition with: flags)
		with: myLabel! !

!FeEdition methodsFor: 'endorsing'!

{void CLIENT} endorse: additionalEndorsements {CrossRegion}
	"Essential.  Adds to the endorsements on this Edition.  The region of additionalEndorsements must consist of a finite number of (club ID, token ID) pairs.  CurrentKeyMaster must hold the signature authority of all the Clubs used to endorse; the request will blast and do nothing if any of the required authority is lacking.  (Redoing an endorse() undoes a retract())"
	
	FeRangeElement validateEndorsement: additionalEndorsements with: CurrentKeyMaster fluidGet.
	myBeEdition endorse: additionalEndorsements!

{CrossRegion CLIENT} endorsements
	"Essential.  Return all of the endorsements which have been placed on this Edition and not retracted."
	
	^myBeEdition endorsements!

{void CLIENT} retract: endorsements {CrossRegion}
	"Essential.  Removes endorsements from this Edition.  This requires that the CurrentKeyMaster hold signature authority for all of the Clubs whose endorsements are in the list; will blast and do nothing if any of the required authority is lacking, even if the endorsements weren't there to be retracted.  Ignores all endorsements which you could have removed, but which don't happen to be there right now.
	
	In the current release removed endorsements aren't preserved, so they vanish forever.  Beginning in some future release removed endorsements will become inactive, but it will be possible to detect that they once had been present.  The intent is for a removed endorsement to be analogous to a signature that has been struck out.  You can express that you changed your mind, but you can't undo the past."
	
	FeRangeElement validateEndorsement: endorsements with: CurrentKeyMaster fluidGet.
	myBeEdition retract: endorsements!

{CrossRegion CLIENT} visibleEndorsements
	"Essential.  Return all the unretracted endorsements on this Edition along with those on any Works directly on it which the CurrentKeyMaster has permission to read."
	
	^myBeEdition visibleEndorsements! !

!FeEdition methodsFor: 'becoming'!

{void} addFillRangeDetector: detector {FeFillRangeDetector}
	"Essential.  Connect a FillRangeDetector to the underlying BeEdition so that when any of the PlaceHolders in that Edition become any other kind of RangeElement, then the Detector will be triggered with an Edition containing the new RangeElements (but not necessarily at the same positions, or even in the same CoordinateSpace). If there already are non-PlaceHolders, then the Detector is triggered immediately with those RangeElements.
	See FillRangeDetector::allFilled (Edition * newIdentities)."
	
	myBeEdition addDetector: detector!

{XnRegion CLIENT} canMakeRangeIdentical: newIdentities {FeEdition}
	with: positions {XnRegion default: NULL}
	"Essential.  Return the region consisting of all locations at which my RangeElements can NOT be made identical to the corresponding RangeElements in the other Edition. (This seems like the opposite of what you want, but in fact it makes it easy to check for success.)
	Does not check whether you have permissions to do so, just whether it could be done by someone with the appropriate permissions. See rangeOwners."
	
	Dean shouldImplement.
	^NULL "fodder"!

{FeFillRangeDetector CLIENT} fillRangeDetector
	"Essential.  Return a FillRangeDetector so that when any of the PlaceHolders in this Edition become any other kind of RangeElement, then the Detector will be triggered with an Edition containing the new RangeElements (but not necessarily at the same positions, or even in the same CoordinateSpace). If there already are non-PlaceHolders, then the Detector is triggered immediately with those RangeElements.
	See FillRangeDetector::allFilled (Edition * newIdentities)."
	
	Dean shouldImplement.
	self addFillRangeDetector: NULL.
	^NULL "fodder"!

{FeEdition CLIENT} makeRangeIdentical: newIdentities {FeEdition}
	with: positions {XnRegion default: NULL}
	"Essential.  Try to change the identity of each RangeElements of this Edition which are in the Region (or all if no Region supplied) to that of the RangeElement at the same position in the other Edition. Returns the subset of this Edition which did not end up with the new identities, because of
		- lack of ownership authority
		- different contents
		- contents of other edition unreadable
		- incompatible types
		- no corresponding new identity
		
Note that the labels on the RangeElements need not match and will NOT be changed."
	
	| never {BeEdition} maybe {BeEdition} trial {BeEdition} result {Pair of: BeEdition} theRegion {XnRegion} |
	"Keep trying the primitive routine until it says it can't do any more"
	self knownBug. "put loop into server loop"
	(self coordinateSpace isEqual: newIdentities coordinateSpace) ifFalse:
		[^self].
	never := CurrentGrandMap fluidGet newEmptyEdition: self coordinateSpace.
	maybe := myBeEdition.
	theRegion := maybe domain.
	positions ~~ NULL ifTrue:
		[theRegion := theRegion intersect: positions].
	trial := newIdentities beEdition copy: theRegion.
	[(result := maybe tryAllBecome: trial) fetchRight ~~ NULL]
		whileTrue:
			[never := never combine: (result left cast: BeEdition).
			maybe := result right cast: BeEdition.
			trial := trial copy: maybe domain].
	^FeEdition on: never with: myLabel!

{IDRegion CLIENT} rangeOwners: positions {XnRegion default: NULL} 
	"The owners of all the RangeElements in the given Region, or in the entire 
	Edition if no Region is specified."

	^myBeEdition rangeOwners: positions!

{void} removeFillRangeDetector: detector {FeFillRangeDetector}
	"Essential.  Remove a Detector which had been added to this Edition. You should remove every Detector you add, although they will go away automatically when a client session terminates."
	
	(Heaper isDestructed: myBeEdition) ifFalse:
		[myBeEdition removeDetector: detector]!

{FeEdition CLIENT} setRangeOwners: newOwner {ID} with: region {XnRegion default: NULL}
	"Changes the owner of all RangeElements in the Edition (but not the Edition itself!!); requires the authority of the current owner of each range element. If a Region is supplied, then only sets those in the region.
	Returns the subset of this Edition which is in the Region whose owners did not end up being the new Owner because of lack of authority."
	
	| theRegion {XnRegion} |
	region == NULL
		ifTrue: [theRegion := self domain]
		ifFalse: [theRegion := region].
	^FeEdition on: (myBeEdition setRangeOwners: newOwner with: theRegion) with: myLabel! !

!FeEdition methodsFor: 'labelling'!

{FeLabel} label

	^myLabel!

{XnRegion CLIENT} positionsLabelled: label {FeLabel}
	"Return a region consisting of exactly the positions in this Edition which are associated with the given label.
	
	{ k | <k,label,v> in self }"
	
	self thingToDo. "rename Be protocol"
	^myBeEdition keysLabelled: (label fetchBe cast: BeLabel)!

{FeEdition CLIENT} rebind: position {Position} with: edition {FeEdition}
	"Return a new FeEdition which is a copy of this Edition with the contained Edition at the given position replaced by the given Edition, but with the Label at that position unchanged.  Equivalent to
		this->with (position, edition->relabelled (this->get (position)->label ())).

	Note that rebind() is useless (and blasts) when a non-edition RangeElement is at the given position.
		
	{ <k,l,v> | ((k isEqual: position) and (v is same as edition)) 
				or (<k,l,v> in self and k !!= position) }"
	
	^self class fromOne: position with: (edition relabelled: ((self get: position) cast: FeEdition) label)!

{FeRangeElement} relabelled: label {FeLabel}

	^FeEdition on: myBeEdition with: label! !

!FeEdition methodsFor: 'server accessing'!

{BeEdition} beEdition
	^myBeEdition!

{BeCarrier} carrier
	"Return an object that wraps up any run-time state that might be needed inside the Be system.  Right now that means labels."
	
	^BeCarrier make: (myLabel getOrMakeBe cast: BeLabel) with: myBeEdition!

{FeRangeElement} fetch: position {Position}
	"The value at the position, or NULL if there is none"
	^myBeEdition fetch: position!

{BeRangeElement | NULL} fetchBe

	^myBeEdition!

{BeRangeElement} getOrMakeBe

	^myBeEdition! !

!FeEdition methodsFor: 'client implementation'!

{FeRangeElement} again
	"These don't change as long as someone has a handle on them."
	
	^self!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented]! !

!FeEdition methodsFor: 'private: create'!

create: beEdition {BeEdition} with: label {FeLabel}

	super create.
	myBeEdition := beEdition.
	myLabel _ label.! !

!FeEdition methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	| before {char star} |
	self isEmpty ifTrue: [oo << 'Edition()'. ^VOID].
	before := 'Edition('.
	(self retrieve: NULL with: NULL with: FeEdition IGNORE.U.TOTAL.U.ORDERING) forEach:
		[ :bundle {FeBundle} |
		oo << before << bundle region << ' -> '.
		bundle cast: FeArrayBundle into:
			[ :array | oo << array array]
		cast: FeElementBundle into:
			[ :range | oo << range element]
		cast: FePlaceHolderBundle into:
			[ :place | oo << '{...}'].
		before := ', '].
	oo << ')'! !

!FeEdition methodsFor: 'smalltalk: defaults'!

{XnRegion CLIENT} canMakeRangeIdentical: newIdentities {FeEdition}

	^self canMakeRangeIdentical: newIdentities with: NULL!

{BooleanVar CLIENT} isRangeIdentical: other {FeEdition}

	^self isRangeIdentical: other with: NULL!

{FeEdition CLIENT} makeRangeIdentical: newIdentities {FeEdition}

	^self makeRangeIdentical: newIdentities with: NULL!

{FeEdition CLIENT} notSharedWith: other {FeEdition}

	^self notSharedWith: other with: 0!

{FeEdition CLIENT} rangeTranscluders
	
	^self rangeTranscluders: NULL with: NULL with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	
	^self rangeTranscluders: positions with: NULL with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	
	^self rangeTranscluders: positions with: filter with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: transitiveFilter {Filter default: NULL}
	
	^self rangeTranscluders: positions with: filter with: transitiveFilter with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: transitiveFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self rangeTranscluders: positions with: filter with: transitiveFilter with: flags with: NULL!

{FeEdition CLIENT} rangeWorks
	^self rangeWorks: NULL with: NULL with: 0 with: NULL!

{FeEdition CLIENT} rangeWorks: region {XnRegion default: NULL}
	^self rangeWorks: region with: NULL with: 0 with: NULL!

{FeEdition CLIENT} rangeWorks: region {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	^self rangeWorks: region with: filter with: 0 with: NULL!

{FeEdition CLIENT} rangeWorks: region {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self rangeWorks: region with: filter with: flags with: NULL!

{(Stepper of: Bundle) CLIENT} retrieve

	^self retrieve: NULL with: NULL with: 0!

{(Stepper of: Bundle) CLIENT} retrieve: positions {XnRegion default: NULL}

	^self retrieve: positions with: NULL with: 0!

{(Stepper of: Bundle) CLIENT} retrieve: positions {XnRegion default: NULL} with: order {OrderSpec default: NULL}

	^self retrieve: positions with: order with: 0!

{FeEdition CLIENT} setRangeOwners: newOwner {ID}

	^self setRangeOwners: newOwner with: NULL!

{XnRegion CLIENT} sharedRegion: other {FeEdition}
	^self sharedRegion: other with: 0!

{FeEdition CLIENT} sharedWith: other {FeEdition}
	^self sharedWith: other with: 0!

{TableStepper CLIENT of: FeRangeElement} stepper
	^self stepper: NULL with: NULL!

{TableStepper CLIENT of: FeRangeElement} stepper: region {XnRegion default: NULL}
	^self stepper: region with: NULL! !

!FeEdition methodsFor: 'smalltalk: passe'!

{void} addCompletionDetector: detector {FeCompletionDetector}
	self passe!

{void} addFillInDetector: detector {FeFillInDetector}

	self passe!

{FeEdition} allBecome: newIdentities {FeEdition} with: positions {XnRegion default: NULL}

	self passe "makeRangeIdentical"!

{PrimArray} asArray: positions {XnRegion default: NULL}
	with: ordering {OrderSpec default: NULL}

	self passe "use retrieve"!

{XnRegion} keysLabelled: label {FeLabel}

	self passe!

{FeEdition} parcelAt: position {Position}
	"Some subset of this Edition, containing the given position, all with the same owner
	
	{ <k,l,v> | <k,l,v> in self and <position,l2,v2> in self and v.owner == v2.owner }"
	
self passe!

{FeEdition of: ID and: FeEdition} parcels
	"Divides this Edition into pieces each of whose RangeElements are all owned by a single Club.
	
	{ <k1, { <k2,v2> } > | <k2,v2> in self and k1 == v2's owner }"
	
	self passe!

{void} removeCompletionDetector: detector {FeCompletionDetector}
self passe!

{void} removeFillInDetector: detector {FeFillInDetector}

	self passe!

{FeEdition} reorganize: oldRegion {XnRegion | NULL}
	with: oldOrder {OrderSpec | NULL}
	with: newRegion {XnRegion | NULL}
	with: newOrder {OrderSpec | NULL}
	"Rearrange the positions of this Edition to lie in the given region, with the given ordering. Equivalent to server->makeEdition (this->asArray (oldRegion, oldOrder), newRegion, newOrder, NULL), except that it doesn't require everything to be in the same zone (and is of course more efficient).
	
	This message is tentative and may be removed from the protocol."
	
	^FeEdition on: (myBeEdition
			reorganize: oldRegion with: oldOrder with: newRegion with: newOrder) with: myLabel!

{FeEdition} setAllOwners: newOwner {ID} with: region {XnRegion default: NULL}

	self passe "setRangeOwners"!

{FeEdition} transclusions: positions {XnRegion default: NULL}
	with: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTransclusions {FeEdition default: NULL}

	self passe "rangeTranscluders"!

{void} unendorse: endorsements {CrossRegion}

	self passe "retract"!

{Pair of: PrimSpec and: FeEdition} zoneAt: position {Position}
	"Essential.  A zone containing the given position, all with the same kind of RangeElements."
	
	| result {Pair} |
	self passe.
	self thingToDo. "get rid of BeEdition protocol"
	result := myBeEdition zoneAt: position.
	^Pair make: result left
		with: (FeEdition on: (result left cast: BeEdition) with: myLabel)!

{FeEdition} zoneOf: values {PrimSpec}

	self passe!

{TwoStepper of: PrimSpec and: FeEdition} zones: ordering {OrderSpec default: NULL}
	"Divides this Edition up into pieces all of whose RangeElements have the same PrimSpec. If no ordering is given, then uses the default full ordering for this CoordinateSpace."
	
	self passe! !

!FeEdition methodsFor: 'obsolete:'!

{BooleanVar} includesKey: position {Position}
	"Whether the given position is in the Edition. Equivalent to
		this->domain ()->hasMember (position)"
	
	^myBeEdition includesKey: position!

{XnRegion} keysOf: value {FeRangeElement}
	"All of the keys in this Edition at which the given RangeElement can be found. Equivalent to
		this->sharedRegion (theServer ()->makeEditionWith (some position, value)).
		
	{ k | <k,l,v> in self and v is same as value }"
	
	^myBeEdition keysOf: value! !

!FeEdition methodsFor: 'destruct'!

{void} destruct

	myBeEdition removeFeRangeElement: self.
	super destruct.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeEdition class
	instanceVariableNames: ''!

(FeEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeEdition class methodsFor: 'smalltalk: defaults'!

{FeEdition CLIENT} fromArray: values {PrimArray of: FeRangeElement}
	"Essential.  Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between  the keys and the indices in the array.
	If a Region is given, then it must have the same count as the array.  If no Region is given, then it is taken to be the IntegerRegion from 0  to the size of the array. If no OrderSpec is given, then it is the default ascending full ordering for that CoordinateSpace."
			
	^self fromArray: values with: NULL with: NULL!

{FeEdition CLIENT} fromArray: values {PrimArray of: FeRangeElement}
	with: keys {XnRegion default: NULL}
	"Essential.  Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between  the keys and the indices in the array.
	If a Region is given, then it must have the same count as the array.  If no Region is given, then it is taken to be the IntegerRegion from 0  to the size of the array. If no OrderSpec is given, then it is the default ascending full ordering for that CoordinateSpace."
			
	^self fromArray: values with: keys with: NULL! !

!FeEdition class methodsFor: 'creation'!

{FeEdition CLIENT} empty: keySpace {CoordinateSpace}
	"An empty Edition, with the given CoordinateSpace but no contents."

	^FeEdition on: (CurrentGrandMap fluidGet newEmptyEdition: keySpace)!

{FeEdition CLIENT} fromAll: keys {XnRegion} with: value {FeRangeElement}
	"Essential.  A singleton Edition mapping from a Region of keys (potentially infinite) to a single value."

	^FeEdition on: 
		(CurrentGrandMap fluidGet
			newEditionWithAll: keys
			with: value carrier)!

{FeEdition CLIENT} fromArray: values {PrimArray of: FeRangeElement}
	with: keys {XnRegion default: NULL}
	with: ordering {OrderSpec default: NULL}
	"Essential.  Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between  the keys and the indices in the array.
	If a Region is given, then it must have the same count as the array.  If no Region is given, then it is taken to be the IntegerRegion from 0  to the size of the array. If no OrderSpec is given, then it is the default ascending full ordering for that CoordinateSpace."
			
	| theKeys {XnRegion} theOrdering {OrderSpec} |
	keys == NULL
		ifTrue: [theKeys := IntegerRegion make: IntegerVar0 with: values count]
		ifFalse: [theKeys := keys].
	ordering == NULL
		ifTrue: [theOrdering := theKeys coordinateSpace getAscending]
		ifFalse: [theOrdering := ordering].
	values
		cast: PrimDataArray into: 
			[ :data |
			^FeEdition on: 
				(CurrentGrandMap fluidGet
					newDataEdition: data
					with: theKeys 
					with: theOrdering )]
		cast: PtrArray into: 
			[ :ptr | 
			^FeEdition on: 
				(CurrentGrandMap fluidGet
					newValueEdition: ptr 
					with: theKeys 
					with: theOrdering)].
	^NULL "fodder"!

{FeEdition CLIENT} fromOne: key {Position} with: value {FeRangeElement}
	"A singleton Edition mapping from a single key to a single value."
	
	^FeEdition on: (CurrentGrandMap fluidGet newEditionWith: key with: value carrier)!

{FeEdition} on: be {BeEdition} 

	| result {FeEdition} |
	result := self create: be with: FeLabel fake.
	be addFeRangeElement: result.
	^result!

{FeEdition} on: be {BeEdition} with: label {FeLabel}

	| result {FeEdition} |
	result := self create: be with: label.
	be addFeRangeElement: result.
	^result!

{FeEdition CLIENT} placeHolders: keys {XnRegion} 
	"Essential.  Create a new Edition mapping from each key in the Region to a new, unique PlaceHolder. The owner will have the capability to make them become something else."
	
	^FeEdition on: (CurrentGrandMap fluidGet newPlaceHolders: keys)! !

!FeEdition class methodsFor: 'constants'!

{Int32 constFn INLINE CLIENT} DIRECT.U.CONTAINERS.U.ONLY
	"For transcluders and works queries - only return objects which directly contain the sources of the query (i.e. excludes those which only contain it transitively through intermediate Editions)"
	^4!

{Int32 constFn INLINE CLIENT} FROM.U.OTHER.U.TRANSITIVE.U.CONTENTS
	"For sharedWith/sharedRegion/notSharedWith - look for RangeElements contained transitively within the other Edition"

	^8!

{Int32 constFn INLINE CLIENT} FROM.U.TRANSITIVE.U.CONTENTS
	"For transcluders, and works queries - consider RangeElements contained transitively inside the Edition, as well as just its immediate RangeElements"
	^2!

{Int32 constFn INLINE CLIENT} IGNORE.U.ARRAY.U.ORDERING
	"Used for retrieve.  Allow the ArrayBundles in retrieve to be organized according to a different ordering."
	
	^2!

{Int32 constFn INLINE CLIENT} IGNORE.U.TOTAL.U.ORDERING
	"Used for retrieve.  Allow non-contiguous chunks to be grouped together on retrieve, and allow the bundles to be presented in any order."
	
	^1!

{Int32 constFn INLINE CLIENT} LOCAL.U.PRESENT.U.ONLY
	"For transcluders and works queries - only guarantee to return items which are currently known to this server"
	^1!

{Int32 constFn INLINE CLIENT} OMIT.U.SHARED
	"For cost - omit the cost of shared material"
	
	^1!

{Int32 constFn INLINE CLIENT} otherTransitiveContents
	"For sharedWith/sharedRegion/notSharedWith"

	^2!

{Int32 constFn INLINE CLIENT} PRORATE.U.SHARED
	"For cost - prorate the cost of shared material among Editions sharing it"
	
	^2!

{Int32 constFn INLINE CLIENT} SEPARATE.U.OWNERS
	"For retrieve - ensure that each Bundle in a retrieve has a single owner"
	
	^32!

{Int32 constFn INLINE CLIENT} thisTransitiveContents
	"Used for version comparison."

	^1!

{Int32 constFn INLINE CLIENT} TO.U.TRANSITIVE.U.CONTENTS
	"For sharedRegion, sharedWith, notSharedWith queries - look down towards transitively contained material"
	^2!

{Int32 constFn INLINE CLIENT} TOTAL.U.SHARED
	"For cost - count the entire cost of shared material"
	
	^3! !

!FeEdition class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Int32 constFn INLINE CLIENT} DIRECT.U.CONTAINERS.U.ONLY
{Int32 constFn INLINE CLIENT} FROM.U.OTHER.U.TRANSITIVE.U.CONTENTS
{Int32 constFn INLINE CLIENT} FROM.U.TRANSITIVE.U.CONTENTS
{Int32 constFn INLINE CLIENT} IGNORE.U.ARRAY.U.ORDERING
{Int32 constFn INLINE CLIENT} IGNORE.U.TOTAL.U.ORDERING
{Int32 constFn INLINE CLIENT} LOCAL.U.PRESENT.U.ONLY
{Int32 constFn INLINE CLIENT} OMIT.U.SHARED
{Int32 constFn INLINE CLIENT} PRORATE.U.SHARED
{Int32 constFn INLINE CLIENT} SEPARATE.U.OWNERS
{Int32 constFn INLINE CLIENT} TO.U.TRANSITIVE.U.CONTENTS
{Int32 constFn INLINE CLIENT} TOTAL.U.SHARED
{void CLIENT} addFillRangeDetector: detector {PrFillRangeDetector}
{XuRegion CLIENT} canMakeRangeIdentical: newIdentities {FeEdition} with: positions {XuRegion default: NULL}
{FeEdition CLIENT} combine: other {FeEdition}
{CoordinateSpace CLIENT} coordinateSpace
{FeEdition CLIENT} copy: positions {XuRegion}
{IntegerVar CLIENT} cost: method {Int32}
{IntegerVar CLIENT} count
{XuRegion CLIENT} domain
{void CLIENT} endorse: endorsements {CrossRegion}
{CrossRegion CLIENT} endorsements
{FeRangeElement CLIENT} get: position {Position}
{BooleanVar CLIENT} hasPosition: position {Position}
{BooleanVar CLIENT} isEmpty
{BooleanVar CLIENT} isFinite
{BooleanVar CLIENT} isRangeIdentical: other {FeEdition}
{BooleanVar CLIENT} isRangeIdentical: other {FeEdition} with: region {XuRegion default: NULL}
{FeEdition CLIENT} makeRangeIdentical: newIdentities {FeEdition} with: positions {XuRegion default: NULL}
{Mapping CLIENT} mapSharedOnto: other {FeEdition}
{Mapping CLIENT} mapSharedTo: other {FeEdition}
{FeEdition CLIENT} notSharedWith: other {FeEdition} with: flags {Int32 default: Int32Zero}
{XuRegion CLIENT} positionsLabelled: label {FeLabel}
{XuRegion CLIENT} positionsOf: value {FeRangeElement}
{IDRegion CLIENT} rangeOwners: positions {XuRegion default: NULL}
{FeEdition CLIENT} rangeTranscluders: positions {XuRegion default: NULL} with: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
{FeEdition CLIENT} rangeWorks: positions {XuRegion default: NULL} with: filter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
{FeEdition CLIENT} rebind: position {Position} with: edition {FeEdition}
{void CLIENT} removeFillRangeDetector: detector {PrFillRangeDetector}
{FeEdition CLIENT} replace: other {FeEdition}
{void CLIENT} retract: endorsements {CrossRegion}
{(Stepper of: Bundle) CLIENT} retrieve: positions {XuRegion default: NULL} with: order {OrderSpec default: NULL} with: flags {Int32 default: Int32Zero}
{FeEdition CLIENT} setRangeOwners: newOwner {ID} with: positions {XuRegion default: NULL}
{XuRegion CLIENT} sharedRegion: other {FeEdition} with: flags {Int32 default: Int32Zero}
{FeEdition CLIENT} sharedWith: other {FeEdition} with: flags {Int32 default: Int32Zero}
{TableStepper CLIENT of: FeRangeElement} stepper: region {XuRegion default: NULL} with: order {OrderSpec default: NULL}
{FeRangeElement CLIENT} theOne
{FeEdition CLIENT} transformedBy: mapping {Mapping}
{CrossRegion CLIENT} visibleEndorsements
{FeEdition CLIENT} with: position {Position} with: value {FeRangeElement}
{FeEdition CLIENT} withAll: positions {XuRegion} with: value {FeRangeElement}
{FeEdition CLIENT} without: position {Position}
{FeEdition CLIENT} withoutAll: positions {XuRegion}
"! !

FeRangeElement subclass: #FeLabel
	instanceVariableNames: 'myBeLabel {BeLabel | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeLabel comment:
'An identity attached to a RangeElement within an Edition.'!

(FeLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeLabel methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myBeLabel!

{BeRangeElement} getOrMakeBe

	myBeLabel == NULL ifTrue:
		[myBeLabel _ CurrentGrandMap fluidGet newLabel.
		myBeLabel addFeRangeElement: self].
	^myBeLabel! !

!FeLabel methodsFor: 'client accessing'!

{FeRangeElement} again

	self unimplemented.
	^NULL "fodder"!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}

	self unimplemented! !

!FeLabel methodsFor: 'destruct'!

{void} destruct

	myBeLabel == NULL ifFalse:
		[myBeLabel removeFeRangeElement: self].
	super destruct.! !

!FeLabel methodsFor: 'creation'!

create: label {BeLabel | NULL}
	super create.
	myBeLabel _ label.! !

!FeLabel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self getOrMakeBe hashForEqual << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeLabel class
	instanceVariableNames: ''!

(FeLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeLabel class methodsFor: 'creation'!

{FeLabel} fake
	"The label will be made on demand."

	^self on: NULL!

{FeLabel CLIENT} make
	"Essential. Create a new unique Label"
	
	^FeLabel fake!

{FeLabel} on: label {BeLabel | NULL}
	
	| result {FeLabel} |
	result := self create: label.
	label ~~ NULL ifTrue:
		[label addFeRangeElement: result].
	^result! !

FeFillDetector subclass: #WorksTestFillDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTestFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillDetector methodsFor: 'triggering'!

{void} filled: transclusion {FeRangeElement}

	[myOutput << myTag << transclusion << '
'] smalltalkOnly.
	'(*myOutput) << myTag << transclusion << "\n";' translateOnly.! !

!WorksTestFillDetector methodsFor: 'private: create'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksTestFillDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTestFillDetector class
	instanceVariableNames: ''!

(WorksTestFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillDetector class methodsFor: 'pseudo constructors'!

{FeFillDetector} make: oo {ostream reference} with: tag {Character star}

	^self create: oo with: tag.! !

Heaper subclass: #FeAdminer
	instanceVariableNames: 'myAdminKM {FeKeyMaster}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeAdminer comment:
'A client interface for system administration operations. This object can only be obtained using a KeyMaster that has System Admin authority. '!

(FeAdminer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeAdminer methodsFor: 'administrivia'!

{void CLIENT} acceptConnections: open {BooleanVar}
	"Essential. Enable or disable the ability of the Server to accept communications connections from client machines. Anyone who has received a GateKeeper or Server object will continue to stay connected, but no new such objects will be handed out"
	
	CurrentGrandMap fluidGet acceptConnections: open!

{Stepper CLIENT of: FeSession} activeSessions
	"Essential. Return a list of all active sessions."
	
	^FeSession allActive!

{void CLIENT} execute: commands {PrimIntArray}
	"Essential. Execute a sequence of server configuration commands."
	
	| rc {Rcvr} next {Heaper | NULL} |
	self knownBug. "only accepts UInt8Arrays"
	rc := TextyXcvrMaker make 
				makeRcvr: (TransferSpecialist make: (Cookbook make.String: 'boot'))
				with: (XnReadStream make: (commands cast: UInt8Array)).
	next := rc receiveHeaper. 
	[next ~~ NULL] whileTrue: 
		[next cast: Thunk into: [:thunk | thunk execute] others: [].
		next := rc receiveHeaper].
	rc destroy!

{void CLIENT} grant: clubID {ID} with: globalIDs {IDRegion}
	"Essential. Grant a Club the authority to assign global IDs on this Server."
	
	CurrentGrandMap fluidGet grant: clubID with: globalIDs!

{TableStepper CLIENT of: ID and: IDRegion} grants: clubIDs {IDRegion default: NULL}
	with: globalIDs {IDRegion default: NULL}
	"Essential. List who has been granted authority to various regions of the global IDSpace on this Server."
	
	^CurrentGrandMap fluidGet grants: clubIDs with: globalIDs!

{BooleanVar CLIENT} isAcceptingConnections
	"Essential. Whether the Server is accepting communications connections from client machines. "
	
	^CurrentGrandMap fluidGet isAcceptingConnections!

{void CLIENT} shutdown
	"Essential. Shutdown the Server immediately, taking down all the connections and writing all current changes to disk."
	
	[DiskManager] USES.
	CurrentPacker fluidFetch purge.
	ServerLoop scheduleTermination.! !

!FeAdminer methodsFor: 'smalltalk: passe'!

{void} clearProfile

	self passe "rc file"!

{void} consistencyCheck

	self passe "rc file"!

{FeLockSmith} defaultLockSmith

	self passe!

{void} disableAccess: clubID {ID}
	"Disable login access to a Club, by revoking its direct membership of the System Access Club"
	
	self passe. "see FeServer"!

{void} enableAccess: clubID {ID}
	self passe. "see FeServer"!

{void} nameClub: name {Sequence} with: clubID {ID}
	self passe. "see FeServer"!

{void} renameClub: oldName {PackOBits} with: newName {PackOBits}
	self passe. "see FeServer"!

{void} setDefaultLockSmith: lockSmith {FeLockSmith}

	self passe!

{void} shutDown

	self passe "shutdown"!

{void} unnameClub: name {PackOBits}
	self passe. "see FeServer"!

{void} writeProfile

	self passe "rc file"! !

!FeAdminer methodsFor: 'security'!

{FeLockSmith CLIENT} gateLockSmith
	"Essential. The LockSmith which hands out locks when a client tries to login through the GateKeeper with an invalid Club ID or name."
	[BeGrandMap] USES.
	^(FeLockSmith spec wrap: CurrentGrandMap fluidGet gateLockSmithEdition) cast: FeLockSmith!

{void CLIENT} setGateLockSmith: lockSmith {FeLockSmith}
	"Essential. Set the LockSmith which creates locks to hand out when a client tries to login with an invalid Club ID or name through the GateKeeper."
	[BeGrandMap] USES.
	CurrentGrandMap fluidFetch setGateLockSmithEdition: lockSmith edition! !

!FeAdminer methodsFor: 'smalltalk: defaults'!

{TableStepper CLIENT of: ID and: IDRegion} grants
	^self grants: NULL with: NULL!

{TableStepper CLIENT of: ID and: IDRegion} grants: clubIDs {IDRegion default: NULL}
	^self grants: clubIDs with: NULL! !

!FeAdminer methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeAdminer class
	instanceVariableNames: ''!

(FeAdminer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeAdminer class methodsFor: 'create'!

{FeAdminer CLIENT} make

	FeKeyMaster assertAdminAuthority.
	^self create! !

!FeAdminer class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} acceptConnections: open {BooleanVar}
{Stepper CLIENT of: FeSession} activeSessions
{void CLIENT} execute: commands {PrimIntegerArray}
{FeLockSmith CLIENT} gateLockSmith
{void CLIENT} grant: clubID {ID} with: globalIDs {IDRegion}
{TableStepper CLIENT of: ID and: IDRegion} grants
{TableStepper CLIENT of: ID and: IDRegion} grants: clubIDs {IDRegion default: NULL}
{TableStepper CLIENT of: ID and: IDRegion} grants: clubIDs {IDRegion default: NULL} with: globalIDs {IDRegion default: NULL}
{BooleanVar CLIENT} isAcceptingConnections
{void CLIENT} setGateLockSmith: lockSmith {FeLockSmith}
{void CLIENT} shutDown
"! !

Heaper subclass: #FeBundle
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeBundle comment:
'Describes a single chunk of information from an Edition'!

(FeBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeBundle methodsFor: 'protected: create'!

create: region {XnRegion}

	super create.
	myRegion := region.! !

!FeBundle methodsFor: 'accessing'!

{XnRegion CLIENT} region
	"Essential. The positions in the Edition for which I describe the contents"
	
	^myRegion! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeBundle class
	instanceVariableNames: ''!

(FeBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeBundle class methodsFor: 'smalltalk: system'!

info.stProtocol
"{XnRegion CLIENT} region
"! !

FeBundle subclass: #FeElementBundle
	instanceVariableNames: 'myElement {FeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeElementBundle comment:
'Describes a region of an Edition in which all indices in my region hold the same RangeElement.'!

(FeElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeElementBundle methodsFor: 'accessing'!

{FeRangeElement CLIENT} element
	"Essential. The RangeElement which is at every position in my region"
	
	^myElement! !

!FeElementBundle methodsFor: 'private: create'!

create: region {XnRegion} with: element {FeRangeElement}

	super create: region.
	myElement := element! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeElementBundle class
	instanceVariableNames: ''!

(FeElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeElementBundle class methodsFor: 'create'!

make: region {XnRegion} with: element {FeRangeElement}

	^self create: region with: element! !

!FeElementBundle class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeRangeElement CLIENT} element
"! !

FeBundle subclass: #FeArrayBundle
	instanceVariableNames: '
		myArray {PrimArray}
		myOrder {OrderSpec}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeArrayBundle comment:
'Describes a chunk of information represented as an array. The number of elements in the array are the same as my region, and they are ordered according to OrderSpec given to the retrieve operation which produced me.'!

(FeArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeArrayBundle methodsFor: 'accessing'!

{PrimArray CLIENT} array
	"Essential. The array of elements in this bundle"
	
	^myArray copy!

{OrderSpec CLIENT} ordering
	"Essential. The order relating the elements in the array to the positions in the region."
	
	^myOrder! !

!FeArrayBundle methodsFor: 'private: create'!

create: region {XnRegion} with: array {PrimArray} with: order {OrderSpec}

	super create: region.
	myArray := array.
	myOrder _ order! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeArrayBundle class
	instanceVariableNames: ''!

(FeArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeArrayBundle class methodsFor: 'create'!

make: region {XnRegion} with: array {PrimArray} with: order {OrderSpec}

	^self create: region with: array with: order! !

!FeArrayBundle class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimArray CLIENT} array
{OrderSpec CLIENT} order
"! !

FeBundle subclass: #FePlaceHolderBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FePlaceHolderBundle comment:
'Describes a region of an Edition in which all indices in my region have a distinct PlaceHolder.'!

(FePlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FePlaceHolderBundle methodsFor: 'private: create'!

create: region {XnRegion}

	super create: region.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePlaceHolderBundle class
	instanceVariableNames: ''!

(FePlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FePlaceHolderBundle class methodsFor: 'create'!

make: region {XnRegion}

	^self create: region! !

XnExecutor subclass: #RevisionDetectorExecutor
	instanceVariableNames: 'myWork {FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
RevisionDetectorExecutor comment:
'This class informs its work when its last detector has gone away.'!

(RevisionDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisionDetectorExecutor methodsFor: 'protected: create'!

create: work {FeWork}
	super create.
	myWork := work! !

!RevisionDetectorExecutor methodsFor: 'execute'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myWork removeLastRevisionDetector]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RevisionDetectorExecutor class
	instanceVariableNames: ''!

(RevisionDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisionDetectorExecutor class methodsFor: 'create'!

{XnExecutor} make: work {FeWork}
	^ self create: work! !

XuPromise subclass: #XuBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuBundle comment:
'Describes a single chunk of information from an Edition'!

(XuBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeBundle {FeBundle}
	super create: anFeBundle.! !

!XuBundle methodsFor: 'promise access'!

{FeBundle} getActualFeBundle
	self isBroken
		ifFalse: [^super actualThing cast: FeBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuBundle methodsFor: 'accessing'!

{XuRegion} region

	"Essential. The positions in the Edition for which I describe the contents"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeBundle region)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuBundle class
	instanceVariableNames: ''!

(XuBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBundle class methodsFor: 'pseudo-constructors'!

make: anFeBundle {FeBundle}
	^self create: anFeBundle!

{XuBundle} makeBroken: problem {Problem star}
	| broke {XuBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuBundle subclass: #XuArrayBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuArrayBundle comment:
'Describes a chunk of information represented as an array. The number of elements in the array are the same as my region, and they are ordered according to OrderSpec given to the retrieve operation which produced me.'!

(XuArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuArrayBundle methodsFor: 'promise access'!

{FeArrayBundle} getActualFeArrayBundle
	self isBroken
		ifFalse: [^super actualThing cast: FeArrayBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuArrayBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeArrayBundle {FeArrayBundle}
	super create: anFeArrayBundle.! !

!XuArrayBundle methodsFor: 'accessing'!

{XuArray} array

	"Essential. The array of elements in this bundle"
	
	| retVal {XuArray} |
	(self isBroken) ifTrue:
		[^XuArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuArray make: (self getActualFeArrayBundle array)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuOrderSpec} ordering

	"Essential. The order relating the elements in the array to the positions in the region."
	
	| retVal {XuOrderSpec} |
	(self isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuOrderSpec make: (self getActualFeArrayBundle ordering)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuArrayBundle class
	instanceVariableNames: ''!

(XuArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuArrayBundle class methodsFor: 'pseudo-constructors'!

make: anFeArrayBundle {FeArrayBundle}
	^self create: anFeArrayBundle!

{XuArrayBundle} makeBroken: problem {Problem star}
	| broke {XuArrayBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuArrayBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuBundle subclass: #XuElementBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuElementBundle comment:
'Describes a region of an Edition in which all indices in my region hold the same RangeElement.'!

(XuElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuElementBundle methodsFor: 'promise access'!

{FeElementBundle} getActualFeElementBundle
	self isBroken
		ifFalse: [^super actualThing cast: FeElementBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuElementBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeElementBundle {FeElementBundle}
	super create: anFeElementBundle.! !

!XuElementBundle methodsFor: 'accessing'!

{XuRangeElement} element

	"Essential. The RangeElement which is at every position in my region"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeElementBundle element)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuElementBundle class
	instanceVariableNames: ''!

(XuElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuElementBundle class methodsFor: 'pseudo-constructors'!

make: anFeElementBundle {FeElementBundle}
	^self create: anFeElementBundle!

{XuElementBundle} makeBroken: problem {Problem star}
	| broke {XuElementBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuElementBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

XuBundle subclass: #XuPlaceHolderBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuPlaceHolderBundle comment:
'Describes a region of an Edition in which all indices in my region have a distinct PlaceHolder.'!

(XuPlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPlaceHolderBundle methodsFor: 'promise access'!

{FePlaceHolderBundle} getActualFePlaceHolderBundle
	self isBroken
		ifFalse: [^super actualThing cast: FePlaceHolderBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuPlaceHolderBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFePlaceHolderBundle {FePlaceHolderBundle}
	super create: anFePlaceHolderBundle.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPlaceHolderBundle class
	instanceVariableNames: ''!

(XuPlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPlaceHolderBundle class methodsFor: 'pseudo-constructors'!

make: anFePlaceHolderBundle {FePlaceHolderBundle}
	^self create: anFePlaceHolderBundle!

{XuPlaceHolderBundle} makeBroken: problem {Problem star}
	| broke {XuPlaceHolderBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPlaceHolderBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

Tester subclass: #WorksTester
	instanceVariableNames: '
		myConnection {Connection NOCOPY}
		myCR {Character star NOCOPY}
		myTestID {ID NOCOPY}'
	classVariableNames: 'TheTester {WorksTester} '
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WorksTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	
	| testID {ID} |
	myConnection := Connection make: FeServer.
	myConnection bootHeaper.
	CurrentKeyMaster fluidSet: 
		((FeServer loginByName: (WorksTester sequence: 'Test')) cast: BooLock) boo.
	CurrentKeyMaster fluidGet incorporate: FeKeyMaster makePublic.
	testID := WorksTester clubID: (WorksTester sequence: 'Test').
	InitialOwner fluidSet: testID.
	InitialReadClub fluidSet: testID.
	InitialEditClub fluidSet: testID.
	InitialSponsor fluidSet: testID.
	CurrentAuthor fluidSet: testID.
	
	self makeEditionTestOn: oo.
	self editionTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.

	self crossTestOn: oo.
	self compareTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	
	self globalIDTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self workTestOn: oo.
	self endorseTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self historyTestOn: oo.
	self sponsorTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self kmTestOn: oo.

	self transclusionsTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self transcludersBugTestOn: oo.

	self ownerTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self labelTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	
	FeServer waitForWrite: (WorksWaitDetector make: oo with: 'Test done!!').! !

!WorksTester methodsFor: 'tests'!

{void} compareTestOn: oo {ostream reference}
	"Test the various version comparision operations"
	
	| a {FeEdition} b {FeEdition} work1 {FeWork} work2 {FeWork} work3 {FeWork} edn {FeEdition} region {XnRegion} |
	a := FeEdition placeHolders: (IntegerRegion interval: Int32Zero with:100).
	b := (((a copy: (IntegerSpace make below: (IntegerPos make: 50) with: false))
		transformedBy: (IntegerSpace make translation: 100))
		combine: (FeEdition placeHolders: (IntegerSpace make interval: (IntegerPos make: Int32Zero) with: (IntegerPos make: 50))))
		combine: ((a copy: (IntegerSpace make interval: (IntegerPos make: 25) with: (IntegerPos make: 75)))
		transformedBy: (IntegerSpace make translation: 25)).
	oo << 'a sharedWith b: ' << (a sharedWith: b) << myCR
		<< 'a notSharedWith b: ' << (a notSharedWith: b) << myCR
		<< 'a sharedRegion b: ' << (a sharedRegion: b) << myCR
		<< 'a mapSharedTo b: ' << (a mapSharedTo: b) << myCR
		<< 'a sharedRegion b copy [120,130): '
			<< (a sharedRegion: (b copy: (IntegerRegion make: 120 with: 130))) << myCR
		<< 'a keysOf a[50]: ' << (a positionsOf: (a get: (IntegerPos make: 50))) << myCR
		<< 'b sharedWith a: ' << (b sharedWith: a) << myCR
		<< 'b notSharedWith a: ' << (b notSharedWith: a) << myCR
		<< 'b mapSharedTo a: ' << (b mapSharedTo: a) << myCR
		<< 'b sharedRegion a: ' << (b sharedRegion: a) << myCR
		<< 'b sharedRegion a copy [20,30): '
			<< (b sharedRegion: (a copy: (IntegerRegion make: 20 with: 30))) << myCR
		<< 'b positionsOf a[50]: ' << (b positionsOf: (a get: (IntegerPos make: 50))) << myCR.
	work1 := FeWork make: (FeText make: (UInt8Array string: 'foo')) edition.
	work2 := FeWork make: (FeEdition fromOne: Int32Zero integer with: work1).
	edn := FeEdition fromOne: Int32Zero integer with: work1.
	work3 := work2 edition theOne cast: FeWork.
	region := edn positionsOf: work3.
	oo << 'region = ' << region << myCR.!

{void} crossTestOn: oo {ostream reference}

	| four {PtrArray} is {IDSpace} cross {CrossSpace} doc {FeEdition} |
	oo << myCR << 'CrossSpace retrieval test' <<myCR.
	four := PtrArray nulls: 4.
	is := IDSpace unique.
	four at: UInt32Zero store: is.
	four at: 1 store: IntegerSpace make.
	four at: 2 store: IntegerSpace make.
	four at: 3 store: IntegerSpace make.
	cross := CrossSpace make: four.
	doc := FeEdition empty: cross.
	
	1 to: 10 do: [ :i {Int32} |
		four at: UInt32Zero store: is newID asRegion.
		four at: 1 store: (IntegerSpace make interval: (IntegerPos make: i) with: (IntegerPos make: i + 4)).
		four at: 2 store: (IntegerSpace make interval: (IntegerPos make: i) with: (IntegerPos make: 21 - i)).
		four at: 3 store: (IntegerSpace make interval: (IntegerPos make: i) with: (IntegerPos make: i + 1)).
		doc := doc combine: (FeEdition fromAll: (cross crossOfRegions: four)
			with: (FeDataHolder make: (PrimIntValue make: i)))].
	
	1 to: 3 do: [ :j {Int32} |
		oo << 'Looking for dimension ' << j << ' >= 10' << myCR.
		(doc copy: (cross extrusion: j with: (IntegerSpace make above: (IntegerPos make: 10) with: true)))
			retrieve forEach: [ :bundle {FeElementBundle} |
				oo << 'found ' << bundle element << ' at ' << bundle region << myCR]].!

{void} editionTestOn: oo {ostream reference}
	"Test the simple Edition operations"
	
	| edition {FeEdition} |
	oo << 'Testing various Edition operations' << myCR.
	edition := FeEdition empty: IntegerSpace make.
	oo << 'initially: ' << edition << myCR
		<< ' coordinateSpace: ' << edition coordinateSpace << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	edition := edition with: (IntegerPos make: Int32Zero) with: FeRangeElement placeHolder.
	oo << 'with(0): ' << edition << myCR
		<< ' theOne: ' << edition theOne << myCR.
	edition := edition withAll: (IntegerSpace make above: (IntegerPos make: 1) with: true)
		with: (FeDataHolder make: (PrimIntValue make: 65)).
	oo << 'withAll: ' << edition << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	oo << 'stepper:' << myCR.
	[ScruTable] USES.
	(edition stepper: (IntegerSpace make interval: (IntegerPos make: IntegerVarZero) with: (IntegerPos make: 2))) forPositions:
		[ :p {Position} :v {FeRangeElement} |
		oo << ' ' << p << ' -> ' << v << myCR].
	edition := edition without: (IntegerPos make: 3).
	oo << 'without 3' << edition << myCR.
	edition := edition withoutAll: (IntegerSpace make above: (IntegerPos make: 2) with: true).
	oo << 'withoutAll: ' << edition << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR
		<< ' get 1: ' << (edition get: (IntegerPos make: 1)) << myCR.
	
	oo << 'combined: ' << (edition combine: (FeEdition fromOne: (IntegerPos make: 5)
			with: FeRangeElement placeHolder)) << myCR.
	oo << 'replaced: ' << (edition replace: (FeEdition fromOne: (IntegerPos make: 1)
			with: FeRangeElement placeHolder)) << myCR.!

{void} endorseTestOn: oo {ostream reference}
	"Test endorsing and unendorsing Editions and Works"
	
	| e1 {FeEdition} w1 {FeWork} iD {ID} userRegion {IDRegion} |
	e1 := FeEdition empty: IntegerSpace make.
	w1 := FeWork make: e1.
	oo << 'Initial endorsements:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR << myCR.
	
	userRegion _ CurrentAuthor fluidGet asRegion cast: IDRegion.
	e1 endorse: (FeServer endorsementRegion: userRegion with: userRegion).
	iD := IDSpace global newID.
	w1 endorse: (FeServer endorsementRegion: userRegion with: (iD asRegion cast: IDRegion)).
	oo << 'After endorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.
	
	e1 retract: (FeServer endorsementRegion: userRegion with: userRegion).
	w1 retract: (FeServer endorsementRegion: userRegion with: (iD asRegion cast: IDRegion)).
	oo << 'After unendorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.!

{void} globalIDTestOn: oo {ostream reference}
	"Test assigning and retrieving by global IDs"
	
	| p1 {FeRangeElement as: FePlaceHolder} id1a {ID} id1b {ID} ids {IDRegion}
	  p2 {FeRangeElement as: FePlaceHolder} id2 {ID} ed {FeEdition} |
	p1 := FeRangeElement placeHolder.
	(ids := FeServer iDsOf: p1) isEmpty ifFalse:
		[oo << 'Newly created place holder ' << p1
			<< ' should not have had any IDs but was reported to have ' << ids << myCR].
	id1a := FeServer assignID: p1.
	((ids := FeServer iDsOf: p1) isEqual: id1a asRegion) ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << id1a asRegion
			<< ' but was reported to have IDs ' << ids << myCR].
	id1b := FeServer assignID: p1.
	((ids := FeServer iDsOf: p1) isEqual: (id1a asRegion with: id1b)) ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << (id1a asRegion with: id1b)
			<< ' but was reported to have IDs ' << ids << myCR].
	p2 := FeRangeElement placeHolder.
	id2 := FeServer assignID: p2.
	ed := (FeEdition fromOne: (IntegerPos make: Int32Zero) with: p1)
		combine: (FeEdition fromOne: (IntegerPos make: 1) with: p2).
	((ids := FeServer iDsOfRange: ed)
			isEqual: ((id1a asRegion with: id1b) with: id2))
		ifFalse:
			[oo << 'PlaceHolders ' << ed
				<< ' should have IDs ' << ((id1a asRegion with: id1b) with: id2)
				<< ' but was reported to have IDs ' << ids << myCR].

	oo << 'Global ID assignment test successful
'!

{void} historyTestOn: oo {ostream reference}
	| work {FeWork} |
	work _ FeWork make: (FeEdition fromArray: (WorksTester string: 'Howdy doody.')).
	work setHistoryClub: FeServer publicClubID.
	work revise: (FeEdition fromArray: (WorksTester string: 'Good bye')).
	work revise: (FeEdition fromArray: (WorksTester string: 'Much better.')).
	oo << 'The trail is: ' << work revisions << myCR.
	work revisions stepper forPositions: 
		[:position {Position} :value {FeWork} |
		oo << position << '->' << (value edition retrieve theOne cast: FeArrayBundle) array << myCR].
	
	"self halt."
	oo << myCR.!

{void} kmTestOn: oo {ostream reference}
	"Test the operation of KeyMasters"
	
	| km {FeKeyMaster} clubspec {FeWrapperSpec} test {FeClub}
	  club1 {FeClub} detect1 {FeStatusDetector} work1 {FeWork}
	  club2 {FeClub} detect2 {FeStatusDetector} work2 {FeWork}
	  desc {FeClubDescription}  |
	
	km := CurrentKeyMaster fluidGet copy.
	CurrentKeyMaster fluidBind: km during:
		[clubspec := FeWrapperSpec get: (WorksTester sequence: 'ClubDescription').
		test := (FeServer get: CurrentAuthor fluidGet) cast: FeClub.
		
		club1 := FeClub make: 
				(FeClubDescription make: FeSet make with: FeBooLockSmith make) edition.
		oo << 'Club1 ' << (FeServer iDOf: club1) << ' is initially '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km actualAuthority << myCR << myCR.

		oo << 'Logged in as ' << ((FeServer login: (FeServer iDOf: club1)) cast: BooLock) boo.
		
		club2 := FeClub make: (FeClubDescription make: FeSet make with: FeBooLockSmith make) edition.
		oo << 'Club 2 ' << (FeServer iDOf: club2) << ' is initially '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km actualAuthority << myCR << myCR.
		
		InitialEditClub fluidBind: (FeServer iDOf: club1) during:
		[InitialReadClub fluidBind: (FeServer iDOf: club1) during:
			[work1 := FeWork make: (FeEdition empty: IntegerSpace make)]].
		detect1 := (WorksTestStatusDetector make: oo with: '
Work 1').
		work1 addStatusDetector: detect1.
		oo << 'Giving Work 1 edit authority to Club 1' << myCR.
		work1 requestGrab.
		
		InitialEditClub fluidBind: (FeServer iDOf: club2) during:
			[work2 := FeWork make: (FeEdition empty: IntegerSpace make)].
		detect2 := (WorksTestStatusDetector make: oo with: '
Work 2').
		work2 addStatusDetector: detect2.
		oo << 'Giving Work 2 edit authority to Club 2' << myCR.
		work2 requestGrab.
		
		desc := (clubspec wrap: club1 edition) cast: FeClubDescription.
		club1 revise: (desc withMembership: (desc membership with: test)) edition.
		oo << 'Club 1 should now have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become grabbed: ' << work1 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) cast: FeClubDescription.
		club2 revise: (desc withMembership: (desc membership with: club1)) edition.
		oo << 'Club 2 should now have Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should have become grabbed: ' << work2 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) cast: FeClubDescription.
		club2 revise: (desc
			withMembership: ((desc membership
				without: club1) with: (FeServer get: FeServer publicClubID))) edition.
		oo << 'Club 2 should have Public but not Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should retain Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should remain grabbed: ' << work2 canRevise << myCR << myCR.
		
		km removeLogins: (FeServer publicClubID asRegion cast: IDRegion).
		oo << 'The combined KeyMaster should have lost Public & Club 2 authority: '
			<< ' login ' << km loginAuthority << myCR
			<< ' actual ' << km actualAuthority << myCR
			<< 'and Work 2 should have become released but readable:'
			<< ' canRevise ' << work2 canRevise
			<< ' canRead ' << work2 canRead << myCR << myCR.
		
		desc := (clubspec wrap: club1 edition) cast: FeClubDescription.
		club1 revise: (desc withMembership: (desc membership without: test)) edition.
		oo << 'Club 1 should no longer have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should not have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become released and unreadable:'
			<< ' canRevise ' << work1 canRevise
			<< ' canRead ' << work1 canRead << myCR << myCR.
		
		"work2 removeStatusDetector: detect2."
		"work1 removeStatusDetector: detect1."
		club1 release.
		club2 release].

	self thingToDo. "Clean up persistent information in Server"!

{void} labelTestOn: oo {ostream reference}
	|    edition {FeEdition} e1 {FeEdition} e2 {FeEdition} e3 {FeEdition} 
	  e4 {FeEdition} e1prime {FeEdition} edition2 {FeEdition} |
	e1 _ FeEdition fromArray: (WorksTester string: 'First Edition').
	e2 _ FeEdition fromArray: (WorksTester string: 'Second Edition').
	e3 _ FeEdition fromArray: (WorksTester string: 'Third Edition').
	e4 _ FeEdition fromArray: (WorksTester string: 'Fourth Edition').
	
	edition _ FeEdition fromArray: (PrimSpec pointer arrayWithThree: e1 with: e2 with: (FeWork make: e1)).
	
	oo << 'Labels:' << myCR.
	oo << ' ' << e1 label << ' ' << e2 label << ' ' << e3 label << ' ' << e4 label << myCR.
	oo << 'labelled e1: '<< (edition positionsLabelled: e1 label) << myCR.
	e1prime _ ((edition fetch: (IntegerPos make: IntegerVarZero)) cast: FeEdition) with: (IntegerPos make: 1) with: FeRangeElement placeHolder.
	
	edition2 _ edition with: (IntegerPos make: IntegerVarZero) with: e1prime.
	oo << 'edit e1: ' << (edition2 positionsLabelled: e1 label) << myCR.
	
	oo << 'labelled e2: ' << (edition2 positionsLabelled: e2 label) << myCR.
	oo << 'rebind e2: ' << ((edition2 rebind: (IntegerPos make: 1) with: e3) positionsLabelled: e2 label) << myCR.
	oo << 'duplicate e1: ' << ((edition2 with: (IntegerPos make: 1) with: e1) positionsLabelled: e1 label) << myCR.
	
	oo << myCR.!

{void} makeEditionTestOn: oo {ostream reference}
	"Try making Editions in a variety of ways"
	
	| edn {FeEdition} place {FeRangeElement} data {FeDataHolder} bits {PrimArray} |
	oo << (edn := FeEdition empty: SequenceSpace make) << myCR
		<< (FeEdition empty: IntegerSpace make) << myCR.
	
	oo << (FeEdition placeHolders: (IntegerSpace make interval: (IntegerPos make: IntegerVarZero) with: (IntegerPos make: 10))) << myCR
		<< (FeEdition placeHolders: SequenceSpace make emptyRegion) << myCR
		<< (FeEdition placeHolders: SequenceSpace make fullRegion) << myCR.
	
	data := FeDataHolder make: (PrimIntValue make: 3).
	place := FeRangeElement placeHolder.
	oo << (FeEdition fromOne: (IntegerPos make: IntegerVarZero) with: edn) << myCR
		<< (FeEdition fromOne: (IntegerPos make: 1) with: place) << myCR
		<< (FeEdition fromOne: (IntegerPos make: 2) with: data) << myCR.
	
	oo << (FeEdition fromAll: (IntegerSpace make above: (IntegerPos make: 10) with: true) with: edn) << myCR
		<< (FeEdition fromAll: (IntegerSpace make below: (IntegerPos make: 100) with: false) with: place) << myCR
		<< (FeEdition fromAll: IntegerSpace make emptyRegion with: place) << myCR
		<< (FeEdition fromAll: IDSpace unique fullRegion with: data) << myCR.
	
	oo << (FeEdition fromArray: (WorksTester string: '')) << myCR.
	oo << (FeEdition fromArray: (WorksTester string: 'hello world')) << myCR.
	
	bits := WorksTester string: 'hello world!!'.
	oo << (FeEdition fromArray: bits) << myCR
		<< (FeEdition fromArray: bits with: (IntegerSpace make interval: (IntegerPos make: 10) with: (IntegerPos make: 22))) << myCR
		"<< (FeEdition fromArray: bits
			with: NULL
			with: IntegerSpace make getDescending) << myCR
		<< (FeEdition fromArray: bits
			with: (IntegerSpace make interval: (IntegerPos make: 100) with: (IntegerPos make: 113))
			with: IntegerSpace make getDescending) << myCR".
	
	oo << 'Making Editions test finished' << myCR << myCR.!

{void} ownerTestOn: oo {ostream reference}
	|  work {FeWork} club {FeClub} edition {FeEdition} |
	club := (FeServer get: FeServer publicClubID) cast: FeClub.
	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.

	InitialOwner fluidBind: CurrentAuthor fluidGet during:
		[work _ FeWork make: (FeEdition fromArray: (WorksTester string: 'The one I can change.'))].
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	edition _ FeEdition fromArray: (PrimSpec pointer arrayWithTwo: work with: club) 
		with: ((WorksTester sequence: 'changeable') asRegion with: (WorksTester sequence: 'permanent'))
		with: SequenceSpace make ascending.
	
	oo << 'Set owners of: ' << edition << myCR.
	oo << 'result: ' << (edition setRangeOwners: FeServer publicClubID) << myCR.

	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	oo << myCR.!

{void} sponsorTestOn: oo {ostream reference}
	"Test the sponsoring mechanism"
	
	| club {FeClub} testClub {FeClub} blank {FeEdition} w1 {FeWork} w2 {FeWork} |
	testClub := (FeServer get: CurrentAuthor fluidGet) cast: FeClub.
	club := FeClub make: 
			(FeClubDescription make: 
				(FeSet make: 
					((PrimSpec pointer arrayWith: (FeServer get: CurrentAuthor fluidGet)) cast: PtrArray))
		with: FeWallLockSmith make) edition.
	
	blank := FeEdition fromArray: (UInt8Array string:'blank').
	w1 := FeWork make: blank.
	FeServer assignID: w1.
	w2 := FeWork make: blank.
	FeServer assignID: w1.
	oo << 'Initially ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 sponsor: (CurrentAuthor fluidGet asRegion cast: IDRegion).
	w2 sponsor: ((CurrentAuthor fluidGet asRegion
					with: (FeServer iDOf: club)) cast: IDRegion).
	oo << 'After sponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 unsponsor: (CurrentAuthor fluidGet asRegion cast: IDRegion).
	w2 unsponsor: ((CurrentAuthor fluidGet asRegion
					with: (FeServer iDOf: club)) cast: IDRegion).
	oo << 'After unsponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	
	self thingToDo. "test authority checks"
	self thingToDo. "get rid of persistent info"!

{void} transcludersBugTestOn: oo {ostream reference}
	
	|  text {FeText} refs {FeEdition} work {FeWork}
	  detector {FeFillRangeDetector} container {FeEdition}
	  text2 {FeText} values {PtrArray} |

	oo << myCR << myCR << 'Transcluders bug test' << myCR << myCR.

	"Test a bug in the transcluders mechanism:
		if E1 = {x -> E2}, then E1 transcluders will be triggered by an Edition containing E2"
	text := FeText make: ((WorksTester string: 'oops') cast: PrimDataArray).
	container := FeEdition fromOne: 1 integer with: text edition.
	refs := container transcluders: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter.
	detector := WorksTestFillRangeDetector make: oo
		with: 'Should not have been transcluded by '.
	refs addFillRangeDetector: detector.
	work := FeWork make: (FeSingleRef make: text edition) edition.
	refs removeFillRangeDetector: detector.
	
	"if E1 = {x -> E2, y -> E3}, then E1 transcluders may be triggered by another separately created Edition containing E1 & E2?"
	values := PtrArray nulls: 2.
	text2 := FeText make: ((WorksTester string: 'oops') cast: PrimDataArray).
	values at: UInt32Zero store: text edition.
	values at: 1 store: text2 edition.
	container := FeEdition fromArray: values.
	refs := container transcluders: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter.
	refs addFillRangeDetector: detector.
	work revise: (FeEdition fromArray: values).
	refs removeFillRangeDetector: detector.!

{void} transclusionsTestOn: oo {ostream reference}
	"Test the transclusions query"
	
	|  text {FeText} n {IntegerVar} texts {FeEdition} refs {FeEdition}
	  detector {FeFillRangeDetector} work {FeWork} interval {IntegerRegion} |

	oo << myCR << myCR << 'Transclusions test' << myCR << myCR.
	text := FeText make: ((WorksTester string: '(abcdefghijklmnopqrstuvwxyz)') cast: PrimDataArray).
	n := text count.
	work := FeWork make: (FeSingleRef make: text edition) edition.
	texts := text edition rangeTranscluders: NULL
		with: (FeWrapperSpec get: (WorksTester sequence: 'Text')) filter.
	refs := text edition rangeTranscluders: NULL
		with: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter.
	detector := WorksTestFillRangeDetector make: oo with: 'Transcluded by '.
	texts addFillRangeDetector: detector.
	refs addFillRangeDetector: detector.

	interval _ IntegerSpace make interval: (IntegerPos make: (n // 2)) with: (IntegerPos make: n).
	text := text move: IntegerVarZero with: interval.
	work revise: (FeSingleRef make: text edition) edition.
	text := text extract: ((IntegerRegion integerExtent: n // 4 with: n // 4) complement cast: IntegerRegion).
	work revise: (FeSingleRef make: text edition) edition.
	text := text insert: n // 2 with: (FeText make: (((WorksTester string: '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]')) cast: PrimDataArray)).
	work revise: (FeSingleRef make: text edition) edition.
	
	texts := text edition rangeTranscluders: interval
		with: (FeWrapperSpec get: (WorksTester sequence: 'Text')) filter
		with: NULL
		with: Int32Zero
		with: texts.
	refs := text edition rangeTranscluders: interval
		with: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter
		with: NULL
		with: Int32Zero
		with: refs.
	
	text := text extract: (IntegerSpace make above: (IntegerPos make: n // 2) with: true).
	work revise: (FeSingleRef make: text edition) edition.
	text := text extract: (IntegerSpace make below: (IntegerPos make: n) with: false).
	work revise: (FeSingleRef make: text edition) edition.
	text := text move: IntegerVarZero with: interval.
	work revise: (FeSingleRef make: text edition) edition.
	
	texts removeFillRangeDetector: (detector cast: FeFillRangeDetector).
	refs removeFillRangeDetector: (detector cast: FeFillRangeDetector).!

{void} workTestOn: oo {ostream reference}
	"Try the various operations on Works"
	
	| e1 {FeEdition} w1 {FeWork} km {FeKeyMaster} |
	e1 := FeEdition fromArray: (WorksTester string: 'hello world').
	w1 := FeWork make: e1.
	self dumpWorkOn: oo with: 'As newly created ' with: w1.
	
	w1 addStatusDetector: (WorksTestStatusDetector make: oo with: '
Work 1').
	w1 release.
	
	self dumpWorkOn: oo with: 'With authority restored' with: w1.
	w1 grab.
	self dumpWorkOn: oo with: 'Grabbed' with: w1.
	CurrentKeyMaster fluidBind: ((FeServer loginByName: (Sequence string: 'Test')) cast: BooLock) boo during:
		[w1 grab.
		self dumpWorkOn: oo with: 'Grabbed again' with: w1].
	w1 requestGrab.
	self dumpWorkOn: oo with: 'Grab requested again' with: w1.
	w1 release.
	self dumpWorkOn: oo with: 'Released' with: w1.

	km := FeKeyMaster makePublic.
	CurrentKeyMaster fluidBind: km during:
		[w1 requestGrab.
		self dumpWorkOn: oo with: 'Grab requested yet again' with: w1.
		km incorporate: ((FeServer loginByName: (Sequence string: 'Test')) cast: BooLock) boo.
		self dumpWorkOn: oo with: 'KeyMaster incorporated' with: w1].
	
	km removeLogins: (CurrentAuthor fluidGet asRegion cast: IDRegion).
	self dumpWorkOn: oo with: 'KeyMaster login removed' with: w1.! !

!WorksTester methodsFor: 'private:'!

{void} dumpWorkOn: oo {ostream reference} with: tag {char star} with: work {FeWork}
	"Print the state and contents of a Work"
	
	oo << myCR << tag << '['.
	work canRead ifTrue:
		[oo << work edition].
	work canRevise ifTrue:
		[oo << ' (grabbed)'].
	oo << ']'! !

!WorksTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartWorksTester: rcvr {Rcvr unused default: NULL}

	myConnection := NULL.
	myCR := '
'! !

!WorksTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartWorksTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTester class
	instanceVariableNames: ''!

(WorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WorksTester class methodsFor: 'server library'!

{ID} clubID: clubName {Sequence}
	"Looks up the ID of a named Club in the directory maintained by the System Admin Club. Requires read permission on the directory. Blasts if there is no Club with that name."
	
	^FeServer iDOf: (((FeServer get: FeServer clubDirectoryID) cast: FeWork) edition get: clubName)!

{IntegerPos} integer: val {IntegerVar}

	^ IntegerPos make: val!

{Sequence} sequence: string {char star}

	^ Sequence string: string!

{PrimArray} string: string {char star}

	^UInt8Array string: string! !

!WorksTester class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	TheTester := NULL!

staticTimeNonInherited
	"PrServer defineFluid: #ClientServer with: XuPromise emulsion with: [NULL]"! !

XuPromise subclass: #XuServer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuServer comment:
'The fundamental Server object. Used for managing the global name space, creating Works, Editions, and Clubs, and other general server management operations.

Many operations in the protocol use fluidly bound parameters. The possible parameters are:
	FeServer defineClientFluid: #CurrentServer with: Listener emulsion with: [NULL].

CurrentKeyMaster - a KeyMaster for providing authority to read and/or edit
CurrentAuthor - the ID of the Club under whose name Work revisions are being done; requires signature authority
InitialReadClub - the ID of the initial read Club of all newly created Works and Clubs
InitialEditClub - the ID of the initial edit Club of all newly created Works and Clubs
InitialOwner - the ID of the Club which owns newly created RangeElements
InitialSponsor - the ID of the Club which sponsors newly created Works and Clubs; requires signature authority'!

(XuServer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuServer methodsFor: 'promise access'!

{FeServer} getActualFeServer
	self isBroken
		ifFalse: [^super actualThing cast: FeServer.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuServer methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeServer {FeServer}
	super create: anFeServer.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuServer class
	instanceVariableNames: ''!

(XuServer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuServer class methodsFor: 'pseudo-constructors'!

make: anFeServer {FeServer}
	^self create: anFeServer!

{XuServer} makeBroken: problem {Problem star}
	| broke {XuServer} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuServer} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

Tester subclass: #PrWorksTester
	instanceVariableNames: '
		myConnection {Connection NOCOPY}
		myServer {PrServer NOCOPY}
		myCR {Character NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(PrWorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #SMALLTALK.ONLY; yourself)!

!PrWorksTester methodsFor: 'private:'!

{void} dumpWorkOn: oo {ostream reference} with: tag {char star} with: work {PrWork}
	"Print the state and contents of a Work"
	
	oo << tag << $[.
	work canRead value ifTrue:
		[oo << work edition].
	work canRevise value ifTrue:
		[oo << ' (grabbed)'].
	oo << $]! !

!PrWorksTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartWorksTester: rcvr {Rcvr unused default: NULL}

	myServer _ NULL.
	myConnection := NULL.
	myCR := Character cr.! !

!PrWorksTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	
	| gk {XuServer} testID {XuID} |
	myConnection := Connection make: XuServer.
	gk := myConnection bootHeaper cast: XuServer.
	XuCurrentKeyMaster fluidSet: 
		((gk loginByName: (PrWorksTester sequence: 'Test'))
			delayCast: XuBooLock) boo.
	PrCurrentServer fluidSet: myServer.
	XuCurrentKeyMaster fluidGet incorporate: XuKeyMaster make.
	testID := PrWorksTester clubID: (PrWorksTester sequence: 'Test').
	XuInitialOwner fluidSet: testID.
	XuInitialReadClub fluidSet: testID.
	XuInitialEditClub fluidSet: testID.
	XuInitialSponsor fluidSet: testID.
	XuCurrentAuthor fluidSet: testID.
	
	self makeEditionTestOn: oo.
	self editionTestOn: oo.
	self compareTestOn: oo.
	
	self globalIDTestOn: oo.
	self workTestOn: oo.
	self endorseTestOn: oo.
	self historyTestOn: oo.
	self sponsorTestOn: oo.
	self kmTestOn: oo.

	"self transclusionsTestOn: oo."

	self ownerTestOn: oo.
	self labelTestOn: oo.
	
	XuServer waitForWrite: (WorksWaitDetector create: oo with: 'Test done!!').! !

!PrWorksTester methodsFor: 'tests'!

{void} compareTestOn: oo {ostream reference}
	"Test the various version comparision operations"
	
	| a {XuEdition} b {XuEdition} |
	a := myServer newPlaceHolders: (myServer integerSpace interval: (XuInteger make: Int32Zero) with: (XuInteger make: 100)).
	b := (((a copy: (myServer integerSpace below: (XuInteger make: 50) with: (XuInteger make: false)))
		transformedBy: (myServer integerSpace translation: (XuInteger make: 100)))
		combine: (myServer newPlaceHolders: (myServer integerSpace interval: (XuInteger make: Int32Zero) with: (XuInteger make: 50))))
		combine: ((a copy: (myServer integerSpace interval: (XuInteger make: 25) with: (XuInteger make: 75)))
		transformedBy: (myServer integerSpace translation: (XuInteger make: 25))).
	oo << 'a sharedWith b: ' << (a sharedWith: b) << myCR
		<< 'a notSharedWith b: ' << (a notSharedWith: b) << myCR
		<< 'a sharedRegion b: ' << (a sharedRegion: b) << myCR
		<< 'a mapSharedTo b: ' << (a mapSharedTo: b) << myCR
		<< 'a keysOf a[50]: ' << (a positionsOf: (a get: (PrWorksTester integer: 50))) << myCR
		<< 'b sharedWith a: ' << (b sharedWith: a) << myCR
		<< 'b notSharedWith a: ' << (b notSharedWith: a) << myCR
		<< 'b mapSharedTo a: ' << (b mapSharedTo: a) << myCR
		<< 'b sharedRegion a: ' << (b sharedRegion: a) << myCR
		<< 'b positionsOf a[50]: ' << (b positionsOf: (a get: (PrWorksTester integer: 50))) << myCR.!

{void} editionTestOn: oo {ostream reference}
	"Test the simple Edition operations"
	
	| edition {XuEdition} |
	oo << 'Testing various Edition operations' << myCR.
	edition := myServer newEmptyEdition: myServer integerSpace.
	oo << 'initially: ' << edition << myCR
		<< ' coordinateSpace: ' << edition coordinateSpace << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	edition := edition with: (PrWorksTester integer: Int32Zero) with: myServer newPlaceHolder.
	oo << 'with(0): ' << edition << myCR
		<< ' theOne: ' << edition theOne << myCR.
	edition := edition withAll: (myServer integerSpace above: (XuInteger make: 1) with: (XuInteger make: true))
		with: (myServer newDataHolder: (PrWorksTester uInt8Spec value: (XuInteger make: 65))).
	oo << 'withAll: ' << edition << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	oo << 'stepper:' << myCR.
	(edition stepper: (myServer integerSpace interval: (XuInteger make: IntegerVarZero) with: (XuInteger make: 2))) forPromisedPairs:
		[ :k {Position} :v {XuRangeElement} |
		oo << ' ' << k << ' -> ' << v << myCR].
	edition := edition without: (PrWorksTester integer: 3).
	oo << 'without 3' << edition << myCR.
	edition := edition withoutAll: (myServer integerSpace above: (XuInteger make: 2) with: (XuInteger make: true)).
	oo << 'withoutAll: ' << edition << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR
		<< ' get 1: ' << (edition get: (PrWorksTester integer: 1)) << myCR.
	
	oo << 'combined: ' << (edition combine: (myServer
			newEditionWith: (PrWorksTester integer: 5)
			with: myServer newPlaceHolder)) << myCR.
	oo << 'replaced: ' << (edition replace: (myServer
			newEditionWith: (PrWorksTester integer: 1)
			with: myServer newPlaceHolder)) << myCR.!

{void} endorseTestOn: oo {ostream reference}
	"Test endorsing and unendorsing Editions and Works"
	
	| e1 {PrEdition} w1 {PrWork} iD {PrID} userRegion {PrIDRegion} |
	e1 := myServer newEmptyEdition: myServer integerSpace.
	w1 := myServer newWork: e1.
	oo << 'Initial endorsements:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR << myCR.
	
	userRegion _ PrCurrentAuthor fluidGet asRegion delayCast: PrIDRegion.
	e1 endorse: (myServer endorsementRegion: userRegion with: userRegion).
	iD := XuIDSpace global newID.
	w1 endorse: (myServer endorsementRegion: userRegion with: (iD asRegion delayCast: PrIDRegion)).
	oo << 'After endorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.
	
	e1 retract: (myServer endorsementRegion: userRegion with: userRegion).
	w1 retract: (myServer endorsementRegion: userRegion with: (iD asRegion delayCast: PrIDRegion)).
	oo << 'After unendorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.!

{void} globalIDTestOn: oo {ostream reference}
	"Test assigning and retrieving by global IDs"
	
	| p1 {PrPlaceHolder} id1a {PrID} id1b {PrID} ids {PrIDRegion}
	  p2 {PrPlaceHolder} id2 {PrID} ed {PrEdition} |
	p1 := myServer newPlaceHolder.
	(ids := myServer iDsOf: p1) isEmpty value ifFalse:
		[oo << 'Newly created place holder ' << p1
			<< ' should not have had any IDs but was reported to have ' << ids << myCR].
	id1a := myServer assignID: p1.
	((ids := myServer iDsOf: p1) areActualsEqual: id1a asRegion) value ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << id1a asRegion
			<< ' but was reported to have IDs ' << ids << myCR].
	id1b := myServer assignID: p1.
	((ids := myServer iDsOf: p1) areActualsEqual: (id1a asRegion with: id1b)) value ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << (id1a asRegion with: id1b)
			<< ' but was reported to have IDs ' << ids << myCR].
	p2 := myServer newPlaceHolder.
	id2 := myServer assignID: p2.
	ed := (myServer newEditionWith: (PrWorksTester integer: Int32Zero) with: p1)
		combine: (myServer newEditionWith: (PrWorksTester integer: 1) with: p2).
	((ids := myServer iDsOfRange: ed)
			areActualsEqual: ((id1a asRegion with: id1b) with: id2)) value
		ifFalse:
			[oo << 'PlaceHolders ' << ed
				<< ' should have PrIDs ' << ((id1a asRegion with: id1b) with: id2)
				<< ' but was reported to have IDs ' << ids << myCR].

	oo << 'Global ID assignment test successful
'!

{void} historyTestOn: oo {ostream reference}
	| work {PrWork} |
	work _ myServer newWork: (myServer newEdition: (PrWorksTester string: 'Howdy doody.')).
	work setHistoryClub: myServer publicClubID.
	work revise: (myServer newEmptyEdition: myServer integerSpace).
	work revise: (myServer newEdition: (PrWorksTester string: 'Much better.')).
	oo << 'The trail is: ' << work revisions << myCR.
	work revisions stepper forPromisedPairs: 
		[:key {Position} :value {PrWork} |
		oo << key << '->' << value edition retrieve << myCR].
	
	"self halt."
	oo << myCR.!

{void} kmTestOn: oo {ostream reference}
	"Test the operation of KeyMasters"
	
	| km {PrKeyMaster} s {PrServer} clubspec {PrWrapperSpec} test {PrClub}
	  club1 {PrClub} detect1 {FeStatusDetector} work1 {PrWork}
	  club2 {PrClub} detect2 {FeStatusDetector} work2 {PrWork}
	  desc {PrClubDescription} |
	
	km := PrCurrentKeyMaster fluidGet copy.
	PrCurrentKeyMaster fluidBind: km during:
		[s := myServer.
		clubspec := s wrapperSpec: (PrWorksTester sequence: 'ClubDescription').
		test := (s get: PrCurrentAuthor fluidGet) delayCast: PrClub.
		
		club1 := s newClub: (s
			newClubDescription: s newSet
			with: s newBooLockSmith) edition.
		oo << 'Club1 is initially '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km << myCR << myCR.

		club2 := s newClub: (s
			newClubDescription: s newSet
			with: s newBooLockSmith) edition.
		oo << 'Club 2 is initially '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km << myCR << myCR.
		
		PrInitialEditClub fluidBind: (s iDOf: club1) during:
			[work1 := s newWork: (s newEmptyEdition: s integerSpace)].
		detect1 := (WorksTestStatusDetector make: oo with: '
Work 1').
		work1 addStatusDetector: detect1.
		oo << 'Giving Work 1 edit authority to Club 1' << myCR.
		work1 requestGrab.
		
		PrInitialEditClub fluidBind: (s iDOf: club2) during:
			[work2 := s newWork: (s newEmptyEdition: s integerSpace)].
		detect2 := (WorksTestStatusDetector make: oo with: '
Work 2').
		work2 addStatusDetector: detect2.
		oo << 'Giving Work 2 edit authority to Club 2' << myCR.
		work2 requestGrab.
		
		desc := (clubspec wrap: club1 edition) delayCast: PrClubDescription.
		club1 revise: (desc withMembership: (desc membership with: test)) edition.
		oo << 'Club 1 should now have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become grabbed: ' << work1 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) delayCast: PrClubDescription.
		club2 revise: (desc withMembership: (desc membership with: club1)) edition.
		oo << 'Club 2 should now have Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should have become grabbed: ' << work2 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) delayCast: PrClubDescription.
		club2 revise: (desc withMembership: ((desc membership without: club1) with: test)) edition.
		oo << 'Club 2 should have Public but not Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should retain Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should remain grabbed: ' << work2 canRevise << myCR << myCR.
		
		km removeLogins: s publicClubID asRegion.
		oo << 'The combined KeyMaster should have lost Public & Club 2 authority: '
			<< km loginAuthority << myCR
			<< km actualAuthority << myCR
			<< 'and Work 2 should have become released but unreadable:'
			<< ' canRevise ' << work2 canRevise
			<< ' canRead ' << work2 canRead << myCR << myCR.
		
		desc := (clubspec wrap: club1 edition) delayCast: PrClubDescription.
		club1 revise: (desc withMembership: (desc membership without: test)) edition.
		oo << 'Club 1 should no longer have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should not have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become released and unreadable:'
			<< ' canRevise ' << work1 canRevise
			<< ' canRead ' << work1 canRead << myCR << myCR.
		
		"work2 removeStatusDetector: detect2."
		"work1 removeStatusDetector: detect1."
		club1 release.
		club2 release].

	self thingToDo. "Clean up persistent information in Server"!

{void} labelTestOn: oo {ostream reference}
	| s {PrServer}   edition {PrEdition} e1 {PrEdition} e2 {PrEdition} e3 {PrEdition} 
	  e4 {PrEdition} e1prime {PrEdition} edition2 {PrEdition} |
	s _ myServer.
	e1 _ s newEdition: (PrWorksTester string: 'First Edition').
	e2 _ s newEdition: (PrWorksTester string: 'Second Edition').
	e3 _ s newEdition: (PrWorksTester string: 'Third Edition').
	e4 _ s newEdition: (PrWorksTester string: 'Fourth Edition').
	
	edition _ s newEdition: (myServer pointerSpec arrayWithThree: e1 with: e2 with: (s newWork: e1)).
	
	oo << 'Labels:' << myCR.
	oo << ' ' << e1 label << ' ' << e2 label << ' ' << e3 label << ' ' << e4 label << myCR.
	oo << 'labelled e1: '<< (edition positionsLabelled: e1 label) << myCR.
	e1prime _ (edition fetch: (PrWorksTester integer: IntegerVarZero)) with: (PrWorksTester integer: 1) with: s newPlaceHolder.
	
	edition2 _ edition with: (PrWorksTester integer: IntegerVarZero) with: e1prime.
	oo << 'edit e1: ' << (edition2 positionsLabelled: e1 label) << myCR.
	
	oo << 'labelled e2: ' << (edition2 positionsLabelled: e2 label) << myCR.
	oo << 'rebind e2: ' << ((edition2 rebind: (PrWorksTester integer: 1) with: e3) positionsLabelled: e2 label) << myCR.
	oo << 'duplicate e1: ' << ((edition2 with: (PrWorksTester integer: 1) with: e1) positionsLabelled: e1 label) << myCR.
	
	oo << myCR.!

{void} makeEditionTestOn: oo {ostream reference}
	"Try making Editions in a variety of ways"
	
	| edn {PrEdition} place {PrRangeElement} data {PrDataHolder} bits {PrPrimArray} |
	oo << (edn := myServer newEmptyEdition: myServer sequenceSpace) << myCR
		<< (myServer newEmptyEdition: myServer integerSpace) << myCR.
	
	oo << (myServer newPlaceHolders: (myServer integerSpace interval: (PrInteger make: IntegerVarZero) with: (PrInteger make: 10))) << myCR
		<< (myServer newPlaceHolders: myServer sequenceSpace fullRegion) << myCR.
	
	data := myServer newDataHolder: ((myServer uIntSpec: (PrInteger make: 32)) value: (PrInteger make: 3)).
	place := myServer newPlaceHolder.
	oo << (myServer newEditionWith: (PrWorksTester integer: IntegerVarZero) with: edn) << myCR
		<< (myServer newEditionWith: (PrWorksTester integer: 1) with: place) << myCR
		<< (myServer newEditionWith: (PrWorksTester integer: 2) with: data) << myCR.
	
	oo << (myServer newEditionWithAll: (myServer integerSpace above: (PrInteger make: 10) with: (PrBoolean make: true)) with: edn) << myCR
		<< (myServer newEditionWithAll: (myServer integerSpace below: (PrInteger make: 100) with: (PrBoolean make: false)) with: place) << myCR
		<< (myServer newEditionWithAll: myServer newIDSpace fullRegion with: data) << myCR.
	
	oo << (myServer newEdition: (PrWorksTester string: 'hello world')) << myCR.
	
	bits := PrWorksTester string: 'hello world!!'.
	oo << (myServer newEdition: bits) << myCR
		<< (myServer newEdition: bits with: (myServer integerSpace interval: (PrInteger make: 10) with: (PrInteger make: 22))) << myCR
		"<< (myServer newEdition: bits
			with: NULL
			with: myServer integerSpace getDescending) << myCR
		<< (myServer newEdition: bits
			with: (myServer integerSpace interval: (PrInteger make: 100) with: (PrInteger make: 112))
			with: myServer integerSpace getDescending) << myCR".
	
	oo << 'Making Editions test finished' << myCR << myCR.!

{void} ownerTestOn: oo {ostream reference}
	| s {PrServer} work {PrWork} club {PrClub} edition {PrEdition} |
	s _ myServer.
	club := (s get: s publicClubID) delayCast: PrClub.
	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.

	PrInitialOwner fluidBind: PrCurrentAuthor fluidGet during:
		[work _ s newWork: (s newEdition: (PrWorksTester string: 'The one I can change.'))].
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	edition _ s newEdition: (myServer pointerSpec arrayWithTwo: work with: club) 
		with: ((PrWorksTester sequence: 'changeable') asRegion with: (PrWorksTester sequence: 'permanent'))
		with: XuSequenceSpace make ascending.
	
	oo << 'Set owners of: ' << edition << myCR.
	oo << 'result: ' << (edition setRangeOwners: s publicClubID) << myCR.

	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	oo << myCR.!

{void} sponsorTestOn: oo {ostream reference}
	"Test the sponsoring mechanism"
	
	| club {PrClub} testClub {PrClub} blank {PrEdition} w1 {PrWork} w2 {PrWork} |
	testClub := (myServer get: PrCurrentAuthor fluidGet) delayCast: PrClub.
	club := myServer 
		newClub: 
			(myServer newClubDescription: 
				(myServer newSet: 
					(myServer pointerSpec arrayWith: (myServer get: PrCurrentAuthor fluidGet)))
		with: myServer newWallLockSmith) edition.
	
	blank := myServer newEmptyEdition: myServer integerSpace.
	w1 := myServer newWork: blank.
	myServer assignID: w1.
	w2 := myServer newWork: blank.
	myServer assignID: w1.
	oo << 'Initially ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 sponsor: PrCurrentAuthor fluidGet asRegion.
	w2 sponsor: (PrCurrentAuthor fluidGet asRegion
			with: (myServer iDOf: club)).
	oo << 'After sponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 unsponsor: PrCurrentAuthor fluidGet asRegion.
	w2 unsponsor: (PrCurrentAuthor fluidGet asRegion
			with: (myServer iDOf: club)).
	oo << 'After unsponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	
	self thingToDo. "test authority checks"
	self thingToDo. "get rid of persistent info"!

{void} transclusionsTestOn: oo {ostream reference}
	"Test the transclusions query"
	
	| s {PrServer} text {PrText} n {IntegerVar} texts {PrEdition} refs {PrEdition}
	  detector {FeFillDetector} work {PrWork} |
	
	oo << myCR << myCR << 'Transclusions test' << myCR << myCR.
	s := myServer.
	text := s newText: (PrWorksTester string: '(abcdefghijklmnopqrstuvwxyz)').
	n := 28.
	texts := text edition rangeTranscluders: NULL
		with: (s wrapperSpec: (PrWorksTester sequence: 'Text')) filter.
	refs := text edition rangeTranscluders: NULL
		with: (s wrapperSpec: (PrWorksTester sequence: 'HyperRef')) filter.
	detector := WorksTestFillDetector make: oo with: 'Transcluded by '.
	texts addFillRangeDetector: detector.

	work := s newWork: (s newSingleRef: text edition) edition.
	text := text move: (PrInteger make: IntegerVarZero)
		with: (myServer integerSpace
			interval: (PrInteger make: n // 2) with: (PrInteger make: n)).
	work revise: (s newSingleRef: text edition) edition.
	text := text extract: (myServer integerSpace
		interval: (PrInteger make: n // 4)
		with: (PrInteger make: n // 2)) complement.
	work revise: (s newSingleRef: text edition) edition.
	text := text insert: (PrInteger make: n // 2)
		with: (s newText: (PrWorksTester
			string: '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]')).
	work revise: (s newSingleRef: text edition) edition.
	
	texts := text edition
		rangeTranscluders: (myServer integerSpace
			interval: (PrInteger make: n // 2) with: (PrInteger make: n))
		with: (s wrapperSpec: (PrWorksTester sequence: 'Text')) filter
		with: NULL
		with: (PrInteger make: IntegerVarZero)
		with: texts.
	refs := text edition
		rangeTranscluders: (myServer integerSpace
			interval: (PrInteger make: n // 2) with: (PrInteger make: n))
		with: (s wrapperSpec: (PrWorksTester sequence: 'HyperRef')) filter
		with: NULL
		with: (PrInteger make: IntegerVarZero)
		with: refs.
	refs addFillRangeDetector: detector. "put this in a different place just"
	
	text := text extract: (myServer integerSpace
		above: (PrInteger make: n // 2) with: (PrBoolean make: true)).
	work revise: (s newSingleRef: text edition) edition.
	text := text extract: (myServer integerSpace
		below: (PrInteger make: n) with: (PrBoolean make: false)).
	work revise: (s newSingleRef: text edition) edition.
	text := text move: (PrInteger make: IntegerVarZero)
		with: (myServer integerSpace
			interval: (PrInteger make: n // 2 )with: (PrInteger make: n)).
	work revise: (s newSingleRef: text edition) edition.
	
	self knownBug. "need to intern promises for Detectors so that they can be removed"
	"texts removeFillRangeDetector: detector.
	refs removeFillRangeDetector: detector."!

{void} workTestOn: oo {ostream reference}
	"Try the various operations on Works"
	
	| e1 {PrEdition} w1 {PrWork} |
	e1 := myServer newEdition: (PrWorksTester string: 'hello world').
	w1 := myServer newWork: e1.
	self dumpWorkOn: oo with: 'As newly created ' with: w1.
	
	w1 addStatusDetector: (WorksTestStatusDetector make: oo with: '
Work 1').
	w1 release.
	
	self dumpWorkOn: oo with: 'With authority restored' with: w1.
	w1 grab.
	self dumpWorkOn: oo with: 'Grabbed' with: w1.
	w1 release.
	self dumpWorkOn: oo with: 'Released' with: w1.

	
	PrCurrentKeyMaster fluidBind: PrKeyMaster make during:
		[w1 requestGrab].! !

!PrWorksTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartWorksTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrWorksTester class
	instanceVariableNames: ''!

(PrWorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #SMALLTALK.ONLY; yourself)!

!PrWorksTester class methodsFor: 'server library'!

{PrID} clubID: clubName {PrSequence}
	"Looks up the ID of a named Club in the directory maintained by the System Admin Club. Requires read permission on the directory. Blasts if there is no Club with that name."
	
	| s {PrServer} |
	s _ PrCurrentServer fluidGet.
	^s iDOf: (((s get: s clubDirectoryID) delayCast: PrWork) edition get: clubName)!

{PrXuInteger} integer: val {IntegerVar}

	^PrIntegerSpace make position: (PrInteger make: val)!

{PrSequence} sequence: string {char star}

	^XuSequenceSpace make position: (self uInt8Spec string: string)!

{PrPrimArray} string: string {char star}

	^self uInt8Spec string: string!

{PrPrimSpec} uInt8Spec

	self passe! !

!PrWorksTester class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	"XuServer defineFluid: #ClientServer with: XuPromise emulsion with: [NULL]"! !

XuPromise subclass: #XuAdminer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuAdminer comment:
'A client interface for system administration operations. This object can only be obtained using a KeyMaster that has System Admin authority. '!

(XuAdminer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuAdminer methodsFor: 'administrivia'!

{XuVoid} acceptConnections: open {XuIntValue} 

	"Essential. Enable or disable the ability of the Server to accept communications connections from client machines. Anyone who has received a GateKeeper or Server object will continue to stay connected, but no new such objects will be handed out"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(open isBroken) ifTrue:
		[^XuVoid makeBrokenBy: open].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeAdminer acceptConnections:open getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} activeSessions

	"Essential. Return a list of all active sessions."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeAdminer activeSessions)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} execute: commands {XuIntArray} 

	"Essential. Execute a sequence of server configuration commands."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(commands isBroken) ifTrue:
		[^XuVoid makeBrokenBy: commands].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeAdminer execute: ((XuPromise getActual: commands) cast: PrimIntArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} grant: clubID {XuID} with: globalIDs {XuIDRegion} 

	"Essential. Grant a Club the authority to assign global IDs on this Server."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(clubID isBroken) ifTrue:
		[^XuVoid makeBrokenBy: clubID].
	(globalIDs isBroken) ifTrue:
		[^XuVoid makeBrokenBy: globalIDs].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeAdminer grant: ((XuPromise getActual: clubID) cast: ID) with: ((XuPromise getActual: globalIDs) cast: IDRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} grants: clubIDs {XuIDRegion default: DefaultNull} with: globalIDs {XuIDRegion default: DefaultNull} 

	"Essential. List who has been granted authority to various regions of the global IDSpace on this Server."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].
	(clubIDs isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: clubIDs].
	(globalIDs isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: globalIDs].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeAdminer grants: ((XuPromise getActual: clubIDs) cast: IDRegion) with: ((XuPromise getActual: globalIDs) cast: IDRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isAcceptingConnections

	"Essential. Whether the Server is accepting communications connections from client machines. "
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeAdminer isAcceptingConnections)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} shutdown

	"Essential. Shutdown the Server immediately, taking down all the connections and writing all current changes to disk."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeAdminer shutdown)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuAdminer methodsFor: 'promise access'!

{FeAdminer} getActualFeAdminer
	self isBroken
		ifFalse: [^super actualThing cast: FeAdminer.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuAdminer methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeAdminer {FeAdminer}
	super create: anFeAdminer.! !

!XuAdminer methodsFor: 'security'!

{XuLockSmith} gateLockSmith

	"Essential. The LockSmith which hands out locks when a client tries to login through the GateKeeper with an invalid Club ID or name."
	
	| retVal {XuLockSmith} |
	(self isBroken) ifTrue:
		[^XuLockSmith makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuLockSmith makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuLockSmith make: (self getActualFeAdminer gateLockSmith)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} setGateLockSmith: lockSmith {XuLockSmith} 

	"Essential. Set the LockSmith which creates locks to hand out when a client tries to login with an invalid Club ID or name through the GateKeeper."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(lockSmith isBroken) ifTrue:
		[^XuVoid makeBrokenBy: lockSmith].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeAdminer setGateLockSmith: ((XuPromise getActual: lockSmith) cast: FeLockSmith))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuAdminer methodsFor: 'smalltalk: defaults'!

{XuTableStepper} grants

	^self  grants: DefaultNull!

{XuTableStepper} grants: clubIDs {XuIDRegion default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].
	(clubIDs isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: clubIDs].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeAdminer grants: ((XuPromise getActual: clubIDs) cast: IDRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuAdminer class
	instanceVariableNames: ''!

(XuAdminer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuAdminer class methodsFor: 'pseudo-constructors'!

make: anFeAdminer {FeAdminer}
	^self create: anFeAdminer!

{XuAdminer} makeBroken: problem {Problem star}
	| broke {XuAdminer} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuAdminer} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

FeWaitDetector subclass: #WorksWaitDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
WorksWaitDetector comment:
'This class keeps a pointer to an ostream rather than a reference since class ios::operator=() is private.'!

(WorksWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksWaitDetector methodsFor: 'creation'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksWaitDetector methodsFor: 'triggering'!

{NOACK CLIENT} done

	[myOutput << myTag << '
'] smalltalkOnly.
	'*myOutput << myTag << "\n";' translateOnly.! !

!WorksWaitDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksWaitDetector class
	instanceVariableNames: ''!

(WorksWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksWaitDetector class methodsFor: 'creation'!

{FeWaitDetector} make: oo {ostream reference} with: tag {Character star}
	^self create: oo with: tag! !