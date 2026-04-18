'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:55 pm'!

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