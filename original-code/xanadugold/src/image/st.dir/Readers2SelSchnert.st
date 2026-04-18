'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:54 pm'!

XnModel subclass: #Readers2SelSchnert
	instanceVariableNames: '
		myReadersModel {PermissionsModel}
		myEditorsModel {PermissionsModel}
		myReaderSelection {BooleanModel}
		myReadersList {ScruSet of: ID}
		mySelectionModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(Readers2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Readers2SelSchnert */
friend SPTR(Readers2SelSchnert)  readers2SelSchnert (
		PermissionsModel * edit, 
		PermissionsModel * read, 
		BooleanModel * checkB, 
		BooleanModel * selected, 
		ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Readers2SelSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	self updateModel!

{void} updateModel
	| tmp {ScruSet} |
	tmp _ (myReadersModel members cast: ImmuSet) unionWith: 
		myEditorsModel members.
	mySelectionModel setValue: 
		(myReaderSelection getValue not and: [tmp intersects: myReadersList])! !

!Readers2SelSchnert methodsFor: 'private: create'!

create: editors {PermissionsModel} with: readers {PermissionsModel} with: readSel {BooleanModel} with: model {BooleanModel} with: clubList {ScruSet of: ID}

	super create.
	myEditorsModel _ editors.
	myEditorsModel addDependent: self.
	myReadersModel _ readers.
	myReadersModel addDependent: self.
	myReaderSelection _ readSel.
	myReadersList _ clubList.
	mySelectionModel _ model.
	self updateModel!

{void} destruct

	myEditorsModel removeDependent: self.
	myEditorsModel _ NULL.
	myReadersModel removeDependent: self.
	myReadersModel _ NULL.
	myReadersList _ NULL.
	mySelectionModel _ NULL.
	myReaderSelection _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Readers2SelSchnert class
	instanceVariableNames: ''!

(Readers2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Readers2SelSchnert */
friend SPTR(Readers2SelSchnert)  readers2SelSchnert (
		PermissionsModel * edit, 
		PermissionsModel * read, 
		BooleanModel * checkB, 
		BooleanModel * selected, 
		ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Readers2SelSchnert class methodsFor: 'make'!

make: edit {PermissionsModel} with: read {PermissionsModel} with: checkB {BooleanModel} with: selected {BooleanModel} with: ids {ScruSet of: ID}

	^ self create: edit with: read with: checkB with: selected with: ids! !