'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:04 pm'!

AbstractListComp subclass: #PortionListComp
	instanceVariableNames: '
		myStyle {ListStyle}
		myLayout {AbstractLayout}
		myPortions {ListModel of: Portion}
		myBoundaries {IntegerVarArray}
		myLastBound {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!
PortionListComp comment:
'The PortionListComp is a composer that allocates its space to subviews based on the portions specified for each subview.  The portions specify a minimum and maximum size for each subview, and a proportional rate at which each subview is to grow.  For example, if there are portions for subviews a, b, and c with rates of 1, 2, 1, then b will grow at twice the rate of a or c.  Have Fun!!!!'!

(PortionListComp getOrMakeCxxClassDescription)
	friends:
'/* friends for class PortionListComp */
friend SPTR(PortionListComp) portionListComp (ListStyle * style, ListModel OF1(Portion) * portions);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PortionListComp methodsFor: 'accessing'!

{XnRegion} compositionRegion
	"the region that everything is composed into"
	| spacing {IntegerVar} |
	(spacing _ myStyle spacing) == IntegerVar0 ifTrue:
		[^myStyle axis project: (IntegerRegion
			make: (self boundaryAtIndex: IntegerVar0)
			with: (self boundaryAtIndex: myLastBound))]
	ifFalse:
		[ | result {XnRegion} bound {IntegerVar} next {IntegerVar} |
		result _ IntegerRegion make.
		bound _ self boundaryAtIndex: IntegerVar0.
		1 to: myLastBound do: [ :i {IntegerVar} |
			next _ self boundaryAtIndex: i.
			result _ result unionWith: (IntegerRegion make: bound with: next - spacing).
			bound _ next].
		^myStyle axis project: (result cast: IntegerRegion)]!

{PointRegion} computeEnclosureFor: views {ScruTable of: Viewer} 
	| s {IntegerVar} p {IntegerVar} axis {Orientation} |
	views isEmpty ifTrue: [^PointRegion make].
	axis _ myStyle axis.
	p _ s _ IntegerVar0.
	views stepper forEach: [:v {Viewer} | | extent {PointPos} |
			extent _ v enclosure extent.
			s _ s max: (axis secondaryOfPoint: extent).
			p _ p + (axis primaryOfPoint: extent)].
	^PointRegion regionExtent: 
		(axis orientPoint: 
			(PointPos make: p + (views count - 1 * myStyle spacing) with: s))!

{XnRegion} regionAt: index {IntegerVar}
	(index >= IntegerVar0 and: [index <= myLastBound])
		ifFalse: [^PointRegion make].
	^myStyle axis project: (IntegerRegion
		make: (self boundaryAtIndex: index)
		with: (self boundaryAtIndex: index + 1) - myStyle spacing)!

{IntegerVar} regionIndexFor: aPoint {PointPos} 
	"find the virtual area in which the point lies. Notice 
	that this could use binary 
	search for large collections."

	| primaryDistance {IntegerVar} |
	primaryDistance _ myStyle axis primaryOfPoint: aPoint.
	primaryDistance < IntegerVar0 ifTrue: [Heaper BLAST: #INVALID.U.POINT].
	IntegerVar0 to: myLastBound do:
		[:index {IntegerVar} |
			primaryDistance <= (myBoundaries integerVarAt: index DOTasLong) ifTrue: [^index - 1]].
	Heaper BLAST: #INVALID.U.POINT.
	^NULL!

{ListStyle} style
	^ myStyle!

{Dsp} translationAt: index {IntegerVar}
	"Return the amount to translate by to get to the origin of the indexed 
	subView. "

	^PointTranslateDsp make: (myStyle axis
		orientPoint: (PointPos
			make: (self boundaryAtIndex: index)
			with: IntegerVar0))! !

!PortionListComp methodsFor: 'composing'!

{void} compose: views {ScruTable of: Viewer} with: layout {AbstractLayout} 
	"Reset all the boundaries between the views based on the 
	enclosures 
	of the views."

	| current {IntegerVar} axis {Orientation} secondary {IntegerVar} extents {IntegerVarArray} spacing {IntegerVar} |
	myLayout _ layout.
	axis _ myStyle axis.
	secondary _ axis secondaryOfPoint: myLayout extent.
	extents _ self computeExtents: IntegerVar0 to: (axis primaryOfPoint: myLayout extent).
	spacing _ myStyle spacing.
	current _ IntegerVar0.
	IntegerVar0 almostTo: extents count do: 
		[:index {IntegerVar} | 
		((views intGet: index)
			cast: Viewer)
			composeWith: (ExtentLayout make: (axis orientPoint: (PointPos make: (extents integerVarAt: index DOTasLong)
								- spacing with: secondary))).
		current _ current + (extents integerVarAt: index DOTasLong).
		myBoundaries at: index DOTasLong + 1 storeIntegerVar: current]!

{RegionLayout} layoutAt: index {IntegerVar} 
	| axis {Orientation} prime {IntegerVar} |
	axis _ myStyle axis.
	self thingToDo.
	"Fix this for zero base."
	prime _ (self boundaryAtIndex: index + 1)
				- (self boundaryAtIndex: index) - myStyle spacing.
	^RegionLayout make: 
		(axis orientPoint: (PointPos make: prime with: (axis secondaryOfPoint: myLayout extent)))!

{void} recompose: views {ScruTable of: Viewer} with: start {IntegerVar unused} with: where {XnRegion unused} 
	"Composition only changes if the composition for all 
	 subViews changes.  If this instead returned the delta
	 for individual subViews, this would return an interesting
	 value."

	self compose: views with: myLayout! !

!PortionListComp methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << ' boundaries: ' 
		<< myBoundaries << '\n composed in: ' << myLayout! !

!PortionListComp methodsFor: 'private: accessing'!

{IntegerVar} boundaryAtIndex: i {IntegerVar}
	^ myBoundaries integerVarAt: i DOTasLong! !

!PortionListComp methodsFor: 'smalltalk: debugging'!

inspectPieces
	"Return pieces to be used in a tree browser."

	| result |
	result _ OrderedCollection with: myStyle.
	result addAll: myPortions asTable asOrderedCollection.
	^result! !

!PortionListComp methodsFor: 'protected: creation'!

create: style {ListStyle} with: portions {ListModel of: Portion} 

	super create.
	myStyle _ style.
	myStyle addDependent: self.
	myLayout _ RegionLayout make.
	myLastBound _ portions count + 1.
	myBoundaries _ IntegerVarArray zeros: myLastBound DOTasLong.
	myPortions _ portions.
	myPortions addDependent: self!

{void} destruct
	myStyle removeDependent: self.
	myStyle _ NULL.
	myLayout _ NULL.
	myBoundaries destroy.
	myBoundaries _ NULL.
	myPortions removeDependent: self.
	myPortions _ NULL.
	super destruct! !

!PortionListComp methodsFor: 'private:'!

{IntegerVarArray} computeExtents: start {IntegerVar} to: stop {IntegerVar} 
	"This algorithm works by first getting information from 
	the portions. It collects the sum of the minimum sizes 
	and also the sum of the max sizes (that are not infinity) 
	and if any of the maxes is infinity. It also sums the 
	rates provided. 
	Next, the algorithm allocates the minimum for each 
	portion plus a portion of any leftover space (extent limit 
	minus the minimums) according to the rates provided. It 
	makes sure that the maximum for a portion is not exceeded, 
	if it is, the portion will be clipped back to the maximum 
	and the difference summed for the next phase. 
	The last phase is to allocate the clipped parts to 
	portions that have not reached their maximum. This is 
	done iteratively in case a portion reaches its max during 
	this phase."

	| extent {IntegerVar} dMax {IntegerVar} dMin {IntegerVar} dFraction {IEEEDoubleVar} noInfinities {BooleanVar} storeDom {IntegerVarArray} extra {IntegerVar} clipped {IEEEDoubleVar} nextBound {IEEEDoubleVar} evenCut {IEEEDoubleVar} maxOut {IntegerVar} |
	extent _ stop - start.
	dMin _ dMax _ IntegerVar0.
	dFraction _ 0.0 asFloat.
	noInfinities _ true.
	maxOut _ IntegerVar0.
	myPortions asTable stepper
		forEach: 
			[:serving {Portion} | 
			dMin _ dMin + serving minEnclosure.
			serving hasMaximum
				ifTrue: [dMax _ dMax + serving maxEnclosure]
				ifFalse: [noInfinities _ false].
			dFraction _ dFraction + serving fractionalRate].
	storeDom _ IntegerVarArray zeros: myPortions count DOTasLong.
	dMin < extent
		ifTrue: [extra _ extent - dMin]
		ifFalse: [extra _ IntegerVar0].
	clipped _ 0.0 asFloat.
	nextBound _ 0.0 asFloat.
	evenCut _ extra DOTasLong asFloat / dFraction.
	IntegerVar0 almostTo: myPortions count do: 
		[:index {IntegerVar} | 
		| tPort {Portion} disUn {IEEEDoubleVar} |
		tPort _ (myPortions fetch: index)
					cast: Portion.
		disUn _ tPort minEnclosure DOTasLong asFloat + (evenCut * tPort fractionalRate).
		tPort hasMaximum ifTrue: [disUn > tPort maxEnclosure DOTasLong
				ifTrue: 
					[clipped _ clipped + (disUn - tPort maxEnclosure DOTasLong asFloat).
					disUn _ tPort maxEnclosure DOTasLong asFloat.
					maxOut _ maxOut + 1]].
		storeDom at: index DOTasLong storeIntegerVar: (nextBound + disUn) rounded - nextBound rounded.
		nextBound _ nextBound + disUn].
	(noInfinities and: [clipped = 0.0 asFloat])
		ifTrue: [^storeDom].
	[clipped > 1.0 asFloat]
		whileTrue: 
			[evenCut _ clipped / maxOut DOTasLong asFloat.
			nextBound _ clipped _ 0.0 asFloat.
			maxOut _ IntegerVar0.
			IntegerVar0 almostTo: myPortions count do: 
				[:index2 {IntegerVar} | 
				| tPort {Portion} disUn {Float} lastUn {IntegerVar} |
				tPort _ (myPortions fetch: index2)
							cast: Portion.
				lastUn _ myBoundaries integerVarAt: index2 DOTasLong.
				disUn _ lastUn DOTasLong asFloat + (evenCut * tPort fractionalRate).
				tPort hasMaximum ifTrue: [lastUn >= tPort maxEnclosure
						ifTrue: [maxOut _ maxOut + 1.
							disUn _ lastUn DOTasLong asFloat]
						ifFalse: [disUn >= tPort maxEnclosure DOTasLong
								ifTrue: 
									[clipped _ clipped + (disUn - tPort maxEnclosure DOTasLong asFloat).
									disUn _ tPort maxEnclosure DOTasLong asFloat.
									maxOut _ maxOut + 1]]].
				storeDom at: index2 DOTasLong storeIntegerVar: (nextBound + disUn) rounded - nextBound rounded.
				nextBound _ nextBound + disUn]].
	^storeDom! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PortionListComp class
	instanceVariableNames: ''!

(PortionListComp getOrMakeCxxClassDescription)
	friends:
'/* friends for class PortionListComp */
friend SPTR(PortionListComp) portionListComp (ListStyle * style, ListModel OF1(Portion) * portions);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PortionListComp class methodsFor: 'pseudo constructors'!

make: style {ListStyle} with: portions {ListModel of: Portion} 
	^self create: style with: portions! !