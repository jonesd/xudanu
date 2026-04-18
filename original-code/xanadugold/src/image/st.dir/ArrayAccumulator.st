'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:38 pm'!

TableAccumulator subclass: #ArrayAccumulator
	instanceVariableNames: 'arrayInternal {MuArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(ArrayAccumulator getOrMakeCxxClassDescription)
	friends:
'friend class XuArray;';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ArrayAccumulator methodsFor: 'protected: create'!

create: onTable {MuArray}
	super create.
	arrayInternal _ onTable! !

!ArrayAccumulator methodsFor: 'operations'!

{void} step: obj {Heaper} 
	arrayInternal isEmpty
		ifTrue: [arrayInternal atInt: IntegerVar0 store: obj]
		ifFalse: [arrayInternal atInt: (arrayInternal domain quickCast: IntegerRegion) stop introduce: obj]!

{Heaper} value
	^ arrayInternal.! !

!ArrayAccumulator methodsFor: 'create'!

{Accumulator} copy
	^ ArrayAccumulator make: (arrayInternal copy cast: MuArray)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ArrayAccumulator class
	instanceVariableNames: ''!

(ArrayAccumulator getOrMakeCxxClassDescription)
	friends:
'friend class XuArray;';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ArrayAccumulator class methodsFor: 'create'!

{TableAccumulator} make: onTable {MuArray}
	^ self create: onTable! !

!ArrayAccumulator class methodsFor: 'smalltalk: creation'!

create.IntegerTable: aTable	
	^self new create: aTable! !