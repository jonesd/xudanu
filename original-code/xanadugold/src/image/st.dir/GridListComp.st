'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:03 pm'!

AbstractListComp subclass: #GridListComp
	instanceVariableNames: '
		myStyle {ListStyle}
		myLayout {AbstractLayout}
		myComposedCount {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!

(GridListComp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!GridListComp methodsFor: 'create/delete'!

create: style {ListStyle} 
	super create.
	myStyle _ style.
	self addDependent: style.
	myLayout _ RegionLayout make.
	myComposedCount _ IntegerVar0! !

!GridListComp methodsFor: 'accessing'!

{XnRegion} compositionRegion
	"the region that everything is composed into"
	self unimplemented.
	^NULL!

{PointRegion} computeEnclosureFor: views {ScruTable of: Viewer} 
	| axis {Orientation} maxI {IntegerVar} |
	views isEmpty ifTrue: [^PointRegion make].
	myComposedCount _ views count.
	axis _ myStyle axis.
	maxI _ IntegerVar0.
	views stepper forEach:
		[:v {Viewer} | 
			maxI _ maxI max: (axis secondaryOfPoint: v enclosure extent)].
	^PointRegion regionExtent: (axis orientPoint: (PointPos make: myStyle grid * myComposedCount with: maxI))!

{XnRegion} regionAt: index {IntegerVar unused}
	self unimplemented.
	^NULL!

{IntegerVar} regionIndexFor: aPoint {PointPos} 
	"find the virtual area in which the point lies. Notice
that this could 
	use binary search for large collections."

	| num {IntegerVar} index {IntegerVar} |
	num _ myStyle axis primaryOfPoint: aPoint.
	num < IntegerVar0 ifTrue: [^-1].
	index _ num // myStyle grid.
	index >= IntegerVar0
		ifTrue: [index < myComposedCount
				ifTrue: [^index + 1]
				ifFalse: [^myComposedCount]]
		ifFalse: [^-1]!

{ListStyle} style
	^ myStyle!

{Dsp} translationAt: index {IntegerVar} 
	"Return the amount to translate by to get to the origin 
	of the indexed 
	subView."
	[Converter] USES.
	^(myStyle axis orientPoint: (PointPos make: index - 1 * myStyle grid with: IntegerVar0))
		convert: Dsp! !

!GridListComp methodsFor: 'composing'!

{void} compose: views {ScruTable of: Viewer} with: layout {AbstractLayout} 
	| subS {Stepper of: Viewer} |
	myLayout _ layout.
	myComposedCount _ views count.
	subS _ views stepper.
	"Compose the subView in a gridded area. 
	Note that all regions are the same."
	subS forEach: [:viewer {Viewer} | viewer composeWith: (self layoutAt: IntegerVar0)]!

{RegionLayout} layoutAt: index {IntegerVar unused} 
	| axis {Orientation} |
	axis _ myStyle axis.
	^RegionLayout make: (axis orientPoint: (PointPos make: myStyle grid with: (axis secondaryOfPoint: myLayout extent)))!

{void} recompose: views {ScruTable of: Viewer} with: start {IntegerVar unused} with: where {XnRegion unused} 
	"Composition only changes if the composition for all 
	subViews changes. If this instead returned the delta 
	for individual subViews, this would return an interesting 
	value."

	self compose: views with: myLayout! !

!GridListComp methodsFor: 'protected: creation'!

{void} destruct
	self removeDependent: myStyle.
	myStyle _ NULL.
	myLayout _ NULL.
	super destruct! !

!GridListComp methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << 'grid: ' << myStyle grid << '\n composed in: ' << myLayout! !