'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:10 pm'!

FeRevisionDetector subclass: #CommRevisionDetector
	instanceVariableNames: '
		myManager {PromiseManager}
		myNumber {IntegerVar}
		myTarget {FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
CommRevisionDetector comment:
'Send the detector events over comm.'!

(CommRevisionDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommRevisionDetector methodsFor: 'creation'!

create: pm {PromiseManager} with: number {IntegerVar} with: target {FeWork}
	super create.
	myManager _ pm.
	myNumber _ number.
	myTarget _ target! !

!CommRevisionDetector methodsFor: 'triggering'!

{void} revised: work {FeWork}
	with: contents {FeEdition}
	with: author {ID}
	with: time {IntegerVar}
	with: sequence {IntegerVar}
	
	"Essential. The Work has been revised. Gives the Work, the current Edition, the 
	author ID who had it grabbed, the sequence number of the revision to the 
	Work, and the clock time on the Server (note that the clock time is only as 
	reliable as the Server's operating system, which is usually not very)."

	myManager queueDetectorEvent: 
		(RevisedEvent
			make: myNumber
			with: work
			with: contents
			with: author
			with: time
			with: sequence)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommRevisionDetector class
	instanceVariableNames: ''!

(CommRevisionDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommRevisionDetector class methodsFor: 'creation'!

make: pm {PromiseManager} with: number {IntegerVar} with: target {FeWork}

	^self create: pm with: number with: target! !