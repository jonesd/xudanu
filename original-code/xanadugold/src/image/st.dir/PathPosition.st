'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:22 pm'!

UnOrdered subclass: #PathPosition
	instanceVariableNames: '
		myKey {Position}
		mySubKey {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Paths'!
PathPosition comment:
'A PathPosition represents a position in a nested coordinate space, with a key in the outer keySpace, and a subKey in the inner space. The inner space may of course be another PathSpace, and so on...

PathPositions are used in LinkEnds and Waldos to denote paths down from a document to one of it`s sub-documents (or sub-sub-documents, etc.)'!

(PathPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PathPosition methodsFor: 'comparing'!

{UInt32} hashForEqual

	^myKey hashForEqual bitXor: mySubKey hashForEqual!

{BooleanVar} isEqual: other {Heaper} 

	other 
		cast: PathPosition into: [:pp |
			^(pp key isEqual: myKey)
			 and: [pp subKey isEqual: mySubKey]]
		others: [^false]! !

!PathPosition methodsFor: 'accessing'!

{XnRegion} asRegion

	| result {MuTable} |
	result := MuTable make: self key coordinateSpace.
	result at: self key introduce: self subKey.
	^PathRegion make: result asImmuTable!

{CoordinateSpace} coordinateSpace

	^PathSpace make: myKey coordinateSpace!

{Position} fetchBelow: subKey {Position}
	"The position below the first occurrence of the given key. Returns NULL if it is the subKey of the last nested PathRegion. Fails with
		BLAST(NotInPath) if the key does not occur at all"
	
	(myKey isEqual: subKey)
		ifTrue: [^mySubKey].
	mySubKey
		cast: PathPosition into: [:pp |
			^pp fetchBelow: subKey]
		others:
			[(mySubKey isEqual: subKey)
				ifTrue: [^NULL].
			Heaper BLAST: #NotInPath]!

{Position} key
	"The outer key."
	
	^myKey!

{ScruTable of: Position} pathTable
	"A table of the successive keys, including the last subKey. They are stored at consecutive integers, beginning with zero."
	
	| n {IntegerVar} result {MuTable} sub {Position} next {Position} |
	n := IntegerVar0.
	result := MuTable make: IntegerSpace make.
	sub := self.
		[result atInt: n store: sub.
		n := n + 1.
		next := NULL.
		sub cast: PathPosition
			into: [ :pathPos | next := pathPos subKey].
		sub := next.
		sub == NULL ifTrue:
			[^result]] repeat!

{Position} subKey
	"The inner key."
	
	^mySubKey! !

!PathPosition methodsFor: 'create'!

create: key {Position} with: sub {Position}
	super create.
	myKey _ key.
	mySubKey _ sub! !

!PathPosition methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << '[' << myKey << ', ' << mySubKey << ']'! !

!PathPosition methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myKey _ receiver receiveHeaper.
	mySubKey _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myKey.
	xmtr sendHeaper: mySubKey.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PathPosition class
	instanceVariableNames: ''!

(PathPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PathPosition class methodsFor: 'pseudo constructors'!

make: keys {ScruTable of: Position}
	"Given a table of keys, constructs a PathPosition which has the corresponding sequence of nested keys. The table must have at least two contiguous elements, beginning at zero."
	
	| result {PathPosition} | 
	result := PathPosition make: ((keys intGet: keys count - 2) cast: Position)
		with: ((keys intGet: keys count - 1) cast: Position).
	keys count - 3 downTo: IntegerVar0 do: [ :i {IntegerVar} |
		result := PathPosition make: ((keys intGet: i) cast: Position) with: result].
	^result!

make: key {Position} with: subKey {Position}
	^PathPosition create: key with: subKey!

make: key {Position} with: subKey {Position} with: subSubKey {Position}
	^PathPosition make: key with: (PathPosition make: subKey with: subSubKey)!

make: key {Position} with: subKey {Position} with: subSubKey {Position} with: subSubSubKey {Position}
	^PathPosition make: key
		with: (PathPosition make: subKey
			with: (PathPosition make: subSubKey with: subSubSubKey))! !

!PathPosition class methodsFor: 'exceptions: exceptions'!

problems.NotInPath
	^self signals: #(NotInPath)! !