'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:35 pm'!

Abraham subclass: #DoublingFlock
	instanceVariableNames: 'myCount {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(DoublingFlock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #EQ; add: #LOCKED; add: #CONCRETE; yourself)!

!DoublingFlock methodsFor: 'accessing'!

{Int32} count
	^myCount!

{void} doDouble
	
	DiskManager consistent: 1 with:
		[myCount _ myCount * 2.
		self diskUpdate]! !

!DoublingFlock methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveTestFlock: rcvr {Rcvr} 
	Int32Zero almostTo: myCount do: 
		[:i {Int32} | rcvr receiveInt32 ~~ i ifTrue: [Heaper BLAST: #MustMatch]]!

{void SEND.HOOK} sendTestFlock: xmtr {Xmtr}
	Int32Zero almostTo: myCount do: [:i {Int32} | xmtr sendInt32: i]! !

!DoublingFlock methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self hashForEqual <<', ' << myCount << ')'! !

!DoublingFlock methodsFor: 'creation'!

create: hash {UInt32}
	super create: hash.
	myCount _ 1.
	self newShepherd!

create: hash {UInt32} with: count {Int32}
	super create: hash.
	myCount _ count.
	self newShepherd! !

!DoublingFlock methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: (IntegerPos integerHash: myCount)! !

!DoublingFlock methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCount _ receiver receiveInt32.
	self receiveTestFlock: receiver.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myCount.
	self sendTestFlock: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DoublingFlock class
	instanceVariableNames: ''!

(DoublingFlock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #EQ; add: #LOCKED; add: #CONCRETE; yourself)!

!DoublingFlock class methodsFor: 'creation'!

make: hash {UInt32}
	^self create: hash!

make: hash {UInt32} with: count {Int32}
	^self create: hash with: count! !