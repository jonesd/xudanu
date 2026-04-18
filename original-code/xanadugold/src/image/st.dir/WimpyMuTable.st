'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:34 pm'!

MuTable subclass: #WimpyMuTable
	instanceVariableNames: 'myTable {MuTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Wimpy'!
WimpyMuTable comment:
'Note that this is not a COPY class.  Wimpy COPY collections are guaranteed to break if a GC happens
while they are being received.'!

(WimpyMuTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!WimpyMuTable methodsFor: 'accessing'!

{Heaper} at: key {Position} store: value {Heaper} 

	 | cell {Heaper} |
	cell _ WimpyCell create: value.
	^myTable at: key store: cell!

{CoordinateSpace} coordinateSpace
	
	^myTable coordinateSpace!

{IntegerVar} count

	^myTable count!

{XnRegion} domain

	^myTable domain!

{Heaper} fetch: key {Position} 
	
	| result {Heaper} |
	result _ myTable fetch: key.
	result ~~ NULL ifTrue: [result _ (result cast: WimpyCell) value].
	^result!

{XnRegion} runAtInt: index {IntegerVar}
	
	^super runAtInt: index!

{ScruTable} subTable: reg {XnRegion} 

	^WimpyMuTable create: ((myTable subTable: reg) cast: MuTable)!

{ScruTable} transformedBy: dsp {Dsp} 

	^WimpyMuTable create: ((myTable transformedBy: dsp) cast: MuTable)!

{BooleanVar} wipe: key {Position}

	^ myTable wipe: key.! !

!WimpyMuTable methodsFor: 'creation'!

{ScruTable} copy
	^WimpyMuTable create: (myTable copy cast: MuTable)!

create: table {MuTable}
	super create.
	myTable _ table!

{ScruTable} emptySize: size {IntegerVar}

	^WimpyMuTable create: ((myTable emptySize: size) cast: MuTable)! !

!WimpyMuTable methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^myTable includesIntKey: aKey!

{BooleanVar} includesKey: aKey {Position}
	^myTable includesKey: aKey!

{BooleanVar} isEmpty
	^myTable isEmpty! !

!WimpyMuTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	^myTable runAt: key! !

!WimpyMuTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	^WimpyTableStepper create: (myTable stepper: order)! !

!WimpyMuTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myTable _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myTable.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WimpyMuTable class
	instanceVariableNames: ''!

(WimpyMuTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!WimpyMuTable class methodsFor: 'pseudo-constructors'!

make: table {MuTable}
	^self create: table! !