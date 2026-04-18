'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:18 pm'!

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