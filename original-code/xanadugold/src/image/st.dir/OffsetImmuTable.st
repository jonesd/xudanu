'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:00 pm'!

ImmuTable subclass: #OffsetImmuTable
	instanceVariableNames: '
		myTable {ImmuTable}
		myDsp {Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(OffsetImmuTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OffsetImmuTable methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^myTable coordinateSpace!

{IntegerVar} count

	^myTable count!

{XnRegion} domain

	^myDsp ofAll: myTable domain!

{Heaper} fetch: anIndex {Position} 

	^myTable intFetch: (myDsp inverseOfInt: (anIndex cast: IntegerPos) asIntegerVar)!

{Heaper} intFetch: idx {IntegerVar} 
	^myTable intFetch: (myDsp inverseOfInt: idx)!

{ScruTable} subTable: encl {XnRegion}

	^OffsetScruTable create: (myTable subTable: (myDsp inverseOfAll: encl)) with: myDsp.!

{ScruTable} transformedBy: dsp {Dsp} 

	(myDsp inverse isEqual: dsp) 
		ifTrue: [^myTable]
		ifFalse: [^OffsetScruTable create: myTable with: (dsp compose: myDsp)]! !

!OffsetImmuTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	(self includesKey: (myDsp inverseOf: key))
		ifTrue: [^ key asRegion]
		ifFalse: [^ myTable coordinateSpace emptyRegion]!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	^myDsp ofAll: (myTable runAtInt: (myDsp inverseOfInt: anIdx))! !

!OffsetImmuTable methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.OffsetImmuTable hashForEqual + myTable hashForEqual + myDsp hashForEqual!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^myTable includesIntKey: (myDsp inverseOfInt: aKey)!

{BooleanVar} includesKey: aKey {Position}
	
	^ myTable includesKey: (myDsp inverseOf: aKey)!

{BooleanVar} isEmpty
	^myTable isEmpty! !

!OffsetImmuTable methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << myDsp << ', ' << myTable << ')'! !

!OffsetImmuTable methodsFor: 'creation'!

create: table {ImmuTable} with: dsp {Dsp}
	super create.
	myTable _ table.
	myDsp _ dsp!

{ScruTable} emptySize: size {IntegerVar}

	^ myTable emptySize: size! !

!OffsetImmuTable methodsFor: 'conversion'!

{MuTable} asMuTable
	| newTab {MuTable} s {TableStepper} |
	newTab _ (myTable emptySize: myTable count) asMuTable.
	(s _ myTable stepper) forEach: [ :e {Heaper} |
		newTab at: (myDsp of: s position) store: e].
	^ newTab! !

!OffsetImmuTable methodsFor: 'smalltalk: private:'!

{TableStepper} stepper

	^ OffsetScruTableStepper create.Stepper: (myTable stepper) with: myDsp! !

!OffsetImmuTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL} 

	^OffsetScruTableStepper create.Stepper: (myTable stepper: order) with: myDsp! !

!OffsetImmuTable methodsFor: 'private: private'!

{Dsp} innerDsp
	^myDsp!

{ScruTable} innerTable
	^myTable! !

!OffsetImmuTable methodsFor: 'SEF manipulation'!

{ImmuTable} combineWith: other {ImmuTable}

	| newTable {MuTable} others {TableStepper} |
	newTable _ myTable copy asMuTable.
	others _ other stepper.
	[others hasValue] whileTrue:
		[newTable at: (myDsp inverseOf: others position) store: others fetch.
		others step].
	others destroy.
	^OffsetImmuTable create: newTable asImmuTable with: myDsp!

{ImmuTable} without: index {Position} 

	^OffsetImmuTable create: (myTable without: (myDsp inverseOf: index)) with: myDsp! !