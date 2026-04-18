'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:03 pm'!

CollectionViewer subclass: #ListMultiViewer
	instanceVariableNames: '
		compositorInternal {AbstractListComp}
		myFill {FillViewer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!
ListMultiViewer comment:
'This could be generalized to non-overlapping display.  The layout object returns the enclosures that have moved and by how much.  The CompositeView then determines the proper update and movement order to optimize redisplay.

In the meantime, this knows how to update a changing list of views..  The layout is responsible for knowing where each subView goes (based on its predecessors).  Thus, we can switch Layout objects to change recomposition algorithm and layout algorithm.  The style determines whether the axis is horizontal or vertical.

This should have a separate view to handle what to do in the spaces.  The space view should generalize to allow a connection view.
	
	myFill is a fill viewer which is used to white out any uncomposed space in the viewer'!

(ListMultiViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class ListMultiViewer */
friend class ListDirector;
friend SPTR(ListMultiViewer)  listMultiViewer (ListModel OF1(Viewer) * views, AbstractListComp * layout);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListMultiViewer methodsFor: 'private: create/delete'!

create: views {ListModel of: Viewer} with: newComp {AbstractListComp} 
	super create: views.
	compositorInternal _ newComp.
	myFill _ FillViewer make: FMColor fmWhiteColor! !

!ListMultiViewer methodsFor: 'accessing'!

{void} composeWith: aLayout {AbstractLayout} 
	self fetchEditRecord == NULL
		ifTrue: [compositorInternal compose: self subViews asTable with: aLayout]
		ifFalse: [compositorInternal compose: self subViews asTable with: aLayout
		"compositorInternal recompose: self subViews with: self editStart with: self fetchEditRecord"].
	self setEditRecord: IntegerRegion make.
	myFill setEnclosure: (compositorInternal uncomposedRegion)!

{XnRegion} regionAt: selectionKey {IntegerVar} 
	"Return the region allocated to the subView represented by 
	selectionKey. 
	CompositeViews insist that the selectionKeys be integers."
	"I can't understand the previous comment, if you do fix something"
	"^compositorInternal regionAt: (selectionKey cast: XuInteger) 
	asIntegerVar"

	^compositorInternal regionAt: selectionKey!

{Position} selectionFor: point {PointPos}
	"Find a point in a subView region expanded out
	to the compositionRegion boundary.
	Only meaningful for OrderedComposites."

	^(compositorInternal regionIndexFor: point) integer! !

!ListMultiViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	"Project all the subs that fit through the warp, then 
	fill the remaining space."

	| displayBox {PointRegion} stp {TableStepper} |
	self checkComposition.
	displayBox _ aWarp enclosure.
	stp _ (self subViews asTable subTable: 
		(IntegerRegion make: (compositorInternal regionIndexFor: displayBox origin)
					with: (compositorInternal regionIndexFor: displayBox corner) + 1)) stepper.
	stp forEach: [:v {Viewer} | (self distort: aWarp at: stp index)
			display: v].
	aWarp display: myFill.
	self validate! !

!ListMultiViewer methodsFor: 'transforming'!

{Warp} distort: aWarp {Warp} at: index {IntegerVar} 
	^aWarp intersect: (compositorInternal regionAt: index)
		translateBy: (compositorInternal translationAt: index)!

{Dsp} dspAt: index {IntegerVar}
	"Return the transformation between me and my subView at index."

	^compositorInternal translationAt: index! !

!ListMultiViewer methodsFor: 'smalltalk:'!

inspectPieces
	"Return pieces to be used in a tree browser."

	| result |
	result _ super inspectPieces.
	result add: compositorInternal.
	^result! !

!ListMultiViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel} 
	self subViews == (sender cast: ListModel) ifTrue:
		[(ur isKindOf: RegionUR)
			ifTrue: [(ur basicCast: RegionUR) region stepper
forEach: 
						[:pos {IntegerPos} | self attach: ((self subViews
get: pos asIntegerVar) cast: Viewer)]]
		ifFalse: [(ur isKindOf: InsertionUR)
			ifTrue: [| sPos {IntegerVar} |
				(sPos _ (ur basicCast: InsertionUR) index).
				sPos almostTo: sPos + (ur basicCast: InsertionUR)
count do: 
						 	[:idx {IntegerVar} | self attach: ((self subViews
get: idx) cast: Viewer)]]
		ifFalse: [(ur isKindOf: DeletionUR)
			ifTrue: [self setEditRecord: (self getEditRecord
unionWith: ((ur basicCast: DeletionUR) region))]
			ifFalse: [Heaper BLAST: #UNKNOWN.U.UPDATE.U.RECORD]]].
		super update: ur from: sender.
		self changedEnclosure]! !

!ListMultiViewer methodsFor: 'protected: change'!

{void} updateEnclosure: aSubView {Viewer unused}
	"A subView's bounding region just changed."

	self changedEnclosure!

{void} updateEnclosureBy: subView {Viewer} with: delta {PointPos}
	"A subView's bounding region just changed.  The delta is a clue as to how it changed.
	  That is, the subviews extent changed by delta"

	(((compositorInternal style cast: ListStyle) axis cast: Orientation) primaryOfPoint: delta) ~~ IntegerVar0
		ifTrue: [super updateEnclosureBy: subView with: delta]! !

!ListMultiViewer methodsFor: 'protected: composing'!

{void}compose: subView{Viewer} at: index{IntegerVar} 
	"We should really shorten the compositionRegion 
	as we go through the subViews, but this makes 
	the structure too complex.  We'll change it if 
	we have to...."

	subView composeWith: (compositorInternal layoutAt: index)! !

!ListMultiViewer methodsFor: 'protected: enclosure'!

{PointRegion} computeEnclosure
	^compositorInternal computeEnclosureFor: self subViews asTable! !

!ListMultiViewer methodsFor: 'private: composing'!

{void} checkComposition
	"I am supposed to see if the current composition is
correct and 
	update it as appropriate."

	self getEditRecord isEmpty not
		ifTrue: [| leftOver {PointRegion} |
			leftOver _ compositorInternal uncomposedRegion.
			compositorInternal
				recompose: self subViews asTable
				with: self editStart
				with: self getEditRecord.
			self setEditRecord: IntegerRegion make.
			(leftOver isEqual: compositorInternal uncomposedRegion)
				ifFalse: [myFill setEnclosure: compositorInternal
uncomposedRegion]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListMultiViewer class
	instanceVariableNames: ''!

(ListMultiViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class ListMultiViewer */
friend class ListDirector;
friend SPTR(ListMultiViewer)  listMultiViewer (ListModel OF1(Viewer) * views, AbstractListComp * layout);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListMultiViewer class methodsFor: 'smalltalk: example'!

exampleCollection
	^OrderedCollection
		with: (Form fromUser)
		with: (Form fromUser)
		with: (Form fromUser)
		with: (Form fromUser)! !

!ListMultiViewer class methodsFor: 'pseudo constructors'!

make: views {ListModel of: Viewer} with: layout {AbstractListComp}
	^ self create: views with: layout! !