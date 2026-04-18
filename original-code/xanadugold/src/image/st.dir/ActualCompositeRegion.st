'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:02 pm'!

CompositeRegion subclass: #ActualCompositeRegion
	instanceVariableNames: 'myRegions {(ImmuTable of: XnRegion)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(ActualCompositeRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualCompositeRegion methodsFor: 'creation'!

create: cs {CoordinateSpace} with: regions {ImmuTable of: XnRegion}
	super create: cs.
	myRegions _ regions.! !

!ActualCompositeRegion methodsFor: 'enumerating'!

{IntegerVar} count
	| result {IntegerVar} |
	result _ IntegerVar0.
	self subRegions stepper forEach: [ :sub {XnRegion} |
		result _ result + sub count].
	^result!

{Stepper} stepper: order {OrderSpec unused default: NULL}
	self unimplemented.
	^NULL! !

!ActualCompositeRegion methodsFor: 'operations'!

{XnRegion} complement

	| subs {TableStepper} result {MuTable} |
	result _ MuTable make: self subRegions coordinateSpace.
	(subs _ self subRegions stepper) forEach: [ :sub {XnRegion} |
		result at: subs position store: sub complement].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable!

{XnRegion} intersect: other {XnRegion}
	| subs {TableStepper} result {MuTable} |
	((other isKindOf: EmptyCompositeRegion)
			or: [(other isKindOf: FullCompositeRegion)
			or: [(other isKindOf: CompositeSliceRegion)]])
		ifTrue: [^other intersect: self].
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | slice {CompositeGapRegion} |
		slice _ other basicCast: CompositeGapRegion.
		result _ self subRegions asMuTable.
		result at: slice key replace: (slice region intersect: (self subRegion: slice key))]
	ifFalse:
		[result _ MuTable make: self subRegions coordinateSpace.
		(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
			result at: subs position store: ((self subRegion: subs position) intersect: sub)]].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable!

{XnRegion} minus: other {XnRegion}
	| subs {TableStepper} result {MuTable} |
	((other isKindOf: EmptyCompositeRegion)
			or: [(other isKindOf: FullCompositeRegion)
			or: [other isKindOf: CompositeGapRegion]])
		ifTrue: [^(other basicCast: CompositeRegion) subtractedFrom: self].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		result _ self subRegions asMuTable.
		result at: slice key replace: ((self subRegion: slice key) minus: slice region)]
	ifFalse:
		[result _ MuTable make: self subRegions coordinateSpace.
		(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
			result at: subs position store: ((self subRegion: subs position) minus: sub)]].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable!

{XnRegion} simpleUnion: other {XnRegion}
	| subs {TableStepper} result {MuTable} |
	((other isKindOf: EmptyCompositeRegion)
			or: [(other isKindOf: FullCompositeRegion)
			or: [(other isKindOf: CompositeGapRegion)]])
		ifTrue: [^other simpleUnion: self].
	result _ MuTable make: self subRegions coordinateSpace.
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
			(subs position isEqual: slice key) ifFalse:
				[result at: slice key introduce: sub asSimpleRegion]].
		result at: slice key introduce: (slice region simpleUnion: (self subRegion: slice key)).]
	ifFalse:
		[(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
			result at: subs position store: ((self subRegion: subs position) simpleUnion: sub)]].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable!

{XnRegion} subtractedFrom: other {CompositeRegion}
	"other minus: self -- arranged this way for modularity"
	| result {MuTable of: XnRegion} subs {TableStepper} |
	"minus should only pass this an ActualCompositeRegion or a CompositeGapRegion"
	result _ MuTable make: self subRegions coordinateSpace.
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		(subs _ self subRegions stepper) forEach: [ :sub {XnRegion} |
			(subs position isEqual: gap key)
				ifTrue: [result at: gap key
					introduce: (gap region minus: sub)]
				ifFalse: [result at: subs position
					introduce: sub complement]]]
	ifFalse:
		[(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
			result at: subs position introduce: (sub minus: (self subRegion: subs position))]].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable!

{XnRegion} unionWith: other {XnRegion}
	| subs {TableStepper} result {MuTable} |
	((other isKindOf: EmptyCompositeRegion)
			or: [(other isKindOf: FullCompositeRegion)
			or: [(other isKindOf: CompositeGapRegion)]])
		ifTrue: [^other unionWith: self].
	(other isKindOf: CompositeSliceRegion) ifTrue:
		[ | slice {CompositeSliceRegion} |
		slice _ other basicCast: CompositeSliceRegion.
		result _ self subRegions asMuTable.
		result at: slice key replace: (slice region unionWith: (self subRegion: slice key)).]
	ifFalse:
		[result _ MuTable make: self subRegions coordinateSpace.
		(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
			result at: subs position introduce: ((self subRegion: subs position) simpleUnion: sub)]].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable! !

!ActualCompositeRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	^myRegions hashForEqual bitXor: #cat.U.ActualCompositeRegion hashForEqual!

{BooleanVar} hasMember: atPos {Position}
	^(self subRegion: (atPos cast: CompositePosition) key) hasMember: (atPos cast: CompositePosition) position!

{BooleanVar} intersects: other {XnRegion}
	"tell whether it has any points in common"
	| subs {TableStepper} |
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		self subRegions domain stepper forEach: [ :key {Position} |
			(key isEqual: gap key)
				ifTrue: [((self subRegion: key) intersects: gap region)
					ifTrue: [^true]]
				ifFalse: [(self subRegion: key) isEmpty
					ifFalse:	 [^true]]].
		^false].
	(other isKindOf: ActualCompositeRegion) ifFalse:
		[^(other cast: CompositeRegion) intersects: self].
	(subs _ (other basicCast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
		((self subRegion: subs position) intersects: sub)
			ifTrue: [^true]].
	^false!

{BooleanVar} isEmpty
	^false "if empty, this would be an EmptyCompositeRegion"!

{BooleanVar} isEqual: other {Heaper}

	other cast: ActualCompositeRegion into: [:o |
			^myRegions isEqual: o subRegions]
		else: [^false]!

{BooleanVar} isFinite
	| subs {TableStepper} |
	(subs _ self subRegions stepper) forEach: [ :sub {XnRegion} |
		((self subRegion: subs position) isFinite)
			ifFalse: [^false]].
	^true!

{BooleanVar} isFull	

	^false!

{BooleanVar} isSimple
	| subs {TableStepper} |
	(subs _ self subRegions stepper) forEach: [ :sub {XnRegion} |
		((self subRegion: subs position) isSimple)
			ifFalse: [^false]].
	^true!

{BooleanVar} isSubsetOf: other {XnRegion}
	| subs {TableStepper} |
	((other isKindOf: EmptyCompositeRegion) or: [other isKindOf: CompositeSliceRegion])
		ifTrue: [^false].
	(other isKindOf: FullCompositeRegion) ifTrue: [^true].
	(other isKindOf: CompositeGapRegion) ifTrue:
		[ | gap {CompositeGapRegion} |
		gap _ other basicCast: CompositeGapRegion.
		^(self subRegion: gap key) isSubsetOf: gap region].
	(subs _ (other cast: ActualCompositeRegion) subRegions stepper) forEach: [ :sub {XnRegion} |
		((self subRegion: subs position) isSubsetOf: sub)
			ifFalse: [^false]].
	^true! !

!ActualCompositeRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	| subs {TableStepper} result {MuTable} |
	result _ MuTable make: self subRegions coordinateSpace.
	(subs _ self subRegions stepper) forEach: [ :sub {XnRegion} |
		result at: subs position store: sub asSimpleRegion].
	^CompositeRegion make: self coordinateSpace with: result asImmuTable!

{XnRegion} subRegion: key {Position}
	"the region in a subspace"
	^(myRegions get: key) cast: XnRegion!

{ImmuTable of: XnRegion} subRegions
	^myRegions! !

!ActualCompositeRegion methodsFor: 'actual'!

{ScruSet of: XnRegion} distinctions

	self unimplemented.
	^NULL!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	self unimplemented.
	^NULL! !

!ActualCompositeRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name.
	self subRegions printOnWithSyntax: oo with: '(' with: ': ' with: ', ' with: ')'.! !

!ActualCompositeRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegions.! !