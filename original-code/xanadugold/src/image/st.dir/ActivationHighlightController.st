'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:43 pm'!

FMController subclass: #ActivationHighlightController
	instanceVariableNames: '
		myHighlightVariable {VariableModel}
		activeHighlight {Highlight}
		inactiveHighlight {Highlight}
		active {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
ActivationHighlightController comment:
'Instances respond to de/activate messages to change the highlightObject 
stored in a VariableModel appropriately.  Dependent SelectionViews use 
the highlightObject for drawing their selection.  This allows selections 
which change to outlines (for example) when another window gets 
selected.'!

(ActivationHighlightController getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActivationHighlightController methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	"Change the activation state and the highlight object."

	event activate ifTrue: 
		[active _ true.
		myHighlightVariable setValue: activeHighlight].
	event deactivate ifTrue: 
		[active _ false.
		myHighlightVariable setValue: inactiveHighlight]!

{BooleanVar} requestEvents: event {FMEvent}
	"Respond to events that change the activation
	 state and thence the highlight."

	active
		ifTrue: [^event deactivate]
		ifFalse: [^event activate]! !

!ActivationHighlightController methodsFor: 'create'!

create: highlightModel {VariableModel}
	super create.
	active _ false.
	myHighlightVariable _ highlightModel.
	activeHighlight _ HighlightAll make.
	inactiveHighlight _ highlightModel getValue cast: Highlight.!

create: highlightModel {VariableModel} with: highlightActive {Highlight}
	super create.
	active _ false.
	myHighlightVariable _ highlightModel.
	activeHighlight _ highlightActive.
	inactiveHighlight _ highlightModel getValue cast: Highlight.! !

!ActivationHighlightController methodsFor: 'accessing'!

{VariableModel} highlightModel
	^myHighlightVariable! !

!ActivationHighlightController methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !