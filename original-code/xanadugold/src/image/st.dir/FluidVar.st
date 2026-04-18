'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:19 pm'!

Object subclass: #FluidVar
	instanceVariableNames: '
		myInitBlock {BlockClosure}
		myEmulsion {Emulsion}
		myOffset {Integer}
		myName {Symbol}
		myType {Class}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-fluid'!



!FluidVar methodsFor: 'private: accessing'!

emulsion
	^ myEmulsion! !

!FluidVar methodsFor: 'obsolete'!

fluidVar
	"Return the fluidly bound value."
	^ myEmulsion fluidsSpace at: myOffset! !

!FluidVar methodsFor: 'accessing'!

fluidBind: value during: dynamicBlock
	"Take on new definition during execution of a block, and assure that old value is restored.
	For the benefit of smalltalk only code that may want to use this in an expression, the result of the block evaluation is returned."
	| old oldSpace result |
	old _ self fluidFetch.
	oldSpace _ myEmulsion fetchOldRawSpace.
	self fluidSet: value.
	result _ dynamicBlock
		valueNowOrOnUnwindDo: 
			[self fluidSet: old].
	myEmulsion fetchOldRawSpace == oldSpace assert: 'Emulsion space switched during fluidBind'.
	^ result!

fluidFetch
	"Return the fluidly bound value."
	^ myEmulsion fluidsSpace at: myOffset!

fluidGet
	"Return the fluidly bound value."
	self fluidFetch == NULL ifTrue: [Heaper BLAST: #NULLFluid].
	^self fluidFetch!

fluidSet: newValue
	"self == CurrentPacker ifTrue: [self halt]."
	"assign a new value to the fluid variable"
	myEmulsion fluidsSpace ~~ nil ifTrue: [myEmulsion fluidsSpace at: myOffset put: newValue]!

{void} init
	"called by Emulsion fluidsSpace when a new space is acquired"
	self fluidSet: self initialValue!

{Object} initialValue
	^ myInitBlock ~~ nil ifTrue: [myInitBlock value] ifFalse: [nil].! !

!FluidVar methodsFor: 'create'!

create: initialBlock {BlockClosure} with: emulsion {Emulsion} with: name {Symbol} with: class {Class}
	"This create the first fluid variable within the emulsion"
	super create.
	myInitBlock _ initialBlock.
	emulsion ~~ NULL assert: 'Must have an emulsion'.
	myEmulsion _ emulsion.
	myOffset _ myEmulsion addFluid: self.
	myName _ name.
	myType _ class.! !

!FluidVar methodsFor: 'printing'!

printOn: aStream
	aStream << self getCategory name << '('.
	myEmulsion ~~ nil
	ifTrue:
		[aStream << myEmulsion class << '/' << myName
		<< '{' << myType << '}' << ',  ' << myOffset.
		myOffset ~~ nil
		ifTrue: ["aStream << '->' << (myEmulsion fluidsSpace at: myOffset)"]
		ifFalse: [aStream << '->nil myOffset']]
	ifFalse:
		[aStream << '???????'].
	aStream << ')'! !

!FluidVar methodsFor: 'special'!

goAway
	myEmulsion _ nil.
	myInitBlock _ nil.
	myName ~~ nil ifTrue:
		[Smalltalk safeAt: myName asSymbol put: nil].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FluidVar class
	instanceVariableNames: ''!



!FluidVar class methodsFor: 'cleanup'!

cleanup: varName {Symbol}
	"If there is a fluidVar by the given name, set its value to nil"
	| var |
	var _ Smalltalk at: varName asSymbol ifAbsent: [].
	(var isKindOf: FluidVar)
		ifTrue:
			[(var emulsion isKindOf: Emulsion)
				ifTrue: [var fluidSet: nil]
				ifFalse: [Transcript show: varName asString, ' has no emulsion.']]!

{void} cleanupGarbage
	"Reset all fluid variables to their initial states."
	"FluidVar cleanupGarbage."
	
	FluidVar allInstancesDo: [:fluid |
		fluid emulsion ~~ Emulsion imageEmulsion ifTrue: [fluid goAway]]! !

!FluidVar class methodsFor: 'make'!

make: varName {String} 
	with: initialValueBlock {BlockClosure | nil} 
	with: emulsion {Emulsion}
	with: class {Class}
	
	(Smalltalk at: varName asSymbol ifAbsent: []) isBehavior 
		ifTrue: [self error: varName, 'cannot be used as a fluid because it conflicts with a class name.'].
	Smalltalk safeAt: varName asSymbol put:
		(self create: initialValueBlock with: emulsion with: varName asSymbol with: class)! !

!FluidVar class methodsFor: 'smalltalk: passe'!

make: varName {String}
	
	self passe!

make: varName {String} with: initialValue {Heaper | NULL}
	
	self passe! !