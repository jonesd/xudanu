'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:32 pm'!

Heaper subclass: #EditOperation
	instanceVariableNames: '
		myStartPosition {IntegerVar}
		myFinalPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
EditOperation comment:
'EditOperation and its subclasses represent the operations that map one document to another to show a comparison.'!

(EditOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!EditOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	self subclassResponsibility! !

!EditOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar}
	super create.
	myStartPosition _ s.
	myFinalPosition _ f.! !

!EditOperation methodsFor: 'deferred accessing'!

{IntegerVar} count
	self subclassResponsibility!

{IntegerRegion} finalLocations
	self subclassResponsibility!

{IntegerRegion} startLocations
	self subclassResponsibility! !

!EditOperation methodsFor: 'accessing'!

{IntegerVar} finalPosition
	"return the position in the final document of this operation"
	^myFinalPosition!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	self subclassResponsibility!

{IntegerVar} startPosition
	"return the position in the start document of this operation"
	^myStartPosition! !

!EditOperation methodsFor: 'obsolete'!

{BooleanVar} contiguousInFinal: anOp {EditOperation}
	"Am I adjacent to anOp in the final doc if we're both present there?"
	|myFinal {IntegerRegion} otherFinal {IntegerRegion} |
	myFinal _ self finalLocations.
	otherFinal _ anOp finalLocations.
	((myFinal isEmpty) or: [otherFinal isEmpty]) 
		ifTrue: [^true].  "deletions can be included in a composite"
	(myFinal start == otherFinal stop)
		ifTrue: [^true].
	(myFinal stop == otherFinal start)
		ifTrue: [^true].
	^false! !

!EditOperation methodsFor: 'testing'!

{BooleanVar} isInsertMove
	"Am I an insertion of text which comes from somewhere else?"
	^false!

{BooleanVar} isPureDelete
	"am I a delete of some text which couldn't be a move."
	^false!

{BooleanVar} isPureInsert
	"am I an insert of some text which couldn't be a move."
	^false! !