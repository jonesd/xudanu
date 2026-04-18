'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:20 pm'!

WaldoModel subclass: #DirectoryModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(DirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DirectoryModel methodsFor: 'create'!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	super create: km with: id with: worktype with: phantom! !

!DirectoryModel methodsFor: 'accessing'!

{void} at: name {PackOBits} storeClubID: iD {ID}
	self bertIsGrabbed ifFalse: [self makeEditable].
	self directoryWaldo at: name store: iD!

{ListModel of: ID} clubIDs
	"provide a list of club ids in this directory (suitable for framing)"
	| table {IntegerTable} index {IntegerVar} ids {ScruSet of: ID} |
	index _ IntegerVar0.
	table _ MuArray make.IntegerVar: (ids _ self directoryWaldo clubIDs) count.
	ids stepper forEach: [:id {ID} | 
		table atInt: index introduce: id.
		index _ index + 1].
	^ListModel make: table!

{ListModel of: PackOBits} clubNames
	| table {IntegerTable} index {IntegerVar} names {ScruSet of: PackOBits} |
	index _ IntegerVar0.
	table _ MuArray make.IntegerVar: (names _ self directoryWaldo clubIDs) count.
	names stepper forEach: [:name {PackOBits} | 
		table atInt: index introduce: name.
		index _ index + 1].
	^ListModel make: table!

{ID} fetchClubID: name {PackOBits}
	
	^ self directoryWaldo fetchClubID: name!

{PackOBits} fetchClubName: iD {ID}
	
	^ self directoryWaldo fetchClubName: iD!

{void} removeName: name {PackOBits}
	self bertIsGrabbed ifFalse: [self makeEditable].
	self directoryWaldo wipe: name! !

!DirectoryModel methodsFor: 'protected: accessing'!

{XuDirectory} directoryWaldo
	^ self waldo cast: XuDirectory! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DirectoryModel class
	instanceVariableNames: ''!

(DirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DirectoryModel class methodsFor: 'make'!

make: keyMaster {KeyMaster} 
	^self create: keyMaster with: NULL with: (Sequence string: 'XuDirectory') with: false!

make: km {KeyMaster} with: id {ID} with: phantom {BooleanVar default: false}

	^ self create: km with: id with: (Sequence string: 'XuDirectory') with: phantom! !

!DirectoryModel class methodsFor: 'smalltalk: make'!

make: km {KeyMaster} with: id {ID}

	^ self create: km with: id with: (Sequence string: 'XuDirectory') with: false! !

!DirectoryModel class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	"self REQUIRES: XuDirectory."! !