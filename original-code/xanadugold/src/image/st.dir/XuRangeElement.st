'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:17 pm'!

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