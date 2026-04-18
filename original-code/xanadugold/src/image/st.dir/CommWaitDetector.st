'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:11 pm'!

FeWaitDetector subclass: #CommWaitDetector
	instanceVariableNames: '
		myManager {PromiseManager}
		myNumber {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
CommWaitDetector comment:
'Send the detector events over comm.'!

(CommWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommWaitDetector methodsFor: 'creation'!

create: pm {PromiseManager} with: number {IntegerVar}
	super create.
	myManager _ pm.
	myNumber _ number!

{void} destruct
	FeServer removeWaitDetector: self.
	super destruct! !

!CommWaitDetector methodsFor: 'triggering'!

{void} done
	"Essential.  Whatever I was waiting for has happened"
	
	myManager queueDetectorEvent: (DoneEvent make: myNumber)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommWaitDetector class
	instanceVariableNames: ''!

(CommWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommWaitDetector class methodsFor: 'creation'!

make: pm {PromiseManager} with: number {IntegerVar}

	^self create: pm with: number! !