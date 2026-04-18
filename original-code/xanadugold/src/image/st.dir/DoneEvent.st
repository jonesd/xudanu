'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:11 pm'!

DetectorEvent subclass: #DoneEvent
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(DoneEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DoneEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	pm sendResponse: PromiseManager doneResponse.
	pm sendIntegerVar: self detector.! !

!DoneEvent methodsFor: 'creation'!

create: detector {IntegerVar}
	super create: detector! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DoneEvent class
	instanceVariableNames: ''!

(DoneEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DoneEvent class methodsFor: 'creation'!

{DetectorEvent} make: detector {IntegerVar}
	^ self create: detector! !