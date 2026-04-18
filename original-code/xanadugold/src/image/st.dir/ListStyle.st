'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:04 pm'!

XnModel subclass: #ListStyle
	instanceVariableNames: '
		axisInternal {Orientation}
		alignmentInternal {AlignmentEnum}
		spacingInternal {IntegerVar}
		spaceColorInternal {FMColor}
		spreadingInternal {BooleanVar}
		gridInternal {IntegerVar}'
	classVariableNames: '
		DefaultHorizontalStyle {ListStyle} 
		DefaultVerticalStyle {ListStyle} '
	poolDictionaries: ''
	category: 'FM-Multi'!
ListStyle comment:
'I represent a layout style for a list.  I define the axis along which the list is displayed (horizontal or vertical), the alignment of items along the other axis, the spacing between items, the color for filling the spaces, and whether the items are packed along the axis or spread out to fill the composition region.

Instance Variables:
	axis	<Point>  "unit x or unit y"
	alignment	<Symbol>  "left, center, right"
	spacing	<Integer>
	spaceColor	<Form>  "halftone"
	spreading	<Boolean>

Class Variables:
	DefaultHorizontalStyle	<ListStyle>
	DefaultVerticalStyle	<ListStyle>
'!

(ListStyle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListStyle methodsFor: 'accessing'!

{void}alignCentered
	self setAlignment: #center!

{void}alignLeft
	self setAlignment: #left!

{AlignmentEnum}alignment
	^alignmentInternal!

{void}alignRight
	self setAlignment: #right!

{Orientation}axis
	^axisInternal!

{IntegerVar}grid
	^gridInternal!

{void}horizontal
	self setAxis: Orientation xAxis!

{void}noSpread
	self setSpreading: false!

{void} setAlignment: place {AlignmentEnum} 
	alignmentInternal _ place.
	"This should be something like; self changed: (UpdateRecord make). 
	Later we'll add special Update record types."
	self changed: NewContentsUpdate make!

{void}setAxis: orientation{Orientation}
	axisInternal _ orientation.
	self changed: NewContentsUpdate make!

{void}setSpaceColor: aHalftone{FMColor}
	spaceColorInternal _ aHalftone.
	self changed: NewContentsUpdate make!

{void} setSpacing: anInteger{IntegerVar}
	spacingInternal _ anInteger.
	self changed: NewContentsUpdate make!

{void}setSpreading: aBoolean{BooleanVar}
	spreadingInternal _ aBoolean.
	self changed: NewContentsUpdate make!

{FMColor}spaceColor
	^spaceColorInternal!

{IntegerVar}spacing
	^spacingInternal!

{void}spread
	self setSpreading: true!

{BooleanVar}spreading
	^spreadingInternal!

{void}vertical
	self setAxis: Orientation yAxis! !

!ListStyle methodsFor: 'create'!

create: ax{Orientation}
	super create.
	axisInternal _ ax.
	alignmentInternal _ #left.
	spreadingInternal _ false.
	spacingInternal _ IntegerVar0.
	spaceColorInternal _ FMColor fmWhiteColor.
	gridInternal _ 12!

create: ax{Orientation} with: gr{IntegerVar}
	super create.
	axisInternal _ ax.
	alignmentInternal _ #left.
	spreadingInternal _ false.
	spacingInternal _ IntegerVar0.
	spaceColorInternal _ FMColor fmWhiteColor.
	gridInternal _ gr! !

!ListStyle methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('.
	oo << axisInternal << ', ' << spacingInternal << ', ' << spreadingInternal << ', ' << gridInternal.
	oo << ')'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListStyle class
	instanceVariableNames: ''!

(ListStyle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListStyle class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self allInstances do: [:ls | ls clean]!

{void} initTimeNonInherited
	"ListStyle initTimeNonInherited"
	self REQUIRES: Orientation.
	DefaultVerticalStyle _ self create: Orientation yAxis with: 12.
	DefaultHorizontalStyle _ self create: Orientation xAxis with: 12.
	DefaultHorizontalStyle setSpacing: 8!

{void} linkTimeNonInherited
	"ListStyle linkTimeNonInherited"
	DefaultVerticalStyle _ NULL.
	DefaultHorizontalStyle _ NULL! !

!ListStyle class methodsFor: 'constants'!

{ListStyle}defaultHorizontal
	^DefaultHorizontalStyle!

{ListStyle}defaultVertical
	^DefaultVerticalStyle! !

!ListStyle class methodsFor: 'pseudoconstructors'!

make: axis {Orientation} with: grid {IntegerVar}

	^ self create: axis with: grid! !