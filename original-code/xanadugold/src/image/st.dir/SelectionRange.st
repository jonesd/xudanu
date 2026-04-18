'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:09 pm'!

SelectionObject subclass: #SelectionRange
	instanceVariableNames: '
		myRange {XnRegion}
		pivot {IntegerVar}
		myInsert {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!
SelectionRange comment:
'Instances model range selections.  These are particularly useful for representing text selections and selections in list views.  

This class can be extended to support double-click selection in either the controller or the dependent of these instances.  To handle selection in the controller, enable the current selection to be extended with a range.  The when the selection is a double-click selection, the controller simply extends the selection with the range for the selected word.  To handle selection in the dependent, extend these models to have an attribute that goes along with the selection.  The displaying viewer or the compositor then finds the appropriate word boundaries to actually select.  Both of these are interesting for various reasons.  

Allowing the selection to be extended would allow the outline selection object to span even collapsed children with a single selection operation.

For text, the distinctions in a selection designate positions between selected elements, not the selected elements themselves.  Otherwise, an empty range could not designate the position between two characters.'!

(SelectionRange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectionRange methodsFor: 'accessing'!

{void} select: region {XnRegion}
	self setSelectionRange: region!

{XnRegion} selection
	^myRange!

{Position} selectionPoint
	"the active point in the selection"
	^self selectionPosition integer!

{IntegerVar} selectionPosition
	^myInsert!

{XnRegion} selectionRange
	^myRange!

{void} setSelectionPosition: aPos {IntegerVar} 
	| oldRange {XnRegion} |
	oldRange _ myRange.
	myRange _ IntegerRegion make.
	myInsert _ aPos.
	"This is just the old region because the new region is empty."
	(oldRange ~~ NULL and: [oldRange isEmpty not])
		ifTrue: [self changed: (RegionUR make: oldRange)]!

{void} setSelectionRange: aRegion {XnRegion} 
	| oldRange {XnRegion} newRegion {IntegerRegion} |
	oldRange _ myRange.
	newRegion _ aRegion quickCast: IntegerRegion.
	myRange _ newRegion.
	newRegion isEmpty ifTrue:
		[myInsert _ IntegerVar0]
	ifFalse: [newRegion isBoundedBelow ifTrue:
		[myInsert _ newRegion start]
	ifFalse: [newRegion isBoundedAbove ifTrue:
		[myInsert _ newRegion stop]
	ifFalse:
		[myInsert _ IntegerVar0]]].
	"This should include the old region."
	(myRange isEqual: oldRange) 
		ifFalse: [self changed: (RegionUR make: myRange)]! !

!SelectionRange methodsFor: 'selecting'!

{void} beginSelect: key {Position} 
	| oldRange {XnRegion} |
	oldRange _ myRange.
	myRange _ IntegerRegion make.
	pivot _ (key cast: IntegerPos) asIntegerVar.
	myInsert _ pivot.
	myInsert < IntegerVar0 ifTrue: [myInsert _ IntegerVar0].
	"This should include the old region."
	(myRange isEqual: oldRange)
		ifFalse: [oldRange == NULL
				ifTrue: [self changed: (RegionUR make: (IntegerRegion make: pivot))]
				ifFalse: [self changed: (RegionUR make: ((IntegerRegion make: pivot)
								simpleUnion: oldRange))]]!

{void} continueSelect: key {Position} 
	| newPos {IntegerVar} |
	newPos _ (key cast: IntegerPos) asIntegerVar.
	newPos >= IntegerVar0
		ifTrue: 
			[| oldRange {XnRegion} |
			oldRange _ myRange.
			newPos == myInsert
				ifTrue: [myRange _ IntegerRegion make]
				ifFalse: [newPos < pivot
						ifTrue: [myRange _ IntegerRegion make: newPos with: pivot]
						ifFalse: [myRange _ IntegerRegion make: pivot with: newPos]].
			(myRange isEqual: oldRange)
				ifFalse: [(oldRange == NULL or: [oldRange isEmpty])
						ifTrue: [self changed: (RegionUR make: myRange)]
						ifFalse: [self changed: (RegionUR make: 
									(myRange simpleUnion: oldRange))]]]!

{void} endSelect: key {Position}
	self continueSelect: key!

{void} extendSelect: key {Position unused}
	"This is for shift-selection.  Start a new selection
	 which is an extension of a previous selection."

self unimplemented.
	"(key isEqual: NoSelection) ifFalse:
	[| keyRegion {XuRegion} max {IntegerVar} oldRegion
{XuRegion} | 
	keyRegion _ key asRegion.
	oldRegion _ myRange.
	max _ IntegerVar0.
	keyRegion distinctions stepper
		forEach: [:distinct {XuRegion} || count {IntegerVar} |
			count _ (oldRegion intersect: distinct) stepper count.
			count > max ifTrue: 
				[max _ count]].
	key - start > (stop - key)
		ifTrue: 
			[pivot _ start.
			stop _ key]
		ifFalse: 
			[pivot _ stop.
			start _ key]]"!

{void} multiSelect: key {Position}
	"Multiple selections are currently not handled. 
	 These will be done using runModels."

	self beginSelect: key! !

!SelectionRange methodsFor: 'create'!

create
	super create.
	myRange _ IntegerRegion make.
	pivot _ myInsert _ IntegerVar0! !

!SelectionRange methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << $(.
	myRange isEmpty 
		ifTrue: [oo << myInsert]
		ifFalse: [oo << myRange].
	oo << $)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectionRange class
	instanceVariableNames: ''!

(SelectionRange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectionRange class methodsFor: 'pseudo constructors'!

make
	^ self create! !