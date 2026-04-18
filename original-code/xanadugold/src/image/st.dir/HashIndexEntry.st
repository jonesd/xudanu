'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:05 pm'!

TableEntry subclass: #HashIndexEntry
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(HashIndexEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!HashIndexEntry methodsFor: 'accessing'!

{BooleanVar} match: key {Position}
	"Return true if my key matches key."
	
	key cast: IntegerPos into: [:pos | 
			^pos asIntegerVar == self value hashForEqual]
		others: [^false].
	^ false "compiler fodder"!

{BooleanVar} matchInt: index {IntegerVar}
	"Return true if my key matches the position associated with index."
	
	^index == self value hashForEqual!

{Position} position
	^self value hashForEqual integer!

{BooleanVar} replaceValue: newValue {Heaper}
	"Return true if my value can be replaced in place, and false if the entire entry must be replaced."
	
	^newValue hashForEqual == self value hashForEqual and: [super replaceValue: newValue]! !

!HashIndexEntry methodsFor: 'creation'!

{TableEntry} copy
	^ HashIndexEntry create: self value!

create: value {Heaper}
	super create: value!

create: next {TableEntry} with: value {Heaper}
	super create: next with: value! !

!HashIndexEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !