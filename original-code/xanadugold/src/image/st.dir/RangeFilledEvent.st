'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:21 pm'!

DetectorEvent subclass: #RangeFilledEvent
	instanceVariableNames: 'myFilling {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(RangeFilledEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RangeFilledEvent methodsFor: 'creation'!

create: detector {IntegerVar} with: filling {Heaper}
	super create: detector.
	myFilling _ filling! !

!RangeFilledEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	pm sendResponse: PromiseManager rangeFilledResponse.
	pm sendIntegerVar: self detector.
	pm sendPromise: myFilling! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RangeFilledEvent class
	instanceVariableNames: ''!

(RangeFilledEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RangeFilledEvent class methodsFor: 'creation'!

{DetectorEvent} make: detector {IntegerVar} with: filling {Heaper}
	^ self create: detector with: filling! !