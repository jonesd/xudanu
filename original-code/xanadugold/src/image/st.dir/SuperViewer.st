'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:13 pm'!

Viewer subclass: #SuperViewer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
SuperViewer comment:
'Subclasses implement views that contain other views.  The additional protocol here supports communication up a structure of viewers for change propagation and model/display position mapping.'!

(SuperViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class SuperViewer */
friend LeafViewer;
friend ContainedSuperViewer;
';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SuperViewer methodsFor: 'accessing'!

{Dsp} globalDsp
	"Propagate up the view tree computing the global dsp from subView."

	self subclassResponsibility!

{XnRegion} regionAt: index {IntegerVar}
	"Return the displayRegion occupied by the model position."
	
	self subclassResponsibility!

{Position} selectionFor: aPoint {PointPos}
	"Find the model position corresponding to the display position (a XuPoint)."

	self subclassResponsibility!

{void} setSuperView: aViewer {SuperViewer} 
	"Set the viewer that contains the receiver."

	self subclassResponsibility!

{SuperViewer} superView
	"Return the viewer that contains the receiver."

	self subclassResponsibility! !

!SuperViewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp} 
	"This is the fundamental display message 
	for Viewers, that subclasses must implement."

	self subclassResponsibility! !

!SuperViewer methodsFor: 'protected: accessing'!

{PointRegion} computeEnclosure 
	self subclassResponsibility!

{Dsp} computeGlobalDsp: subView {Viewer} 
	"Propagate up the view tree computing the global dsp from subView."
	"This should only be defined as protected in SuperView and MultiView."

	self subclassResponsibility! !

!SuperViewer methodsFor: 'updating'!

{void} updateEnclosure: aSubView {Viewer unused}
	"propagate."

	self changedEnclosure!

{void} updateEnclosureBy: aSubView {Viewer unused} with: delta {PointPos}
	"propagate."

	self changedEnclosureBy: delta!

{void} updateImage: aSubView {Viewer}
	"Since the subView will not send this if it has already changed, we don't 
	 need to test the changedSubView flag here."

	self subclassResponsibility! !

!SuperViewer methodsFor: 'creat/delete'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SuperViewer class
	instanceVariableNames: ''!

(SuperViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class SuperViewer */
friend LeafViewer;
friend ContainedSuperViewer;
';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SuperViewer class methodsFor: 'pseudo constructors'!

{SuperViewer} capViewer.make
	^CapViewer create! !