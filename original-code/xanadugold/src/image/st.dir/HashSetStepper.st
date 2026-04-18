'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:40 pm'!

Stepper subclass: #HashSetStepper
	instanceVariableNames: '
		myElements {SharedPtrArray}
		myCurrent {Int32}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(HashSetStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HashSetStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	(myElements ~~ NULL and: [myCurrent < myElements count])
		ifTrue: [^myElements fetch: myCurrent]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^myElements ~~ NULL and: [myCurrent < myElements count]!

{void} step
	myCurrent _ myCurrent + 1.
	self verifyEntry! !

!HashSetStepper methodsFor: 'protected: destruct'!

{void} destruct
	myElements ~~ NULL ifTrue: [
		myElements shareLess].
	super destruct! !

!HashSetStepper methodsFor: 'protected: creation'!

create: elements {SharedPtrArray} with: current {Int32}
	super create.
	myElements _ elements.
	myElements shareMore.
	myCurrent _ current.
	self verifyEntry! !

!HashSetStepper methodsFor: 'creation'!

{Stepper} copy
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ HashSetStepper create: myElements with: myCurrent]
		ifFalse: [^ (HashSetStepper new.Become: result) create: myElements with: myCurrent]!

{void} destroy
	(SomeSteppers store: self) ifFalse:
		[super destroy]! !

!HashSetStepper methodsFor: 'private:'!

{void} verifyEntry
	myElements ~~ NULL ifTrue: [
		myCurrent < myElements count ifTrue: [
			myCurrent := myElements indexPast: NULL with: myCurrent.
			myCurrent == -1 ifTrue: [myCurrent := myElements count]].
		self hasValue ifFalse: [
			myElements shareLess.
			myElements := NULL]].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HashSetStepper class
	instanceVariableNames: ''!

(HashSetStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HashSetStepper class methodsFor: 'pseudo constructors'!

{Stepper} make: elements {SharedPtrArray}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ self create: elements with: Int32Zero]
		ifFalse: [^ (self new.Become: result) create: elements with: Int32Zero]! !

!HashSetStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 16.!

linkTimeNonInherited
	SomeSteppers := NULL! !