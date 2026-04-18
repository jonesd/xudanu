'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:03 pm'!

CompositeRegion subclass: #CompositeGapRegion
	instanceVariableNames: '
		myKey {Position}
		myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeGapRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CompositeGapRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	^myCS hashForEqual 
		bitXor: (myKey hashForEqual 
		bitXor: (myRegion hashForEqual 
		bitXor: #cat.U.CompositeGapRegion hashForEqual))!

{BooleanVar} hasMember: atPos {Position}
	| cmp {CompositePosition} |
	cmp _ atPos cast: CompositePosition.
	((cmp key isEqual: myKey) and: [myRegion hasMember: cmp position])
		ifTrue: [^true] ifFalse: [^false]!

{BooleanVar} intersects: other {XnRegion}
	"tell whether it has any points in common"
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		((self coordinateSpace cast: CompositeSpace) subSpaces count > 2
				or: [myRegion isEmpty not
				or: [gap region isEmpty not]])
			ifTrue: [^true] ifFalse: [^false]].
	^other intersects: self!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper} 
	other cast: CompositeGapRegion into: [:o | 
			^((myCS isEqual: o coordinateSpace)
				and: [myKey isEqual: o key])
				and: [myRegion isEqual: o region]]
		else: [^false]!

{BooleanVar} isFinite
	self unimplemented.
	^false!

{BooleanVar} isFull	

	^false!

{BooleanVar} isSimple
	^myRegion isSimple!

{BooleanVar} isSubsetOf: other {XnRegion}
	| gap {CompositeGapRegion} |
	((other isKindOf: EmptyCompositeRegion) or: [other isKindOf: ActualCompositeRegion])
		ifTrue: [^false].
	(other isKindOf: FullCompositeRegion) ifTrue: [^true].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		(self coordinateSpace cast: CompositeSpace) subSpaces count > 2 ifTrue: [^false].
		slice _ other basicCast: CompositeSliceRegion.
		((slice key isEqual: myKey) not and: [myRegion isEmpty and: [slice region isFull]])
			ifTrue: [^true] ifFalse: [^false]].
	gap _ other cast: CompositeGapRegion.
	((gap key isEqual: myKey) and: [myRegion isSubsetOf: gap region])
		ifTrue: [^true] ifFalse: [^false]! !

!CompositeGapRegion methodsFor: 'operations'!

{XnRegion} complement

	^CompositeRegion compositeSliceRegion: self coordinateSpace with: myKey with: myRegion complement!

{XnRegion} intersect: other {XnRegion}
	| gap {CompositeGapRegion} |
	((other cast: CompositeRegion) isKindOf: CompositeGapRegion)
		ifFalse: [^other intersect: self].
	gap _ other basicCast: CompositeGapRegion.
	(gap key isEqual: myKey) ifFalse:
		[^CompositeRegion compositeTwoGapRegion: self coordinateSpace
			with: myKey
			with: myRegion
			with: gap key
			with: gap region].
	^CompositeRegion compositeGapRegion: self coordinateSpace
		with: myKey
		with: (myRegion intersect: ((other basicCast: CompositeGapRegion) region))!

{XnRegion} minus: other {XnRegion}
	| slice {CompositeSliceRegion} |
	((other cast: CompositeRegion) isKindOf: CompositeSliceRegion) ifFalse:
		[^(other basicCast: CompositeRegion) subtractedFrom: self].
	slice _ other basicCast: CompositeSliceRegion.
	(slice key isEqual: myKey) ifFalse:
		[^CompositeRegion compositeTwoGapRegion: self coordinateSpace
			with: myKey
			with: myRegion
			with: slice key
			with: slice region complement].
	^CompositeRegion compositeGapRegion: self coordinateSpace
		with: myKey
		with: (myRegion minus: slice region)!

{XnRegion} simpleUnion: other {XnRegion}
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		(gap key isEqual: myKey) ifFalse:
			[^CompositeRegion fullCompositeRegion: self coordinateSpace].
		^CompositeRegion compositeGapRegion: self coordinateSpace
			with: myKey
			with: (myRegion simpleUnion: gap region)].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(slice key isEqual: myKey) ifFalse:
			[^self].
		^CompositeRegion compositeSliceRegion: self coordinateSpace
			with: myKey
			with: (myRegion simpleUnion: slice region)].
	^(other cast: CompositeRegion) simpleUnion: self!

{XnRegion} subtractedFrom: other {CompositeRegion}
	"other minus: self -- arranged this way for modularity"
	^CompositeRegion compositeSliceRegion: self coordinateSpace
		with: myKey
		with: ((other subRegion: myKey) minus: myRegion)!

{XnRegion} unionWith: other {XnRegion}
	(other isKindOf: ActualCompositeRegion) ifTrue:
		[^CompositeRegion compositeGapRegion: self coordinateSpace
			with: myKey
			with: (myRegion unionWith: ((other basicCast: ActualCompositeRegion)
					subRegion: myKey))].
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		(gap key isEqual: myKey) ifFalse:
			[^CompositeRegion fullCompositeRegion: self coordinateSpace].
		^CompositeRegion compositeGapRegion: self coordinateSpace
			with: myKey
			with: (myRegion unionWith: gap region)].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(slice key isEqual: myKey) ifFalse:
			[^self].
		^CompositeRegion compositeGapRegion: self coordinateSpace
			with: myKey
			with: (myRegion unionWith: slice region)].
	^(other cast: CompositeRegion) unionWith: self! !

!CompositeGapRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^CompositeRegion compositeGapRegion: self coordinateSpace with: myKey with: myRegion asSimpleRegion!

{Position} key
	^myKey!

{XnRegion} region
	^myRegion!

{XnRegion} subRegion: key {Position}
	"the region in a subspace"
	(key isEqual: myKey)
		ifTrue: [^myRegion]
		ifFalse: [^((self coordinateSpace cast: CompositeSpace) subSpace: key) fullRegion]! !

!CompositeGapRegion methodsFor: 'creation'!

create: cs {CoordinateSpace} with: key {Position} with: region {XnRegion}
	super create: cs.
	myKey _ key.
	myRegion _ region.! !

!CompositeGapRegion methodsFor: 'actual'!

{ScruSet of: XnRegion} distinctions

	self unimplemented.
	^NULL!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	self unimplemented.
	^NULL! !

!CompositeGapRegion methodsFor: 'enumerating'!

{IntegerVar} count
	self unimplemented.
	^IntegerVar0!

{Stepper} stepper: order {OrderSpec unused default: NULL}
	self unimplemented.
	^NULL! !

!CompositeGapRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myKey << ': ' << myRegion << ')'! !