'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:54 pm'!

XnModel subclass: #User2DefaultPermissionSchnert
	instanceVariableNames: '
		myUser {UserModel}
		myDefault {VariableModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
User2DefaultPermissionSchnert comment:
'Retrieve the user''s default permissions from the profile information

		myUser {UserModel}
		myDefault {VariableModel of: PackOBits}'!

(User2DefaultPermissionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2DefaultPermissionSchnert methodsFor: 'create'!

create: who {UserModel} with: def {VariableModel of: ID}
	super create.
	myUser _ who.
	myDefault _ def.
	who addDependent: self.
	self updateDefault! !

!User2DefaultPermissionSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	"change the default permissions"

	model == (myUser basicCast: XnModel) ifTrue: [self updateDefault]! !

!User2DefaultPermissionSchnert methodsFor: 'private: private updating'!

{void} updateDefault
	myDefault setValue: myUser keyMaster userID! !

!User2DefaultPermissionSchnert methodsFor: 'protected: creation'!

{void} destruct
	myUser removeDependent: self.
	super destruct! !

!User2DefaultPermissionSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	
	<< ' myUser = ' << myUser 
	<<	'myDefault = ' << myUser! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

User2DefaultPermissionSchnert class
	instanceVariableNames: ''!

(User2DefaultPermissionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2DefaultPermissionSchnert class methodsFor: 'make'!

make: who {UserModel} with: def {VariableModel of: ID}
	^self create: who with: def! !