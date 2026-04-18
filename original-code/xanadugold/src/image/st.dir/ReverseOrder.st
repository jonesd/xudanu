'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:57 pm'!

OrderSpec subclass: #ReverseOrder
	instanceVariableNames: 'myOrder {OrderSpec}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(ReverseOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ReverseOrder methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^myOrder coordinateSpace!

{OrderSpec} reversed
	
	^myOrder! !

!ReverseOrder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myOrder hashForEqual bitXor: -1!

{BooleanVar} follows: x {Position} with: y {Position}
	
	^myOrder follows: y with: x!

{BooleanVar} followsInt: x {IntegerVar} with: y {IntegerVar}

	^myOrder followsInt: y with: x!

{BooleanVar} isEqual: other{Heaper}

	other cast: OrderSpec into: [:os |
			^myOrder isEqual: os reversed]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFullOrder: keys {XnRegion default: NULL}

	^myOrder isFullOrder: keys!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}
	"Return true if some position in before is less than or equal to all positions in after."
	
	self unimplemented.
	^false! !

!ReverseOrder methodsFor: 'private: creation'!

create: order {OrderSpec}

	super create.
	myOrder := order! !

!ReverseOrder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOrder _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOrder.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReverseOrder class
	instanceVariableNames: ''!

(ReverseOrder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ReverseOrder class methodsFor: 'pseudoconstructors'!

{OrderSpec} make: order {OrderSpec}

	^self create: order! !