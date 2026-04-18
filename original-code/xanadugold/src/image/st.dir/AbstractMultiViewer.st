'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:00 pm'!

ContainedSuperViewer subclass: #AbstractMultiViewer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!
AbstractMultiViewer comment:
'An abstract superclass to define the protocol and conventions followed by CompositeViews.  The actual representation of subViews may differ among the subclasses.

Composite views must be able to determine their composition separately from displaying.'!

(AbstractMultiViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class AbstractMultiViewer */

	friend class ListDirector;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractMultiViewer methodsFor: 'accessing'!

{void} composeWith: aLayout {AbstractLayout unused} 
	| stp {TableStepper} |
	stp _ self subViews asTable stepper.
	stp forEach: [:v {Viewer} | self compose: v at: stp
index]!

{XnRegion} regionAt: oldIndex {IntegerVar} 
	"Return a subView region per 
	the current contents of the display."

	self subclassResponsibility!

{Position} selectionFor: aPoint {PointPos} 
	"Find a point in a subView region expanded out 
	to the compositionRegion boundary. 
	Only meaningful for OrderedComposites."

	self subclassResponsibility!

{ListModel of: Viewer} subViews
	"Return a Collection containing all the receiver's subViews."

	^self subclassResponsibility! !

!AbstractMultiViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender
{XnModel unused} 
	"sender can only be subViews"

	self changedEnclosure!

{void} updateImage: subView {Viewer unused} 
	"A subview's image just changed. 
	Subclasses might want to do something 
	more complicated."

	self changedImage! !

!AbstractMultiViewer methodsFor: 'printing'!

{void} printIndentedOn: oo {ostream reference} with: level {IntegerVar}
	| stomp {Stepper} |
	level DOTasLong timesRepeat: [oo << '	'].
	super printOn: oo.
	oo << '(
'.
	stomp _ self subViews asTable stepper.
	[stomp hasValue] whileTrue: [| sv {Viewer} | 
		sv _ (stomp fetch) cast: Viewer.
		sv printIndentedOn: oo with: (level + 1).
		stomp step.
		stomp hasValue ifTrue: [ oo << ',
' ]].
	oo << ')'!

{void} printOn: oo {ostream reference}
	self printIndentedOn: oo with: IntegerVar0! !

!AbstractMultiViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	"A very simple displaying algorithm."

	| subS {TableStepper} |
	subS _ self subViews asTable stepper.
	subS forEach: [:v {Viewer} | (self distort: aWarp at: subS index) display: v].
	self validate!

{Warp} distort: warp {Warp} at: index {IntegerVar} 
	"Default is just to clip"

	^warp intersect: (self regionAt: index)! !

!AbstractMultiViewer methodsFor: 'smalltalk:'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^self subViews asTable asOrderedCollection!

{void}update.RemoveUR: ur{UpdateRecord} from: sender{XnModel}
	"sender can only be subViews"

	self detach: ur element! !

!AbstractMultiViewer methodsFor: 'protected: accessing'!

{void}attach: subView{Viewer}
	"Do the bookkeepping associated with adding a view."

	subView setSuperView: self.
	self changedEnclosure!

{void} compose: subView {Viewer} at: index {IntegerVar unused} 
	"Recompose a subView appropriately, 
	when attaching it or when its enclosure 
	changes. Subclasses may want something 
	different."

	subView composeWith: RegionLayout emptyLayout!

{PointRegion} computeEnclosure
	| s {ScruTable of: Viewer} encl {XnRegion} |
	encl _ PointRegion make.
	(s _ self subViews asTable) isEmpty ifTrue: [^encl quickCast: PointRegion].
	s stepper forEach: [:v {Viewer} | encl _ encl simpleUnion: v enclosure].
	^encl quickCast: PointRegion!

{Dsp} computeGlobalDsp: subView {Viewer} 
	"Propagate up the view tree computing the global dsp from subView."

	^(self dspAt: (self subViews asTable backfollowFrom: subView) stepper index)
		compose: self globalDsp!

{void} detach: subView {Viewer} 
	"This goes after a subView gets removed."

	self changedEnclosure.
	subView superView == self 
		ifTrue: [subView setSuperView: (SuperViewer capViewer.make
basicCast: SuperViewer)]!

{Dsp} dspAt: index {IntegerVar}
	"Return the transformation between me and my subView at index."

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AbstractMultiViewer class
	instanceVariableNames: ''!

(AbstractMultiViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class AbstractMultiViewer */

	friend class ListDirector;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractMultiViewer class methodsFor: 'smalltalk: example'!

{ScruTable of: Viewer}exampleCollection

	[| vv |
	vv _ OrderedCollection create.
	self exampleViewers with: self exampleRegions do: [:v :w | vv add: (v boundedBy: w)].
	^vv] smalltalkOnly!

{ScruTable of: XnRegion}exampleRegions

	[^OrderedCollection
		with: (20 @ 20 extent: 40 @ 60)
		with: (50 @ 40 extent: 120 @ 80)
		with: (80 @ 80 extent: 100 @ 100)
		with: (20 @ 140 extent: 200 @ 40)] smalltalkOnly! !

!AbstractMultiViewer class methodsFor: 'smalltalk: init'!

initialize
	"NoSelectionIndex is used for communication between ListComps and ListViews. 
	 NoSelection is used for communication between ListViews and ListControllers."
	 "AbstractMultiViewer initialize."
	 
	Smalltalk at: #NoSelectionx put: -1 integer! !

AbstractMultiViewer initialize!
