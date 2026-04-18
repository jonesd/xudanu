'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:40 pm'!

TableStepper subclass: #IntegerTableStepper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!
IntegerTableStepper comment:
'Consider this a protected class.  It is public only for use by the "array" module.'!

(IntegerTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!IntegerTableStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	self subclassResponsibility!

{Heaper wimpy} get
	| res {Heaper wimpy} |
	res _ self fetch.
	res == NULL ifTrue: [Heaper BLAST: #EmptyStepper].
	^res!

{BooleanVar} hasValue
	self subclassResponsibility!

{void} step
	self subclassResponsibility! !

!IntegerTableStepper methodsFor: 'special'!

{Position} position
	self subclassResponsibility! !

!IntegerTableStepper methodsFor: 'create'!

{Stepper} copy
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerTableStepper class
	instanceVariableNames: ''!

(IntegerTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!IntegerTableStepper class methodsFor: 'pseudoConstructors'!

make: aTable {IntegerTable} with: anOrder {OrderSpec default: NULL} 
	"Do not consider public.  Only for use by the modules inttab, array, and awarray."
	
	aTable cast: ActualIntegerTable into: [:tab |
			(anOrder followsInt: 1  with: IntegerVar0)
				ifTrue: [^ITAscendingStepper create: tab]
				ifFalse: [^ITDescendingStepper create: tab]]
		others: [anOrder == NULL
				ifTrue: [^ITGenericStepper create: aTable]
				ifFalse: [^ITGenericStepper create: aTable with.OrderSpec: anOrder]].
	^ NULL "compiler fodder"!

make: aTable {IntegerTable} 
	with: start {IntegerVar} 
	with: stop {IntegerVar} 
	"Do not consider public.  Only for use by the modules inttab, array, and awarray."
	
	aTable cast: ActualIntegerTable into: [:tab |
			^ITAscendingStepper
				create: tab
				with: start
				with: stop]
		others: [^ITGenericStepper
				create: aTable
				with: start
				with: stop
				with: 1].
	^ NULL "compiler fodder"! !

!IntegerTableStepper class methodsFor: 'smalltalk: smalltalk creation'!

create: onTable {IntegerTable} with.OrderSpec: anOrderSpec {OrderSpec}
	^ self new create: onTable with.OrderSpec: anOrderSpec! !