'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:11 pm'!

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