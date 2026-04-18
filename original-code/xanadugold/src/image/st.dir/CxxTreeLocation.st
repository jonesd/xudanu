'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:35 pm'!

Object subclass: #CxxTreeLocation
	instanceVariableNames: 'turns {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-File Organization'!



!CxxTreeLocation methodsFor: 'accessing'!

{IntegerVar} count
	^ turns size!

{OrderedCollection of: Symbol} turns
	^ turns asOrderedCollection! !

!CxxTreeLocation methodsFor: 'alteration'!

{void} addFirst: aTurn {String}

	turns := (Array with: aTurn asSymbol) , turns!

{void} addLast: aTurn {String}

	turns := turns , (Array with: aTurn asSymbol)! !

!CxxTreeLocation methodsFor: 'creation'!

create
	turns _ #()!

create.String: firstTurn {String}
	turns _ Array with: firstTurn asSymbol! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxTreeLocation class
	instanceVariableNames: ''!



!CxxTreeLocation class methodsFor: 'creation'!

create.String: aStr
	^ self new create.String: aStr!

make
	^ self new create!

make.String: aString {String}
	^ self create.String: aString! !