'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:04 pm'!

Abraham subclass: #Counter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-counter'!

(Counter getOrMakeCxxClassDescription)
	friends:
'friend class SimpleTurtle;
';
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!Counter methodsFor: 'accessing'!

{IntegerVar} count
	^self subclassResponsibility!

{IntegerVar} decrement
	^self subclassResponsibility!

{IntegerVar} decrementBy: count {IntegerVar}
	^self subclassResponsibility!

{IntegerVar} increment
	^self subclassResponsibility!

{IntegerVar} incrementBy: count {IntegerVar}
	^self subclassResponsibility!

{void} setCount: count {IntegerVar}
	self subclassResponsibility! !

!Counter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self count << ')'! !

!Counter methodsFor: 'protected: creation'!

create
	super create!

create: hash {UInt32}
	super create: hash! !

!Counter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Counter class
	instanceVariableNames: ''!

(Counter getOrMakeCxxClassDescription)
	friends:
'friend class SimpleTurtle;
';
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!Counter class methodsFor: 'pseudo-constructors'!

{Counter} fakeCounter: count {IntegerVar} with: batchCount {IntegerVar} with: hash {UInt32}
	^BatchCounter makeFakeCounter: count with: batchCount with: hash!

make
	^SingleCounter create.!

make: count {IntegerVar}
	^SingleCounter create: count!

make: count {IntegerVar} with: batchCount {IntegerVar}
	^BatchCounter make: count with: batchCount! !