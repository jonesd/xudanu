Heaper subclass: #FeArchiver
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sysadm'!
FeArchiver comment:
'Used for transferring information to and from external storage medium. This protocol is still expected to evolve.'!

(FeArchiver getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeArchiver methodsFor: 'accessing'!

{FeEdition CLIENT} archive: works {FeEdition} with: medium {FeEdition}
	"Essential.  Copy the entire contents of a set of Works onto secondary storage. Requires read permission on all the Works (or the authority of the System Archive Club, which can read anything). The medium is an Edition describing the kind of device on which to write the backup. The result and the list of Works are wrapped as Sets, the medium as a StorageMedium.
	Returns the set of Works which were in fact successfully backed up."
	
	Dean shouldImplement.
	^NULL "fodder"!

{void CLIENT} markArchived: edition {FeEdition}
	"Essential. Mark the contents of a set of Works as archived so that they can be discarded from the online disk. Requires System Admin authority."
	
	Dean shouldImplement!

{FeEdition CLIENT} restore: works {FeEdition | NULL}
	with: medium {FeEdition}
	"Essential.  Restore information from a backup tape. If a set of Works is specified, then restores only them from the backup medium, otherwise just reads the entire contents. Must have edit authority on Works which are restored. (Is this the right authority? What to do about history?)
	Returns the Works which were restored from tape."
	
	Dean shouldImplement.
	^NULL "fodder"! !

!FeArchiver methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeArchiver class
	instanceVariableNames: ''!

(FeArchiver getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeArchiver class methodsFor: 'create'!

{FeArchiver CLIENT} make

	^self create! !

!FeArchiver class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeEdition CLIENT} archive: works {FeEdition} with: medium {FeEdition}
{void CLIENT} markArchived: edition {FeEdition}
{FeEdition CLIENT} restore: works {FeEdition | NULL} with: medium {FeEdition}
"! !

XuPromise subclass: #XuArchiver
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sysadm'!
XuArchiver comment:
'Used for transferring information to and from external storage medium. This protocol is still expected to evolve.'!

(XuArchiver getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuArchiver methodsFor: 'accessing'!

{XuEdition} archive: works {XuEdition} with: medium {XuEdition} 

	"Essential.  Copy the entire contents of a set of Works onto secondary storage. Requires read permission on all the Works (or the authority of the System Archive Club, which can read anything). The medium is an Edition describing the kind of device on which to write the backup. The result and the list of Works are wrapped as Sets, the medium as a StorageMedium.
	Returns the set of Works which were in fact successfully backed up."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(works isBroken) ifTrue:
		[^XuEdition makeBrokenBy: works].
	(medium isBroken) ifTrue:
		[^XuEdition makeBrokenBy: medium].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeArchiver archive: ((XuPromise getActual: works) cast: FeEdition) with: ((XuPromise getActual: medium) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} markArchived: edition {XuEdition} 

	"Essential. Mark the contents of a set of Works as archived so that they can be discarded from the online disk. Requires System Admin authority."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(edition isBroken) ifTrue:
		[^XuVoid makeBrokenBy: edition].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeArchiver markArchived: ((XuPromise getActual: edition) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} restore: works {XuEdition} with: medium {XuEdition} 

	"Essential.  Restore information from a backup tape. If a set of Works is specified, then restores only them from the backup medium, otherwise just reads the entire contents. Must have edit authority on Works which are restored. (Is this the right authority? What to do about history?)
	Returns the Works which were restored from tape."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(works isBroken) ifTrue:
		[^XuEdition makeBrokenBy: works].
	(medium isBroken) ifTrue:
		[^XuEdition makeBrokenBy: medium].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeArchiver restore: ((XuPromise getActual: works) cast: FeEdition) with: ((XuPromise getActual: medium) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuArchiver methodsFor: 'promise access'!

{FeArchiver} getActualFeArchiver
	self isBroken
		ifFalse: [^super actualThing cast: FeArchiver.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuArchiver methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeArchiver {FeArchiver}
	super create: anFeArchiver.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuArchiver class
	instanceVariableNames: ''!

(XuArchiver getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuArchiver class methodsFor: 'pseudo-constructors'!

make: anFeArchiver {FeArchiver}
	^self create: anFeArchiver!

{XuArchiver} makeBroken: problem {Problem star}
	| broke {XuArchiver} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuArchiver} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !