'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:47 pm'!

PopSensor subclass: #ActualPopSensor
	instanceVariableNames: 'myOOPtr {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sensor'!

(ActualPopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ActualPopSensor methodsFor: 'private:'!

{ostream reference} oo
	
	'return *myOOPtr;' translateOnly.
	[^myOOPtr] smalltalkOnly.! !

!ActualPopSensor methodsFor: 'creation'!

create: ooPtr {ostream star}

	super create.
	myOOPtr _ ooPtr.! !

!ActualPopSensor methodsFor: 'accessing'!

{void PROXY} poppedValue: answer {Rational}
	
	self oo << 'PopSensor got value: ' << answer << '
'.! !

!ActualPopSensor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !