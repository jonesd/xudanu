'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:10 pm'!

FeStatusDetector subclass: #WorksTestStatusDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTestStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestStatusDetector methodsFor: 'triggering'!

{void} grabbed: work {FeWork} with: author {ID} with: reason {IntegerVar}

	[myOutput << myTag << ' canRevise (' << author << ')
'] smalltalkOnly.
	'(*myOutput) << myTag << " canRevise (" << author << ")\n";' translateOnly.!

{void} released: work {FeWork} with: reason {IntegerVar}

	[myOutput << myTag << ' released
'] smalltalkOnly.
	'(*myOutput) << myTag << " released\n";' translateOnly! !

!WorksTestStatusDetector methodsFor: 'private: create'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksTestStatusDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTestStatusDetector class
	instanceVariableNames: ''!

(WorksTestStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksTestStatusDetector class methodsFor: 'pseudo constructors'!

{FeStatusDetector} make: oo {ostream reference} with: tag {Character star}

	^self create: oo with: tag.! !