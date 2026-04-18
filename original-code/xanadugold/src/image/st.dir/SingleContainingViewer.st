'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:12 pm'!

ContainedSuperViewer subclass: #SingleContainingViewer
	instanceVariableNames: '
		subViewInternal {Viewer}
		changedSubView {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
SingleContainingViewer comment:
'Subclasses implement views that contain exactly one other view and modify it some way (selection, scrolling, scaling, etc.).'!

(SingleContainingViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SingleContainingViewer methodsFor: 'testing'!

{BooleanVar} isChanged
	^super isChanged or: [changedSubView]!

{BooleanVar} selfIsChanged
	^super isChanged!

{BooleanVar} subViewIsChanged
	^changedSubView! !

!SingleContainingViewer methodsFor: 'accessing'!

{void} composeWith: layout {AbstractLayout}
	"Since the default boundingRegion gets transformed, so must the compositionRegion."

	subViewInternal composeWith: layout!

{Dsp} dsp
	"Return the transformation between me and my subView."

	^PointSpace make identityDsp!

{XnRegion} regionAt: index {IntegerVar}
	"Return the displayRegion occupied by the model position."
	
	index = 1 
		ifTrue: [^subViewInternal enclosure]
		ifFalse: [^PointRegion make]!

{Position} selectionFor: aPoint {PointPos} 
	"Find the model position corresponding to the display position (a XuPoint)."

	(subViewInternal enclosure hasMember: aPoint)
		ifTrue: [ ^ Integer0]
		ifFalse: [ ^ -1 integer]!

{void} setSubView: newView {Viewer} 
	subViewInternal == newView ifTrue: [^VOID].
	"A little consistency checking...."
	subViewInternal == NULL 
		ifFalse: [subViewInternal superView == self 
			ifTrue: [subViewInternal setSuperView: NULL]].
	subViewInternal _ newView.
	subViewInternal setSuperView: self! !

!SingleContainingViewer methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	super printOn: aStream.
	aStream << ' on '.
	subViewInternal printOn: aStream! !

!SingleContainingViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	(self distort: aWarp) display: subViewInternal.
	self validate!

{Warp} distort: warp {Warp}
	"Distort the warp appropriately for projecting subViews."

	^warp! !

!SingleContainingViewer methodsFor: 'updating'!

{void} updateImage: aSubView {Viewer unused}
	"Since the subView will not send this if it has already changed, we don't 
	 need to test the changedSubView flag here."

	changedSubView ifFalse:
		[changedSubView _ true.
		"If I've already changed, then my superView already knows."
		super isChanged ifFalse: [self superView updateImage: self]].
	super changedImage! !

!SingleContainingViewer methodsFor: 'protected: protected'!

{PointRegion} computeEnclosure
	^subViewInternal enclosure!

{Dsp} computeGlobalDsp: subView {Viewer unused}
	"Propagate up the view tree computing the global dsp from subView."

	^self dsp compose: self globalDsp!

{void} validate
	super validate.
	changedSubView _ false! !

!SingleContainingViewer methodsFor: 'smalltalk: smalltalk only'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: subViewInternal! !

!SingleContainingViewer methodsFor: 'unprotected accessing'!

{Viewer} subView
	^subViewInternal! !

!SingleContainingViewer methodsFor: 'protected: creation'!

{void} destruct
	| sub {Viewer wimpy} |
	sub _ subViewInternal.
	sub destroy.
	subViewInternal _ NULL.
	super destruct! !

!SingleContainingViewer methodsFor: 'create/delete'!

create: aSubView {Viewer}
	super create.
	subViewInternal _ NULL.
	changedSubView _ true.
	self setSubView: aSubView! !