'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:06 pm'!

TableEntry subclass: #IndexEntry
	instanceVariableNames: 'myIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(IndexEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!IndexEntry methodsFor: 'accessing'!

{IntegerVar} index
	^ myIndex!

{BooleanVar} match: key {Position}
	"Return true if my key matches key."
	
	key cast: IntegerPos into: [:pos | 
			^pos asIntegerVar == myIndex]
		others: [^false].
	^ false "compiler fodder"!

{BooleanVar} matchInt: index {IntegerVar}
	"Return true if my key matches the position associated with index."
	
	^index == myIndex!

{Position} position
	^myIndex integer! !

!IndexEntry methodsFor: 'creation'!

{TableEntry} copy
	^ IndexEntry create: myIndex with:self value!

create: index {IntegerVar} with: value {Heaper}
	super create: value.
	myIndex _ index!

create: next {TableEntry} with: value {Heaper} with: index {IntegerVar}
	super create: next with: value.
	myIndex _ index! !

!IndexEntry methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myIndex integer << ' -> ' << self value << ')'! !

!IndexEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myIndex _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myIndex.! !