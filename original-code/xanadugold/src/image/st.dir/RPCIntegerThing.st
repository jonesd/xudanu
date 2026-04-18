'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:47 pm'!

Heaper subclass: #RPCIntegerThing
	instanceVariableNames: 'myInt {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rpcxcvr'!
RPCIntegerThing comment:
'This is a wrapper for IntegerVars that RPCSpecialist can store in its sets in lieu of XuIntegers'!

(RPCIntegerThing getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!RPCIntegerThing methodsFor: 'create'!

create: ivar {IntegerVar}
	super create.
	myInt _ ivar! !

!RPCIntegerThing methodsFor: 'accessing'!

{IntegerVar} asIntegerVar
	^ myInt! !

!RPCIntegerThing methodsFor: 'testing'!

{UInt32} hashForEqual
	^ myInt DOTasLong!

{BooleanVar} isEqual: other {Heaper}
	(other isKindOf: RPCIntegerThing) ifFalse: [ ^ false ].
	^ myInt == (other basicCast: RPCIntegerThing) asIntegerVar! !

!RPCIntegerThing methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myInt _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myInt.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RPCIntegerThing class
	instanceVariableNames: ''!

(RPCIntegerThing getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!RPCIntegerThing class methodsFor: 'create'!

make: ivar {IntegerVar}
	^ self create: ivar! !