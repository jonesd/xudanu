'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:56 pm'!

MuTable subclass: #IntegerTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
IntegerTable comment:
'The IntegerTable class is used for tables that have arbitrary XuInteger keys in their domain.  Since ScruTable & MuTable already provide all the unboxed versions of the table protocol, there is little need for this class to be a type.  However, this class does provide a bit of extra protocol convenience: highestIndex & lowestIndex. Unless these are retired, we cannot retire this class from type status.
	
	Note that there may be tables with XuInteger keys (i.e., IntegerSpace domains) which are not kinds of IntegerTables.  In particular it is perfectly sensible to create a HashTable with XuInteger keys when the domain region is likely to be sparse.'!

(IntegerTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!IntegerTable methodsFor: 'accessing'!

{void} atInt: key {IntegerVar} introduce: value {Heaper}
	| old {Heaper} |
	(old _ self atInt: key store: value) ~~ NULL
		ifTrue: [self atInt: key store: old. "restore prior condition"
			Heaper BLAST: #AlreadyInTable]!

{void} atInt: key {IntegerVar} replace: value {Heaper} 
	(self atInt: key store: value) == NULL
		ifTrue: [self intWipe: key. "restore prior condition"
			Heaper BLAST: #NotInTable]!

{Heaper} atInt: key {IntegerVar} store: value {Heaper} 

	self subclassResponsibility!

{CoordinateSpace} coordinateSpace

	^IntegerSpace make!

{IntegerVar} count

	self subclassResponsibility!

{XnRegion} domain

	self subclassResponsibility.!

{IntegerVar} highestIndex
	"Given that the table is non-empty, 'intTab->highestIndex()' is equivalent to 
	'CAST(IntegerRegion,intTab->domain())->upperBound() -1'. The reason for the 
	'-1' is that the 'upperBound' is an exclusive upper bound (see 
	IntegerRegion::upperBound), whereas 'highestIndex' is the highest index which is 
	in my domain. I need to here specify what 'highestIndex' does if I am empty."

	self subclassResponsibility!

{Heaper} intFetch: key {IntegerVar} 

	self subclassResponsibility!

{void} intRemove: anIdx {IntegerVar}
	
	(self intWipe: anIdx) ifFalse: [Heaper BLAST: #NotInTable]!

{BooleanVar} intWipe: anIdx {IntegerVar}
	self subclassResponsibility!

{IntegerVar} lowestIndex
	"Given that the table is non-empty, 'intTab->lowestIndex()' is equivalent to 
	'CAST(IntegerRegion,intTab->domain())->lowerBound()'. 'lowestIndex' is the 
	lowest index which is in my domain. I need to here specify what 'lowestIndex' 
	does if I am empty."

	self subclassResponsibility!

{ScruTable} subTable: reg {XnRegion} 

	self subclassResponsibility! !

!IntegerTable methodsFor: 'accessing overloads'!

{void} at: key {Position} introduce: value {Heaper} 

	self atInt: (key cast: IntegerPos) asIntegerVar introduce: value!

{void} at: key {Position} replace: value {Heaper} 

	self atInt: (key cast: IntegerPos) asIntegerVar replace: value!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: (key cast: IntegerPos) asIntegerVar!

{BooleanVar} includesKey: aKey {Position}
	^ self includesIntKey: (aKey cast: IntegerPos) asIntegerVar!

{void} remove: aPos {Position}
	
	self intRemove: (aPos cast: IntegerPos) asIntegerVar!

{XnRegion} runAt: key {Position} 
	^ self runAtInt: (key cast: IntegerPos) asIntegerVar!

{BooleanVar} wipe: anIdx {Position}

	^ self intWipe: ((anIdx cast: IntegerPos) asIntegerVar)! !

!IntegerTable methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility.! !

!IntegerTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	self subclassResponsibility! !

!IntegerTable methodsFor: 'runs'!

{XnRegion} runAtInt: key {IntegerVar}
	self subclassResponsibility! !

!IntegerTable methodsFor: 'creation'!

{ScruTable} copy
	self subclassResponsibility!

create
	"Create a new table with an unspecified number of initial domain positions."
	super create!

{ScruTable} emptySize: size {IntegerVar}

	self subclassResponsibility!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar} 
	"Return a table which contains the elements from start to stop, starting at 
	firstIndex. Zero-based subclasses will blast if firstIndex is non-zero"

	self subclassResponsibility!

{ScruTable} subTableBetween: startIndex {IntegerVar} with: stopIndex {IntegerVar}
	"Hack for C++ overloading problem"
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerTable class
	instanceVariableNames: ''!

(IntegerTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!IntegerTable class methodsFor: 'smalltalk: pseudoConstructors'!

{IntegerTable} make: something {Heaper}
	(something isKindOf: String) 
		ifTrue: [^ self make.charVector: something].
	^ self make.IntegerVar: (something cast: Integer)!

{MuTable} make: from {IntegerVar} with: to {IntegerVar}

	^self make.IntegerVar: from with: to! !

!IntegerTable class methodsFor: 'pseudoConstructors'!

{IntegerTable} make
	"A new empty IntegerTable"
	
	^ ActualIntegerTable create.!

{IntegerTable} make.IntegerVar: someSize {IntegerVar} 
	"A new empty IntegerTable. 'someSize' is a hint about how big the table is likely 
	to need to be ('highestIndex - lowestIndex + 1', not 'count')."

	^ActualIntegerTable create.IntegerVar: someSize!

{IntegerTable} make.IntegerVar: fromIdx {IntegerVar} with: toIdx {IntegerVar} 
	"Hint that the domain's lowerBound (inclusive) will eventually be 'fromIdx', and 
	the domain's upperBound (exclusive) will eventually be 'toIdx'."

	^ActualIntegerTable create: fromIdx with: toIdx!

{IntegerTable} make.Region: reg {IntegerRegion} 
	"Hint that the domain of the new table will eventually be (or at least resemble) 
	'reg'."

	^ActualIntegerTable create: reg start with: reg stop! !

!IntegerTable class methodsFor: 'smalltalk: passe'!

{IntegerTable} make.ScruTable: table {ScruTable} 
	"A new IntegerTable initialized from 'table' in a wierd and screwy way"
	
	"| newTable {IntegerTable} stomp {TableStepper} |
	newTable _ IntegerTable make.IntegerVar: (table count).
	stomp _ table stepper.
	[stomp hasValue] whileTrue:
		[newTable at.IntegerVar: stomp index introduce: (table get.IntegerVar: stomp index).
		stomp step].
	^newTable"
	
	self passe!

{IntegerTable} make.WordArray: wv {MuWordArray}
	"Make a copy of 'wv' as an IntegerTable. The IntegerTable starts out with the 
	same state as 'wv', but unlike 'wv' is not obligated to maintain MuArray 
	constraints."
	self passe.! !