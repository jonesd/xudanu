'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:36 pm'!

Heaper subclass: #MoveMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MoveMaker methodsFor: 'accessing'!

{MuSet of: EditSequences} sequences
	self subclassResponsibility! !

!MoveMaker methodsFor: 'arranging Sequences'!

{EditSequence} arrange: aSeq {EditSequence}
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MoveMaker class
	instanceVariableNames: ''!

(MoveMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MoveMaker class methodsFor: 'pseudoConstructors'!

{MoveMaker} make: seqs {MuSet of: EditSequence}

	^FirstFitMaker create: seqs! !