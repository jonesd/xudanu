'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:08 pm'!

Heaper subclass: #TableEntry
	instanceVariableNames: '
		myNext {TableEntry}
		myValue {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(TableEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #EQ; add: #DEFERRED; add: #COPY; yourself)!

!TableEntry methodsFor: 'accessing'!

{TableEntry} copy

	self subclassResponsibility!

{TableEntry INLINE | NULL} fetchNext
	^myNext!

{IntegerVar} index
	^ (self position cast: IntegerPos) asIntegerVar!

{BooleanVar} match: key {Position}
	"Return true if my key matches key."
	
	self subclassResponsibility!

{BooleanVar} matchInt: index {IntegerVar}
	"Return true if my key matches the position associated with index."
	
	^self match: index integer!

{BooleanVar} matchValue: value {Heaper}
	"Return true if my value matches value.  Note that this *must* test EQ first in
	 case the value is no longer a heaper.  Otherwise we could never remove a 
	 destructed object."
	
	^value == (myValue basicCast: Heaper star) or: [value isEqual: myValue]!

{Position} position
	self subclassResponsibility!

{BooleanVar} replaceValue: newValue {Heaper}
	"Return true if my value can be replaced in place, and false if the entire entry must be replaced."
	
	"The default implementation."
	myValue _ newValue.
	^true!

{void INLINE} setNext: next {TableEntry | NULL}
	"Change my pointer to the rest of the chain in this bucket."
	myNext _ next!

{Heaper INLINE} value
	^myValue! !

!TableEntry methodsFor: 'protected: creation'!

create: value {Heaper}
	super create.
	myNext _ NULL.
	myValue _ value!

create: next {TableEntry} with: value {Heaper}
	super create.
	myNext _ next.
	myValue _ value! !

!TableEntry methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self position << ' -> ' << self value << ')'! !

!TableEntry methodsFor: 'destroy'!

{void} destroy
	"temporarily don't destroy."! !

!TableEntry methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNext _ receiver receiveHeaper.
	myValue _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myNext.
	xmtr sendHeaper: myValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TableEntry class
	instanceVariableNames: ''!

(TableEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #EQ; add: #DEFERRED; add: #COPY; yourself)!

!TableEntry class methodsFor: 'creation'!

{TableStepper INLINE} bucketStepper: array {SharedPtrArray}
	^BucketArrayStepper make: array!

make.IntegerVar: index {IntegerVar} with: value {Heaper}
	index == value hashForEqual
		ifTrue: [^HashIndexEntry create: value]
		ifFalse: [^IndexEntry create: index with: value]!

make: key {Position} with: value {Heaper}

	key cast: IntegerPos into: [:xuint | 
			^self make.IntegerVar: xuint asIntegerVar with: value]
		cast: HeaperAsPosition into: [:hap |
				(key isEqual: (HeaperAsPosition make: value))
					ifTrue: [ ^HeaperAsEntry create: value]
					ifFalse: [^PositionEntry create: key with: value]]
		others: [^PositionEntry create: key with: value].
	^ NULL "compiler fodder"! !