'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:07 pm'!

FMSelectionViewer subclass: #MultiSelectionViewer
	instanceVariableNames: '
		myHighlightModel {VariableModel of: Highlight}
		myHighlight {Highlight}
		mySelectionModel {SelectionObject}
		mySelection {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!
MultiSelectionViewer comment:
'Display a selection using myHighlight on the region for every model positions in mySelectionModel.

myHighlightModel contains the highlight to use.  This lets a single controller elsewhere change the highlight model used by several selection views (such as when selecting the view).'!

(MultiSelectionViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiSelectionViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 

	"changed ifTrue: ["
	self updateState.
	"]"
	aWarp display: self subView.
	(myHighlight isEqual: NoHighlight make)
		ifFalse: [self highlightOn: aWarp].
	self validate! !

!MultiSelectionViewer methodsFor: 'bogus '!

{FMColor} highlightColor
	"This is supposed to return the color object used for 
	drawing highlights. This probably requires the color of the 
	destination warp to produce a proper response. Should this color be 
	handed to the subView? Certainly a combination rule could be 
	handed to subViews."
	"Highlighting isn't done using colors, it's done using 
	color maps. The superview determines the background color. The 
	subview determines the foreground color? Is the clear operation in 
	subViews a paint white or paint with the background color (paint 
	transparent?)?"

	self unimplemented.
	^NULL! !

!MultiSelectionViewer methodsFor: 'highlighting'!

{void} highlightOn: aWarp {Warp} 
	"Toggle the current highlight."

	[Stepper] USES.
	mySelection stepper forEach: [:pos {IntegerPos} | 
		myHighlight reverse: 
				((self subView regionAt: pos asIntegerVar) cast: PointRegion)
			on: aWarp]!

{Highlight} newHighlight
	"Compute the new highlight object."

	mySelectionModel selection isEmpty
		ifTrue: [^NoHighlight make]
		ifFalse: [^myHighlightModel getValue cast: Highlight]!

{void} updateState
	"Change the record of the currently visible state to reflect the 
	current state of the models."

	myHighlight _ self newHighlight.
	mySelection _ mySelectionModel selection! !

!MultiSelectionViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	self changedImage! !

!MultiSelectionViewer methodsFor: 'create/delete'!

create: aSubView {Viewer} with: selectionModel {SelectionObject} with: highlightModel {VariableModel of: Highlight}
	super create: aSubView.
	myHighlightModel _ highlightModel.
	myHighlightModel addDependent: self.
	myHighlight _ myHighlightModel getValue cast: Highlight.
	mySelectionModel _ selectionModel.
	mySelectionModel addDependent: self.! !

!MultiSelectionViewer methodsFor: 'smalltalk: obsolete'!

{BooleanVar}displayIsAdditive: displayStyle{Displayable}
	"Assume that the displayStyle is additive!!  Selection views are currently always additive."

	^self subViewIsChanged not or: [self subView displayIsAdditive: displayStyle]! !

!MultiSelectionViewer methodsFor: 'protected: creation'!

{void} destruct
	myHighlightModel removeDependent: self.
	mySelectionModel removeDependent: self.
	super destruct! !

!MultiSelectionViewer methodsFor: 'protected: accessing'!

{Highlight} highlight
	^ myHighlight!

{Heaper} selection
	^ mySelection! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiSelectionViewer class
	instanceVariableNames: ''!

(MultiSelectionViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiSelectionViewer class methodsFor: 'pseudo constructors'!

make: aSubView {Viewer} with: selectionModel {SelectionObject} with: highlightModel {VariableModel of: Highlight}
	^self create: aSubView with: selectionModel with: highlightModel! !