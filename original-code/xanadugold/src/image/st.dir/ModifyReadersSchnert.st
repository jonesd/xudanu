'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:52 pm'!

XnModel subclass: #ModifyReadersSchnert
	instanceVariableNames: '
		myReadersModel {PermissionsModel}
		myReaderB {BooleanModel}
		myEditorB {BooleanModel}
		myPermissionsID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(ModifyReadersSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyReadersSchnert */
friend SPTR(ModifyReadersSchnert)  modifyReadersSchnert (PermissionsModel * readP, BooleanModel * editB, BooleanModel * readB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyReadersSchnert methodsFor: 'private: create'!

create: onPerm {PermissionsModel} with: editB {BooleanModel} with: readB {BooleanModel} with: anID {ID}

	super create.
	myReadersModel _ onPerm.
	myEditorB _ editB.
	myEditorB addDependent: self.
	myReaderB _ readB.
	myReaderB addDependent: self.
	myPermissionsID _ anID!

{void} destruct

	myReaderB removeDependent: self.
	myReadersModel _ NULL.
	myReaderB _ NULL.
	myEditorB _ NULL.
	myPermissionsID _ NULL.
	super destruct! !

!ModifyReadersSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	self updateModel!

{void} updateModel

	myReaderB getValue
		ifTrue: [myEditorB getValue
			ifFalse: [(myReadersModel members hasMember: myPermissionsID)
				ifFalse: [myReadersModel addMember: myPermissionsID]]]
		ifFalse: [(myReadersModel members hasMember: myPermissionsID)
			ifTrue: [myReadersModel removeMember: myPermissionsID]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModifyReadersSchnert class
	instanceVariableNames: ''!

(ModifyReadersSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyReadersSchnert */
friend SPTR(ModifyReadersSchnert)  modifyReadersSchnert (PermissionsModel * readP, BooleanModel * editB, BooleanModel * readB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyReadersSchnert class methodsFor: 'make'!

make: readP {PermissionsModel} with: editB {BooleanModel} with: readB {BooleanModel} with: id {ID}

	^ self create: readP with: editB with: readB with: id! !