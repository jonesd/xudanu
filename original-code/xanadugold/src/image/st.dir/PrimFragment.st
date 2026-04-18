'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:37 pm'!

CompareFragment subclass: #PrimFragment
	instanceVariableNames: '
		srcLocs {IntegerRegion}
		destLocs {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(PrimFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimFragment methodsFor: 'creation'!

create: s {IntegerVar} with: sLocs {IntegerRegion} with: dLocs {IntegerRegion}
	super create: s.
	srcLocs _ sLocs.
	destLocs _ dLocs.! !

!PrimFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'prim[' << self count << ', ' .
	stream << srcLocs << ' --> '.
	stream << destLocs << ']'.! !

!PrimFragment methodsFor: 'merging'!

{Pair of: PrimFragment} breakAt: length { IntegerVar }
	"Break a move at length, returning the two pieces."
	^Pair make: (PrimFragment make: length with: self startLocations with: self finalLocations) 
		with: (self withoutFirst: length)!

{Pair of: PrimFragment} merge: aMove { PrimFragment }
	"merge two PrimFragments, returning one if their sizes are the same, and two otherwise."
	^Pair make: (self overlapFromMerge: aMove) with: (self overhangFromMerge: aMove)!

{IntegerTable of: PrimFragment} mergeInto:  moves {IntegerTable of: PrimFragment} 
	with: position {IntegerVar}
	"add to a table at a position.  Cascade additions as necessary.  Don't check for overlap"
	
	((moves intFetch: position) == NULL)
		ifTrue:
			[moves atInt: position store: self.
			^moves]
		ifFalse:  [
			| newMoves {"Pair of:" PrimFragment} overlap {PrimFragment} overhang {PrimFragment} |
			newMoves _ (moves intFetch: position) cast: PrimFragment.
			overlap _ newMoves overlapFromMerge: self.
			overhang _ newMoves overhangFromMerge: self.
			"newMoves _ ((moves fetch.IntegerVar: position) cast: PrimFragment) merge: self."
			moves atInt: position replace: overlap.
			(overhang == NULL) 
				ifFalse: [^overhang mergeInto: moves with: (position + overlap count)]
				ifTrue: [^moves]]!

{PrimFragment} overhangFromMerge: aMove {PrimFragment}
	"merge with aMove, returning a Move representing the non-common part."
	(self count == aMove count)
		ifTrue: [^NULL]
		ifFalse: [self count < aMove count
			ifFalse: [^self withoutFirst: aMove count]
			ifTrue: [^aMove withoutFirst: self count]]!

{PrimFragment} overlapFromMerge: aMove {PrimFragment}
	"merge two PrimFragments, return a PrimFragment representing their common beginning"
	| newStarts {IntegerRegion} newDests {IntegerRegion} |
	newStarts _ (aMove startLocations unionWith: self startLocations) cast: IntegerRegion.
	newDests _ (aMove finalLocations unionWith: self finalLocations) cast: IntegerRegion.
	((self count min: aMove count) == IntegerVar0) ifTrue: [^NULL].
	^PrimFragment make: (self count min: aMove count) with: newStarts with: newDests!

{PrimFragment} withoutFirst: minuend { IntegerVar }
	"return a PrimFragment representing this move with the front lopped off"
	^PrimFragment make: self count - minuend
			with: (((IntegerMapping make: minuend) ofAll: self startLocations) cast: IntegerRegion)
			with: (((IntegerMapping make: minuend) ofAll: self finalLocations) cast: IntegerRegion)! !

!PrimFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^true!

{BooleanVar} simpleMove
	"Am I a simple move from one location to one other?"
	^(srcLocs count == 1) and: [destLocs count == 1]! !

!PrimFragment methodsFor: 'accessing'!

{IntegerRegion} finalLocations
	^destLocs!

{IntegerRegion} startLocations
	^srcLocs! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimFragment class
	instanceVariableNames: ''!

(PrimFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimFragment class methodsFor: 'smalltalk: smalltalk only'!

{PrimFragment} make: s {IntegerVar} with: sLocs {Heaper} with: dLocs {Heaper}

	^(sLocs isKindOf: IntegerVar)
		ifTrue: [(dLocs isKindOf: IntegerVar)
			ifTrue: [PrimFragment make: s with.IntegerVar: sLocs with.IntegerVar: dLocs]
			ifFalse: [PrimFragment make: s with.IntegerVar: sLocs with.IntegerRegion: dLocs]]
		ifFalse: [(dLocs isKindOf: IntegerVar)
			ifTrue: [PrimFragment make: s with.IntegerRegion: sLocs with.IntegerVar: dLocs]
			ifFalse: [PrimFragment make: s with.IntegerRegion: sLocs with.IntegerRegion: dLocs]]! !

!PrimFragment class methodsFor: 'pseudoConstructors'!

{PrimFragment} make: s {IntegerVar} with.IntegerRegion: sLocs {IntegerRegion} with.IntegerRegion: dLocs {IntegerRegion}

	^PrimFragment create: s with: sLocs with: dLocs!

{PrimFragment} make: s {IntegerVar} with.IntegerRegion: sLocs {IntegerRegion} with.IntegerVar: dLoc {IntegerVar}

	^PrimFragment create: s with: sLocs with: (IntegerRegion make: dLoc)!

{PrimFragment} make: s {IntegerVar} with.IntegerVar: sLoc {IntegerVar} with.IntegerRegion: dLocs {IntegerRegion}

	^PrimFragment create: s with: (IntegerRegion make: sLoc) with: dLocs!

{PrimFragment} make: s {IntegerVar} with.IntegerVar: sLoc {IntegerVar} with.IntegerVar: dLoc {IntegerVar}

	^PrimFragment create: s with: (IntegerRegion make: sLoc) with: (IntegerRegion make: dLoc)! !