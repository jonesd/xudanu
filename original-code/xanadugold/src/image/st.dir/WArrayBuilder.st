'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:02 pm'!

FMBuilder subclass: #WArrayBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
WArrayBuilder comment:
'Builds a read-only text view onto an XuWordArray'!

(WArrayBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WArrayBuilder methodsFor: 'building'!

{FMBuilding} build: model {Heaper as: MuWordArray}
	[Converter] USES. 
	^Scaffold fluidGet build: ((model quickCast: MuWordArray) convert: AttributedTextModel)! !

!WArrayBuilder methodsFor: 'creation'!

create
	super create! !

!WArrayBuilder methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WArrayBuilder class
	instanceVariableNames: ''!

(WArrayBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WArrayBuilder class methodsFor: 'make'!

make
	^self create! !