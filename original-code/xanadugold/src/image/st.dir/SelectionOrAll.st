'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:09 pm'!

SelectionObject subclass: #SelectionOrAll
	instanceVariableNames: '
		selectionInternal {SelectionObject}
		allModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!
SelectionOrAll comment:
'Instances represent selections that could be switched to span the entire linear space.  This is used to switch a normal selection to cover an entire document.  The representation is an internal selection object to which instances forward if the selectAll flag model is false.  If the flag is true, then the receiver acts like an infinite range selection.'!

(SelectionOrAll getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectionOrAll methodsFor: 'accessing'!

{BooleanModel} allFlagModel
	^allModel!

{void} select: region {XnRegion}
	selectionInternal select: region!

{XnRegion} selection
	self allFlagModel getValue
		ifTrue: [^selectionInternal selection coordinateSpace fullRegion]
		ifFalse: [^selectionInternal selection]!

{Position} selectionPoint
	"the active point in the selection"
	^selectionInternal selectionPoint! !

!SelectionOrAll methodsFor: 'selecting'!

{void}beginSelect: key{Position}
	selectionInternal beginSelect: key!

{void}continueSelect: key{Position} 
	selectionInternal continueSelect: key!

{void}endSelect: key{Position}
	selectionInternal endSelect: key!

{void}extendSelect: key{Position}
	selectionInternal extendSelect: key!

{void}multiSelect: key {Position}
	selectionInternal multiSelect: key! !

!SelectionOrAll methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel} 
	(selectionInternal basicCast: XnModel) == sender
		ifTrue: [self changed: ur]
		ifFalse: [(allModel basicCast: XnModel) == sender
			 ifTrue: [allModel getValue
					ifTrue: [selectionInternal removeDependent: self]
					ifFalse: [selectionInternal addDependent: self].
				self changed: NewContentsUpdate make]]! !

!SelectionOrAll methodsFor: 'create/delete'!

create: selection {SelectionObject}
	super create.
	selectionInternal _ selection.
	allModel _ BooleanModel create.
	allModel addDependent: self.
	allModel ifFalse: [selection addDependent: self]!

create: selection {SelectionObject} with: allFlagModel {BooleanModel}
	super create.
	allModel _ allFlagModel.
	allModel addDependent: self.
	selectionInternal _ selection.
	allModel getValue ifFalse: [selection addDependent: self]! !

!SelectionOrAll methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	super printOn: aStream.
	aStream << ' ' << selectionInternal << ' flag: ' << allModel getValue! !

!SelectionOrAll methodsFor: 'smalltalk: inspect'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: selectionInternal with: allModel! !

!SelectionOrAll methodsFor: 'protected: creation'!

{void} destruct
	selectionInternal removeDependent: self.
	allModel removeDependent: self.
	selectionInternal _ NULL.
	allModel _ NULL.
	super destruct! !