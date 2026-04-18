'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:33 pm'!

Stepper subclass: #ItemStepper
	instanceVariableNames: 'myItem {Heaper | NULL}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-stepper'!
ItemStepper comment:
'This is a Stepper when you just want to step across a single item.'!

(ItemStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ItemStepper methodsFor: 'create'!

{Stepper} copy
	myItem == NULL
		ifTrue: [ ^ self ]
		ifFalse: [
			| result {Heaper} |
			result := SomeSteppers fetch.
			result == NULL
				ifTrue: [^ItemStepper create: myItem]
				ifFalse: [^(ItemStepper new.Become: result) create: myItem]]!

create: item {Heaper | NULL}
	super create.
	myItem _ item!

{void} destroy
	(SomeSteppers store: self) ifFalse: [super destroy]! !

!ItemStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^myItem!

{BooleanVar} hasValue
	^myItem ~~ NULL!

{void} step
	myItem _ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ItemStepper class
	instanceVariableNames: ''!

(ItemStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ItemStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 8!

linkTimeNonInherited
	SomeSteppers := NULL! !

!ItemStepper class methodsFor: 'create'!

{Stepper} make: item {Heaper}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ self create: item]
		ifFalse: [^ (self new.Become: result) create: item]! !