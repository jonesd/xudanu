'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:40 pm'!

Heaper subclass: #FeSession
	instanceVariableNames: '
		myInitialLogin {ID | NULL}
		myConnectTime {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeSession comment:
'Represent a single unique connection to the server over some underlying bytestream channel.'!

(FeSession getOrMakeCxxClassDescription)
	friends:
'friend class Lock;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeSession methodsFor: 'accessing'!

{IntegerVar CLIENT} connectTime
	"Essential. The clock time at which the connection was initiated."
	
	^myConnectTime!

{void CLIENT} endSession: withPrejudice {BooleanVar default: false}
	"Essential. Terminate this connection.  If withPrejudice is false, it completes the current request and flushes all output before disconnecting."
	
	self subclassResponsibility!

{ID CLIENT} initialLogin
	"Essential. The ID of the club that the session logged into to get past the perimeter.  Blast of the session is not yet admitted."
	
	myInitialLogin == NULL ifTrue: [Heaper BLAST: #NotLoggedIn].
	^myInitialLogin!

{BooleanVar CLIENT} isConnected
	"Return whether the session has sucessfully logged in, and is still logged in."
	
	self subclassResponsibility!

{BooleanVar} isLoggedIn
	"Return whether the session has sucessfully logged in."
	
	^myInitialLogin ~~ NULL!

{UInt8Array CLIENT} port
	"Essential. A system-specific description of the actual transport medium over which the connection is being maintained."
	
	self subclassResponsibility! !

!FeSession methodsFor: 'smalltalk: defaults'!

{void CLIENT} endSession
	"Essential. Gracefully terminate this connection"
	
	self endSession: false! !

!FeSession methodsFor: 'creation'!

create
	super create.
	myInitialLogin _ NULL.
	myConnectTime _ FeServer currentTime.
	CurrentSession fluidSet: self! !

!FeSession methodsFor: 'private: accessing'!

{void} setInitialLogin: iD {ID}
	"Set the ID of the Club which initially logged in during this session"
	
	(myInitialLogin == NULL) assert.
	myInitialLogin := iD.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeSession class
	instanceVariableNames: ''!

(FeSession getOrMakeCxxClassDescription)
	friends:
'friend class Lock;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeSession class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT} connectTime
{void CLIENT} disconnect
{IDRegion CLIENT} initialLogins
{PrimIntegerArray CLIENT} port
"! !

!FeSession class methodsFor: 'accessing'!

{Stepper of: FeSession} allActive
	"CurrentSessions fluidFetch == NULL
		ifTrue: [^Stepper itemStepper: CurrentSession fluidGet]
		ifFalse:
			[| acc {SetAccumulator} cur {FePromiseSession} |
			acc _ SetAccumulator make.
			cur _ CurrentSessions fluidGet.
			[cur ~~ NULL] whileTrue:
				[acc step: cur.
				cur _ cur next].
			^(acc value cast: ScruSet) stepper]"
	^ ImmuSet make stepper!

{FeSession CLIENT} current
	^CurrentSession fluidGet! !

!FeSession class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	FeSession defineFluid: #CurrentSession with: ServerChunk emulsion with: [DefaultSession make].! !