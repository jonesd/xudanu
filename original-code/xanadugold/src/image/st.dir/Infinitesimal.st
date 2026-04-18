'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:16 pm'!

MetaNumeric subclass: #Infinitesimal
	instanceVariableNames: 'negative '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers-MetaNumeric'!
Infinitesimal comment:
'Infinitesimals represent numbers so close to zero that they are unrepresentable in more conventional forms.  Infinitesimal may be thought of as the reciprocal of Infinity.

Instance variables
	negative	<Boolean> whether the value is greater or less than zero'!


!Infinitesimal methodsFor: 'arithmetic'!

* aNumber 
	"Multiply aNumber by the receiver"

	^aNumber productFromInfinitesimal: self!

+ aNumber 
	"Add the receiver to aNumber"

	^aNumber sumFromInfinitesimal: self!

- aNumber 
	"Subtract aNumber from the receiver"

	^aNumber differenceFromInfinitesimal: self!

/ aNumber 
	"Divide the receiver by aNumber"

	^aNumber quotientFromInfinitesimal: self!

negated

	^self class negative: negative == false! !

!Infinitesimal methodsFor: 'comparing'!

< aNumber 
	"Compare the receiver and aNumber"

	^aNumber lessFromInfinitesimal: self!

hash

	^16382! !

!Infinitesimal methodsFor: 'testing'!

isZero
	"Answer whether 'self = self class zero'.  We can't use #= because
	#= is defined in terms of #isZero"

	^false!

negative
	"Answer whether the receiver is less than zero"

	^negative!

positive
	"Answer whether the receiver is greater than zero"

	^negative == false! !

!Infinitesimal methodsFor: 'truncation and roundoff'!

truncated

	^0! !

!Infinitesimal methodsFor: 'printing'!

printOn: aStream

	aStream nextPut: (negative ifTrue: [$-] ifFalse: [$+]).
	aStream nextPutAll: 'tiny'! !

!Infinitesimal methodsFor: 'double dispatching'!

differenceFromInfinitesimal: aNumber 

	self negative ~= aNumber negative
		ifTrue: [^aNumber copy]
		ifFalse: [^self class
				raise: #domainErrorSignal
				receiver: aNumber
				selector: #-
				arg: self
				errorString: 'Can''t compute the difference of Infinitesimals of like sign']!

differenceFromInfinity: aNumber

	^aNumber copy!

differenceFromSomeNumber: aNumber

	aNumber isZero
		ifTrue:	[^self negated].
	^aNumber numericValue!

lessFromInfinitesimal: aNumber 

	aNumber negative = self negative
		ifTrue: [^self class
				raise: #unorderedSignal
				receiver: aNumber
				selector: #<
				arg: self
				errorString: 'Can''t compare Infinitesimals of like sign']
		ifFalse: [^aNumber negative]!

lessFromInfinity: aNumber

	^aNumber negative!

lessFromSomeNumber: aNumber

	aNumber isZero
		ifTrue:	[^self positive].
	^aNumber negative!

productFromInfinitesimal: aNumber 

	self negative
		ifTrue: [^aNumber negated]
		ifFalse: [^aNumber copy]!

productFromInfinity: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #*
		arg: self
		errorString: 'The product of Infinity and Infinitesimal is undefined'!

productFromSomeNumber: aNumber

	aNumber isZero
		ifTrue:	[^0].
	aNumber numericValue = 1
		ifTrue:	[^self].
	aNumber negative
		ifTrue:	[^self negated]
		ifFalse:	[^self copy]!

quotientFromInfinitesimal: aNumber 

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #/
		arg: self
		errorString: 'Can''t divide an Infinitesimal by an Infinitesimal'!

quotientFromInfinity: aNumber 

	self negative
		ifTrue:	[^aNumber negated]
		ifFalse:	[^aNumber copy]!

quotientFromSomeNumber: aNumber 

	aNumber isZero
		ifTrue:	[^0].
	^Infinity negative: aNumber negative ~= self negative!

sumFromInfinitesimal: aNumber 

	self negative = aNumber negative
		ifTrue: [^aNumber copy]
		ifFalse: [^self class
				raise: #domainErrorSignal
				receiver: aNumber
				selector: #+
				arg: self
				errorString: 'Can''t add Infinitesimals of differing signs']!

sumFromInfinity: aNumber

	^aNumber copy!

sumFromSomeNumber: aNumber
	"Return the identity of the receiver, so that equality works.
	Try the following code for an example

	Number unorderedSignal
		handle:
			[ :ex |
			Transcript cr; show: 'i = i can''t be tested'.
			ex returnWith: false]
		do:	[| i |
			0 + (i := Infinitesimal positive) = i
				ifTrue:	[Transcript cr; show: 'i = i'].
			i + i = i
				ifFalse:	[Transcript cr; show: 'i ~= i']]
	"

	aNumber isZero
		ifTrue:	[^self].
	^aNumber numericValue! !

!Infinitesimal methodsFor: 'converting'!

asDouble
	"Answer a Double that approximates the receiver."

	^0 asDouble!

asFloat
	"Answer a Float that approximates the receiver."

	^0.0!

asRational
	"Answer a Rational number that approximates the receiver."

	^0! !

!Infinitesimal methodsFor: 'private: private'!

negative: aBoolean

	negative := aBoolean! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Infinitesimal class
	instanceVariableNames: ''!


!Infinitesimal class methodsFor: 'instance creation'!

negative
	"Answer negative infinitesimal"

	^self negative: true!

negative: boolean
	"Answer a 'new' infinitesimal, either positive or negative"

	^self basicNew negative: boolean!

positive
	"Answer positive infinitesimal"

	^self negative: false! !