'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:06 pm'!

Highlight subclass: #HighlightAll
	instanceVariableNames: '
		myColor {FMColor}
		myInset {IntegerVar}'
	classVariableNames: 'SingleHighlightAll {HighlightAll} '
	poolDictionaries: ''
	category: 'FM-Selection'!
HighlightAll comment:
'I highlight by reversing the entire (possibly inset) region with a given color.

Instance Variables:
	color	<Form>  "halftone mask"
	width	<Integer | Rectangle>  "inset"
'!

(HighlightAll getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HighlightAll methodsFor: 'testing'!

{BooleanVar}isIncremental
	"Incremental display only works if
	there is no inset."

	^myInset == IntegerVar0! !

!HighlightAll methodsFor: 'accessing'!

{FMColor}color
	^myColor!

{IntegerVar} inset
	^myInset! !

!HighlightAll methodsFor: 'displaying'!

{void} reverse: aRegion {PointRegion} on: warp {Warp} 
	myInset == IntegerVar0
		ifTrue: [((warp inkColor: myColor)
				inkColorMap: FMColorMap selectColorMap)
				fill: aRegion]
		ifFalse: [((warp inkColor: myColor)
				inkColorMap: FMColorMap selectColorMap)
				fill: (aRegion insetByInt: myInset)]! !

!HighlightAll methodsFor: 'create'!

create
	super create.
	myColor _ FMColor fmWhiteColor.
	myInset _ IntegerVar0!

create: color {FMColor}
	super create.
	myColor _ color.
	myInset _ IntegerVar0!

create: color {FMColor} with: inset {IntegerVar}
	super create.
	myColor _ color.
	myInset _ inset! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HighlightAll class
	instanceVariableNames: ''!

(HighlightAll getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HighlightAll class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeNonInherited
	SingleHighlightAll _ self create!

linkTimeNonInherited
	SingleHighlightAll _ NULL! !

!HighlightAll class methodsFor: 'pcreate'!

{HighlightAll} make
	^SingleHighlightAll! !