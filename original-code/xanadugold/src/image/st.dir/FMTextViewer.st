'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:51 pm'!

ContainedSuperViewer subclass: #FMTextViewer
	instanceVariableNames: '
		mySubView {Viewer}
		myDirector {FMTextDirector}
		myLayout {AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMTextViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextViewer methodsFor: 'accessing'!

{XnRegion} displayRegionFor: modelRegion {XnRegion unused}
	"Return the displayRegion occupied by the model region."
	
	self unimplemented.
	^NULL!

{XnRegion} regionAt: index {IntegerVar unused}
	"Return the displayRegion occupied by the model position."
	
	self unimplemented.
	^NULL!

{Position} selectionFor: aPoint {PointPos}
	"Find the model position corresponding to the display position (a XuPoint)."

	^ mySubView selectionFor: aPoint! !

!FMTextViewer methodsFor: 'creation'!

create: onDirector {FMTextDirector} with: subViews {Viewer} 
	super create.
	mySubView _ subViews.
	myDirector _ onDirector.
	myDirector addDependent: self.
	subViews setSuperView: self.
	myLayout _ NULL!

create: onDirector {FMTextDirector} with: subViews {ListMultiViewer} with: layout {AbstractLayout} 
	"This constructor is used for fixed-layout text"

	super create.
	mySubView _ subViews.
	myDirector _ onDirector.
	myDirector addDependent: self.
	subViews setSuperView: self.
	myLayout _ layout!

{void} destruct
	myDirector removeDependent: self.
	myDirector destroy.
	myDirector _ NULL.
	mySubView _ NULL.
	myLayout _ NULL.
	super destruct! !

!FMTextViewer methodsFor: 'displaying'!

{void} composeWith: layout {AbstractLayout} 
	"Note that if we get here and I have a non-null layout, then that is 
	a fixed layout that I am composing to. If myLayout is NULL, then 
	pay attention to the layout being passed in (layout to window...)"

	myLayout == NULL ifTrue: [
		myDirector composeWith: layout.
		mySubView composeWith: layout]!

{void} displayOn: aWarp {Warp} 
	aWarp display: mySubView.
	self validate!

{void} fixedCompose
	"This method is provided to allow builders that are making a 
	fixed-layout text display to compose the text. Since the 
	composeWith: method will not do anything, this is provided."

	myLayout ~~ NULL
		ifTrue: [myDirector composeWith: myLayout.
			mySubView composeWith: myLayout]
		ifFalse: [Heaper BLAST: #NO.U.LAYOUT.U.PROVIDED]! !

!FMTextViewer methodsFor: 'updating'!

{void}updateImage: aSubView {Viewer unused}
	"Since the subView will not send this if it has already
changed, we don't 
	 need to test the changedSubView flag here."

	self changedEnclosure! !

!FMTextViewer methodsFor: 'protected: composing'!

{PointRegion} computeEnclosure

	^ mySubView enclosure! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMTextViewer class
	instanceVariableNames: ''!

(FMTextViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextViewer class methodsFor: 'pseudo constructor'!

make: onDir {FMParaDirector} with: viewer {Viewer}

	^ self create: onDir with: viewer!

make: onDir {FMParaDirector} with: viewer {Viewer} with: layout {AbstractLayout}

	^ self create: onDir with: (viewer cast: ListMultiViewer) with: layout! !