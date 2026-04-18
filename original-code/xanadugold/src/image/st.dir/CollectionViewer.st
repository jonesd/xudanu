'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:02 pm'!

AbstractMultiViewer subclass: #CollectionViewer
	instanceVariableNames: '
		subViewsInternal {ListModel of: Viewer}
		myEdit {IntegerRegion}
		myEditStart {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!
CollectionViewer comment:
'These CompositeViews have a collection for a model and a transformation to derive the proper view class for the elements.
	
		subViewsInternal hold the list model of subviews to compose and display.
		
		myEdit holds a region indicating which subviews need to be composed.
		myEditStart holds the first position at which recomposition needs to be done and
		myEditEnd holds the last position for recomposition.
		
		The edit region does not maintain the start and stop positions because on a view
		deletion, the remaining views do not need to be composed, they just need their
		locations updated.  Likewise, on a view insertion, only the inserted views need to
		be composed.'!

(CollectionViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class CollectionViewer */

	friend class ListDirector;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CollectionViewer methodsFor: 'accessing'!

{XnRegion}regionAt: oldIndex{IntegerVar}
	"Return a subView region per
	the current contents of the display."
	
	self subclassResponsibility!

{Position}selectionFor: aPoint{PointPos}
	"Find a point in a subView region expanded out
	to the compositionRegion boundary.
	Only meaningful for OrderedComposites."

	self subclassResponsibility!

{ListModel of: Viewer} subViews
	"Return a Collection containing all the receiver's subViews."

	^subViewsInternal! !

!CollectionViewer methodsFor: 'protected: accessing'!

{Dsp} dspAt: index {IntegerVar}
	"Return the transformation between me and my subView at index."

	self subclassResponsibility!

{IntegerVar} editStart

	^ myEditStart!

{XnRegion} fetchEditRecord

	^ myEdit!

{XnRegion} getEditRecord

	myEdit == NULL ifTrue: [myEdit _ self subViews asTable domain cast: IntegerRegion].
	^ myEdit!

{void} setEditRecord: newEdit {XnRegion}

	myEdit _ newEdit cast: IntegerRegion!

{void} setEditStart: newStart {IntegerVar} 
	newStart < myEditStart ifTrue: [myEditStart _ newStart.
		myEdit == NULL
			ifTrue: [myEdit _ IntegerRegion make: myEditStart]
			ifFalse: [myEdit isEmpty ifTrue: [myEdit _
IntegerRegion make: myEditStart]]]! !

!CollectionViewer methodsFor: 'protected: change'!

{void} changedEnclosure
	super changedEnclosure!

{void} changedEnclosureBy: delta {PointPos} 
	super changedEnclosureBy: delta!

{void} update: ur {UpdateRecord} from: sender {XnModel
unused}
	"The theory in this routine is that if there is no edit
record, the viewer has
	not been composed at all yet, therefore ignore the
change, because there
	is no edit record to update yet.  When the first compose
is done, the edit
	record will be created and then this routine will be used
to track the changes."
	
	myEdit == NULL ifTrue: [^ VOID].
	(ur isKindOf: RegionUR)
		ifTrue: [myEdit _ (myEdit unionWith: (ur basicCast:
RegionUR) region) cast: IntegerRegion]
	ifFalse: [(ur isKindOf: InsertionUR) 
		ifTrue: [ | moved {Mapping} pos {IntegerVar} iur
{InsertionUR} cnt {IntegerVar} |
			pos _ (iur _ ur basicCast: InsertionUR) index.
			moved _ (IntegerMapping make: (cnt _ iur count)) restrict:
(IntegerRegion after: pos).
			myEdit _ ((moved ofAll: myEdit) 
							unionWith: (IntegerRegion make: pos with: (pos +
cnt))) cast: IntegerRegion.
			self setEditStart: pos]
	ifFalse: [(ur isKindOf: DeletionUR)
		ifTrue: [(ur basicCast: DeletionUR) region simpleRegions 
			forEach: [:sr {IntegerRegion} | | moved {Mapping} |
				moved _ (IntegerMapping make: (sr count negated))
restrict: (IntegerRegion after: sr stop).
				myEdit _ ((moved ofAll: myEdit) cast:
IntegerRegion).
				self setEditStart: (sr start)]]
	ifFalse: [Heaper BLAST: #UNKNOWN.U.UPDATE.U.RECORD]]]!

{void} updateEnclosure: subView {Viewer} 
	"A subView's bounding region just changed."

	myEdit == NULL ifTrue: [^ VOID].
	myEdit _ (myEdit unionWith: 
				(IntegerRegion make: (self subViews asTable backfollowFrom: subView) stepper index))
				cast: IntegerRegion.
	self changedEnclosure!

{void} updateEnclosureBy: subView {Viewer} with: delta {PointPos} 
	"A subView's bounding region just changed. The delta is a clue as to 
	how it changed.  That is, the subviews extent changed by delta"

	myEdit == NULL ifTrue: [^VOID].
	myEdit _ (myEdit unionWith: (IntegerRegion make: (self subViews asTable backfollowFrom: subView) stepper index))
				cast: IntegerRegion.
	self changedEnclosureBy: delta! !

!CollectionViewer methodsFor: 'updating'!

{void} updateImage: subView {Viewer unused} 
	"A subview's image just changed."

	self changedImage! !

!CollectionViewer methodsFor: 'protected: creation'!

create: views {ListModel of: Viewer}
	super create.
	subViewsInternal _ views.
	views addDependent: self.  "heh 18 September 1990"
	"This doesn't call the subclass attach operation in C++."
	self subViews asTable stepper forEach: [:v {Viewer} | self attach: v].
	myEdit _ NULL.
	myEditStart _ IntegerVar0!

{void} destruct
(subViewsInternal isKindOf: ListModel) ifTrue:
	[subViewsInternal removeDependent: self. "heh 18 September 1990" 
	
	self subViews asTable stepper forEach: [:v {Viewer} | self detach: v.  v destroy].].
	super destruct! !