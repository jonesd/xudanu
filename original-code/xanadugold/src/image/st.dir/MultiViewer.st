'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:12 pm'!

AbstractMultiViewer subclass: #MultiViewer
	instanceVariableNames: '
		mySubViews {ListModel of: Viewer}
		changedSubViews {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
MultiViewer comment:
'This subclass is used as a simple form of multiviewer that holds multiple subviews without imposing spatial ordering on them.  It requires that each subview translate itself to a position within this view and restrict itself appropriately.'!

(MultiViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class MultiViewer */
friend SPTR(MultiViewer)  multiViewer (ListModel OF1(Viewer) * onList);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiViewer methodsFor: 'accessing'!

{XnRegion} regionAt: index {IntegerVar unused} 
	"Return the displayRegion occupied by the model position."

	self unimplemented.
	^NULL!

{Position} selectionFor: aPoint {PointPos unused}
	"Find the model position corresponding to the display
position (a XuPoint)."

	self unimplemented.
	^ NULL!

{ListModel of: Viewer} subViews
	^mySubViews! !

!MultiViewer methodsFor: 'updating'!

{BooleanVar} isChanged
	^ changedSubViews or: [super isChanged]!

{void} update: ur {UpdateRecord} from: sender {XnModel} 
	sender == (mySubViews basicCast: XnModel) 
		ifTrue: [(ur isKindOf: InsertionUR)
			ifTrue: [((mySubViews fetch: (ur basicCast: InsertionUR) index) cast: Viewer)
						setSuperView: self]
			ifFalse: ["what can i do?"(ur isKindOf: DeletionUR)
					ifTrue: []]].
	self changedEnclosure!

{void} updateImage: aSubView {Viewer unused} 
	changedSubViews ifFalse: [changedSubViews _ true.
		super isChanged ifFalse: [self superView updateImage: self]].
	super changedImage! !

!MultiViewer methodsFor: 'protected: change'!

{PointRegion} computeEnclosure
	| reg {PointRegion} |
	[Stepper, ScruTable] USES.
	reg _ PointRegion make.
	self subViews asTable stepper forEach: [:sv {Viewer} |
		reg _ (reg simpleUnion: sv enclosure) cast: PointRegion].
	^ reg!

{Dsp} computeGlobalDsp: subView {Viewer unused}
	"I don't affect the dsp of my subviews, they must do that
for themselves."

	^ self globalDsp!

{Dsp} dspAt: index {IntegerVar unused} 
	^PointTranslateDsp make!

{void} validate
	super validate.
	changedSubViews _ false! !

!MultiViewer methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	super printOn: aStream.
	aStream << ' on '.
	mySubViews asTable printOnWithSimpleSyntax: aStream with: '(' with: ', ' with: ')'! !

!MultiViewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp} 
	"This is the fundamental display message 
	for Viewers, that subclasses must implement."

	self subViews asTable stepper forEach: [:sv {Viewer} |
		aMedium display: sv].
	self validate! !

!MultiViewer methodsFor: 'private: creation etc'!

create: onList {ListModel} 
	super create.
	mySubViews _ onList.
	changedSubViews _ true.
	mySubViews addDependent: self.
	mySubViews asTable stepper forEach: [:sv {Viewer} | sv setSuperView: self]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiViewer class
	instanceVariableNames: ''!

(MultiViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class MultiViewer */
friend SPTR(MultiViewer)  multiViewer (ListModel OF1(Viewer) * onList);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiViewer class methodsFor: 'pseudo constructors'!

make: onList {ListModel of: Viewer}

	^ self create: onList! !