'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:30 pm'!

Heaper subclass: #CompareFragment
	instanceVariableNames: 'size {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
CompareFragment comment:
'CompareFragment and its subclasses represent ranges of a document that is being compared with another.  The different subclasses represent fragments that are shared in different ways.  DeleteFragments and InsertFragments are in only one of the documents.  PrimFragments are in 
both, and know all the locations in each document that they occupy.  CompositeFragments hold onto more than one other Fragment to represent moving them as a unit in a comparison display.'!

(CompareFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CompareFragment methodsFor: 'creation'!

create: s {IntegerVar}
	super create.
	size _ s.! !

!CompareFragment methodsFor: 'accessing'!

{ IntegerVar } count
	^size!

{IntegerRegion} finalLocations
	"the locations where this string starts in the final document"
	self subclassResponsibility!

{IntegerRegion} startLocations
	"The locations where this string begins in the original document"
	self subclassResponsibility! !

!CompareFragment methodsFor: 'obsolete'!

{BooleanVar} contiguousInFinal: aFragment {CompareFragment}
	|myFinal {IntegerRegion} otherFinal {IntegerRegion} |
	myFinal _ self finalLocations.
	otherFinal _ aFragment finalLocations.
	((myFinal isEmpty) or: [otherFinal isEmpty]) 
		ifTrue: [^true].  "deletions can be included in a composite"
	(myFinal start == otherFinal stop)
		ifTrue: [^true].
	(myFinal stop == otherFinal start)
		ifTrue: [^true].
	^false! !

!CompareFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	self subclassResponsibility!

{BooleanVar} simpleMove
	"Am I a simple move from one location to one other?"
	^false! !