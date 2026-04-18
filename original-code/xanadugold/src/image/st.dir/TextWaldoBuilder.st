'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:28 pm'!

FMBuilder subclass: #TextWaldoBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!

(TextWaldoBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextWaldoBuilder methodsFor: 'creation'!

create
	super create! !

!TextWaldoBuilder methodsFor: 'build'!

{FMBuilding} build: model {Heaper as: XuText} 
 
	^ Scaffold fluidGet build: (model convert: AttributedTextModel)! !

!TextWaldoBuilder methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextWaldoBuilder class
	instanceVariableNames: ''!

(TextWaldoBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextWaldoBuilder class methodsFor: 'pseudo constructors'!

make
	^self create! !