'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:45 pm'!

OrderSpec subclass: #CrossOrderSpec
	instanceVariableNames: '
		mySpace {CrossSpace}
		mySubOrders {PtrArray of: OrderSpec}
		myLexOrder {PrimIntArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!
CrossOrderSpec comment:
'myLexOrder lists the lexicographic order in which each dimension should be processed.  Every dimension should be listed exactly one, from most significant (at index 0) to least significant.

mySubOrders are indexed by *dimension*, not by lexicographic order.  In order to index by lex order, look up the dimension in myLexOrder, and then look up the resulting dimension number in mySubOrders.'!

(CrossOrderSpec getOrMakeCxxClassDescription)
	friends:
'friend class GenericCrossSpace;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!CrossOrderSpec methodsFor: 'private: creation'!

create: space {CrossSpace} with: subOrders {PtrArray of: OrderSpec} with: lexOrder {PrimIntArray}

	super create.
	mySpace := space.
	mySubOrders := subOrders.
	myLexOrder := lexOrder! !

!CrossOrderSpec methodsFor: 'accessing'!

{CoordinateSpace INLINE} coordinateSpace
	
	^mySpace!

{PrimIntArray CLIENT} lexOrder
	"Lists the lexicographic order in which each dimension should be processed.  Every dimension is listed exactly once, from most significant (at index 0) to least significant."

	^myLexOrder copy cast: PrimIntArray!

{OrderSpec CLIENT} subOrder: i {Int32}
	"The sub OrderSpec used for the given axis. Note that this is *not* in lex order."
	
	^(mySubOrders fetch: i) cast: OrderSpec!

{PtrArray CLIENT of: OrderSpec} subOrders
	"The sub OrderSpec used for each axis in the space. Note that this is *not* in lex order, but rather indexed by axis number."
	
	^mySubOrders copy cast: PtrArray! !

!CrossOrderSpec methodsFor: 'testing'!

{UInt32} actualHashForEqual

	Someone shouldImplement.
	^UInt32Zero "fodder"!

{BooleanVar} follows: x {Position unused} with: y {Position unused}
	
	MarkM shouldImplement.
	^false "fodder"!

{BooleanVar} isEqual: other {Heaper unused}

	Someone shouldImplement.
	^false "fodder"!

{BooleanVar} isFullOrder: keys {XnRegion unused default: NULL}
	"Essential.  If this returns TRUE, then I define a full order over all positions in 'keys' (or all positions in the space if 'keys' is NULL).  However, if I return FALSE, that doesn't guarantee that I don't define a full ordering.  I may happen to define a full ordering without knowing it.
	
	A full ordering is one in which for each a, b in keys; either this->follows(a, b) or this->follows(b, a)."
	
	Someone shouldImplement.
	^false "fodder"!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}
	"Return true if some position in before is less than or equal to all positions in after."
	
	before cast: GenericCrossRegion into: [ :bc |
	after cast: GenericCrossRegion into: [ :ac |
			Int32Zero almostTo: myLexOrder count do: [ :i {Int32} |
				| dim {Int32} sub {OrderSpec} |
				dim := (myLexOrder integerAt: i) DOTasLong.
				sub := (mySubOrders get: dim) cast: OrderSpec.
				Int32Zero almostTo: bc boxCount do: [ :bi {Int32} | | bp {XnRegion} |
					bp := bc boxProjection: bi with: dim.
					Int32Zero almostTo: ac boxCount do: [ :ai {Int32} | | ap {XnRegion} |
					ap := ac boxProjection: ai with: dim.
					(sub preceeds: bp with: ap) ifTrue: [^true]]]].
				^false]
	others: [self unimplemented]]
	others: [self unimplemented].
	^false "fodder"! !

!CrossOrderSpec methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySpace _ receiver receiveHeaper.
	mySubOrders _ receiver receiveHeaper.
	myLexOrder _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySpace.
	xmtr sendHeaper: mySubOrders.
	xmtr sendHeaper: myLexOrder.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CrossOrderSpec class
	instanceVariableNames: ''!

(CrossOrderSpec getOrMakeCxxClassDescription)
	friends:
'friend class GenericCrossSpace;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!CrossOrderSpec class methodsFor: 'pseudoconstructors'!

make: space {CrossSpace} 
	with: subOrderings {(PtrArray of: OrderSpec | NULL) default: NULL} 
	with: lexOrder {PrimIntArray default: NULL}

	| lexO {PrimIntArray} 
	  subOrders {PtrArray of: OrderSpec} |
	  
	subOrders := PtrArray nulls: space axisCount.
	Int32Zero almostTo: subOrders count do: [:i {Int32} |
		subOrders at: i store: (space axis: i) fetchAscending].
	
	subOrderings ~~ NULL ifTrue:
		[Int32Zero almostTo: subOrders count do: [:i {Int32} |
			| subOrder {OrderSpec | NULL} |
			subOrder := (subOrderings fetch: i) cast: OrderSpec.
			subOrder == NULL ifTrue:
				[(subOrders fetch: i) ~~ NULL assert: 'Must have an ordering from each space']
			ifFalse:
				[subOrders at: i store: subOrder]]].
	
	lexOrder == NULL ifTrue:
		[lexO := PrimIntArray zeros: 32 with: subOrders count.
		Int32Zero almostTo: subOrders count do: [:i {Int32} |
			lexO at: i storeInteger: i]]
	ifFalse:
		[lexO := lexOrder].
	^self create: space with: subOrders with: lexO! !

!CrossOrderSpec class methodsFor: 'smalltalk: defaults'!

make: space
	
	^self make space with: NULL with: NULL!

make: space with: subOrderings
	
	^self make space with: subOrderings with: NULL! !

!CrossOrderSpec class methodsFor: 'private: pseudo constructors'!

{CrossOrderSpec} fetchAscending: space {GenericCrossSpace}
	with: subSpaces {PtrArray of: CoordinateSpace}
	"Only used during construction; must pass the array in explicitly since the space isnt initialized yet"
	
	| result {PtrArray of: OrderSpec} lex {PrimIntArray} |
	result := PtrArray nulls: subSpaces count.
	lex := PrimIntArray zeros: 32 with: subSpaces count.
	Int32Zero almostTo: result count do: [ :dimension {Int32} | | sub {OrderSpec} |
		sub := ((subSpaces fetch: dimension) cast: CoordinateSpace) fetchAscending.
		sub == NULL ifTrue:
			[^NULL].
		result at: dimension store: sub.
		lex at: dimension storeInteger: dimension].
	^self create: space with: result with: lex!

{CrossOrderSpec} fetchDescending: space {GenericCrossSpace}
	with: subSpaces {PtrArray of: CoordinateSpace}
	"Only used during construction; must pass the array in explicitly since the space isnt initialized yet"
	
	| result {PtrArray of: OrderSpec} lex {PrimIntArray} |
	result := PtrArray nulls: subSpaces count.
	lex := PrimIntArray zeros: 32 with: subSpaces count.
	Int32Zero almostTo: result count do: [ :dimension {Int32} | | sub {OrderSpec} |
		sub := ((subSpaces fetch: dimension) cast: CoordinateSpace) fetchAscending.
		sub == NULL ifTrue:
			[^NULL].
		result at: dimension store: sub.
		lex at: dimension storeInteger: dimension].
	^self create: space with: result with: lex! !

!CrossOrderSpec class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Int32Array CLIENT} lexOrder
{OrderSpec CLIENT} subOrder: i {Int32}
{PtrArray CLIENT of: OrderSpec} subOrders
"! !