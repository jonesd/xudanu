'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:10 pm'!

FeFillRangeDetector subclass: #CommFillRangeDetector
	instanceVariableNames: '
		myManager {PromiseManager}
		myNumber {IntegerVar}
		myTarget {FeEdition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
CommFillRangeDetector comment:
'Send the detector events over comm.'!

(CommFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommFillRangeDetector methodsFor: 'creation'!

create: pm {PromiseManager} with: number {IntegerVar} with: target {FeEdition}
	super create.
	myManager _ pm.
	myNumber _ number.
	myTarget _ target! !

!CommFillRangeDetector methodsFor: 'triggering'!

{void} rangeFilled: newIdentities {FeEdition}
	"Essential.  Some of the PlaceHolders in the Edition on which I was placed have become something else. The Edition has their new identies as its RangeElements, though the keys may bear no relationship to those in the original Edition."
	
	myManager queueDetectorEvent: (RangeFilledEvent make: myNumber with: newIdentities)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommFillRangeDetector class
	instanceVariableNames: ''!

(CommFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CommFillRangeDetector class methodsFor: 'creation'!

make: pm {PromiseManager} with: number {IntegerVar} with: target {FeEdition}

	^self create: pm with: number with: target! !