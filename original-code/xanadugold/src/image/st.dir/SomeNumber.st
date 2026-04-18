'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:20 pm'!

MetaNumeric subclass: #SomeNumber
	instanceVariableNames: 'value '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers-MetaNumeric'!
SomeNumber comment:
'SomeNumber represents a nonMetaNumeric scalar Number coerced into the MetaNumeric domain.  SomeNumbers responds to numeric protocol the same way that their value would, except that their generality is that of other MetaNumerics, and they know how to perform computations relative to MetaNumeric values

Instance variables:
	value		<Number> the number that this instance represents
'!


!SomeNumber methodsFor: 'accessing'!

numericValue
	"Represent the receiver as a non-meta scalar quantity"

	^value! !

!SomeNumber methodsFor: 'arithmetic'!

* aNumber 
	"Answer the result of multiplying the receiver by the argument, aNumber."

	^aNumber productFromSomeNumber: self!

+ aNumber 
	"Answer the sum of the receiver and the argument, aNumber."

	^aNumber sumFromSomeNumber: self!

- aNumber 
	"Answer the difference between the receiver and aNumber."

	^aNumber differenceFromSomeNumber: self!

/ aNumber 
	"Answer the result of dividing receiver by aNumber."

	^aNumber quotientFromSomeNumber: self! !

!SomeNumber methodsFor: 'testing'!

isZero
	"Answer whether 'self = self class zero'.  We can't use #= because
	#= is defined in terms of #isZero"

	^value isZero! !

!SomeNumber methodsFor: 'comparing'!

< aNumber

	^aNumber lessFromSomeNumber: self! !

!SomeNumber methodsFor: 'truncation and round off'!

truncated
	"Answer an integer nearest the receiver toward zero."

	^value truncated! !

!SomeNumber methodsFor: 'double dispatching'!

differenceFromInfinitesimal: aNumber

	value = 0
		ifTrue:	[^aNumber]
		ifFalse:	[^value negated]!

differenceFromInfinity: aNumber

	value = 0
		ifTrue:	[^aNumber]
		ifFalse:	[^aNumber copy]!

differenceFromSomeNumber: aNumber

	^aNumber numericValue - value!

lessFromInfinitesimal: aNumber

	value = 0
		ifTrue:	[^aNumber negative].
	^self positive!

lessFromInfinity: aNumber

	^aNumber negative!

lessFromSomeNumber: aNumber

	^aNumber numericValue < value!

productFromInfinitesimal: aNumber

	value = 0
		ifTrue:	[^0].
	value = 1
		ifTrue:	[^aNumber].
	^value negative
		ifTrue:	[aNumber negated]
		ifFalse:	[aNumber copy]!

productFromInfinity: aNumber

	value = 0
		ifTrue:	[^0].
	value = 1
		ifTrue:	[^aNumber].
	^value negative
		ifTrue:	[aNumber negated]
		ifFalse:	[aNumber copy]!

productFromSomeNumber: aNumber

	^aNumber numericValue * value!

quotientFromInfinitesimal: aNumber 

	value = 0 ifTrue: [^self class
			raise: #divisionByZeroSignal
			receiver: aNumber
			selector: #/
			arg: self
			errorString: 'Can''t divide a number by zero'].
	value = 1
		ifTrue:	[^aNumber].
	^value negative
		ifTrue: [aNumber negated]
		ifFalse: [aNumber copy]!

quotientFromInfinity: aNumber

	value = 0 ifTrue: [^self class
			raise: #divisionByZeroSignal
			receiver: aNumber
			selector: #/
			arg: self
			errorString: 'Can''t divide a number by zero'].
	value = 1
		ifTrue:	[^aNumber].
	^value negative
		ifTrue:	[aNumber negated]
		ifFalse:	[aNumber copy]!

quotientFromSomeNumber: aNumber

	^aNumber numericValue / value!

sumFromInfinitesimal: aNumber

	value = 0
		ifTrue:	[^aNumber]
		ifFalse:	[^value]!

sumFromInfinity: aNumber

	value = 0
		ifTrue:	[^aNumber]
		ifFalse:	[^aNumber copy]!

sumFromSomeNumber: aNumber

	^aNumber numericValue + value! !

!SomeNumber methodsFor: 'converting'!

asDouble
	"Answer a Double that represents the receiver."

	^value asDouble!

asFloat
	"Answer a Float that represents the receiver."

	^value asFloat!

asRational
	"Answer a Rational number that represents the receiver."

	^value asRational!

reduceGeneralityIfPossible
	"Answer the receiver transformed to a lower generality, if such a 
	transformation is possible without losing information. If not, answer 
	the receiver"

	^value! !

!SomeNumber methodsFor: 'printing'!

printOn: aStream 
	"Print the receiver on the stream, aStream.
	Numbers print in a form recognized by the compiler."

	value printOn: aStream! !

!SomeNumber methodsFor: 'private: private'!

setValue: aValue

	value := aValue! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SomeNumber class
	instanceVariableNames: ''!


!SomeNumber class methodsFor: 'instance creation'!

from: aValue
	"Create a wrapper around the given number that allows it to masquerade as a MetaNumber"

	^self basicNew setValue: aValue! !