'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:03 pm'!

Thunk subclass: #UserDirectoryThunk
	instanceVariableNames: 'myUDM {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UserDirectoryThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class UserDirectoryThunk */
friend SPTR(UserDirectoryThunk)  userDirectoryThunk (UserDirectoryModel * udm);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryThunk methodsFor: 'private: create'!

create: onUDM {UserDirectoryModel}

	super create.
	myUDM _ onUDM! !

!UserDirectoryThunk methodsFor: 'operate'!

{void} execute
	"Execute the action defined by this thunk."
	(UDMWindowModel make: myUDM) open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UserDirectoryThunk class
	instanceVariableNames: ''!

(UserDirectoryThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class UserDirectoryThunk */
friend SPTR(UserDirectoryThunk)  userDirectoryThunk (UserDirectoryModel * udm);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryThunk class methodsFor: 'make'!

make: udm {UserDirectoryModel}

	^ self create: udm! !