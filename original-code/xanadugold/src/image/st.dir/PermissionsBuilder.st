'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:53 pm'!

FMBuilder subclass: #PermissionsBuilder
	instanceVariableNames: 'myUserDirectory {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(PermissionsBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsBuilder methodsFor: 'create'!

create: ud {UserDirectoryModel}

	super create.
	myUserDirectory _ ud! !

!PermissionsBuilder methodsFor: 'private: build'!

{FMScaffold} scaffold: pp {Pair}
 
	| scafTab {MuTable} |
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: UInt8Array) 
		introduce: (PermissionSelectBuilder make: pp with: myUserDirectory).
	scafTab at: (HeaperAsPosition make: ListModel)
		introduce: (FMListBuilder make: (BoundingListComp make: ListStyle defaultVertical)).
	^ FMScaffold make: scafTab with: Scaffold fluidGet! !

!PermissionsBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 

	| myListB {FMBuilding} |
	Scaffold fluidBind: (self scaffold: (obj cast: Pair)) during: [
		myListB _ Scaffold fluidGet build: myUserDirectory clubIDs].
	^ myListB! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionsBuilder class
	instanceVariableNames: ''!

(PermissionsBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsBuilder class methodsFor: 'make'!

make: onDir {UserDirectoryModel}

	^ self create: onDir! !