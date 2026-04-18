'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:09 pm'!

XcvrMaker subclass: #BogusXcvrMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(BogusXcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BogusXcvrMaker methodsFor: 'testing'!

{char star} id
	^'bogus'! !

!BogusXcvrMaker methodsFor: 'xcvr creation'!

{SpecialistRcvr} makeRcvr: specialist {TransferSpecialist unused} with: readStream {XnReadStream unused}

	Heaper BLAST: #BogusProtocol.
	^NULL!

{SpecialistXmtr} makeXmtr: specialist {TransferSpecialist} with: writeStream {XnWriteStream}

	Heaper BLAST: #BogusProtocol.
	^NULL! !