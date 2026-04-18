'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:23 pm'!

DetectorEvent subclass: #RevisedEvent
	instanceVariableNames: '
		myWork {Heaper}
		myContents {Heaper}
		myAuthor {Heaper}
		myTime {IntegerVar}
		mySequence {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(RevisedEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisedEvent methodsFor: 'creation'!

create: detector {IntegerVar} 
	with: work {Heaper}
	with: contents {Heaper}
	with: author {Heaper}
	with: time {IntegerVar}
	with: sequence {IntegerVar}
	
	super create: detector.
	myWork _ work.
	myContents _ contents.
	myAuthor _ author.
	myTime _ time.
	mySequence _ sequence! !

!RevisedEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	pm sendResponse: PromiseManager revisedResponse.
	pm sendIntegerVar: self detector.
	pm sendPromise: myWork.
	pm sendPromise: myContents.
	pm sendPromise: myAuthor.
	pm sendIntegerVar: myTime.
	pm sendPromise: (PrimIntValue make: myTime).
	pm sendIntegerVar: mySequence.
	pm sendPromise: (PrimIntValue make: mySequence)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RevisedEvent class
	instanceVariableNames: ''!

(RevisedEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisedEvent class methodsFor: 'creation'!

{DetectorEvent} make: detector {IntegerVar} 
	with: work {Heaper}
	with: contents {Heaper}
	with: author {Heaper}
	with: time {IntegerVar}
	with: sequence {IntegerVar}
	
	^ self create: detector 
		with: work
		with: contents
		with: author
		with: time
		with: sequence! !