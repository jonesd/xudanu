'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:55 pm'!

ImmuTable subclass: #ImmuTableOnMu
	instanceVariableNames: 'myMuTable {MuTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(ImmuTableOnMu getOrMakeCxxClassDescription)
	friends:
'friend SPTR(ImmuTable) immuTable (MuTable*);
friend SPTR(ImmuTable) immuTable (CoordinateSpace * cs);
friend SPTR(ImmuTable) MuTable::asImmuTable ();';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!ImmuTableOnMu methodsFor: 'private: instance creation'!

create: aMuTable {MuTable}
	"use the given Mu to store current value"
	"it should be a copy for my exclusive use"
	"this should only be called from the pseudo constructor or from class methods"

	super create.
	myMuTable _ aMuTable! !

!ImmuTableOnMu methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^myMuTable coordinateSpace!

{IntegerVar} count

	^myMuTable count!

{XnRegion} domain

	^myMuTable domain!

{Heaper} fetch: key {Position} 

	^myMuTable fetch: key!

{Heaper} intFetch: key {IntegerVar}
	^myMuTable intFetch: key!

{ScruTable} subTable: region {XnRegion} 

	^ImmuTableOnMu create: ((myMuTable subTable: region) cast: MuTable)! !

!ImmuTableOnMu methodsFor: 'SEF manipulation'!

{ImmuTable} combineWith: other {ImmuTable}

	| newMuTable {MuTable} others {TableStepper} |
	newMuTable _ myMuTable copy cast: MuTable.
	others _ other stepper.
	[others hasValue] whileTrue:
		[newMuTable at: others position store: others fetch.
		others step].
	others destroy.
	^ImmuTableOnMu create: newMuTable!

{ImmuTable} without: index {Position}

	| newMuTable {MuTable} |
	newMuTable _ myMuTable copy cast: MuTable.
	newMuTable wipe: index.
	^ ImmuTableOnMu create: newMuTable! !

!ImmuTableOnMu methodsFor: 'conversion'!

{MuTable} asMuTable

	^myMuTable copy cast: MuTable! !

!ImmuTableOnMu methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^ myMuTable includesIntKey: aKey!

{BooleanVar} includesKey: aKey {Position}
	^ myMuTable includesKey: aKey!

{BooleanVar} isEmpty
	^myMuTable isEmpty! !

!ImmuTableOnMu methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	^myMuTable copy stepper: order	"making the copy prevents anyone from getting access to the array through TableStepper array"!

{Heaper} theOne
	^ myMuTable theOne! !

!ImmuTableOnMu methodsFor: 'private: accessing'!

{MuTable} getMuTable
	^myMuTable! !

!ImmuTableOnMu methodsFor: 'creation'!

{ScruTable} emptySize: size {IntegerVar}

	^ImmuTableOnMu create: ((myMuTable emptySize: size) cast: MuTable)! !

!ImmuTableOnMu methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	^myMuTable runAt: key!

{XnRegion} runAtInt: key {IntegerVar}
	^myMuTable runAtInt: key! !

!ImmuTableOnMu methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myMuTable << ')'! !

!ImmuTableOnMu methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myMuTable _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myMuTable.! !