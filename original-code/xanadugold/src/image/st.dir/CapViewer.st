'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:10 pm'!

SuperViewer subclass: #CapViewer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
CapViewer comment:
'Sit at the top of a viewer structure an terminate upward propagating messages.'!

(CapViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CapViewer methodsFor: 'accessing'!

{Dsp} globalDsp
	"Propagate up the view tree computing the global dsp from subView."

	^PointSpace make identityDsp!

{XnRegion} regionAt: index {IntegerVar unused}
	"Return the displayRegion occupied by the model position."
	
	self unimplemented.
	^NULL!

{Position} selectionFor: aPoint {PointPos unused}
	"Find the model position corresponding to the display
position (a XuPoint)."

	self unimplemented.
	^NULL!

{void} setSuperView: aViewer {SuperViewer unused}
	"Set the viewer that contains the receiver."

	"self error: 'Cap Views cannot be a subView.'"
	Heaper BLAST: #FatalError!

{SuperViewer} superView
	"Return the viewer that contains the receiver."

	^self! !

!CapViewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp unused} 
	"This is the fundamental display message for Viewers,
that 
	subclasses must implement. 
	-- except that a CapViewer is NEVER displayed, it's just
presen for 
	Dsp information"

	self unimplemented! !

!CapViewer methodsFor: 'protected: protected'!

{PointRegion} computeEnclosure
	self unimplemented.
	^NULL!

{Dsp} computeGlobalDsp: subView {Viewer unused}
	"End the recursion up the tree computing the dsp."

	^PointSpace make identityDsp! !

!CapViewer methodsFor: 'updating'!

{void} updateImage: subView {Viewer unused}
	"The currently displayed image, if any, is now invalid."

	super changedImage! !