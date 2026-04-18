'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:20 pm'!

Heaper subclass: #CalcCreator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!

(CalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #DEFERRED; add: #EQ; yourself)!

!CalcCreator methodsFor: 'proxy accessing'!

{Calc PROXY} newCalc
	"return a new calculator"

	self subclassResponsibility! !

!CalcCreator methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CalcCreator class
	instanceVariableNames: ''!

(CalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #DEFERRED; add: #EQ; yourself)!

!CalcCreator class methodsFor: 'smalltalk: init'!

cleanupGarbage
	CalcCuisine _ NULL!

initTimeNonInherited
	Cookbook declareCookbook: 'calc' with: CalcCreator with: CalcCuisine with: XppCuisine!

linkTimeNonInherited
	Recipe star defineGlobal: #CalcCuisine with: NULL.! !