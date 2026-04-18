'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:05 pm'!

CompositeRegion subclass: #EmptyCompositeRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(EmptyCompositeRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EmptyCompositeRegion methodsFor: 'creation'!

create: cs {CoordinateSpace}
	super create: cs! !

!EmptyCompositeRegion methodsFor: 'enumerating'!

{IntegerVar} count
	^IntegerVar0!

{Stepper} stepper: order {OrderSpec unused default: NULL}
	self unimplemented.
	^NULL! !

!EmptyCompositeRegion methodsFor: 'actual'!

{ScruSet of: XnRegion} distinctions

	^ImmuSet make with: self!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	^(ImmuSet make with: self) stepper! !

!EmptyCompositeRegion methodsFor: 'operations'!

{XnRegion} complement

	^CompositeRegion fullCompositeRegion: self coordinateSpace!

{XnRegion} intersect: other {XnRegion unused}
	^self!

{XnRegion} minus: other {XnRegion unused}
	^self!

{XnRegion} simpleUnion: other {XnRegion}
	^other asSimpleRegion!

{XnRegion} subtractedFrom: other {CompositeRegion}
	^other!

{XnRegion} unionWith: other {XnRegion}
	^other! !

!EmptyCompositeRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	^myCS hashForEqual bitXor: #cat.U.EmptyCompositeRegion hashForEqual!

{BooleanVar} hasMember: atPos {Position unused}
	^false!

{BooleanVar} isEmpty
	^true!

{BooleanVar} isEqual: other {Heaper}

	other cast: EmptyCompositeRegion into: [:o |
			^myCS isEqual: o coordinateSpace]
		else: [^false]!

{BooleanVar} isFinite
	^true!

{BooleanVar} isFull	

	^false!

{BooleanVar} isSimple
	^true!

{BooleanVar} isSubsetOf: other {XnRegion unused}
	^true! !

!EmptyCompositeRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^self!

{XnRegion} subRegion: key {Position}
	"the region in a subspace"
	^((self coordinateSpace cast: CompositeSpace) subSpace: key) emptyRegion! !

!EmptyCompositeRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self coordinateSpace << ')'! !