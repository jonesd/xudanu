'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:52 pm'!

LookupTool subclass: #ID2ClubNameLookup
	instanceVariableNames: 'myDirectoryModel {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!

(ID2ClubNameLookup getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2ClubNameLookup methodsFor: 'accessing'!

{Heaper} lookup: item {Heaper} 
	| name {PackOBits} |
	name _ myDirectoryModel fetchName: (item cast: ID).
	name == NULL
		ifTrue: [^Sequence string: 'UNKNOWN']
		ifFalse: [^name]! !

!ID2ClubNameLookup methodsFor: 'creation'!

create: onUDM {UserDirectoryModel}

	super create.
	myDirectoryModel _ onUDM.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ID2ClubNameLookup class
	instanceVariableNames: ''!

(ID2ClubNameLookup getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2ClubNameLookup class methodsFor: 'make'!

make: udm {UserDirectoryModel}

	^ self create: udm! !