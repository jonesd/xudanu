'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:48 pm'!

Abraham subclass: #ShepherdLocked
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sheph'!

(ShepherdLocked getOrMakeCxxClassDescription)
	friends:
'/* friends for class ShepherdLocked */';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!ShepherdLocked methodsFor: 'instance creation'!

create

	super create! !

!ShepherdLocked methodsFor: 'accessing'!

{BooleanVar} isReallyUnlocked
	[^ (StackExaminer pointersOnStack fetch: self asOop) == NULL] smalltalkOnly.
	'return StackExaminer::pointersOnStack()->fetch((Int32)(void*)this) == NULL;' translateOnly.! !

!ShepherdLocked methodsFor: 'testing locks'!

{void} publicUnlock
	"self unlock"! !

!ShepherdLocked methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShepherdLocked class
	instanceVariableNames: ''!

(ShepherdLocked getOrMakeCxxClassDescription)
	friends:
'/* friends for class ShepherdLocked */';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!ShepherdLocked class methodsFor: 'instance creation'!

{ShepherdLocked} makeLocked
	^ShepherdLocked create!

{ShepherdLocked} makeUnlocked
	| aLockedShepherd {ShepherdLocked} |
	aLockedShepherd _ ShepherdLocked create.
	aLockedShepherd publicUnlock.
	^aLockedShepherd! !