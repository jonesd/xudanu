'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:22 pm'!

Heaper subclass: #FMColorMap
	instanceVariableNames: ''
	classVariableNames: 'SelectMap {FMColorMap} '
	poolDictionaries: ''
	category: 'FM-Warp Display'!

(FMColorMap getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMColorMap methodsFor: 'testing'!

{BooleanVar} isColor
	^false! !

!FMColorMap methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMColorMap class
	instanceVariableNames: ''!

(FMColorMap getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMColorMap class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeNonInherited
	SelectMap _ self create!

linkTimeNonInherited
	SelectMap _ NULL! !

!FMColorMap class methodsFor: 'constants'!

{FMColorMap}selectColorMap
	"Return the colorMap used for representing selection."
	
	^SelectMap! !