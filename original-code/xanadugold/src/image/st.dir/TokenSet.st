'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:43 pm'!

Heaper subclass: #TokenSet
	instanceVariableNames: '
		myTokenMap {IntegerTable of: Heaper}
		myAvailable {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(TokenSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!TokenSet methodsFor: 'accessing'!

{IntegerVar} newToken
	| tok {IntegerVar} |
	tok _ (myAvailable cast: IntegerRegion) start.
	myAvailable _ myAvailable minus: (IntegerRegion make: tok).
	^tok!

{void} reuseToken: tok {IntegerVar}
	myAvailable _ myAvailable unionWith: (IntegerRegion make: tok)!

{Stepper} stepper
	^myAvailable stepper! !

!TokenSet methodsFor: 'creation'!

create
	super create.
	myAvailable _ IntegerRegion after: 1! !

!TokenSet methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TokenSet class
	instanceVariableNames: ''!

(TokenSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!TokenSet class methodsFor: 'creation'!

make
	^self create! !