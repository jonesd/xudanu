'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:13 pm'!

DetectorEvent subclass: #GrabbedEvent
	instanceVariableNames: '
		myWork {Heaper}
		myAuthor {Heaper}
		myReason {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(GrabbedEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!GrabbedEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	pm sendResponse: PromiseManager grabbedResponse.
	pm sendIntegerVar: self detector.
	pm sendPromise: myWork.
	pm sendPromise: myAuthor.
	pm sendIntegerVar: myReason.
	pm sendPromise: (PrimIntValue make: myReason)! !

!GrabbedEvent methodsFor: 'creation'!

create: detector {IntegerVar} with: work {Heaper} with: author {Heaper} with: reason {IntegerVar}
	super create: detector.
	myWork _ work.
	myAuthor _ author.
	myReason _ reason! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrabbedEvent class
	instanceVariableNames: ''!

(GrabbedEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!GrabbedEvent class methodsFor: 'creation'!

{DetectorEvent} make: detector {IntegerVar} with: work {Heaper} with: author {Heaper} with: reason {IntegerVar}
	^self create: detector with: work with: author  with: reason! !