'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:10 pm'!

FeWaitDetector subclass: #WorksWaitDetector
	instanceVariableNames: '
		myTag {Character star}
		myOutput {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
WorksWaitDetector comment:
'This class keeps a pointer to an ostream rather than a reference since class ios::operator=() is private.'!

(WorksWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksWaitDetector methodsFor: 'creation'!

create: oo {ostream reference} with: tag {Character star}

	super create.
	[myOutput := oo] smalltalkOnly.
	'myOutput = &oo;' translateOnly.
	myTag := tag.! !

!WorksWaitDetector methodsFor: 'triggering'!

{NOACK CLIENT} done

	[myOutput << myTag << '
'] smalltalkOnly.
	'*myOutput << myTag << "\n";' translateOnly.! !

!WorksWaitDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksWaitDetector class
	instanceVariableNames: ''!

(WorksWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WorksWaitDetector class methodsFor: 'creation'!

{FeWaitDetector} make: oo {ostream reference} with: tag {Character star}
	^self create: oo with: tag! !