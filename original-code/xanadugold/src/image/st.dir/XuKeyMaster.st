'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:16 pm'!

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