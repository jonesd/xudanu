'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:52 pm'!

XnModel subclass: #Editors2SelSchnert
	instanceVariableNames: '
		myEditorsModel {PermissionsModel}
		myEditorSelection {BooleanModel}
		myEditorsList {ScruSet of: PackOBits}
		mySelectionModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!
Editors2SelSchnert comment:
'This schnert is used look at an editors permission model and detect when any of a list of possible editors are permitted to edit.  The schnert updates a boolean model to reflect the permissions.'!

(Editors2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Editors2SelSchnert */
friend SPTR(Editors2SelSchnert)  editors2SelSchnert (PermissionsModel * pm, BooleanModel * checkB, BooleanModel * selected, ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Editors2SelSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	self updateModel!

{void} updateModel
	| tmp {BooleanVar} |
	tmp _ myEditorsModel members intersects: myEditorsList.
	tmp _ tmp and: [myEditorSelection getValue not].
	mySelectionModel setValue: tmp! !

!Editors2SelSchnert methodsFor: 'private: create'!

create: editors {PermissionsModel} with: editSel {BooleanModel} with: model {BooleanModel} with: clubList {ScruSet of: ID}

	super create.
	myEditorsModel _ editors.
	myEditorsModel addDependent: self.
	myEditorSelection _ editSel.
	myEditorsList _ clubList.
	mySelectionModel _ model.
	self updateModel!

{void} destruct

	myEditorsModel removeDependent: self.
	myEditorsModel _ NULL.
	myEditorsList _ NULL.
	mySelectionModel _ NULL.
	myEditorSelection _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Editors2SelSchnert class
	instanceVariableNames: ''!

(Editors2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Editors2SelSchnert */
friend SPTR(Editors2SelSchnert)  editors2SelSchnert (PermissionsModel * pm, BooleanModel * checkB, BooleanModel * selected, ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Editors2SelSchnert class methodsFor: 'make'!

make: pm {PermissionsModel} with: checkB {BooleanModel} with: selected {BooleanModel} with: ids {ScruSet of: ID}

	^ self create: pm with: checkB with: selected with: ids! !