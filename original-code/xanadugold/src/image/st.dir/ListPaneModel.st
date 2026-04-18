'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:01 pm'!

Heaper subclass: #ListPaneModel
	instanceVariableNames: '
		mySelection {SelectionObject}
		myNameList {ListModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(ListPaneModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListPaneModel methodsFor: 'creation'!

create: onList {ListModel} with: selection {SelectionObject}

	super create.
	myNameList _ onList.
	selection == NULL
		ifTrue: [mySelection _ ListSelection make: IntegerRegion make]
		ifFalse: [mySelection _ selection]! !

!ListPaneModel methodsFor: 'accessing'!

{ListModel} list

	^ myNameList!

{SelectionObject} selection
	^ mySelection! !

!ListPaneModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' on ' << myNameList! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListPaneModel class
	instanceVariableNames: ''!

(ListPaneModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListPaneModel class methodsFor: 'make'!

make: onList {ListModel} with: sel {SelectionObject default: NULL}

	^ self create: onList with: sel! !

!ListPaneModel class methodsFor: 'smalltalk: make'!

make: onList
	^ self create: onList with: NULL! !