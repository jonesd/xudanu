'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:04 pm'!

CompositeRegion subclass: #CompositeSliceRegion
	instanceVariableNames: '
		myKey {Position}
		myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeSliceRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CompositeSliceRegion methodsFor: 'creation'!

create: cs {CoordinateSpace} with: key {Position} with: region {XnRegion}
	super create: cs.
	myKey _ key.
	myRegion _ region.! !

!CompositeSliceRegion methodsFor: 'operations'!

{XnRegion} complement

	^CompositeRegion compositeGapRegion: self coordinateSpace with: myKey with: myRegion complement!

{XnRegion} intersect: other {XnRegion}
	(other isKindOf: ActualCompositeRegion) ifTrue:
		[^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey
				with: (myRegion intersect: ((other basicCast: ActualCompositeRegion)
						subRegion: myKey))].
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		(myKey isEqual: gap key)
			ifTrue: [^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey with: (myRegion intersect: gap region)]
			ifFalse: [^self]].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(myKey isEqual: slice key)
			ifTrue: [^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey with: (myRegion intersect: slice region)]
			ifFalse: [^CompositeRegion emptyCompositeRegion: self coordinateSpace]].
	^other intersect: self!

{XnRegion} minus: other {XnRegion}
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(myKey isEqual: slice key)
			ifTrue: [^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey with: (myRegion minus: slice region)]
			ifFalse: [^self]].
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		(myKey isEqual: gap key)
			ifTrue: [^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey with: (myRegion minus: gap region)]
			ifFalse: [^CompositeRegion emptyCompositeRegion: self coordinateSpace]].
	(other isKindOf: ActualCompositeRegion) ifTrue:
		[^CompositeRegion compositeSliceRegion: self coordinateSpace
			with: myKey
			with: (myRegion minus: ((other basicCast: ActualCompositeRegion) subRegion: myKey))].
	^(other cast: CompositeRegion) subtractedFrom: self!

{XnRegion} simpleUnion: other {XnRegion}
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(myKey isEqual: slice key)
			ifTrue: [^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey with: (myRegion simpleUnion: slice region)]
			ifFalse: [^CompositeRegion compositeTwoSliceRegion: self coordinateSpace
				with: myKey with: myRegion asSimpleRegion
				with: slice key with: slice region asSimpleRegion]].
	^other simpleUnion: self!

{XnRegion} subtractedFrom: other {CompositeRegion unused}
	"other minus: self -- arranged this way for modularity"
	self unimplemented. "this should never be sent to a slice region"
	^NULL!

{XnRegion} unionWith: other {XnRegion}
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(myKey isEqual: slice key)
			ifTrue: [^CompositeRegion compositeSliceRegion: self coordinateSpace
				with: myKey with: (myRegion unionWith: slice region)]
			ifFalse: [^CompositeRegion compositeTwoSliceRegion: self coordinateSpace
				with: myKey with: myRegion
				with: slice key with: slice region]].
	^other unionWith: self! !

!CompositeSliceRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	^myCS hashForEqual 
		bitXor: (myKey hashForEqual 
		bitXor: (myRegion hashForEqual 
		bitXor: #cat.U.CompositeSliceRegion hashForEqual))!

{BooleanVar} hasMember: atPos {Position}
	| pos {CompositePosition} |
	pos _ atPos cast: CompositePosition.
	((pos key isEqual: myKey) and: [myRegion hasMember: pos position])
		ifTrue: [^true] ifFalse: [^false]!

{BooleanVar} intersects: other {XnRegion}
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		(myKey isEqual: gap key)
			ifTrue: [^myRegion intersects: gap region]
			ifFalse: [^true]].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		((myKey isEqual: slice key) and: [myRegion intersects: slice region])
			ifTrue: [^true] ifFalse: [^false]].
	(other isKindOf: ActualCompositeRegion) ifTrue:
		[^myRegion intersects: ((other basicCast: ActualCompositeRegion) subRegion: myKey)].
	^(other cast: CompositeRegion) intersects: self!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper} 
	
	other cast: CompositeSliceRegion into: [:o | 
			^((myCS isEqual: o coordinateSpace)
				and: [myKey isEqual: o key])
				and: [myRegion isEqual: o region]]
		else: [^false]!

{BooleanVar} isFinite
	^myRegion isFinite!

{BooleanVar} isFull	

	^false!

{BooleanVar} isSimple
	^myRegion isSimple!

{BooleanVar} isSubsetOf: other {XnRegion}
	(other isKindOf: EmptyCompositeRegion) ifTrue: [^false].
	(other isKindOf: FullCompositeRegion) ifTrue: [^true].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		((myKey isEqual: slice key) and: [myRegion isSubsetOf: slice region])
			ifTrue: [^true] ifFalse: [^false]].
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		((myKey isEqual: gap key) not or: [myRegion isSubsetOf: gap region])
			ifTrue: [^true] ifFalse: [^false]].
	^myRegion isSubsetOf: ((other cast: ActualCompositeRegion) subRegion: myKey)! !

!CompositeSliceRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^CompositeRegion compositeGapRegion: self coordinateSpace
		with: myKey with: myRegion asSimpleRegion!

{Position} key
	^myKey!

{XnRegion} region
	^myRegion!

{XnRegion} subRegion: key {Position}
	"the region in a subspace"
	(key isEqual: myKey)
		ifTrue: [^myRegion]
		ifFalse: [^((self coordinateSpace cast: CompositeSpace) subSpace: key) emptyRegion]! !

!CompositeSliceRegion methodsFor: 'enumerating'!

{IntegerVar} count
	^myRegion count!

{Stepper} stepper: order {OrderSpec unused default: NULL}
	self unimplemented.
	^NULL! !

!CompositeSliceRegion methodsFor: 'actual'!

{ScruSet of: XnRegion} distinctions

	self unimplemented.
	^NULL!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	self unimplemented.
	^NULL! !

!CompositeSliceRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myKey << ': ' << myRegion << ')'! !