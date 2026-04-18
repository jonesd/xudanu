'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:55 pm'!

XnDependent subclass: #Waldo2SubListSchnert
	instanceVariableNames: '
		myRecord {WaldoModel of: IndexedWaldo}
		myKey {Position}
		mySubList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
Waldo2SubListSchnert comment:
'Maintains a list that is kept in a subwaldo'!

(Waldo2SubListSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubListSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	model == (myRecord basicCast: XnModel) ifTrue: [self updateSubList]! !

!Waldo2SubListSchnert methodsFor: 'create'!

create: record {WaldoModel of: IndexedWaldo} with: key {Position} with: subList {ListModel}
	super create.
	myRecord _ record.
	myKey _ key.
	mySubList _ subList.
	myRecord addDependent: self.
	self updateSubList! !

!Waldo2SubListSchnert methodsFor: 'protected: creation'!

{void} destruct
	myRecord removeDependent: self.
	super destruct! !

!Waldo2SubListSchnert methodsFor: 'private: updating'!

{void} updateSubList 
	(mySubList cast: WaldoListModel) replaceWith: (((myRecord waldo cast: IndexedWaldo)
		get: myKey) cast: IndexedWaldo)! !

!Waldo2SubListSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	      << 'myRecord = '  << myRecord  
		      << 'myKey = '   << myKey  
		 << 'mySubList = ' << mySubList! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Waldo2SubListSchnert class
	instanceVariableNames: ''!

(Waldo2SubListSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubListSchnert class methodsFor: 'make'!

make: record {WaldoModel of: IndexedWaldo} with: key {Position} with: subList {ListModel}
	^self create: record with: key with: subList! !