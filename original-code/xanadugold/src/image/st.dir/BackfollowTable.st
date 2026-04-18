'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:53 pm'!

ScruTable subclass: #BackfollowTable
	instanceVariableNames: '
		tableInternal {ScruTable}
		valueInternal {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
BackfollowTable comment:
'Note that they also have lazy/dissemination semantics wrt the table from which they were generated.'!

(BackfollowTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowTable methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^tableInternal coordinateSpace!

{IntegerVar} count

	self makeTable.
	^tableInternal count!

{XnRegion} domain

	self makeTable.
	^tableInternal domain!

{Heaper} fetch: key {Position} 

	| value {Heaper} |
	value _ tableInternal fetch: key.
	(value isEqual: valueInternal) ifTrue: [^value] ifFalse: [^NULL]!

{Heaper} intFetch: key {IntegerVar}
	| value {Heaper} |
	value _ tableInternal intFetch: key.
	(value isEqual: valueInternal) ifTrue: [^value] ifFalse: [^NULL]!

{ScruTable} subTable: reg {XnRegion} 

	self makeTable.
	^tableInternal subTable: reg!

{ScruTable} subTableBetween: start {IntegerVar} with: stop {IntegerVar}
	"Return a table which contains the intersection of this table's domain and the 
	domain specified by the enclosure."

	self makeTable.
	^tableInternal subTable: (IntegerRegion make: start with: stop)! !

!BackfollowTable methodsFor: 'creation'!

{ScruTable} copy
	^BackfollowTable create: (tableInternal copy) with: valueInternal!

create: table {ScruTable} with: value {Heaper}
	super create.
	tableInternal _ table.
	valueInternal _ value!

{ScruTable} emptySize: size {IntegerVar}

	^tableInternal emptySize: size! !

!BackfollowTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	^ tableInternal runAt: key!

{XnRegion} runAtInt: key {IntegerVar}
	^ tableInternal runAtInt: key! !

!BackfollowTable methodsFor: 'testing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^ super includesIntKey: aKey!

{BooleanVar} includesKey: aKey {Position}
	self makeTable.
	^ tableInternal includesKey: aKey!

{BooleanVar} isEmpty
	self makeTable.
	^tableInternal isEmpty!

{BooleanVar} isEqual: other {Heaper}
	^other == self! !

!BackfollowTable methodsFor: 'conversion'!

{ImmuTable} asImmuTable

	self unimplemented.
	^NULL!

{MuTable} asMuTable

	self unimplemented.
	^NULL! !

!BackfollowTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	^BackfollowStepper create: (tableInternal stepper: order) with: valueInternal! !

!BackfollowTable methodsFor: 'smalltalk: enumerating'!

{TableStepper} stepper
	^BackfollowStepper create: tableInternal stepper with: valueInternal! !

!BackfollowTable methodsFor: 'private: private'!

{void} makeTable
	| newTab {MuTable} dStep {TableStepper} |
	newTab _ (tableInternal emptySize: tableInternal count) asMuTable.
	(dStep _ tableInternal stepper) forEach: 
		[:elem {Heaper} | 
			(valueInternal isEqual: elem) ifTrue: [newTab at: dStep position introduce: elem]].
	tableInternal destroy.
	tableInternal _ newTab! !

!BackfollowTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	tableInternal _ receiver receiveHeaper.
	valueInternal _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: tableInternal.
	xmtr sendHeaper: valueInternal.! !