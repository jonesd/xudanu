'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:19 pm'!

Number subclass: #MetaNumeric
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers-MetaNumeric'!
MetaNumeric comment:
'MetaNumeric is the abstract superclass for unrepresentable numbers.  These include Infinity (very large numbers), Infinitesimal (very tiny numbers), and NotANumber (undefinable values).  In addition, the class SomeNumber represents finitely expressable numbers in the domain of MetaNumerics, so that coercion is possible if necessary'!


!MetaNumeric methodsFor: 'coercing'!

coerce: aNumber

	^aNumber asMetaNumber!

generality

	^120! !

!MetaNumeric methodsFor: 'double dispatching'!

differenceFromDouble: aDouble

	^self differenceFromSomeNumber: aDouble asMetaNumber!

differenceFromFloat: aFloat

	^self differenceFromSomeNumber: aFloat asMetaNumber!

differenceFromFraction: aFraction

	^self differenceFromSomeNumber: aFraction asMetaNumber!

differenceFromInteger: aInteger

	^self differenceFromSomeNumber: aInteger asMetaNumber!

lessFromDouble: aDouble

	^self lessFromSomeNumber: aDouble asMetaNumber!

lessFromFloat: aFloat

	^self lessFromSomeNumber: aFloat asMetaNumber!

lessFromFraction: aFraction

	^self lessFromSomeNumber: aFraction asMetaNumber!

lessFromInteger: aInteger

	^self lessFromSomeNumber: aInteger asMetaNumber!

productFromDouble: aDouble

	^self productFromSomeNumber: aDouble asMetaNumber!

productFromFloat: aFloat

	^self productFromSomeNumber: aFloat asMetaNumber!

productFromFraction: aFraction

	^self productFromSomeNumber: aFraction asMetaNumber!

productFromInteger: aInteger

	^self productFromSomeNumber: aInteger asMetaNumber!

quotientFromDouble: aDouble

	^self quotientFromSomeNumber: aDouble asMetaNumber!

quotientFromFloat: aFloat

	^self quotientFromSomeNumber: aFloat asMetaNumber!

quotientFromFraction: aFraction

	^self quotientFromSomeNumber: aFraction asMetaNumber!

quotientFromInteger: aInteger

	^self quotientFromSomeNumber: aInteger asMetaNumber!

sumFromDouble: aDouble

	^self sumFromSomeNumber: aDouble asMetaNumber!

sumFromFloat: aFloat

	^self sumFromSomeNumber: aFloat asMetaNumber!

sumFromFraction: aFraction

	^self sumFromSomeNumber: aFraction asMetaNumber!

sumFromInteger: aInteger

	^self sumFromSomeNumber: aInteger asMetaNumber! !

!MetaNumeric methodsFor: 'converting'!

asMetaNumber
	"Represent the number as a MetaNumeric"

	^self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MetaNumeric class
	instanceVariableNames: ''!


!MetaNumeric class methodsFor: 'constants access'!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^SomeNumber from: 1!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^SomeNumber from: 0! !