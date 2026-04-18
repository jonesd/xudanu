'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:47 pm'!

Heaper subclass: #PopSensor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sensor'!

(PopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #DEFERRED; add: #EQ; yourself)!

!PopSensor methodsFor: 'proxy accessing'!

{void PROXY} poppedValue: answer {Rational}

	self subclassResponsibility! !

!PopSensor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PopSensor class
	instanceVariableNames: ''!

(PopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #DEFERRED; add: #EQ; yourself)!

!PopSensor class methodsFor: 'creation'!

make: ooPtr {ostream star}

	^ActualPopSensor create: ooPtr! !