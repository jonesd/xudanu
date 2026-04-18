'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:19 pm'!

CalcCreator subclass: #ActualCalcCreator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!

(ActualCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ActualCalcCreator methodsFor: 'accessing'!

{Calc PROXY} newCalc
	"return a new calculator"

	^ActualCalc create: 20! !

!ActualCalcCreator methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualCalcCreator class
	instanceVariableNames: ''!

(ActualCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ActualCalcCreator class methodsFor: 'pseudo-constructor'!

{CalcCreator} make
	^self create! !