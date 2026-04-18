'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:21 pm'!

DetectorEvent subclass: #ReleasedEvent
	instanceVariableNames: '
		myWork {Heaper}
		myReason {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(ReleasedEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ReleasedEvent methodsFor: 'creation'!

create: detector {IntegerVar} with: work {Heaper} with: reason {IntegerVar}
	super create: detector.
	myWork _ work.
	myReason _ reason! !

!ReleasedEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	pm sendResponse: PromiseManager releasedResponse.
	pm sendIntegerVar: self detector.
	pm sendPromise: myWork.
	pm sendIntegerVar: myReason.
	pm sendPromise: (PrimIntValue make: myReason)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReleasedEvent class
	instanceVariableNames: ''!

(ReleasedEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ReleasedEvent class methodsFor: 'creation'!

{DetectorEvent} make: detector {IntegerVar} with: work {Heaper} with: reason {IntegerVar}
	^self create: detector with: work with: reason! !