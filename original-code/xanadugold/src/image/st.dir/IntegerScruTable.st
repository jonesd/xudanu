'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:56 pm'!

ScruTable subclass: #IntegerScruTable
	instanceVariableNames: 'tableToScru {IntegerTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(IntegerScruTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!IntegerScruTable methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^IntegerSpace make!

{IntegerVar} count

	^tableToScru count!

{XnRegion} domain

	^ tableToScru domain!

{Heaper} fetch: key {Position} 

	^ tableToScru fetch: key!

{Heaper} intFetch: key {IntegerVar}
	^ tableToScru intFetch: key!

{ScruTable} subTable: reg {XnRegion} 

	^ tableToScru subTable: reg!

{ScruTable} subTableBetween: start {IntegerVar} with: stop {IntegerVar}
	"Return a table which contains the intersection of this table's domain and the 
	domain specified by the enclosure."

	^ tableToScru offsetSubTableBetween: start with: stop with: start! !

!IntegerScruTable methodsFor: 'creation'!

{ScruTable} copy
	^ IntegerScruTable create: ((tableToScru copy) quickCast: IntegerTable)!

create: fromTable {IntegerTable}
	super create.
	tableToScru _ fromTable!

{ScruTable} emptySize: size {IntegerVar}

	^ IntegerScruTable create.IntegerVar: ((tableToScru emptySize: size) quickCast: IntegerTable)! !

!IntegerScruTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	^ tableToScru runAt: key!

{XnRegion} runAtInt: key {IntegerVar}
	^ tableToScru runAtInt: key! !

!IntegerScruTable methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.IntegerScruTable hashForEqual + tableToScru hashForEqual!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^ tableToScru includesIntKey: aKey!

{BooleanVar} includesKey: aKey {Position}
	^ tableToScru includesKey: aKey!

{BooleanVar} isEmpty
	^ tableToScru isEmpty!

{BooleanVar} isEqual: other {Heaper} 

	other
		cast: IntegerScruTable into: [:ist |
			^ist innerTable isEqual: tableToScru]
		others: [^false].
	^ false "compiler fodder"! !

!IntegerScruTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	^ tableToScru stepper: order! !

!IntegerScruTable methodsFor: 'conversion'!

{ImmuTable} asImmuTable

	^ tableToScru asImmuTable!

{MuTable} asMuTable

	^ tableToScru copy asMuTable! !

!IntegerScruTable methodsFor: 'private: private'!

{ScruTable} innerTable
	^tableToScru! !

!IntegerScruTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	tableToScru _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: tableToScru.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerScruTable class
	instanceVariableNames: ''!

(IntegerScruTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!IntegerScruTable class methodsFor: 'pseudo constructors'!

{ScruTable} make: fromTable {IntegerTable}
	^ IntegerScruTable create: fromTable! !