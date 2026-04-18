'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:09 pm'!

FeFillDetector subclass: #CommFillDetector
	instanceVariableNames: '
		myManager {PromiseManager}
		myNumber {IntegerVar}
		myTarget {FeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
CommFillDetector comment:
'Send the detector events over comm.'!

(CommFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommFillDetector methodsFor: 'creation'!

create: pm {PromiseManager} with: number {IntegerVar} with: target {FeRangeElement}
	super create.
	myManager _ pm.
	myNumber _ number.
	myTarget _ target! !

!CommFillDetector methodsFor: 'triggering'!

{void} filled: newIdentity {FeRangeElement}
	"A single PlaceHolder has been filled to become another kind of RangeElement"
	
	myManager queueDetectorEvent: (FilledEvent make: myNumber with: newIdentity)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommFillDetector class
	instanceVariableNames: ''!

(CommFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommFillDetector class methodsFor: 'creation'!

make: pm {PromiseManager} with: number {IntegerVar} with: target {FeRangeElement}

	^self create: pm with: number with: target! !