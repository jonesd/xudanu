'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:09 pm'!

FeFillDetector subclass: #WorksTestFillDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTestFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillDetector methodsFor: 'triggering'!

{void} filled: transclusion {FeRangeElement}

	[myOutput << myTag << transclusion << '
'] smalltalkOnly.
	'(*myOutput) << myTag << transclusion << "\n";' translateOnly.! !

!WorksTestFillDetector methodsFor: 'private: create'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksTestFillDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTestFillDetector class
	instanceVariableNames: ''!

(WorksTestFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillDetector class methodsFor: 'pseudo constructors'!

{FeFillDetector} make: oo {ostream reference} with: tag {Character star}

	^self create: oo with: tag.! !