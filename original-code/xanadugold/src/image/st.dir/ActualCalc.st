'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:04 pm'!

Calc subclass: #ActualCalc
	instanceVariableNames: '
		myCount {UInt32}
		myRationals {PtrArray}
		myAfterTOS {UInt32}
		mySensor {PopSensor}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Calc'!

(ActualCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ActualCalc methodsFor: 'accessing'!

{void PROXY} plantPopSensor: sensor {PopSensor}

	mySensor ~= NULL
		ifTrue: [Heaper BLAST: #SensorQueueOverflow].
	myAfterTOS > UInt32Zero
		ifTrue: [sensor poppedValue: self pop]
		ifFalse: [mySensor _ sensor]!

{Rational PROXY} pop

	myAfterTOS <= UInt32Zero
		ifTrue: [Heaper BLAST: #StackUnderflow].
	myAfterTOS _ myAfterTOS -1.
	^(myRationals fetch: myAfterTOS) cast: Rational.!

{void PROXY} push: rat {Rational}

	mySensor ~~ NULL
		ifTrue: [mySensor poppedValue: rat.
				mySensor _ NULL.
				^VOID].
	myAfterTOS >= myCount
		ifTrue: [Heaper BLAST: #StackOverflow].
	myRationals at: myAfterTOS store: rat.
	myAfterTOS _ myAfterTOS +1!

{void PROXY} times

	| a {Rational} b {Rational} |
	a _ self pop.
	b _ self pop.
	self push: (Rational make: a numerator * b numerator
					with: a denominator * b denominator).!

{void PROXY} timesArg: rat {Rational}
	
	self push: rat.
	self times! !

!ActualCalc methodsFor: 'creation'!

create: arrayCount {UInt32}

	super create: 37.
	myCount _ arrayCount.
	myRationals _ PtrArray nulls: myCount.
	myAfterTOS _ UInt32Zero.
	mySensor _ NULL.! !

!ActualCalc methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !