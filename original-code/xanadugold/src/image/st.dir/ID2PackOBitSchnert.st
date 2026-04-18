'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:01 pm'!

XnModel subclass: #ID2PackOBitSchnert
	instanceVariableNames: '
		myUDM {UserDirectoryModel}
		myIDModel {VariableModel of: PackOBits}
		myPackModel {VariableModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(ID2PackOBitSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ID2PackOBitSchnert */
friend SPTR(ID2PackOBitSchnert)  iD2PackOBitSchnert (UserDirectoryModel * udm, VariableModel OF1(ID) * varID, VariableModel OF1(PackOBits) * varPack);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2PackOBitSchnert methodsFor: 'private: creation'!

create: udm {UserDirectoryModel} with: varID {VariableModel of: ID} with: varPack {VariableModel of: PackOBits}

	super create.
	myUDM _ udm.
	myIDModel _ varID.
	myPackModel _ varPack.
	myIDModel addDependent: self.
	self updatePack! !

!ID2PackOBitSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	self updatePack! !

!ID2PackOBitSchnert methodsFor: 'private: updating'!

{void} updatePack
	myIDModel fetchValue == NULL
		ifTrue: [myPackModel setValue: (Sequence string: '')]
		ifFalse: [myPackModel setValue: (myUDM fetchName: (myIDModel fetchValue cast: ID))]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ID2PackOBitSchnert class
	instanceVariableNames: ''!

(ID2PackOBitSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ID2PackOBitSchnert */
friend SPTR(ID2PackOBitSchnert)  iD2PackOBitSchnert (UserDirectoryModel * udm, VariableModel OF1(ID) * varID, VariableModel OF1(PackOBits) * varPack);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2PackOBitSchnert class methodsFor: 'make'!

make: udm {UserDirectoryModel} with: varID {VariableModel of: ID} with: varPack {VariableModel of: PackOBits}

	^ self create: udm with: varID with: varPack! !