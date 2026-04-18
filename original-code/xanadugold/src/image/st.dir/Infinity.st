'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:17 pm'!

MetaNumeric subclass: #Infinity
	instanceVariableNames: 'negative '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers-MetaNumeric'!
Infinity comment:
'Infinities represent numbers so large that they are unrepresentable in more conventional forms.  Dividing a number by zero is a case where an application may choose to generate instances of this class.

Instance variables
	negative	<Boolean> whether the value is greater or less than zero'!


!Infinity methodsFor: 'arithmetic'!

* aNumber 
	"Multiply aNumber by the receiver"

	^aNumber productFromInfinity: self!

+ aNumber 
	"Add aNumber to the receiver"

	^aNumber sumFromInfinity: self!

- aNumber 
	"Subtract aNumber from the receiver"

	^aNumber differenceFromInfinity: self!

/ aNumber 
	"Divide the receiver by aNumber"

	^aNumber quotientFromInfinity: self!

negated

	^self class negative: negative == false! !

!Infinity methodsFor: 'comparing'!

< aNumber 
	"Compare the receiver to aNumber"

	^aNumber lessFromInfinity: self!

hash

	^16383! !

!Infinity methodsFor: 'testing'!

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

!Infinity methodsFor: 'truncation and roundoff'!

truncated

	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #truncated
		errorString: 'Can''t truncate infinity'! !

!Infinity methodsFor: 'printing'!

printOn: aStream

	aStream nextPut: (negative ifTrue: [$-] ifFalse: [$+]).
	aStream nextPutAll: 'infinity'! !

!Infinity methodsFor: 'double dispatching'!

differenceFromInfinitesimal: aNumber

	^self negated!

differenceFromInfinity: aNumber 

	self negative = aNumber negative
		ifTrue: [^self class
				raise: #domainErrorSignal
				receiver: aNumber
				selector: #-
				arg: self
				errorString: 'Can''t subtract Infinities with like signs']
		ifFalse: [^aNumber copy]!

differenceFromSomeNumber: aNumber

	^self negated!

lessFromInfinitesimal: aNumber

	^self positive!

lessFromInfinity: aNumber 

	aNumber negative = self negative
		ifTrue: [^self class
				raise: #unorderedSignal
				receiver: aNumber
				selector: #<
				arg: self
				errorString: 'Can''t compare Infinities of like signs']
		ifFalse: [^aNumber negative]!

lessFromSomeNumber: aNumber

	^self positive!

productFromInfinitesimal: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #*
		arg: self
		errorString: 'The product of Infinity and Infinitesimal is undefined'!

productFromInfinity: aNumber

	aNumber negative
		ifTrue:	[^self negated]
		ifFalse:	[^self copy]!

productFromSomeNumber: aNumber

	aNumber isZero
		ifTrue:	[^0].
	aNumber numericValue = 1
		ifTrue:	[^self].
	aNumber negative
		ifTrue:	[^self negated]
		ifFalse:	[^self copy]!

quotientFromInfinitesimal: aNumber

	self negative
		ifTrue:	[^aNumber negated]
		ifFalse:	[^aNumber copy]!

quotientFromInfinity: aNumber 

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #/
		arg: self
		errorString: 'Can''t divide Infinity by Infinity'!

quotientFromSomeNumber: aNumber 

	aNumber isZero
		ifTrue:	[^0].
	^Infinitesimal negative: aNumber negative ~= self negative!

sumFromInfinitesimal: aNumber

	^self copy!

sumFromInfinity: aNumber 

	self negative ~= aNumber negative
		ifTrue: [^self class
				raise: #domainErrorSignal
				receiver: aNumber
				selector: #+
				arg: self
				errorString: 'Can''t add Infinities of differing signs']
		ifFalse: [^aNumber copy]!

sumFromSomeNumber: aNumber

	aNumber isZero
		ifTrue:	[^self]
		ifFalse:	[^self copy]! !

!Infinity methodsFor: 'private: private'!

negative: aBoolean

	negative := aBoolean! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Infinity class
	instanceVariableNames: ''!


!Infinity class methodsFor: 'instance creation'!

negative
	"Answer negative infinity"

	^self negative: true!

negative: boolean
	"Answer a 'new' infinity, either positive or negative"

	^self basicNew negative: boolean!

positive
	"Answer positive infinity"

	^self negative: false! !