'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:25 pm'!

Heaper subclass: #Sema4
	instanceVariableNames: 'sema4 {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Process Control'!

(Sema4 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Sema4 methodsFor: 'accessing'!

{void} critical: aBlock {BlockClosure}
	sema4 critical: aBlock!

{void} p
	sema4 wait!

{IntegerVar} t
	self unimplemented.
	^IntegerVar0!

{void} v
	sema4 signal! !

!Sema4 methodsFor: 'instance creation'!

create: initialCount {IntegerVar}
	super create.
	sema4 _ Semaphore new.
	initialCount timesRepeat: [self v].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sema4 class
	instanceVariableNames: ''!

(Sema4 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Sema4 class methodsFor: 'instance creation'!

{Sema4} make: count {IntegerVar}

	^ Sema4 create: count! !