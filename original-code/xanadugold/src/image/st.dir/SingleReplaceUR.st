'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:16 pm'!

UpdateRecord subclass: #SingleReplaceUR
	instanceVariableNames: '
		oldValueInternal {Heaper}
		newValueInternal {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
SingleReplaceUR comment:
'This is the update record for VariableModels in which one value gets replaced.'!

(SingleReplaceUR getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SingleReplaceUR methodsFor: 'create'!

create: oldValue{Heaper} with: newValue{Heaper}
	super create.
	oldValueInternal _ oldValue.
	newValueInternal _ newValue! !

!SingleReplaceUR methodsFor: 'accessing'!

{Heaper} newValue
	^newValueInternal!

{Heaper} oldValue
	^oldValueInternal! !

!SingleReplaceUR methodsFor: 'protected: creation'!

{void} destruct
	oldValueInternal _ newValueInternal _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SingleReplaceUR class
	instanceVariableNames: ''!

(SingleReplaceUR getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SingleReplaceUR class methodsFor: 'make'!

make: before {Heaper} with: after {Heaper}
	^self create: before with: after! !