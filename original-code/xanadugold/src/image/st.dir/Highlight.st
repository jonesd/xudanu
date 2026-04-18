'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:06 pm'!

Heaper subclass: #Highlight
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!

(Highlight getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Highlight methodsFor: 'testing'!

{Boolean} isEqual: object {Heaper}
	^object isKindOf: self getCategory!

{BooleanVar}isIncremental
	"Return true if I can convert highlighting of
	a region R into highlighting of a region S by
	highlighting (S xor R)."
	
	self subclassResponsibility! !

!Highlight methodsFor: 'displaying'!

{void}reverse: aRegion {PointRegion} on: aMedium{Warp}
	"Highlight a given region.
	Subclasses will want to do something."
	
	self subclassResponsibility! !

!Highlight methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	"roger - this works for all the subclasses of highlight too."
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Highlight class
	instanceVariableNames: ''!

(Highlight getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Highlight class methodsFor: 'smalltalk: smalltalk create'!

{HighlightAll}highlightAll
	^HighlightAll make!

{HighlightFrame}highlightFrame
	^HighlightFrame make!

{NoHighlight}noHighlight
	^NoHighlight make! !