'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:04 pm'!

XnModel subclass: #ID2LockSchnert
	instanceVariableNames: '
		myKeyMaster {KeyMaster}
		myIDModel {VariableModel of: PackOBits}
		myLockModel {VariableModel of: Lock}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-loginpn'!
ID2LockSchnert comment:
'This schnert watches an ID model and gets the corresponding lock for a user of that ID'!

(ID2LockSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!ID2LockSchnert methodsFor: 'create'!

create: km {KeyMaster} with: onIDModel {VariableModel of: ID} with: lockModel {VariableModel of: Lock}

	super create.
	myKeyMaster _ km.
	myIDModel _ onIDModel.
	myIDModel addDependent: self.
	myLockModel _ lockModel!

{void} destruct

	myIDModel removeDependent: self.
	myIDModel _ NULL.
	myLockModel _ NULL.
	myKeyMaster _ NULL.
	super destruct! !

!ID2LockSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	| anID {ID} |
	[VariableModel] USES.
	anID _ (myIDModel fetchValue cast: ID).
	anID == NULL ifTrue: [myLockModel setValue: NULL.
		^ VOID].
	myLockModel setValue: (XuServer currentServer login: anID)! !

!ID2LockSchnert methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ID2LockSchnert class
	instanceVariableNames: ''!

(ID2LockSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!ID2LockSchnert class methodsFor: 'make'!

make: km {KeyMaster} with: onIDModel {VariableModel of: ID} with: lockModel {VariableModel of: Lock}

	^ self create: km with: onIDModel with: lockModel! !