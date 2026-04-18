'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:02 pm'!

XnModel subclass: #PackOBit2ATMSchnert
	instanceVariableNames: '
		myPackModel {VariableModel of: PackOBits}
		myATMModel {VariableModel of: AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(PackOBit2ATMSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class PackOBit2ATMSchnert */
friend SPTR(PackOBit2ATMSchnert)  packOBit2ATMSchnert (VariableModel OF1(PackOBits) * packM, VariableModel OF1(AttributedTextModel) * atmM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PackOBit2ATMSchnert methodsFor: 'private: creation'!

create: onPackM {VariableModel of: PackOBits} with: atmM {VariableModel of: AttributedTextModel}

	super create.
	myPackModel _ onPackM.
	myATMModel _ atmM.
	myPackModel addDependent: self! !

!PackOBit2ATMSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}
	self updateATM! !

!PackOBit2ATMSchnert methodsFor: 'private: updating'!

{void} updateATM
	myPackModel fetchValue == NULL
		ifTrue: [myATMModel setValue: NULL]
		ifFalse: [myATMModel setValue: ((myPackModel fetchValue convert: MuWordArray)
					convert: AttributedTextModel)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PackOBit2ATMSchnert class
	instanceVariableNames: ''!

(PackOBit2ATMSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class PackOBit2ATMSchnert */
friend SPTR(PackOBit2ATMSchnert)  packOBit2ATMSchnert (VariableModel OF1(PackOBits) * packM, VariableModel OF1(AttributedTextModel) * atmM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PackOBit2ATMSchnert class methodsFor: 'make'!

make: packM {VariableModel of: PackOBits} with: atmM {VariableModel of: AttributedTextModel}

	^ self create: packM with: atmM! !