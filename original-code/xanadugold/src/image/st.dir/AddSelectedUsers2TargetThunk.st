'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:00 pm'!

Heaper subclass: #AddSelectedUsers2TargetThunk
	instanceVariableNames: '
		myULPM {ListPaneModel}
		myUDM {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(AddSelectedUsers2TargetThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2TargetThunk methodsFor: 'creation'!

create: onPane {ListPaneModel} with: target {UserDirectoryModel}

	super create.
	myULPM _ onPane.
	myUDM _ target! !

!AddSelectedUsers2TargetThunk methodsFor: 'action'!

{void} execute!

{void} invoke! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AddSelectedUsers2TargetThunk class
	instanceVariableNames: ''!

(AddSelectedUsers2TargetThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2TargetThunk class methodsFor: 'make'!

make: onPane {ListPaneModel} with: target {UserDirectoryModel}

	^ self create: onPane with: target! !