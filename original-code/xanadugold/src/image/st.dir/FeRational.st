'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:51 pm'!

Heaper subclass: #FeRational
	instanceVariableNames: '
		myNumerator {IntegerVar}
		myDenominator {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(FeRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeRational methodsFor: 'creation'!

create: numerator {IntegerVar} with: denominator {IntegerVar}
	super create.
	myNumerator _ numerator.
	myDenominator _ denominator.! !

!FeRational methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumerator << '/' << myDenominator << ')'! !

!FeRational methodsFor: 'accessing'!

{Heaper CLIENT} asHeaper
	^self!

{IntegerVar CLIENT} denominator
	^myDenominator!

{IntegerVar CLIENT} numerator
	^myNumerator! !

!FeRational methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeRational class
	instanceVariableNames: ''!

(FeRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeRational class methodsFor: 'creation'!

make: numerator {IntegerVar} with: denominator {IntegerVar}

	^FeRational create: numerator with: denominator! !