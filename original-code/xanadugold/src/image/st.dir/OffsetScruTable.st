'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:01 pm'!

ScruTable subclass: #OffsetScruTable
	instanceVariableNames: '
		myTable {ScruTable}
		myDsp {Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(OffsetScruTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OffsetScruTable methodsFor: 'accessing'!

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

!OffsetScruTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	(self includesKey: (myDsp inverseOf: key))
		ifTrue: [^ key asRegion]
		ifFalse: [^ myTable coordinateSpace emptyRegion]!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	^myDsp ofAll: (myTable runAtInt: (myDsp inverseOfInt: anIdx))! !

!OffsetScruTable methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.OffsetScruTable hashForEqual + myTable hashForEqual + myDsp hashForEqual!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^myTable includesIntKey: (myDsp inverseOfInt: aKey)!

{BooleanVar} includesKey: aKey {Position}
	
	^ myTable includesKey: (myDsp inverseOf: aKey)!

{BooleanVar} isEmpty
	^myTable isEmpty!

{BooleanVar} isEqual: other {Heaper} 

	other 
		cast: OffsetScruTable into: [:ost |
			^(ost innerTable isEqual: myTable)
			 and: [ost innerTable isEqual: myTable]]
		others: [^false].
	^ false "compiler fodder"! !

!OffsetScruTable methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << myDsp << ', ' << myTable << ')'! !

!OffsetScruTable methodsFor: 'creation'!

{ScruTable} copy
	^ OffsetScruTable create: myTable copy with: myDsp!

create: table {ScruTable} with: dsp {Dsp}
	super create.
	myTable _ table.
	myDsp _ dsp!

{ScruTable} emptySize: size {IntegerVar}

	^ myTable emptySize: size! !

!OffsetScruTable methodsFor: 'conversion'!

{ImmuTable} asImmuTable

	^ OffsetImmuTable create: myTable asImmuTable with: myDsp!

{MuTable} asMuTable
	| newTab {MuTable} s {TableStepper} |
	newTab _ (myTable emptySize: myTable count) asMuTable.
	(s _ myTable stepper) forEach: [ :e {Heaper} |
		newTab at: (myDsp of: s position) store: e].
	^ newTab! !

!OffsetScruTable methodsFor: 'smalltalk: private'!

{TableStepper} stepper

	^ OffsetScruTableStepper create.Stepper: (myTable stepper) with: myDsp! !

!OffsetScruTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL} 

	^OffsetScruTableStepper create.Stepper: (myTable stepper: order) with: myDsp! !

!OffsetScruTable methodsFor: 'private:'!

{Dsp} innerDsp
	^myDsp!

{ScruTable} innerTable
	^myTable! !