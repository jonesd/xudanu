'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:55 pm'!

XnDependent subclass: #Waldo2ValueSchnert
	instanceVariableNames: '
		myRecord {WaldoModel of: IndexedWaldo}
		myKey {Position}
		myValue {VariableModel}
		myConvertCategory {Category star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
Waldo2ValueSchnert comment:
'Maintains a value that is kept in a slot of a indexed waldo'!

(Waldo2ValueSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2ValueSchnert methodsFor: 'private: updating'!

{void} updateValue
	| aVal {Heaper} res {Heaper} |
	aVal _ (myRecord waldo cast: IndexedWaldo) get: myKey.
	myConvertCategory ~~ NULL 
		ifTrue: [res _ Converter getConversion: myConvertCategory with: aVal]
		ifFalse: [res _ aVal].
	myValue setValue: res! !

!Waldo2ValueSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	model == (myRecord basicCast: XnModel) ifTrue: [self updateValue]! !

!Waldo2ValueSchnert methodsFor: 'create'!

create: record {WaldoModel of: IndexedWaldo} with: key {Position} with: value {VariableModel} with: convertCat {Category star}
	super create.
	myRecord _ record.
	myKey _ key.
	myValue _ value.
	myRecord addDependent: self.
	myConvertCategory _ convertCat.
	self updateValue! !

!Waldo2ValueSchnert methodsFor: 'protected: creation'!

{void} destruct
	myRecord removeDependent: self.
	super destruct! !

!Waldo2ValueSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
			<< ' myRecord = ' << myRecord << '
	myKey = '  << myKey << '
	myValue = ' << myValue.
	myConvertCategory ~~ NULL ifTrue: [aStream << '
	converting value to ' << myConvertCategory]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Waldo2ValueSchnert class
	instanceVariableNames: ''!

(Waldo2ValueSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2ValueSchnert class methodsFor: 'make'!

make: record {WaldoModel of: IndexedWaldo} with: key {Position} with: value {VariableModel} with: convertTo {Category star default: NULL}
	^self create: record with: key with: value with: convertTo! !

!Waldo2ValueSchnert class methodsFor: 'smalltalk: defaults'!

make: record {WaldoModel of: IndexedWaldo} with: key {Position} with: value {VariableModel}
	^self create: record with: key with: value with: NULL! !