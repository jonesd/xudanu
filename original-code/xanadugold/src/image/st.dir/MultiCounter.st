'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:05 pm'!

Abraham subclass: #MultiCounter
	instanceVariableNames: '
		myFirst {Counter}
		mySecond {Counter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-counter'!

(MultiCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!MultiCounter methodsFor: 'accessing'!

{void} decrementBoth
	
	DiskManager consistent: 2 with:
		[myFirst decrement.
		mySecond decrement]!

{IntegerVar} decrementFirst
	^myFirst decrement!

{IntegerVar} decrementSecond
	^mySecond decrement!

{IntegerVar} firstCount
	^myFirst count!

{void} incrementBoth
	
	DiskManager consistent: 2 with:
		[myFirst increment.
		mySecond increment]!

{IntegerVar} incrementFirst
	^myFirst increment!

{IntegerVar} incrementSecond
	^mySecond increment!

{IntegerVar} secondCount
	^mySecond count! !

!MultiCounter methodsFor: 'creation'!

create
	super create.
	myFirst _ Counter make: IntegerVar0.
	mySecond _ Counter make: IntegerVar0.
	self newShepherd.
	self remember!

create: first {IntegerVar}
	super create.
	myFirst _ Counter make: first.
	mySecond _ Counter make: IntegerVar0.
	self newShepherd.
	self remember!

create: first {IntegerVar} with: second {IntegerVar}
	super create.
	myFirst _ Counter make: first.
	mySecond _ Counter make: second.
	self newShepherd.
	self remember! !

!MultiCounter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myFirst count << ', ' << mySecond count << ')'! !

!MultiCounter methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: myFirst hashForEqual)
		bitXor: mySecond hashForEqual! !

!MultiCounter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myFirst _ receiver receiveHeaper.
	mySecond _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myFirst.
	xmtr sendHeaper: mySecond.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiCounter class
	instanceVariableNames: ''!

(MultiCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!MultiCounter class methodsFor: 'pseudo constructors '!

make
	^self create.!

make: count {IntegerVar}
	^self create: count! !