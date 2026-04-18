'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:15 pm'!

Heaper subclass: #SanitationEngineer
	instanceVariableNames: '
		myNext {SanitationEngineer}
		myPrev {SanitationEngineer wimpy}'
	classVariableNames: 'FirstEngineer {SanitationEngineer} '
	poolDictionaries: ''
	category: 'Xanadu-gchooks'!
SanitationEngineer comment:
'SanitationEngineers are used by modules that can perform clever resource management at garbage collection time.  These modules should implement subclasses of SanitationEngineer (SE) which implement the method {void} recycle.
The garbage collector calls the recycle method for each existing SE prior to the marking phase.  SEs are registered
by construction and deregistered by destruction.'!

(SanitationEngineer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!SanitationEngineer methodsFor: 'invoking'!

{void} recycle: required {BooleanVar}
	self subclassResponsibility! !

!SanitationEngineer methodsFor: 'protected: create'!

create
	super create.
	FirstEngineer ~~ NULL ifTrue:
		[ FirstEngineer setPrev: self ].
	myNext := FirstEngineer.
	myPrev := NULL.
	FirstEngineer := self!

{void} destruct
	(myPrev ~~ NULL and: [myPrev isKindOf: SanitationEngineer])
		ifTrue: [ myPrev setNext: myNext ]
		ifFalse: [ FirstEngineer := myNext cast: SanitationEngineer ].
	(myNext ~~ NULL and: [myNext isKindOf: SanitationEngineer]) ifTrue:
		[ myNext setPrev: myPrev ].
	super destruct.! !

!SanitationEngineer methodsFor: 'private: accessing'!

{SanitationEngineer INLINE} next
	^ myNext!

{void INLINE} setNext: n {SanitationEngineer}
	myNext :=  n!

{void INLINE} setPrev: p {SanitationEngineer}
	myPrev := p! !

!SanitationEngineer methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SanitationEngineer class
	instanceVariableNames: ''!

(SanitationEngineer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!SanitationEngineer class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	FirstEngineer := NULL! !

!SanitationEngineer class methodsFor: 'sanitizing'!

{void} garbageDay: required {BooleanVar}
	| se {SanitationEngineer} |
	se := FirstEngineer.
	[se ~~ NULL] whileTrue:
		[ se recycle: required.
		  se := se next ]! !