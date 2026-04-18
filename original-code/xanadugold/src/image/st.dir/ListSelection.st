'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:30 pm'!

SelectionObject subclass: #ListSelection
	instanceVariableNames: '
		mySelection {XnRegion}
		myStart {Position}
		myPoint {Position}
		myOldSelection {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-selobj'!

(ListSelection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListSelection methodsFor: 'accessing'!

{void} select: region {XnRegion}
	myOldSelection _ mySelection.
	myPoint _ myStart _   IntegerPos make: ((region cast: IntegerRegion) start)   .
	self changeSelection: region!

{XnRegion} selection
	^mySelection!

{Position} selectionPoint
	"the active point in the selection"
	^myPoint! !

!ListSelection methodsFor: 'private: private'!

{void} changeSelection: region {XnRegion}
	"assumes myOldSelection has already been set"
	| old {XnRegion} |
	old _ mySelection.
	mySelection _ region.
	(mySelection isEqual: old) ifFalse:
		[self changed: (RegionUR make: (mySelection delta: old))]!

{void} computeSelection: key {Position}
	| change {XnRegion} |
	myPoint _ key.
	change _ myStart asRegion simpleUnion: key asRegion.
	(myOldSelection hasMember: key)
		ifTrue: [self changeSelection: (myOldSelection minus: change)]
		ifFalse: [self changeSelection: (myOldSelection unionWith: change)]! !

!ListSelection methodsFor: 'selecting'!

{void} beginSelect: key {Position}
	"This is the basic start selection operation. 
	 Clear the old selection and start a new one."
	myOldSelection _ myOldSelection coordinateSpace emptyRegion.
	myStart _ key.
	self computeSelection: key!

{void} continueSelect: key {Position}
	"These are sent after one of the selection start
	 operations to continually update the selection as
	 the user moves the mouse."
	self computeSelection: key!

{void} extendSelect: key {Position}
	"Begin a new selection action that extends the pre-existing selection. 
	 The default just starts a new selection.  A better default might be to
	 'continue' the old selection."
	myOldSelection _ mySelection.
	myStart _ key.
	self computeSelection: key!

{void} multiSelect: key {Position}
	"Start an additional selection without upsetting
	 the pre-exinsting selections."

	self extendSelect: key! !

!ListSelection methodsFor: 'create'!

create: region {XnRegion}
	super create.
	myOldSelection _ mySelection _ region.
	myStart _ myPoint _ NULL! !

!ListSelection methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myStart << ', ' << mySelection << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListSelection class
	instanceVariableNames: ''!

(ListSelection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListSelection class methodsFor: 'pseudo constructors'!

make: region {XnRegion}
	^self create: region! !