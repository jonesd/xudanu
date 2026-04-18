'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:52 pm'!

XnModel subclass: #ModifyEditorsSchnert
	instanceVariableNames: '
		myPermissionsModel {PermissionsModel}
		myBoolean {BooleanModel}
		myPermissionsID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(ModifyEditorsSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyEditorsSchnert */
friend SPTR(ModifyEditorsSchnert)  modifyEditorsSchnert (PermissionsModel * editP, BooleanModel * editB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyEditorsSchnert methodsFor: 'private: create'!

create: onPerm {PermissionsModel} with: onBool2Watch {BooleanModel} with: anID {ID}

	super create.
	myPermissionsModel _ onPerm.
	myBoolean _ onBool2Watch.
	myBoolean addDependent: self.
	myPermissionsID _ anID!

{void} destruct

	myBoolean removeDependent: self.
	myPermissionsModel _ NULL.
	myBoolean _ NULL.
	myPermissionsID _ NULL.
	super destruct! !

!ModifyEditorsSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	self updateModel!

{void} updateModel

	myBoolean getValue
		ifTrue: [(myPermissionsModel members hasMember: myPermissionsID)
			ifFalse: [myPermissionsModel addMember: myPermissionsID]]
		ifFalse: [(myPermissionsModel members hasMember: myPermissionsID)
			ifTrue: [myPermissionsModel removeMember: myPermissionsID]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModifyEditorsSchnert class
	instanceVariableNames: ''!

(ModifyEditorsSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyEditorsSchnert */
friend SPTR(ModifyEditorsSchnert)  modifyEditorsSchnert (PermissionsModel * editP, BooleanModel * editB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyEditorsSchnert class methodsFor: 'make'!

make: editP {PermissionsModel} with: editB {BooleanModel} with: id {ID}

	^ self create: editP with: editB with: id! !