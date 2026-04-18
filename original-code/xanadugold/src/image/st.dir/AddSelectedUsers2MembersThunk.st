'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:59 pm'!

Heaper subclass: #AddSelectedUsers2MembersThunk
	instanceVariableNames: '
		myULPM {ListPaneModel}
		myPM {PermissionsModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(AddSelectedUsers2MembersThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2MembersThunk methodsFor: 'action'!

{void} execute!

{void} invoke! !

!AddSelectedUsers2MembersThunk methodsFor: 'creation'!

create: onPane {ListPaneModel} with: target {PermissionsModel}

	super create.
	myULPM _ onPane.
	myPM _ target! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AddSelectedUsers2MembersThunk class
	instanceVariableNames: ''!

(AddSelectedUsers2MembersThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2MembersThunk class methodsFor: 'make'!

make: onPane {ListPaneModel} with: target {PermissionsModel}

	^ self create: onPane with: target! !