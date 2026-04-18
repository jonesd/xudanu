'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:46 pm'!

Stepper subclass: #TableStepper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!
TableStepper comment:
'For enumerating the key->value associations of a table.  A typical use (for a table whose range elements were all Foos) might be:
	
	SPTR(TableStepper) stomp = table->stepper();
	FOR_EACH(Foo,f,stomp, {
		doSomethingWith(stomp->key(), z);
	});
	
	Each iteration of the loop would correspond to an association of the table (snapshotted at the time "->stepper()" was sent).  For each association, "f" (a pointer to Foo) points at the range element, while "stomp->key()" provides the domain element.  See ScruTable::stepper.'!

(TableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!TableStepper methodsFor: 'smalltalk: operations'!

{void} forIndices: fn {BlockClosure of: IntegerVar with: Heaper} 
	[| result {Heaper} |
	[(result _ self fetch) ~~ NULL]
		whileTrue:
			[fn of: self index and: result.
			self step]]
		valueNowOrOnUnwindDo: [self destroy]!

{void} forKeyValues: fn {BlockClosure of: Position with: Heaper} 
	[| result {Heaper} |
	[(result _ self fetch) ~~ NULL]
		whileTrue:
			[fn of: self position and: result.
			self step]]
		valueNowOrOnUnwindDo: [self destroy]!

{void} forPositions: fn {BlockClosure of: Position with: Heaper} 
	[| result {Heaper} |
	[(result _ self fetch) ~~ NULL]
		whileTrue:
			[fn of: self position and: result.
			self step]]
		valueNowOrOnUnwindDo: [self destroy]!

{Position} key
	"A TableStepper actually enumerates the associations of a table. Through the normal Stepper protocol, it makes available the range element of the current association. Through this additional protocol, it make accessible the key of the current association.  This message returns the same object as TwoStepper::other, the only difference being the static knowledge that it's a Position."

	^ self position! !

!TableStepper methodsFor: 'special'!

{IntegerVar} index
	"Unboxed version of TableStepper::key.  See class comment in XuInteger."
	
	^(self position cast: IntegerPos) asIntegerVar!

{Position CLIENT} position
	"A TableStepper actually enumerates the associations of a table. Through the normal Stepper protocol, it makes available the range element of the current association. Through this additional protocol, it make accessible the key of the current association.  This message returns the same object as TwoStepper::other, the only difference being the static knowledge that it's a Position."

	self subclassResponsibility! !

!TableStepper methodsFor: 'create'!

{Stepper} copy
	self subclassResponsibility! !

!TableStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	self subclassResponsibility!

{BooleanVar} hasValue
	self subclassResponsibility!

{void} step

	self subclassResponsibility!

{PrimArray CLIENT} stepManyPairs: count {Int32 default: -1}
	"An array of the remaining elements in alternating positions in the array
		[k1, v1, k2, v2, k3, v3, ...]
	Returns an array of up to count * 2 elements (or some arbitrary number if count is negative), and steps the stepper the corresponding number of times. You should check whether the stepper is atEnd, since it can stop before the number you give it because of some internal limit or grouping issue."
	
	| result {Accumulator} n {Int32} |
	count >= Int32Zero
		ifTrue: [n := count * 2]
		ifFalse: [n := 1000].
	result := PtrArrayAccumulator create: n.
	n := Int32Zero.
	[self hasValue and: [(count < Int32Zero and: [n < 1000]) or: [n < count]]] whileTrue:
		[result step: self position.
		result step: self fetch.
		self step.
		n := n + 1].
	^result value cast: PrimArray! !

!TableStepper methodsFor: 'smalltalk: delayed iteration'!

{void} forPromisedPairs: aBlock

	self knownBug. "only works outside of a delay block"
	[self atEnd value] whileFalse:
		[aBlock value: (XuPromise dynamicType: self position) value: (XuPromise dynamicType: self get).
		self step]! !

!TableStepper methodsFor: 'smalltalk: defaults'!

{PrimArray CLIENT} stepManyPairs
	^self stepManyPairs: -1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TableStepper class
	instanceVariableNames: ''!

(TableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!TableStepper class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Position CLIENT} position
{PrimArray CLIENT} stepManyPairs: count {Int32 default: -1}
"! !

!TableStepper class methodsFor: 'creation'!

{TableStepper INLINE} ascending: array {PtrArray}
	"Note: this being a low level operation, and there being no lightweight form of immutable or lazily copied PtrArray, it is my caller's responsibility to pass me a PtrArray which will in fact not be changed during the life of this stepper.  This is an unchecked an uncheckable precondition on my clients."
	 
	^PtrArrayStepper ascending: array!

{TableStepper INLINE} descending: array {PtrArray}
	"Note: this being a low level operation, and there being no lightweight form of immutable or lazily copied PtrArray, it is my caller's responsibility to pass me a PtrArray which will in fact not be changed during the life of this stepper.  This is an unchecked an uncheckable precondition on my clients."
	
	^PtrArrayStepper descending: array! !