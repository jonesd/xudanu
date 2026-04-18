'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:01 pm'!

AbstractListComp subclass: #BoundingListComp
	instanceVariableNames: '
		myStyle {ListStyle}
		myLayout {AbstractLayout}
		myBoundaries {IntegerVarArray}
		myNextBoundary {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!

(BoundingListComp getOrMakeCxxClassDescription)
	friends:
'/* friends for class BoundingListComp */
friend SPTR(BoundingListComp) boundingListComp (ListStyle * style);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoundingListComp methodsFor: 'accessing'!

{XnRegion} compositionRegion
	"the region that everything is composed into"
	| spacing {IntegerVar} |
	(spacing _ myStyle spacing) == IntegerVar0 ifTrue:
		[^myStyle axis project: (IntegerRegion
			make: (self boundaryAtIndex: IntegerVar0)
			with: (self lastBoundary))]
	ifFalse:
		[ | result {XnRegion} bound {IntegerVar} next {IntegerVar} |
		result _ IntegerRegion make.
		bound _ self boundaryAtIndex: IntegerVar0.
		1 almostTo: myNextBoundary do: [ :i {IntegerVar} |
			next _ self boundaryAtIndex: i.
			result _ result unionWith: (IntegerRegion make: bound with: next - spacing).
			bound _ next].
		^myStyle axis project: (result cast: IntegerRegion)]!

{PointRegion} computeEnclosureFor: views {ScruTable of: Viewer} 
	| s {IntegerVar} p {IntegerVar} axis {Orientation} |
	views isEmpty ifTrue: [^PointRegion make]. 
	axis _ myStyle axis.
	p _ s _ IntegerVar0.
	views stepper
		forEach: 
			[:view {Viewer} | 
			| extent {PointPos} |
			extent _ view enclosure extent.
			s _ s max: (axis  secondaryOfPoint: extent).
			p _ p + (axis primaryOfPoint: extent)].
	^PointRegion regionExtent: (axis orientPoint: (PointPos make: (p + (views count - 1 * myStyle spacing)) with: s))!

{XnRegion} regionAt: index {IntegerVar}

	(index >= IntegerVar0 and: [index < myNextBoundary and: [(self boundaryAtIndex: index) < (self boundaryAtIndex: (index + 1))]])
		ifFalse: [^ PointRegion make].

	^myStyle axis project: (IntegerRegion
		make: (self boundaryAtIndex: index)
		with: (self boundaryAtIndex: index + 1) - myStyle spacing)!

{IntegerVar} regionIndexFor: aPoint {PointPos}
	"find the virtual area in which the point lies. Notice that this could use binary 
	search for large collections."

	| num {IntegerVar} |
	num _ myStyle axis primaryOfPoint: aPoint.
	num <= IntegerVar0 ifTrue: [^IntegerVar0].
	IntegerVar0 almostTo: myNextBoundary do: [:idx {IntegerVar} |
		num <= (myBoundaries integerVarAt: (idx DOTasLong )) ifTrue: [^ idx - 1]].
	^ myNextBoundary - 1!

{ListStyle} style
	^ myStyle!

{Dsp} translationAt: index {IntegerVar}
	"Return the amount to translate by to get to the origin of the indexed 
	subView. "
	^PointTranslateDsp make: (myStyle axis
		orientPoint: (PointPos
			make: (self boundaryAtIndex: index)
			with: IntegerVar0))! !

!BoundingListComp methodsFor: 'composing'!

{void} compose: views {ScruTable of: Viewer} with: layout {AbstractLayout} 
	"Rest all the boundaries between the views based on the 
	enclosures of the views."
	"There is a problem with this code if the subviews demand 
	more area than provided!! heh-23jun90"

	| current {IntegerVar} axis {Orientation} secondary {IntegerVar} lastBoundary {IntegerVar} spacing {IntegerVar} |
	myLayout _ layout.
	myBoundaries at: UInt32Zero storeIntegerVar: IntegerVar0.
	self wipeFrom: 1.
	axis _ myStyle axis.
	secondary _ axis secondaryOfPoint: myLayout extent.
	lastBoundary _ axis primaryOfPoint: myLayout extent.
	current _ IntegerVar0.
	spacing _ myStyle spacing.
	"Compose the subView with the remaining area."
	views stepper
		forEach: 
			[:v {Viewer} | 
			v composeWith: (ExtentLayout make: (axis orientPoint: (PointPos make: lastBoundary - current with: secondary))).
			current _ current + spacing + (axis primaryOfPoint: v enclosure extent).
			self appendBoundary: current]!

{RegionLayout} layoutAt: index {IntegerVar} 
	| axis {Orientation} prime {IntegerVar} | 
	axis _ myStyle axis.
	prime _ (self layoutExtent: index) - myStyle spacing.
	^ (ExtentLayout make: (axis orientPoint: (PointPos make: prime with: (axis secondaryOfPoint: myLayout extent)))) cast: RegionLayout!

{void} recompose: views {ScruTable of: Viewer} with: start {IntegerVar} with: where {XnRegion} 
	| current {IntegerVar} axis {Orientation} secondary {IntegerVar} leftOverRoom {IntegerVar} spacing {IntegerVar} |
	where isEmpty ifTrue: [^VOID].
	axis _ myStyle axis.
	secondary _ axis secondaryOfPoint: myLayout extent.
	leftOverRoom _ axis primaryOfPoint: myLayout extent.
	"now subtract out the space already accounted for by 
	composed views"
	IntegerVar0 almostTo: myNextBoundary - 1 do: [:idx {IntegerVar} | ((where cast: IntegerRegion)
			hasIntMember: idx) not ifTrue: [leftOverRoom _ leftOverRoom - (self layoutExtent: idx)]].
	current _ self boundaryAtIndex: start.
	self wipeFrom: start + 1.
	spacing _ myStyle spacing.
	start almostTo: views count do: 
		[:viewIndex {IntegerVar} | 
		"Compose the subView with the available uncomposed 
		space, but only if 
		the subView needs to be composed."
		| v {Viewer} vExtent {IntegerVar} |
		v _ (views intGet: viewIndex)
					quickCast: Viewer.
		((where cast: IntegerRegion)
			hasIntMember: viewIndex)
			ifTrue: [v composeWith: (ExtentLayout make: (axis orientPoint: (PointPos make: leftOverRoom with: secondary))).
				leftOverRoom _ leftOverRoom - (spacing + (vExtent _ axis primaryOfPoint: v enclosure extent))]
			ifFalse: [vExtent _ axis primaryOfPoint: v enclosure extent].
		current _ current + spacing + vExtent.
		self appendBoundary: current]!

{PointRegion} uncomposedRegion
	| axis {Orientation} prime {IntegerVar} first {PointPos} ext {PointPos} |
	axis _ myStyle axis.
	prime _ self lastBoundary.
	first _  axis orientPoint: (PointPos make: prime with: IntegerVar0).
	ext _ myLayout extent.
	^ PointRegion make: first x with: first y with: ext x with: ext y! !

!BoundingListComp methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << ' boundaries: ['.
	IntegerVar0 almostTo: myNextBoundary do: 
		[:idx {IntegerVar} |
			aStream << (myBoundaries integerVarAt: idx DOTasLong) << ', '].
	aStream << ']\n composed in: ' << myLayout! !

!BoundingListComp methodsFor: 'smalltalk: smalltalk only'!

inspectPieces
	"Return pieces to be used in a tree browser."

	| result |
	result _ OrderedCollection with: myStyle.
	^result! !

!BoundingListComp methodsFor: 'private: accessing'!

{void} appendBoundary: newBound {IntegerVar}

	self checkSize.
	myBoundaries at: myNextBoundary DOTasLong storeIntegerVar: newBound.
	myNextBoundary _ myNextBoundary + 1!

{IntegerVar} boundaryAtIndex: i {IntegerVar} 
	^myBoundaries integerVarAt: i DOTasLong!

{void} checkSize
	myNextBoundary = myBoundaries count
		ifTrue: [myBoundaries _ myBoundaries copyGrow: myNextBoundary DOTasLong]!

{IntegerVar} lastBoundary

	^ myBoundaries integerVarAt: (myNextBoundary - 1) DOTasLong!

{IntegerVar} layoutExtent: index {IntegerVar} 
	index >= myNextBoundary ifTrue: [Heaper BLAST: #NotInDomain].
	^(myBoundaries integerVarAt: (index + 1) DOTasLong) 
	  - (myBoundaries integerVarAt: index DOTasLong)!

{void} wipeFrom: index {IntegerVar}

	"this method removes all boundaries starting at index"
	index almostTo: myBoundaries count do:
		[:i {IntegerVar} |
			myBoundaries at: i DOTasLong storeIntegerVar: -1].
	myNextBoundary _ index! !

!BoundingListComp methodsFor: 'private: creation'!

create: style {ListStyle} 
	super create.
	myStyle _ style.
	style addDependent: self.
	myLayout _ RegionLayout make.
	myBoundaries _ IntegerVarArray zeros: 4. "assumed initialized to zeros"
	myNextBoundary _ 1.!

{void} destruct
	(myStyle isKindOf: ListStyle)
		ifTrue: [myStyle removeDependent: self].
	myStyle _ NULL.
	myLayout _ NULL.
	myBoundaries _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BoundingListComp class
	instanceVariableNames: ''!

(BoundingListComp getOrMakeCxxClassDescription)
	friends:
'/* friends for class BoundingListComp */
friend SPTR(BoundingListComp) boundingListComp (ListStyle * style);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoundingListComp class methodsFor: 'pseudo constructors'!

make: style {ListStyle}
	^ self create: style! !