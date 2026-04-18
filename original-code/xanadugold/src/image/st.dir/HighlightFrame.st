'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:06 pm'!

HighlightAll subclass: #HighlightFrame
	instanceVariableNames: ''
	classVariableNames: 'SingleHighlightFrame {HighlightFrame} '
	poolDictionaries: ''
	category: 'FM-Selection'!
HighlightFrame comment:
'I highlight by bordering a region with a given color and width(s).'!

(HighlightFrame getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HighlightFrame methodsFor: 'testing'!

{BooleanVar}isIncremental
	"Bordering doesn't work incrementally"
	^false! !

!HighlightFrame methodsFor: 'displaying'!

{void} reverse: aRegion {PointRegion} on: warp {Warp} 
	((warp inkColor: self color)
		inkColorMap: FMColorMap selectColorMap)
		borderWidth: aRegion
		with: self inset! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HighlightFrame class
	instanceVariableNames: ''!

(HighlightFrame getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HighlightFrame class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeNonInherited
	SingleHighlightFrame _ self create!

linkTimeNonInherited
	SingleHighlightFrame _ NULL! !

!HighlightFrame class methodsFor: 'pcreate'!

{HighlightFrame} make
	^SingleHighlightFrame! !