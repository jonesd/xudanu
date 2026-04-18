'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:49 pm'!

Heaper subclass: #FeCalc
	instanceVariableNames: '
		myCount {UInt4}
		myRationals {PtrArray}
		myAfterTOS {UInt4}
		mySensor {XuPopSensor}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!
FeCalc comment:
'Class comment'!

(FeCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeCalc methodsFor: 'creation'!

create: arrayCount {UInt4}

	super create.
	myCount _ arrayCount.
	myRationals _ PtrArray nulls: myCount.
	myAfterTOS _ UInt40.
	mySensor _ NULL.! !

!FeCalc methodsFor: 'accessing'!

{void CLIENT} plantPopSensor: sensor {XuPopSensor}

 	mySensor ~= NULL
		ifTrue: [Heaper BLAST: #SensorQueueOverflow].
	myAfterTOS > UInt40
		ifTrue: [sensor poppedValue: (XuRational make: (self pop))]
		ifFalse: [mySensor _ sensor]!

{FeRational CLIENT} pop
	"pops"
	"non-client comment"
	
	myAfterTOS <= UInt40
		ifTrue: [Heaper BLAST: #StackUnderflow].
	myAfterTOS _ myAfterTOS -1.
	^(myRationals fetch: myAfterTOS) cast: FeRational.!

{void CLIENT} push: rat {FeRational}
	"pushes"
 
	mySensor ~~ NULL
		ifTrue: [mySensor poppedValue: (XuRational make: rat).
				mySensor _ NULL.
				^VOID].
	myAfterTOS >= myCount
		ifTrue: [Heaper BLAST: #StackOverflow].
	myRationals at: myAfterTOS store: rat.
	myAfterTOS _ myAfterTOS +1!

{void CLIENT} times

	| a {FeRational} b {FeRational} |
	a _ self pop.
	b _ self pop.
	self push: (FeRational make: a numerator * b numerator
					with: a denominator * b denominator).!

{void CLIENT} timesArg: rat {FeRational}
	
	self push: rat.
	self times!

{void CLIENT} timesCurrent
	
	self push: CurrentRat fluidGet.
	self times! !

!FeCalc methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeCalc class
	instanceVariableNames: ''!

(FeCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeCalc class methodsFor: 'exceptions: exceptions'!

problems.StackOverflow
	^self signals: #(StackOverflow)!

problems.StackUnderflow

	^self signals: #(StackUnderflow)! !

!FeCalc class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	FeRational defineClientFluid: #CurrentRat with: ServerChunk emulsion with: [NULL].! !