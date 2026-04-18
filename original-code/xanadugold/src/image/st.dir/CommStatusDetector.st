'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:10 pm'!

FeStatusDetector subclass: #CommStatusDetector
	instanceVariableNames: '
		myManager {PromiseManager}
		myNumber {IntegerVar}
		myTarget {FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
CommStatusDetector comment:
'Send the detector events over comm.'!

(CommStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommStatusDetector methodsFor: 'creation'!

create: pm {PromiseManager} with: number {IntegerVar} with: target {FeWork}
	super create.
	myManager _ pm.
	myNumber _ number.
	myTarget _ target! !

!CommStatusDetector methodsFor: 'triggering'!

{void} grabbed: work {FeWork} with: author {ID} with: reason {IntegerVar}
	"Essential. The Work has been grabbed, or regrabbed."
	
	myManager queueDetectorEvent: 
		(GrabbedEvent
			make: myNumber
			with: work
			with: author
			with: reason)!

{void} released: work {FeWork} with: reason {IntegerVar}
	"Essential. The revise capability of the Work has been lost."
	
	myManager queueDetectorEvent: 
		(ReleasedEvent
			make: myNumber
			with: work
			with: reason)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommStatusDetector class
	instanceVariableNames: ''!

(CommStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommStatusDetector class methodsFor: 'creation'!

make: pm {PromiseManager} with: number {IntegerVar} with: target {FeWork}

	^self create: pm with: number with: target! !