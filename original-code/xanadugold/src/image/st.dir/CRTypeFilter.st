'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:11 pm'!

CRFilter subclass: #CRTypeFilter
	instanceVariableNames: 'myTypes {IdentitySet of: Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRTypeFilter methodsFor: 'accessing'!

{String} label
	myTypes count = 0
		ifTrue: [^ 'No Types']
	ifFalse: [myTypes count = 1
		ifTrue: [^ 'Matching ', myTypes stepper get]
	ifFalse: [| s ms | s _ 'Matching any of ('.
		(ms _ myTypes stepper).
		[ms hasValue] whileTrue: [| type | 
			type _ ms get.
			s _ s, type.
			ms  step.
			ms hasValue ifTrue: [s _ s, ', ']].
		^ s]]!

{BooleanVar} passes: cr {ChangeRecord}
	^ self types includes: cr type! !

!CRTypeFilter methodsFor: 'protected:'!

{IdentitySet of: Symbol} types

	^ myTypes! !

!CRTypeFilter methodsFor: 'create'!

create: types {Collection of: Symbol}

	super create.
	myTypes _ types! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CRTypeFilter class
	instanceVariableNames: ''!



!CRTypeFilter class methodsFor: 'make'!

make: onThing

	(onThing isKindOf: Symbol)
		ifTrue: [^ self create: (Array with: onThing)]
		ifFalse: [^ self create: onThing]! !