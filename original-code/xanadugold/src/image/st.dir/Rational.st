'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:06 pm'!

Heaper subclass: #Rational
	instanceVariableNames: '
		myNumerator {Int32}
		myDenominator {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Calc'!

(Rational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!Rational methodsFor: 'creation'!

create: numerator {Int32} with: denominator {Int32}
	super create.
	myNumerator _ numerator.
	myDenominator _ denominator.! !

!Rational methodsFor: 'accessing'!

{Int32} denominator
	^myDenominator!

{Int32} numerator
	^myNumerator! !

!Rational methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumerator << '/' << myDenominator << ')'! !

!Rational methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNumerator _ receiver receiveInt32.
	myDenominator _ receiver receiveInt32.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myNumerator.
	xmtr sendInt32: myDenominator.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Rational class
	instanceVariableNames: ''!

(Rational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!Rational class methodsFor: 'creation'!

make: numerator {Int32} with: denominator {Int32}

	^Rational create: numerator with: denominator! !