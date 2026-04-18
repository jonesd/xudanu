'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:53 pm'!

Mapping subclass: #Dsp
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
Dsp comment:
'A Dsp is a mapping from a coordinate space to itself that preserves simple regions.  Every coordinate space must have an identity Dsp (which maps all positions of that space onto themselves). Dsps are necessarily invertable and composable.

(Removed from CoordinateSpace because Dsps are still internal.:
Dsp -- The transformations that can be applied to positions and regions of this cordinate space.  A Dsp is necessarily invertible but generally not order-preserving. The composition of two Dsps is always a Dsp. If you can subtract two Dsps, the result will be another Dsp.  The Dsp of a Position in this space is always another Position in this space.  The Dsp of a simple region is always another simple region.)
	
	
	Considering a Mapping as a set of pairs, a Dsp is one for which each position appears exactly once in the first elements of the pairs, and exactly once in the second elements.  Composition of Dsps isn''t necessarily commutative, though there are currently no counter-examples.  Therefore we must be extra careful to avoid embodying commutativity assumptions in our code, as we currently have no way of finding such bugs.'!

(Dsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Dsp methodsFor: 'accessing'!

{Mapping INLINE} appliedAfter: dsp {Dsp}
	"For Dsp's, it is identical to compose."
	
	^self compose: dsp!

{CoordinateSpace} coordinateSpace
	"the coordinate space of the domain and range of the Dsp"

	self subclassResponsibility!

{XnRegion} domain
	"Must be valid everywhere in the domain for a Dsp."
	
	^self coordinateSpace fullRegion!

{(Dsp | NULL) INLINE} fetchDsp
	^ self!

{BooleanVar INLINE} isComplete

	^false!

{BooleanVar} isIdentity
	"Says whether this Dsp maps every Position onto itself"
	
	self subclassResponsibility!

{Mapping} preCompose: dsp {Dsp} 
	"a->compose(b) is the same as b->preCompose(a).  Don't use it, use
	compose instead."

	^dsp compose: self!

{XnRegion} range
	
	^self coordinateSpace fullRegion!

{CoordinateSpace INLINE} rangeSpace
	"Same as the domain space"
	^ self coordinateSpace!

{ImmuSet of: Mapping} simpleMappings
	"A Dsp is a simpleMapping already, so this just returns the singleton set containing me"
	^ ImmuSet make with: self.!

{ImmuSet of: Mapping} simpleRegionMappings
	"The domain of a Dsp is the simple region covering the whole coordinate space, so
	I just return a singleton set containing myself"

	^ ImmuSet make with: self.!

{Mapping INLINE} transformedBy: dsp {Dsp}
	"For Dsp's, it is identical to preCompose."
	
	^dsp compose: self! !

!Dsp methodsFor: 'combining'!

{Dsp} compose: other {Dsp}
	"Return the composition of the two Dsps. Two Dsps of the same space are always composable.
	(a->compose(b) ->minus(b))->isEqual (a)
	(a->compose(b) ->of(pos))->isEqual (a->of (b->of (pos))"

	self subclassResponsibility!

{Mapping} inverse
	"Return the inverse of this transformation. Considering the Dsp as a set of pairs 
	(see class comment), return the Dsp which has the mirror image of all my 
	pairs."

	self subclassResponsibility!

{Dsp} minus: other {Dsp}
	"Return the difference of the two Dsps.
	(a->compose(b) ->minus(b))->isEqual (a)"

	self subclassResponsibility! !

!Dsp methodsFor: 'transforming'!

{XnRegion} ofAll: reg {XnRegion}
	"If 'reg' is a simple region, then the result must also be simple"
	
	self subclassResponsibility! !

!Dsp methodsFor: 'operations'!

{Mapping INLINE} restrict: region {XnRegion}

	^SimpleMapping restrictTo: region with: self!

{Mapping} restrictRange: region {XnRegion}

	^SimpleMapping restrictTo: (self inverseOfAll: region) with: self! !

!Dsp methodsFor: 'protected:'!

{Mapping} fetchCombine: mapping {Mapping}

	(self isEqual: mapping)
		ifTrue: [^self]
		ifFalse: [^NULL]! !

!Dsp methodsFor: 'deferred transforming'!

{Position} inverseOf: pos {Position}
	"Since Dsps always represent a unique mapping in either direction, the permission to BLAST
	in the Mapping constract no longer applies.
	a->inverseOf(b) ->isEqual (a->inverse()->of(b))"
	
	^(self inverse cast: Dsp) of: pos!

{XnRegion} inverseOfAll: reg {XnRegion}
	"Inverse transform a region.  A simple region must yield a simple region.
	a->inverseOfAll(b) ->isEqual (a->inverseAll()->of(b))"

	^(self inverse cast: Dsp) ofAll: reg!

{Position} of: pos {Position}
	"Since Dsps always represent a unique mapping in either direction, the permission to BLAST
	in the Mapping constract no longer applies."
	
	^(self ofAll: pos asRegion) theOne! !

!Dsp methodsFor: 'deferred combining'!

{Dsp} inverseCompose: other {Dsp}
	"Return the composition of my inverse with the other.
	a->inverseCompose(b) ->isEqual (a->inverse()->compose(b))"

	^(self inverse cast: Dsp) compose: other! !