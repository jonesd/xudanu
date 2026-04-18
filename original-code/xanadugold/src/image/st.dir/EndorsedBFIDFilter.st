'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:16 pm'!

FilterStream subclass: #EndorsedBFIDFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myEndorsements {ImmuSet of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
EndorsedBFIDFilter comment:
'EndorsedBFIDFilter is a primitive filter that backfollows from the ID of each Waldo on the input stream, filtered by the endorsements, and steps over the result.  Uniqueness of output Waldos is NOT guaranteed.'!

(EndorsedBFIDFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!