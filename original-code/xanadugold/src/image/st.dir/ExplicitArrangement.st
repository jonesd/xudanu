'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:51 pm'!

Arrangement subclass: #ExplicitArrangement
	instanceVariableNames: 'myPositions {PtrArray of: Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(ExplicitArrangement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ExplicitArrangement methodsFor: 'create'!

create: positions {PtrArray of: Position}

	super create.
	myPositions := positions.! !

!ExplicitArrangement methodsFor: 'accessing'!

{IntegerVar} indexOf: position {Position}

	Int32Zero almostTo: myPositions count do: [ :i {Int32} |
		(position isEqual: (myPositions fetch: i)) ifTrue:
			[^i]].
	Heaper BLAST: #NotFound.
	^ -1 "compiler fodder"!

{IntegerRegion} indicesOf: region {XnRegion}

	| result {IntegerRegion} |
	result := IntegerRegion make.
	Int32Zero almostTo: myPositions count do: [ :i {Int32} |
		(region hasMember: ((myPositions fetch: i) cast: Position)) ifTrue:
			[result := (result with: i integer) cast: IntegerRegion]].
	^result!

{XnRegion} keysOf: start {Int32} with: stop {Int32}

	| result {XnRegion} |
	result := NULL.
	start almostTo: stop do: [ :i {Int32} |
		result == NULL ifTrue:
			[result := ((myPositions fetch: i) cast: Position) asRegion]
		ifFalse:
			[result := result with: ((myPositions fetch: i) cast: Position)]].
	result == NULL ifTrue:
		[Heaper BLAST: #IndexOutOfBounds].
	^result!

{XnRegion} region

	| result {XnRegion} |
	result := (myPositions get: Int32Zero) cast: XnRegion.
	1 almostTo: myPositions count do: [ :i {Int32} |
		result := result with: ((myPositions get: i) cast: Position)].
	^result! !

!ExplicitArrangement methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^ myPositions contentsHash!

{UInt32} hashForEqual
	^ myPositions contentsHash!

{BooleanVar} isEqual: other {Heaper}
	other cast: ExplicitArrangement
		  into: [:o {ExplicitArrangement} |
		  	^ myPositions contentsEqual: o positions]
		  others: [^ false ].
	^ false "fodder"! !

!ExplicitArrangement methodsFor: 'private: accessing'!

{PtrArray} positions
	^ myPositions! !

!ExplicitArrangement methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPositions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPositions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExplicitArrangement class
	instanceVariableNames: ''!

(ExplicitArrangement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ExplicitArrangement class methodsFor: 'create'!

{Arrangement} make: positions {PtrArray of: Position} 
	^self create: positions! !