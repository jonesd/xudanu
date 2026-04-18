'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:08 pm'!

Highlight subclass: #NoHighlight
	instanceVariableNames: ''
	classVariableNames: 'SingleNoHighlight {NoHighlight} '
	poolDictionaries: ''
	category: 'FM-Selection'!

(NoHighlight getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NoHighlight methodsFor: 'testing'!

{Boolean} isEqual: object {Heaper}
	"This will not translate to c++!!!!"

	^object isKindOf: self getCategory!

{BooleanVar}isIncremental
	"Return true if I can convert highlighting of
	a region R into highlighting of a region S by
	highlighting (S xor R)."
	^true! !

!NoHighlight methodsFor: 'displaying'!

{void}reverse: aRegion {PointRegion} on: aMedium{Warp}
	"Highlight a given region."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NoHighlight class
	instanceVariableNames: ''!

(NoHighlight getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NoHighlight class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeNonInherited
	SingleNoHighlight _ self create!

linkTimeNonInherited
	SingleNoHighlight _NULL! !

!NoHighlight class methodsFor: 'pcreate'!

{NoHighlight} make
	^SingleNoHighlight! !