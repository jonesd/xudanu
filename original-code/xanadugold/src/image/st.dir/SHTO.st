'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:51 pm'!

Heaper subclass: #SHTO
	instanceVariableNames: '
		myHashValue {UInt4}
		myStringValue {Sequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-set'!
SHTO comment:
'SHTO (SpecialHashTestObject) is used for testing hash sets.  It stores an identifying string, along with the hash that it is to return.  This allows a) system independent testing - as the hash will be the same in all test output files, and b) provides for testing complex hash value interactions with spending years looking for the right objects to generate critical hash values.'!

(SHTO getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SHTO methodsFor: 'tests'!

{UInt32} actualHashForEqual

	^ myHashValue!

{BooleanVar} isEqual: other {Heaper} 
	other cast: SHTO
		into: [:foo {SHTO} |
			^myHashValue = foo hashForEqual and: [myStringValue isEqual: foo stringValue]]
		others: [
			^false].
	^false "fodder"! !

!SHTO methodsFor: 'creation'!

create: onString {Sequence} with: onHash {UInt32}

	super create.
	myStringValue _ onString.
	myHashValue _ onHash! !

!SHTO methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('.
	[myHashValue printOn: oo base: 16] smalltalkOnly.
	'{
		char	buffer[9];
		sprintf(buffer, "%X", myHashValue);
		oo << buffer;
	}' translateOnly.
	oo << ', ' << myStringValue << ')'! !

!SHTO methodsFor: 'private: accessing'!

{Sequence} stringValue
	^ myStringValue! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SHTO class
	instanceVariableNames: ''!

(SHTO getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SHTO class methodsFor: 'make'!

make: aString {char vector} with: aHashVal {UInt32}
	| pack {Sequence} |
	pack _ Sequence string: aString.
	^ self create: pack with: aHashVal! !