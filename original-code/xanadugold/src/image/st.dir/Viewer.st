'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:14 pm'!

XnDependent subclass: #Viewer
	instanceVariableNames: '
		changed {BooleanVar}
		enclosureInternal {PointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
Viewer comment:
'This class should be a subclass of Dependent, not XModel.  Alternatively, enclosure and image changes could propagate using the dependency mechanism.

The enclosure caching should be done by specific subclasses.  Implementing it here is a hack.

A view can display a model, and transform from display coordinates to model coordinates and vice-versa (for controllers).  Viewers are dependents of their models, so that they can track changes to their model.

The basic Viewer protocol:

{void} displayOn: aWarp {Warp}
{PointRegion} enclosure
{PointRegion} regionAt: index {IntegerVar}
{Position} selectionFor: point {XuPoint}
'!

(Viewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Viewer methodsFor: 'testing'!

{BooleanVar} isChanged
	^changed! !

!Viewer methodsFor: 'accessing'!

{void} composeWith: aLayout {AbstractLayout} 
	"Compose the receiver using the constraints embodied in
aLayout. 
	The default is to do nothing!!"!

{PointRegion} enclosure
	"Return the minimum region in which the receiver can display all of its contents."

	enclosureInternal == NULL ifTrue: [enclosureInternal _ self computeEnclosure].
	^enclosureInternal!

{Dsp} globalDsp
	"Propagate up the view tree computing the global dsp from subView."

	self subclassResponsibility!

{PointPos} offsetFor: region {XnRegion}
	"find the display position for a given model position"
	| span {IntegerRegion} |
	span _ region cast: IntegerRegion.
	(span isEmpty or: [span isBoundedBelow not])
		ifTrue: [^PointPos make].
	^((self regionAt: span start) cast: PointRegion) origin!

{XnRegion} regionAt: index {IntegerVar}
	"Return the displayRegion occupied by the model position."
	
	self subclassResponsibility!

{Position} selectionFor: aPoint {PointPos}
	"Find the model position corresponding to the display position (a XuPoint)."

	self subclassResponsibility!

{XnRegion} selectionIn: region {XnRegion of: PointPos}
	"Find the model region corresponding to the display region"
	^(self selectionFor: (region cast: PointRegion) origin) asRegion
		simpleUnion: (self selectionFor: (region cast: PointRegion) corner) asRegion!

{void} setSuperView: aViewer {SuperViewer} 
	"Set the viewer that contains the receiver."

	self subclassResponsibility!

{SuperViewer} superView
	"Return the viewer that contains the receiver."

	self subclassResponsibility! !

!Viewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp} 
	"This is the fundamental display message for Viewers, that 
	subclasses must implement. Viewers that display other subViews as 
	a part of their displayOn: method should (must?) display them with 
	the message warp display: subViewer."

	self subclassResponsibility! !

!Viewer methodsFor: 'updating'!

{void} update: updateRecord {UpdateRecord unused} from:
sender {XnModel unused} 
	"Just mark as changedImage"

	self changedImage! !

!Viewer methodsFor: 'protected: protected'!

{void} changedEnclosure
	"The previously computed region is invalid. 
	Notify the superView."

	enclosureInternal _ NULL.
	"When the enclosure changes, the image changes too."
	self changedImage!

{void} changedImage
	"The currently displayed image, if any, is now invalid. 
	If I haven't changed, mark my changed flag and tell my
superView."

	changed _ true!

{PointRegion} computeEnclosure
	self subclassResponsibility!

{void} validate
	changed _ false! !

!Viewer methodsFor: 'create/delete'!

create
	super create.
	changed _ true.
	enclosureInternal _ NULL! !

!Viewer methodsFor: 'smalltalk: smalltalk only'!

displayString
	^self getCategory name!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: self enclosure! !

!Viewer methodsFor: 'printing'!

{void} printIndentedOn: oo {ostream reference} with: level {IntegerVar}

	level DOTasLong timesRepeat: [oo << '	'].
	self printOn: oo.!

{void} printOn: oo {ostream reference}

	oo << self getCategory name! !

!Viewer methodsFor: 'protected: change'!

{void} changedEnclosureBy: delta {PointPos unused} 
	"The previously computed region is invalid. 
	Notify the superView."

	enclosureInternal _ NULL.
	"When the enclosure changes, the image changes too."
	self changedImage! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Viewer class
	instanceVariableNames: ''!

(Viewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Viewer class methodsFor: 'smalltalk: smalltalk examples'!

{Pair} editForms: formList {ImmuTable} 
	"(Viewer editForms: (OrderedCollection with: Form fromUser with: Form 
	fromUser with: Form fromUser)) testView."

	| viewAcc {TableAccumulator} controllerAcc {TableAccumulator} |
	viewAcc _ TableAccumulator make.
	controllerAcc _ TableAccumulator make.
	formList stepper
		forEach: 
			[:elem {Form} | 
			| pair {Pair} |
			pair _ Viewer editForm: elem.
			viewAcc step: pair left.
			pair right ~~ NULL ifTrue: [controllerAcc step: pair right]].
	^Pair make: (ListMultiViewer 
					make: (viewAcc value cast: ScruTable)
					with: (BoundingListComp make: ListStyle defaultVertical))
		with: (MultiController make: (controllerAcc value cast: ScruTable))! !