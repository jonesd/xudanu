'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:12 pm'!

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