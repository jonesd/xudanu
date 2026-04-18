'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:10 pm'!

SuperViewer subclass: #ContainedSuperViewer
	instanceVariableNames: 'mySuperView {SuperViewer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
ContainedSuperViewer comment:
'Implement some of the upward change propagation that''s also implemented in LeafViewer.  Subclasses actually have a superView.'!

(ContainedSuperViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ContainedSuperViewer methodsFor: 'accessing'!

{Dsp} globalDsp
	"Propagate up the view tree computing the global dsp from subView."

	^mySuperView computeGlobalDsp: self!

{XnRegion} regionAt: index {IntegerVar}
	"Return the displayRegion occupied by the model position."
	
	self subclassResponsibility!

{Position} selectionFor: aPoint {PointPos}
	"Find the model position corresponding to the display position (a XuPoint)."

	self subclassResponsibility!

{void} setSuperView: aViewer {SuperViewer} 
	"Set my backPointer to the viwer that contains me."

	mySuperView _ aViewer!

{SuperViewer} superView
	"Return the viewer that contains the receiver."

	^mySuperView! !

!ContainedSuperViewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp} 
	"This is the fundamental display message 
	for Viewers, that subclasses must implement."

	self subclassResponsibility! !

!ContainedSuperViewer methodsFor: 'protected: change'!

{void} changedEnclosure
	"Notify the superView."

	super changedEnclosure.
	mySuperView updateEnclosure: self!

{void} changedEnclosureBy: delta {PointPos} 
	"Notify the superView."

	super changedEnclosureBy: delta.
	mySuperView updateEnclosureBy: self with: delta!

{void} changedImage
	"The currently displayed image, if any, is now invalid.
	If I haven't changed, mark my changed flag and tell my superView."

	self isChanged ifFalse: [mySuperView updateImage: self].
	super changedImage!

{PointRegion} computeEnclosure
	self subclassResponsibility!

{Dsp} computeGlobalDsp: subView {Viewer unused} 
	"Propagate up the view tree computing the global dsp from subView."
	"This should only be defined as protected in SuperView and MultiView."

	^mySuperView computeGlobalDsp: self! !

!ContainedSuperViewer methodsFor: 'updating'!

{void} updateImage: aSubView {Viewer} 
	"Since the subView will not send this if it has already
changed, we 
	don't need to test the changedSubView flag here."

	self subclassResponsibility! !

!ContainedSuperViewer methodsFor: 'creat/delete'!

create
	super create.
	mySuperView _ SuperViewer capViewer.make! !