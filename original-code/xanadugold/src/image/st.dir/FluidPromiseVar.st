'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:19 pm'!

FluidVar subclass: #FluidPromiseVar
	instanceVariableNames: 'myActualFluid {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-fluid'!
FluidPromiseVar comment:
'We have to use the name of the actual fluid variable since the variable itself may not be
initialized when its corresponding promise fluid variable is initialized.  Since this happens during
static init time, the order cannot be controlled.'!



!FluidPromiseVar methodsFor: 'create'!

create: initialBlock {BlockClosure} 
	with: emulsion {Emulsion} 
	with: name {Symbol} 
	with: class {Class}
	with: actual {FluidVar}
	
	super create: initialBlock with: emulsion with: name with: class.
	actual == nil ifTrue: [self halt].
	myActualFluid := actual! !

!FluidPromiseVar methodsFor: 'accessing'!

fluidSet: newValue
	
	super fluidSet: newValue.
	(newValue == NULL or: [newValue isBroken]) ifTrue:
		[(Smalltalk at: myActualFluid) fluidSet: NULL]
	ifFalse:
		[(Smalltalk at: myActualFluid) fluidSet: newValue actualThing]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FluidPromiseVar class
	instanceVariableNames: ''!



!FluidPromiseVar class methodsFor: 'make'!

make: varName {String} 
	with: initialValueBlock {BlockClosure | nil} 
	with: emulsion {Emulsion}
	with: class {Class}
	with: actual {FluidVar}
	
	(Smalltalk at: varName asSymbol ifAbsent: []) isBehavior 
		ifTrue: [self error: varName, 'cannot be used as a fluid because it conflicts with a class name.'].
	Smalltalk safeAt: varName asSymbol put:
		(self create: initialValueBlock with: emulsion with: varName asSymbol with: class with: actual)! !