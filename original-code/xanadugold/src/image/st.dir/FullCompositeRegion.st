'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:06 pm'!

CompositeRegion subclass: #FullCompositeRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(FullCompositeRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FullCompositeRegion methodsFor: 'creation'!

create: cs {CoordinateSpace}
	super create: cs! !

!FullCompositeRegion methodsFor: 'enumerating'!

{IntegerVar} count

	Heaper BLAST: #NotEnumerable.
	"some of the sub spaces might be finite, but we don't have any implemented yet"
	^IntegerVar0!

{Stepper} stepper: order {OrderSpec unused default: NULL}
	self unimplemented.
	^NULL! !

!FullCompositeRegion methodsFor: 'actual'!

{ScruSet of: XnRegion} distinctions

	^ImmuSet make!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	^(ImmuSet make with: self) stepper! !

!FullCompositeRegion methodsFor: 'operations'!

{XnRegion} complement

	^CompositeRegion emptyCompositeRegion: self coordinateSpace!

{XnRegion} intersect: other {XnRegion}
	^other!

{XnRegion} minus: other {XnRegion}
	^other complement!

{XnRegion} simpleUnion: other {XnRegion unused}
	^self!

{XnRegion} subtractedFrom: other {CompositeRegion unused}
	^CompositeRegion emptyCompositeRegion: self coordinateSpace!

{XnRegion} unionWith: other {XnRegion unused}
	^self! !

!FullCompositeRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	^myCS hashForEqual bitXor: #cat.U.FullCompositeRegion hashForEqual!

{BooleanVar} hasMember: atPos {Position unused}
	^true!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}
	
	other cast: FullCompositeRegion into: [:o |
			^myCS isEqual: o coordinateSpace]
		else: [^false]!

{BooleanVar} isFinite
	self unimplemented.
	^false!

{BooleanVar} isFull	

	^true!

{BooleanVar} isSimple
	^true!

{BooleanVar} isSubsetOf: other {XnRegion}
	^other isFull! !

!FullCompositeRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^self!

{XnRegion} subRegion: key {Position}
	"the region in a subspace"
	^((self coordinateSpace cast: CompositeSpace) subSpace: key) fullRegion! !

!FullCompositeRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self coordinateSpace << ')'! !