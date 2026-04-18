'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:19 pm'!

MetaNumeric subclass: #NotANumber
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers-MetaNumeric'!
NotANumber comment:
'NotANumbers are very poor citizens of the number-object world.  They are basically placeholders that indicate that an illegal mathematical operation occurred at some unknown point in the past.  An application may generate NotANumbers when such operations occur as taking the square root of -729, computing the arcSin of 8, etc.'!


!NotANumber methodsFor: 'arithmetic'!

* aNumber

	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #*
		arg: aNumber
		errorString: 'Can''t perform arithmetic functions on NaN'!

+ aNumber

	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #+
		arg: aNumber
		errorString: 'Can''t perform arithmetic functions on NaN'!

- aNumber

	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #-
		arg: aNumber
		errorString: 'Can''t perform arithmetic functions on NaN'!

/ aNumber

	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #/
		arg: aNumber
		errorString: 'Can''t perform arithmetic functions on NaN'! !

!NotANumber methodsFor: 'testing'!

isZero
	"Answer whether 'self = self class zero'.  We can't use #= because
	#= is defined in terms of #isZero"

	^self class
		raise: #unorderedSignal
		receiver: self
		selector: #isZero
		errorString: 'Can''t do comparisons on NaN'! !

!NotANumber methodsFor: 'comparing'!

< aNumber

	^self class
		raise: #unorderedSignal
		receiver: self
		selector: #<
		arg: aNumber
		errorString: 'Can''t do comparisons on NaN'! !

!NotANumber methodsFor: 'double dispatching'!

differenceFromInfinitesimal: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #-
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

differenceFromInfinity: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #-
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

differenceFromSomeNumber: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #-
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

lessFromInfinitesimal: aNumber

	^self class
		raise: #unorderedSignal
		receiver: aNumber
		selector: #<
		arg: self
		errorString: 'Can''t do comparisons on NaN'!

lessFromInfinity: aNumber

	^self class
		raise: #unorderedSignal
		receiver: aNumber
		selector: #<
		arg: self
		errorString: 'Can''t do comparisons on NaN'!

lessFromSomeNumber: aNumber

	^self class
		raise: #unorderedSignal
		receiver: aNumber
		selector: #<
		arg: self
		errorString: 'Can''t do comparisons on NaN'!

productFromInfinitesimal: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #*
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

productFromInfinity: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #*
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

productFromSomeNumber: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #*
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

quotientFromInfinitesimal: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #/
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

quotientFromInfinity: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #/
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

quotientFromSomeNumber: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #/
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

sumFromInfinitesimal: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #+
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

sumFromInfinity: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #+
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'!

sumFromSomeNumber: aNumber

	^self class
		raise: #domainErrorSignal
		receiver: aNumber
		selector: #+
		arg: self
		errorString: 'Can''t perform arithmetic functions on NaN'! !

!NotANumber methodsFor: 'printing'!

printOn: aStream

	aStream nextPutAll: 'NaN'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NotANumber class
	instanceVariableNames: ''!


!NotANumber class methodsFor: 'class initialization'!

initialize
	"NotANumber initialize"

	(Smalltalk includesKey: #Double)
		ifTrue:	[Double initialize]! !

!NotANumber class methodsFor: 'instance creation'!

new

	^self basicNew! !

NotANumber initialize!
