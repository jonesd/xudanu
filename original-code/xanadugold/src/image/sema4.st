'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:40:37 pm'!

((CxxSystemOrganization tree childNamed: 'sema4') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'sema4') destroyFiles]!

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
(CxxSystemOrganization fileNamed: 'sema4')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'sema4')
	addClass: Sema4
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'sema4' value: #file) yourself))!