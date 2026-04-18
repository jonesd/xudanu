'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:36 pm'!

FeSession subclass: #DefaultSession
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
DefaultSession comment:
'The default session.'!

(DefaultSession getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DefaultSession methodsFor: 'accessing'!

{void CLIENT} endSession: withPrejudice {BooleanVar default: false}
	"Do nothing"!

{BooleanVar} isConnected
	"Return whether the session has sucessfully logged in."
	
	^true!

{UInt8Array CLIENT} port
	"Essential. A system-specific description of the actual transport medium over which the connection is being maintained."
	
	^UInt8Array string: 'default'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DefaultSession class
	instanceVariableNames: ''!

(DefaultSession getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DefaultSession class methodsFor: 'creation'!

{FeSession} make
	^self create! !