'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:38 pm'!

Abraham subclass: #PairFlock
	instanceVariableNames: '
		myLeft {Abraham}
		myRight {Abraham}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(PairFlock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #EQ; add: #LOCKED; add: #CONCRETE; yourself)!

!PairFlock methodsFor: 'accessing'!

{Abraham} left
	^myLeft!

{Abraham} right
	^myRight! !

!PairFlock methodsFor: 'creation'!

create: left {Abraham} with: right {Abraham}
	super create.
	myLeft _ left.
	myRight _ right.
	self newShepherd! !

!PairFlock methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: myLeft hashForEqual)
		bitXor: myRight hashForEqual! !

!PairFlock methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myLeft _ receiver receiveHeaper.
	myRight _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myLeft.
	xmtr sendHeaper: myRight.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PairFlock class
	instanceVariableNames: ''!

(PairFlock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #EQ; add: #LOCKED; add: #CONCRETE; yourself)!

!PairFlock class methodsFor: 'creation'!

make: left {Abraham} with: right {Abraham}
	^self create: left with: right! !