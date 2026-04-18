'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:00 pm'!

XnModel subclass: #ClubManagerPaneModel
	instanceVariableNames: '
		myClubID {VariableModel of: PackOBits}
		myUDM {UserDirectoryModel}
		myPermissionsModel {PermissionsModel}
		myNamePack {VariableModel of: PackOBits}
		myNameText {VariableModel of: AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(ClubManagerPaneModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ClubManagerPaneModel methodsFor: 'accessing'!

{Sequence} namePack

	^Sequence numbers: ((myNameText getValue cast: AttributedTextModel)
			asArray cast: PrimIntegerArray)!

{UserDirectoryModel} userDirectoryModel
	^ myUDM! !

!ClubManagerPaneModel methodsFor: 'private: building'!

{FMScaffold} nameScaffold 
	| scafTab {MuTable} |
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: SelectedTextModel)
		introduce: (FMTextEditBuilder make).
	scafTab at: (HeaperAsPosition make: AttributedTextModel)
		introduce: (STMBuilder make).
	^FMScaffold make: scafTab with: Scaffold fluidGet! !

!ClubManagerPaneModel methodsFor: 'buildings'!

{FMBuilding} building
	^ self nameEditBuilding!

{FMBuilding} nameEditBuilding
	| build {FMBuilding} | 
	Scaffold fluidBind: self nameScaffold during: 
		[build _ Scaffold  fluidGet build: (myNameText convert: AttributedTextModel)].
	^build! !

!ClubManagerPaneModel methodsFor: 'creation'!

create: onUDM {UserDirectoryModel} with: idM {VariableModel of: ID}
	super create.
	myUDM _ onUDM.
	myClubID _ idM.
	myClubID addDependent: self.
	myPermissionsModel _ NULL.
	myNamePack _ VariableModel make.
	myNameText _ VariableModel make.
	PackOBit2ATMSchnert make: myNamePack with: myNameText.
	ID2PackOBitSchnert make: myUDM with: myClubID with: myNamePack.! !

!ClubManagerPaneModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	myClubID fetchValue == NULL
		ifTrue: [myPermissionsModel _ NULL.
			myNamePack setValue: (Sequence string: '')]
		ifFalse: [myPermissionsModel ~~ NULL 
			ifTrue: [(myPermissionsModel iD isEqual: (myClubID getValue cast: ID))
					ifFalse: [myPermissionsModel _ NULL]].
			myPermissionsModel _ PermissionsModel 
							fetchPermissionsModel: myUDM keyMaster 
							with: (myClubID getValue cast: ID)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClubManagerPaneModel class
	instanceVariableNames: ''!

(ClubManagerPaneModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ClubManagerPaneModel class methodsFor: 'make'!

make: onUDM {UserDirectoryModel} with: idM {VariableModel of: ID}

	idM == NULL	
		ifTrue: [^ self create: onUDM with: (VariableModel make)]
		ifFalse: [^ self create: onUDM with: idM]! !

!ClubManagerPaneModel class methodsFor: 'smalltalk: make'!

make: onUDM {UserDirectoryModel}
	^ self make: onUDM with: NULL! !