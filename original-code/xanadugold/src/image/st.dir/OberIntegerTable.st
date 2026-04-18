'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:59 pm'!

IntegerTable subclass: #OberIntegerTable
	instanceVariableNames: 'myNextCOW {COWIntegerTable NOCOPY | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(OberIntegerTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class OberIntegerTable */
friend class ITAscendingStepper;
friend class ITDescendingStepper;
friend class ITGenericStepper;
friend class COWIntegerTable;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!OberIntegerTable methodsFor: 'accessing'!

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

!OberIntegerTable methodsFor: 'creation'!

{ScruTable} copy
	self subclassResponsibility!

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

!OberIntegerTable methodsFor: 'runs'!

{XnRegion} runAtInt: key {IntegerVar}
	self subclassResponsibility! !

!OberIntegerTable methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility.! !

!OberIntegerTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	self subclassResponsibility! !

!OberIntegerTable methodsFor: 'private:'!

{PtrArray} elementsArray
	"return the elements array for rapid processing"
	self subclassResponsibility!

{UInt32} endOffset
	"return the size of the elements array for rapid processing"
	self subclassResponsibility!

{IntegerVar} startIndex
	self subclassResponsibility!

{UInt32} startOffset
	"return the size of the elements array for rapid processing"
	self subclassResponsibility! !

!OberIntegerTable methodsFor: 'protected: create'!

create
	super create.
	myNextCOW _ NULL! !

!OberIntegerTable methodsFor: 'vulnerable: COW stuff'!

{void} aboutToWrite
	| nextCOW {COWIntegerTable wimpy} |
	"make a copy of myself for all outstanding CopyOnWrites on me.
	pass that copy to each of the CopyOnWrite objects.
	One of the COWs gets to become my clone, and the rest point at it."
	nextCOW _ self getNextCOW.
	nextCOW ~~ NULL ifTrue:
		[| cowP {COWIntegerTable wimpy} |
		 self becomeCloneOnWrite: nextCOW.
		 cowP _ nextCOW getNextCOW.
		 [cowP ~~ NULL] whileTrue:
		 	[cowP setMuTable: nextCOW.
		 	cowP _ cowP getNextCOW].
		 self setNextCOW: NULL]!

{void} becomeCloneOnWrite: where {Heaper unused}
	self subclassResponsibility!

{COWIntegerTable wimpy} getNextCOW
	^ myNextCOW!

{void} setNextCOW: table {COWIntegerTable}
	myNextCOW _ table! !

!OberIntegerTable methodsFor: 'overload junk'!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: (key cast: IntegerPos) asIntegerVar!

{BooleanVar} includesKey: aKey {Position}
	^ self includesIntKey: (aKey cast: IntegerPos) asIntegerVar!

{XnRegion} runAt: key {Position} 
	^ self runAtInt: (key cast: IntegerPos) asIntegerVar!

{BooleanVar} wipe: key {Position}
	^ self intWipe: (key cast: IntegerPos) asIntegerVar! !