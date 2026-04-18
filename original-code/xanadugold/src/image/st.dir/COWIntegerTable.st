'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:54 pm'!

OberIntegerTable subclass: #COWIntegerTable
	instanceVariableNames: '
		myPrev {OberIntegerTable NOCOPY | NULL}
		myTable {OberIntegerTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(COWIntegerTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(MAY.BECOME ActualIntegerTable ); add: #CONCRETE; add: #COPY; yourself)!

!COWIntegerTable methodsFor: 'accessing'!

{Heaper} atInt: aKey {IntegerVar} store: anObject {Heaper}
	self aboutToWrite.
	^ self atInt: aKey store: anObject!

{CoordinateSpace} coordinateSpace
	
	^ myTable coordinateSpace!

{IntegerVar} count

	^ myTable count!

{XnRegion} domain

	^ myTable domain!

{IntegerVar} highestIndex

	^ myTable highestIndex!

{Heaper} intFetch: key {IntegerVar} 

	^myTable intFetch: key!

{BooleanVar} intWipe: anIdx {IntegerVar}
	self aboutToWrite.
	^self intWipe: anIdx!

{IntegerVar} lowestIndex

	^ myTable lowestIndex!

{ScruTable} subTable: reg {XnRegion} 

	^ myTable subTable: reg! !

!COWIntegerTable methodsFor: 'creation'!

{ScruTable} copy
	^ myTable copy!

create: table {OberIntegerTable}
	super create.
	myPrev _ table.
	self setNextCOW: table getNextCOW.
	table setNextCOW: self.
	myTable _ table!

{void} destroy
	"only recover these during GC.  otherwise crashes occur"!

{ScruTable} emptySize: size {IntegerVar}

	^ myTable emptySize: size!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar} 

	^myTable offsetSubTableBetween: startIndex with: stopIndex with: firstIndex!

{ScruTable} subTableBetween: startIndex {IntegerVar} with: stopIndex {IntegerVar}

	^myTable subTableBetween: startIndex with: stopIndex! !

!COWIntegerTable methodsFor: 'runs'!

{XnRegion} runAtInt: index {IntegerVar}
	^myTable runAtInt: index! !

!COWIntegerTable methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}

	^myTable includesIntKey: aKey!

{BooleanVar} isEmpty
	^ myTable isEmpty! !

!COWIntegerTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	^ myTable stepper: order! !

!COWIntegerTable methodsFor: 'COW stuff'!

{OberIntegerTable wimpy} getPrev
	(myPrev ~~ NULL) assert: 'NULL in getPrev'.
	^ myPrev!

{void} setMuTable: table {OberIntegerTable}
	myTable _ table!

{void} setPrev: set {OberIntegerTable}
	myPrev _ set! !

!COWIntegerTable methodsFor: 'private:'!

{PtrArray} elementsArray
	"return the elements array for rapid processing"
	^ myTable elementsArray!

{UInt32} endOffset
	"return the size of the elements array for rapid processing"
	^ myTable endOffset!

{IntegerVar} startIndex
	^ myTable startIndex!

{UInt32} startOffset
	"return the size of the elements array for rapid processing"
	^ myTable startOffset! !

!COWIntegerTable methodsFor: 'protected: COW stuff'!

{void} aboutToWrite
	| prev {OberIntegerTable wimpy} next {COWIntegerTable wimpy} |
	"become a copy of myMuTable and remove myself from all CopyOnWrite dependendents lists.
	The caller's self/this pointer will point to the becomed object after this returns.
	This makes all my caller's look like they are recursive, but they aren't."
	prev _ self getPrev.
	next _ self getNextCOW.
	next ~~ NULL ifTrue: [ next setPrev: prev ].
	prev setNextCOW: next.
	myTable becomeCloneOnWrite: self.!

{void} becomeCloneOnWrite: where {Heaper unused}
	self shouldNotImplement.! !

!COWIntegerTable methodsFor: 'overload junk'!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: (key cast: IntegerPos) asIntegerVar!

{BooleanVar} includesKey: aKey {Position}
	^ self includesIntKey: ((aKey cast: IntegerPos) asIntegerVar)!

{XnRegion} runAt: key {Position} 

	^ self runAtInt: ((key cast: IntegerPos) asIntegerVar)!

{BooleanVar} wipe: key {Position}
	^ self intWipe: (key cast: IntegerPos) asIntegerVar! !

!COWIntegerTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myTable _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myTable.! !