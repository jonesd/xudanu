'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:33 pm'!

Stepper subclass: #SetTableStepper
	instanceVariableNames: '
		myPtrs {PtrArray}
		myIndex {Int32}'
	classVariableNames: '
		AnArray {PtrArray} 
		AStepper {SetTableStepper} '
	poolDictionaries: ''
	category: 'Xanadu-settab'!

(SetTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!SetTableStepper methodsFor: 'accessing'!

{Heaper} fetch
	myIndex < myPtrs count
		ifTrue: [^ myPtrs fetch: myIndex]
		ifFalse: [^ NULL]!

{BooleanVar} hasValue
	^ myIndex < myPtrs count!

{void} step
	myIndex := myIndex + 1! !

!SetTableStepper methodsFor: 'create'!

{Stepper} copy
	^ SetTableStepper create: (myPtrs copy cast: PtrArray) with: myIndex!

{void} destroy
	AStepper == NULL
		ifTrue: [
			myPtrs storeAll.
			AnArray := myPtrs cast: PtrArray.
			AStepper := self.
			self destruct]
		ifFalse: [
			super destroy].! !

!SetTableStepper methodsFor: 'protected: create'!

create: array {PtrArray}
	super create.
	myPtrs := array.
	myIndex := Int32Zero.!

create: array {PtrArray} with: index {Int32}
	super create.
	myPtrs := array.
	myIndex := index.! !

!SetTableStepper methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetTableStepper class
	instanceVariableNames: ''!

(SetTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!SetTableStepper class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	AnArray := NULL.
	AStepper := NULL.! !

!SetTableStepper class methodsFor: 'create'!

make: array {PtrArray}
	AStepper ~~ NULL
		ifTrue: [
			| result {SetTableStepper} |
			result := (SetTableStepper new.Become: AStepper) create: array.
			AStepper := NULL.
			^ result]
		ifFalse: [
			^ SetTableStepper create: array]! !

!SetTableStepper class methodsFor: 'accessing'!

{PtrArray} array
	AnArray ~~ NULL
		ifTrue: [
			| result {PtrArray} |
			result := AnArray.
			AnArray := NULL.
			^ result]
		ifFalse: [
			^ PtrArray nulls: 16]! !