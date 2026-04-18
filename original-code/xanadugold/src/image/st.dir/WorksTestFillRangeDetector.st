'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:10 pm'!

FeFillRangeDetector subclass: #WorksTestFillRangeDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTestFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillRangeDetector methodsFor: 'triggering'!

{void} rangeFilled: transclusions {FeEdition}

	[myOutput << myTag << transclusions << '
'] smalltalkOnly.
	'(*myOutput) << myTag << transclusions << "\n";' translateOnly.! !

!WorksTestFillRangeDetector methodsFor: 'private: create'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksTestFillRangeDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTestFillRangeDetector class
	instanceVariableNames: ''!

(WorksTestFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestFillRangeDetector class methodsFor: 'pseudo constructors'!

{FeFillRangeDetector} make: oo {ostream reference} with: tag {Character star}

	^self create: oo with: tag.! !