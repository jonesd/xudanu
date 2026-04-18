'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:57 pm'!

ScruTable subclass: #MuTable
	instanceVariableNames: ''
	classVariableNames: '
		AlreadyInTableSignal {Signal smalltalk} 
		NotInDomainSignal {Signal smalltalk} 
		NullInsertionSignal {Signal smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
MuTable comment:
'MuTable represents the base class for all side-effectable tables.  It provides the basic change protocol for tables.  See MuSet.'!

(MuTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class MuTable */
friend class COWMuTable;';
	attributes: ((Set new) add: #EQ; add: #DEFERRED; add: #COPY; yourself)!

!MuTable methodsFor: 'accessing'!

{void} at: key {Position} introduce: value {Heaper} 
	"Associate key with value unless key is already associated with another value.  If so, blast."
	| old {Heaper} |
	((old _ self at: key store: value) ~~ NULL)
		ifTrue: [self at: key store: old.
			Heaper BLAST: #AlreadyInTable]!

{void} at: key {Position} replace: value {Heaper} 
	"Associate key with value only if key is already associated with a value.  Otherwise blast."

	((self at: key store: value) == NULL)
		ifTrue: [self wipe: key. "restore table before blast"
			Heaper BLAST: #NotInTable]!

{Heaper} at: key {Position} store: value {Heaper} 
	"Associate value with key, whether or not there is a previous association.
	  Return the old range element if the position was previously occupied, NULL otherwise"

	self subclassResponsibility!

{CoordinateSpace} coordinateSpace
	
	self subclassResponsibility!

{IntegerVar} count

	self subclassResponsibility!

{XnRegion} domain

	self subclassResponsibility.!

{Heaper} fetch: key {Position} 

	self subclassResponsibility!

{void} remove: anIdx {Position}
	"Remove a key->value association from the table.
	 Blast if the key is not present."

	(self wipe: anIdx) ifFalse: [Heaper BLAST: #NotInTable]!

{ScruTable} subTable: reg {XnRegion} 

	self subclassResponsibility!

{BooleanVar} wipe: anIdx {Position}
	"Remove a key->value association from the table.
	 Do not blast (or do anything else) if the key is not in my current domain.
	 Return TRUE if the association was present and removed,
	 Return FALSE if the association was not there"

	self subclassResponsibility! !

!MuTable methodsFor: 'bulk operations'!

{void} introduceAll: table {ScruTable} 
	with: dsp {Dsp default: NULL} 
	with: region {XnRegion default: NULL}
	"'MuTable::introduceAll is to 'MuTable::introduce' as 'MuTable::storeAll' is to 
	'MuTable::store'.  See MuTable::storeAll.  In addition to the functionality 
	provided by MuTable::storeAll, I BLAST *if* all the associations I'm being
	asked to store override existing associations of mine.  If I BLAST for this
	reason, then I guarantee that I haven't changed myself at all."

	"Since this function checks the relavent regions, it can call the potentially 
	more efficient store:"

	(table coordinateSpace isEqual: self coordinateSpace) ifFalse:
		[ Heaper BLAST: #WrongCoordSpace ].
	dsp == NULL
		ifTrue:
			[(self domain intersects: table domain) ifTrue:
				[ Heaper BLAST: #AlreadyInTable ]]
		ifFalse:
			[region == NULL
				ifTrue:
					[(self domain intersects: (dsp ofAll: table domain)) ifTrue:
						[ Heaper BLAST: #AlreadyInTable ]]
				ifFalse:
					[(self domain intersects: (dsp ofAll: (table domain intersect: region))) ifTrue:
						[ Heaper BLAST: #AlreadyInTable ]]].
	self storeAll: table with: dsp with: region!

{void} replaceAll: table {ScruTable} 
	with: dsp {Dsp default: NULL} 
	with: region {XnRegion default: NULL}
	"'MuTable::replaceAll is to 'MuTable::replace' as 'MuTable::storeAll' is to 
	'MuTable::store'.  See MuTable::storeAll.  In addition to the functionality 
	provided by MuTable::storeAll, I BLAST *unless* all the associations I'm being
	asked to store override existing associations of mine.  If I BLAST for this
	reason, then I guarantee that I haven't changed myself at all."

	"Since this function checks the relavent regions, it can call the potentially 
	more efficient store:"
	
	| stepper {TableStepper} |

	(table coordinateSpace isEqual: self coordinateSpace) ifFalse:
		[ Heaper BLAST: #WrongCoordSpace ].
	dsp == NULL
		ifTrue:
			[(table domain isSubsetOf: self domain) ifFalse:
				[ Heaper BLAST: #AlreadyInTable ].
			(stepper _ table stepper) forEach:
				[ :e {Heaper} |
				self at: stepper position store: e]]
		ifFalse:
			[region == NULL
				ifTrue:
					[((dsp ofAll: table domain) isSubsetOf: self domain) ifFalse:
						[ Heaper BLAST: #AlreadyInTable ].
					(stepper _ table stepper) forEach:
						[ :x {Heaper} |
						self at: (dsp of: stepper position) store: x]]
				ifFalse:
					[((dsp ofAll: (table domain intersect: region)) isSubsetOf: self domain) ifFalse:
						[ Heaper BLAST: #AlreadyInTable ].
					(stepper _ (table subTable: region) stepper) forEach:
						[ :y {Heaper} |
						self at: (dsp of: stepper position) store: y]]]!

{void} storeAll: table {ScruTable} 
	with: dsp {Dsp default: NULL} 
	with: region {XnRegion default: NULL}
	"I 'store' into myself (see MuTable::store) all the associations from 'table'.
	If 'region' is provided, then I only store those associations from 'table' whose
	key is inside 'region'.  If 'dsp' is provided, then I transform the keys (from 
	the remaining associations) by dsp before storing into myself."
	
	| stepper {TableStepper} |

	(table coordinateSpace isEqual: self coordinateSpace) ifFalse:
		[ Heaper BLAST: #WrongCoordSpace ].

	dsp == NULL
		ifTrue:
			[(stepper _ table stepper) forEach:
				[ :e {Heaper} |
				self at: stepper position store: e]]
		ifFalse:
			[| localTable {ScruTable} |
			region ~~ NULL ifTrue: [ localTable _ table subTable: region ]
							ifFalse: [ localTable _ table ].
			(stepper _ localTable stepper) forEach:
				[ :x {Heaper} |
				self at: (dsp of: stepper position) store: x]]!

{void} wipeAll: region {XnRegion}
	"I 'wipe' from myself all associations whose key is in 'region'.  See MuTable::wipe"
	
	(region coordinateSpace isEqual: self coordinateSpace) ifFalse:
		[ Heaper BLAST: #WrongCoordSpace ].

	region stepper forEach: [ :p {Position} | self wipe: p]! !

!MuTable methodsFor: 'testing'!

{BooleanVar} includesKey: aKey {Position}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility.! !

!MuTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	self subclassResponsibility! !

!MuTable methodsFor: 'conversion'!

{ImmuTable} asImmuTable

        ^ImmuTableOnMu create: (self copy cast: MuTable)!

{MuTable} asMuTable
	"Note that muTable->asMuTable() returns a copy of the original.  The two
	are now free to change independently."
	
	^self copy quickCast: MuTable! !

!MuTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	self subclassResponsibility! !

!MuTable methodsFor: 'creation'!

{ScruTable} copy
	self subclassResponsibility!

{ScruTable} emptySize: size {IntegerVar}

	self subclassResponsibility! !

!MuTable methodsFor: 'protected: creation'!

create
	"Create a new table with an unspecified number of initial domain positions."
	super create.! !

!MuTable methodsFor: 'overloads'!

{void} atInt: key {IntegerVar} introduce: value {Heaper} 
	"Unboxed version.  See class comment for XuInteger"

	self at: key integer introduce: value!

{void} atInt: key {IntegerVar} replace: value {Heaper} 
	"Unboxed version.  See class comment for XuInteger"

	self at: key integer replace: value!

{Heaper} atInt: aKey {IntegerVar} store: anObject {Heaper}
	"Unboxed version.  See class comment for XuInteger"

	^ self at: aKey integer store: anObject!

{BooleanVar} includesIntKey: aKey {IntegerVar}

	^self includesKey: aKey integer!

{Heaper} intFetch: key {IntegerVar} 
	^ super intFetch: key!

{void} intRemove: anIdx {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"

	self remove: anIdx integer!

{BooleanVar} intWipe: anIdx {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"

	^ self wipe: anIdx integer!

{XnRegion} runAtInt: index {IntegerVar}
	^self runAt: (index integer)! !

!MuTable methodsFor: 'smalltalk: defaults'!

{void} introduceAll: other {ScruTable}
	self introduceAll: other with: NULL with: NULL!

{void} introduceAll: table {ScruTable} with: dsp {Dsp default: NULL} 
	| stepper {TableStepper} |
	(table coordinateSpace isEqual: self coordinateSpace)
		ifFalse: [Heaper BLAST: #WrongCoordSpace].
	(self domain intersects: (dsp ofAll: table domain))
		ifTrue: [Heaper BLAST: #AlreadyInTable].
	dsp == NULL
		ifTrue: [(stepper _ table stepper) forEach: [:d {Heaper} | 
				self at: stepper position introduce: d]]
		ifFalse: [(stepper _ table stepper) forEach: [:e {Heaper} | 
				self at: (dsp of: stepper position) introduce: e]]!

{void} removeAll: region {XnRegion}

	(region coordinateSpace isEqual: self coordinateSpace) ifFalse:
		[ Heaper BLAST: #WrongCoordSpace ].

	(region isSubsetOf: self domain) ifFalse:
		[ Heaper BLAST: #NotInTable ].
		
	region stepper forEach: [ :p {Position} | self remove: p]!

{void} replaceAll: other {ScruTable}
	self replaceAll: other with: NULL with: NULL!

{void} replaceAll: other {ScruTable} with: dsp {Dsp}
	self replaceAll: other with: dsp with: NULL!

{void} storeAll: other {ScruTable}
	self storeAll: other with: NULL with: NULL!

{void} storeAll: table {ScruTable} with: dsp {Dsp default: NULL} 
	| stepper {TableStepper} |
	(table coordinateSpace isEqual: self coordinateSpace)
		ifFalse: [Heaper BLAST: #WrongCoordSpace].
	dsp == NULL
		ifTrue: [(stepper _ table stepper) forEach: [:e {Heaper} | 
				self at: (dsp of: stepper position) store: e]]
		ifFalse: [(stepper _ table stepper) forEach: [:x {Heaper} | 
				self at: stepper position store: x]]! !

!MuTable methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MuTable class
	instanceVariableNames: ''!

(MuTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class MuTable */
friend class COWMuTable;';
	attributes: ((Set new) add: #EQ; add: #DEFERRED; add: #COPY; yourself)!

!MuTable class methodsFor: 'exceptions:'!

problems.AlreadyInTable
	^self signals: #(AlreadyInTable)!

problems.NullInsertion
	^self signals: #(NullInsertion)! !

!MuTable class methodsFor: 'smalltalk: testing'!

test
	"Table test"
	| iTable |
	iTable _ IntegerTable make.
	iTable at: 0 introduce: #zero.
	iTable at: 1 introduce: #one.
	iTable at: 2 introduce: #two.
	iTable at: 3 introduce: #three.
	Transcript show: 'table printing:'; cr.
	Transcript print: iTable; cr; endEntry.! !

!MuTable class methodsFor: 'pseudo constructors'!

{MuTable} make: cs {CoordinateSpace} 
	"A new empty MuTable whose domain space is 'cs'."
	
	(cs isEqual: IntegerSpace make) ifTrue:
		[^IntegerTable make: 10]
	ifFalse: [^HashTable make.CoordinateSpace: cs]!

{MuTable} make: cs {CoordinateSpace} with: reg {XnRegion} 
	"Semantically identical to 'muTable(cs)'.  'reg' just provides a hint as to what
	part of the domain space the new table should expect to be occupied."
	
	(cs isEqual: IntegerSpace make) ifTrue:
		[^IntegerTable make.Region: (reg cast: IntegerRegion)]
	ifFalse: [^HashTable make.CoordinateSpace: cs]! !

!MuTable class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: IntegerSpace. "Used in pseudoconstructor"
	self REQUIRES: IntegerTable.
	self REQUIRES: HashTable.! !