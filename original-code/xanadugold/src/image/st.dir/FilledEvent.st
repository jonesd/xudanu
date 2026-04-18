'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:13 pm'!

DetectorEvent subclass: #FilledEvent
	instanceVariableNames: 'myFilling {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(FilledEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FilledEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	pm sendResponse: PromiseManager filledResponse.
	pm sendIntegerVar: self detector.
	pm sendPromise: myFilling! !

!FilledEvent methodsFor: 'creation'!

create: detector {IntegerVar} with: filling {Heaper}
	super create: detector.
	myFilling _ filling! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FilledEvent class
	instanceVariableNames: ''!

(FilledEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FilledEvent class methodsFor: 'creation'!

{DetectorEvent} make: detector {IntegerVar} with: filling {Heaper}
	^ self create: detector with: filling! !