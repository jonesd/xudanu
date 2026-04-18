'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:07 pm'!

FMSelectionViewer subclass: #ItemSelectionViewer
	instanceVariableNames: '
		myHighlightModel {VariableModel of: Highlight}
		myHighlight {Highlight}
		mySelectedModel {BooleanModel}
		myLayout {AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!
ItemSelectionViewer comment:
'Instances apply their highlight object to their layout region.  I don''t know quite what to do if the region is infinite.

Should selection instead be done by inserting a selection view above views that get selected?'!

(ItemSelectionViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ItemSelectionViewer methodsFor: 'create/delete'!

create: subView {Viewer} with: selectedModel {BooleanModel} with: highlightModel {VariableModel of: Highlight}
	super create: subView.
	myHighlightModel _ highlightModel.
	myHighlight _ NoHighlight make.
	mySelectedModel _ selectedModel.
	mySelectedModel addDependent: self.
	mySelectedModel getValue ifTrue: [myHighlightModel addDependent: self].
	myLayout _ NULL! !

!ItemSelectionViewer methodsFor: 'testing'!

{FMColor}highlightColor
	"This is supposed to return the color object used for drawing highlights.  
	 This probably requires the color of the destination warp to produce a
	 proper response.  Should this color be handed to the subView?  Certainly
	 a combination rule could be handed to subViews."

	"Highlighting isn't done using colors, it's done using color maps.  The superview determines the background color.  The subview determines the foreground color?  Is the clear operation in subViews a paint white or paint with the background color (paint transparent?)?"
	self unimplemented.
	^NULL! !

!ItemSelectionViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp}
	[Sensor leftShiftDown ifTrue: [self halt]] smalltalkOnly.
	self isChanged ifTrue: [self updateState].
	aWarp display: self subView.
	(myHighlight isEqual: NoHighlight make)
		ifFalse: [self highlightOn: aWarp].
	self validate! !

!ItemSelectionViewer methodsFor: 'composition'!

{void} composeWith: aLayout {AbstractLayout} 
	
	myLayout _ aLayout.
	super composeWith: myLayout.
	self changedImage! !

!ItemSelectionViewer methodsFor: 'highlighting'!

{void} highlightOn: aWarp {Warp} 
	"Toggle the current highlight."

	myHighlight reverse: myLayout rectangle on: aWarp!

{Highlight} newHighlight
	"Compute the new highlight object."

	mySelectedModel getValue
		ifTrue: [^myHighlightModel getValue cast: Highlight]
		ifFalse: [^NoHighlight make]!

{void} updateState
	"Change the record of the currently visible state to reflect the 
	current state of the models."

	myHighlight _ self newHighlight! !

!ItemSelectionViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel} 
	(mySelectedModel basicCast: XnModel) == sender 
		ifTrue: [mySelectedModel getValue
			ifTrue: [myHighlightModel addDependent: self]
			ifFalse: [myHighlightModel removeDependent: self]].
	self changedImage! !

!ItemSelectionViewer methodsFor: 'protected: creation'!

{void} destruct
	mySelectedModel getValue ifTrue: [myHighlightModel removeDependent: self].
	mySelectedModel removeDependent: self.
	mySelectedModel _ NULL.
	super destruct! !

!ItemSelectionViewer methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myHighlightModel getValue.
	mySelectedModel getValue
		ifTrue: [oo << ' - highlight ON)']
		ifFalse: [oo << ' - highlight OFF)']! !

!ItemSelectionViewer methodsFor: 'accessing'!

{BooleanModel} selectionModel

	^ mySelectedModel! !

!ItemSelectionViewer methodsFor: 'protected: accessing'!

{Highlight} highlight

	^ myHighlight!

{Heaper} selection

	^ mySelectedModel! !

!ItemSelectionViewer methodsFor: 'smalltlak: passe'!

{BooleanVar}displayIsAdditive: displayStyle{Displayable}
	"Assume that the displayStyle is additive!!  Selection views are currently always additive."
	self passe.
	^self subViewIsChanged not or: [self subView displayIsAdditive: displayStyle]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ItemSelectionViewer class
	instanceVariableNames: ''!

(ItemSelectionViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ItemSelectionViewer class methodsFor: 'pseudoconstructors'!

make: subView {Viewer} with: selectedModel {BooleanModel} with: highlightModel {VariableModel of: Highlight}
	^ self create: subView with: selectedModel with: highlightModel! !