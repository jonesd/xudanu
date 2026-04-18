'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:04 pm'!

Heaper subclass: #InstanceCache
	instanceVariableNames: '
		myArray {PtrArray}
		myTop {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cache'!
InstanceCache comment:
'InstanceCache is intended to store a small number of frequently used objects with the intent of reducing memory allocation traffic.'!

(InstanceCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!InstanceCache methodsFor: 'accessing'!

{Heaper} fetch
	myTop >= Int32Zero
		ifTrue: [
			| result {Heaper} |
			result := myArray fetch: myTop.
			myArray at: myTop store: NULL.
			myTop := myTop - 1.
			^ result]
		ifFalse: [
			^ NULL]!

{BooleanVar} store: object {Heaper}
	myTop < (myArray count - 1)
		ifTrue: [
			myTop := myTop + 1.
			object destruct.
			(SuspendedHeaper new.Become: object) create.
			myArray at: myTop store: object.
			^ true]
		ifFalse: [
			^ false]! !

!InstanceCache methodsFor: 'protected: create'!

create: size {Int32}
	super create.
	myArray := PtrArray nulls: size.
	myTop := -1! !

!InstanceCache methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InstanceCache class
	instanceVariableNames: ''!

(InstanceCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!InstanceCache class methodsFor: 'create'!

make: size {Int32}
	^ self create: size! !