'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:49 pm'!

Heaper subclass: #FeCalcCreator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!
FeCalcCreator comment:
' '!

(FeCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeCalcCreator methodsFor: 'accessing'!

{FeCalc CLIENT} newCalc
	"return a new calculator"

	^FeCalc create: 20! !

!FeCalcCreator methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeCalcCreator class
	instanceVariableNames: ''!

(FeCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeCalcCreator class methodsFor: 'smalltalk: init'!

cleanupGarbage
	FeCalcCuisine _ NULL!

initTimeNonInherited
	Cookbook declareCookbook: 'fecalc' with: FeCalcCreator with: FeCalcCuisine with: XppCuisine!

linkTimeNonInherited
	Recipe star defineGlobal: #FeCalcCuisine with: NULL.! !

!FeCalcCreator class methodsFor: 'pseudo-constructor'!

{FeCalcCreator} make
	^self create! !