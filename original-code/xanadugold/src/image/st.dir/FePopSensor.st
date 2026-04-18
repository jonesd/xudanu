'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:50 pm'!

Heaper subclass: #FePopSensor
	instanceVariableNames: 'myOOPtr {ostream star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(FePopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FePopSensor methodsFor: 'private:'!

{ostream reference} oo
	
	'return *myOOPtr;' translateOnly.
	[^myOOPtr] smalltalkOnly.! !

!FePopSensor methodsFor: 'creation'!

create: ooPtr {ostream star}

	super create.
	myOOPtr _ ooPtr.! !

!FePopSensor methodsFor: 'accessing'!

{void CLIENT} poppedValue: answer {FeRational}
	
	self oo << 'PopSensor got value: ' << answer  << '
'.! !

!FePopSensor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePopSensor class
	instanceVariableNames: ''!

(FePopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FePopSensor class methodsFor: 'creation'!

make: ooPtr {ostream star}

	^FePopSensor create: ooPtr! !

!FePopSensor class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} poppedValue: answer {FeRational}
"! !