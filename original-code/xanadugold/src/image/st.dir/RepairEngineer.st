'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:14 pm'!

Heaper subclass: #RepairEngineer
	instanceVariableNames: '
		myNext {RepairEngineer}
		myPrev {RepairEngineer wimpy}'
	classVariableNames: 'FirstEngineer {RepairEngineer} '
	poolDictionaries: ''
	category: 'Xanadu-gchooks'!
RepairEngineer comment:
'RepairEngineers are invoked at the top of server loops and the like in order to perform damage control after such events as a conservative GC or a conservative purge in response to an resource emergency with a deep stack.  These modules should implement subclasses of RepairEngineer (RE) which implement the method {void} repair.
REs are registered by construction and deregistered by destruction.'!

(RepairEngineer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!RepairEngineer methodsFor: 'protected: create'!

create
	super create.
	FirstEngineer ~~ NULL ifTrue:
		[ FirstEngineer setPrev: self ].
	myNext := FirstEngineer.
	myPrev := NULL.
	FirstEngineer := self!

{void} destruct
	(myPrev ~~ NULL and: [myPrev isKindOf: RepairEngineer])
		ifTrue: [ myPrev setNext: myNext ]
		ifFalse: [ FirstEngineer := myNext cast: RepairEngineer ].
	(myNext ~~ NULL and: [myNext isKindOf: RepairEngineer]) ifTrue:
		[ myNext setPrev: myPrev ].
	super destruct.! !

!RepairEngineer methodsFor: 'invoking'!

{void} repair
	self subclassResponsibility! !

!RepairEngineer methodsFor: 'private: accessing'!

{RepairEngineer INLINE} next
	^ myNext!

{void INLINE} setNext: n {RepairEngineer}
	myNext :=  n!

{void INLINE} setPrev: n {RepairEngineer}
	myPrev :=  n! !

!RepairEngineer methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RepairEngineer class
	instanceVariableNames: ''!

(RepairEngineer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!RepairEngineer class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	FirstEngineer := NULL! !

!RepairEngineer class methodsFor: 'repairing'!

{void} repairThings
	| se {RepairEngineer} |
	se := FirstEngineer.
	[se ~~ NULL] whileTrue:
		[ se repair.
		  se := se next ]! !