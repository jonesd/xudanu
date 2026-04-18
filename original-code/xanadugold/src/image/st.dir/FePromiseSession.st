'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:39 pm'!

FeSession subclass: #FePromiseSession
	instanceVariableNames: '
		myPort {UInt8Array}
		myManager {PromiseManager}
		myListener {Heaper}
		myNext {FePromiseSession | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FePromiseSession comment:
'Represent a single unique connection to the server over some underlying bytestream channel.'!

(FePromiseSession getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FePromiseSession methodsFor: 'accessing'!

{void CLIENT} endSession: withPrejudice {BooleanVar default: false}
	"Essential. Terminate this connection.  If withPrejudice is false, it completes the current request and flushes all output before disconnecting."
	
	withPrejudice ifFalse: [myManager force].
	myManager _ NULL.
	myListener destroy.
	myListener _ NULL.
	(CurrentSessions fluidGet basicCast: Heaper star) == self 
		ifTrue: [CurrentSessions fluidSet: self next]
		ifFalse: [CurrentSessions fluidGet remove: self]!

{BooleanVar} isConnected
	"Return whether the session has sucessfully logged in."
	
	^myManager ~~ NULL!

{FePromiseSession | NULL} next
	^myNext!

{UInt8Array CLIENT} port
	"Essential. A system-specific description of the actual transport medium over which the connection is being maintained."
	
	^myPort!

{void} remove: session {FePromiseSession}
	myNext ~~ NULL ifTrue:
		[(myNext isEqual: session) 
			ifTrue: [myNext _ session next]
			ifFalse: [myNext remove: session]]! !

!FePromiseSession methodsFor: 'creation'!

create: port {UInt8Array} with: listener {Heaper} with: manager {PromiseManager}
	super create.
	myPort _ port.
	myManager _ manager.
	myListener _ listener.
	myNext _ CurrentSessions fluidFetch.
	CurrentSessions fluidSet: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePromiseSession class
	instanceVariableNames: ''!

(FePromiseSession getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FePromiseSession class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	FePromiseSession defineFluid: #CurrentSessions with: DiskManager emulsion with: [NULL].! !

!FePromiseSession class methodsFor: 'ceration'!

make: port {UInt8Array} with: listener {Heaper} with: manager {PromiseManager}
	^FePromiseSession create: port with: listener with: manager! !