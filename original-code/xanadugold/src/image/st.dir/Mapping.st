'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:55 pm'!

Heaper subclass: #Mapping
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
Mapping comment:
'A mapping is a general mapping from one coordinate space to another, with few of the guarantees provided by Dsps.  In particular, the source and destination coordinate spaces can be different, and the mapping doesn''t have to be everywhere defined (but it has to say where it is defined via "domain" and "range" messages).  A mapping doesn''t have to be unique--the same domain position may map to multiple range positions and vice versa.  A mapping of a XuRegion must yield another XuRegion, but a mapping of a simple region doesn''t have to yield a simple region.
	
	A useful and valid way to think of a Mapping is as a (possibly infinite) set of pairs (a mathematical set, not a ScruSet).  The domain region consists of the first elements of each pair, and the range region consists of the second elements.
	
	A mapping is most useful as a representation of a version comparison of two different organizations of common elements.  The mapping would tell how positions in one organization correspond to positions in the other.'!

(Mapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class Mapping */
friend void storeMapping (Mapping *, MuSet *);
friend class SimpleMapping;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!Mapping methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	"the coordinate space of the domain of the Mapping"

	self subclassResponsibility!

{XnRegion CLIENT} domain
	"Essential.  region in which it is valid."
	
	self subclassResponsibility!

{CoordinateSpace CLIENT INLINE} domainSpace
	"The coordinate space of the domain of the Mapping"

	^self coordinateSpace!

{Dsp | NULL} fetchDsp
	"if this is a Dsp or a Dsp retricted to some domain, return the underlying Dsp.  Otherwise NULL."
	self subclassResponsibility!

{BooleanVar CLIENT} isComplete
	"Essential. Return true if each Position in the domain is mapped to every Position in the range."
	
	Ravi thingToDo. "Decide what to do if it is not simple enough"
	self subclassResponsibility!

{BooleanVar CLIENT} isIdentity
	"Essential. True if this is the identify mapping on the entire space."
	
	Ravi thingToDo. "Decide about domain"
	self subclassResponsibility!

{XnRegion CLIENT} range
	"Essential.  region in which inverse is valid.  Same as the region that the domain region maps to. For you mathematicians, it is the image of the domain under the mapping."
	
	self subclassResponsibility!

{CoordinateSpace CLIENT} rangeSpace
	"The coordinate space of the range of the transformation"
	
	self subclassResponsibility!

{ImmuSet of: Mapping} simpleMappings
	"return a set of simple mappings that would combine to this one"
	self subclassResponsibility!

{ImmuSet of: Mapping} simpleRegionMappings
	"return a set of mappings with simple regions as their domains that would combine 
	to this one."
	
	self subclassResponsibility!

{Stepper CLIENT of: Mapping} simplerMappings
	"Essential. Break this Mapping up into simpler Mappings which can be combined together to get this one."
	
	^self simpleMappings stepper!

{Mapping CLIENT} unrestricted
	"Essential. If this is a 'simpler' Mapping, and not isFull, then return a yet simpleMapping of some class from which you can get more information. Note that m->restrict (region)->unrestricted () is not necessarily the same as m, since information may be lost."
	
	self fetchDsp == NULL ifTrue:
		[Heaper BLAST: #NotSimpleEnough].
	^self fetchDsp! !

!Mapping methodsFor: 'mapping'!

{Position} inverseOf: after {Position}
	"Inverse transform a position.  Must BLAST if there isn't a unique inverse.
	'a->isEqual (this->of (b))' iff 'b->isEqual (this->inverseOf (a))'."

	self subclassResponsibility!

{XnRegion} inverseOfAll: after {XnRegion}
	"Inverse transform of a region.
	'a->isEqual (this->of (b))' iff 'b->isEqual (this->inverseOf (a))'."

	self subclassResponsibility!

{IntegerVar} inverseOfInt: pos {IntegerVar} 
	"Unboxed version of 'this->inverseOf (xuInteger(pos))'. See 
	discussion in the XuInteger class comment about boxed and unboxed 
	protocols"

	^((self inverseOf: pos integer) cast: IntegerPos) asIntegerVar!

{Position CLIENT} of: before {Position} 
	"Transform a position. 'before' must be a Position of my domain space. Iff 'before' is in the domain region over which I am defined and it maps to a unique range Position then the result will be that Position. Otherwise BLAST. For example, if I map 1 to 4, 1 to 5, and 2 to 5 (and nothing else), then this method will yield 5 given 2, but BLAST given anything else. To find all the values 1 maps to, use the 'ofAll' operation on the singleton region whose member is 1."

	self subclassResponsibility!

{XnRegion CLIENT} ofAll: before {XnRegion} 
	"Essential.  Transform a region. The result region has exactly those positions which are the mappings of the positions in 'before'. This must be the case even if these positions cannot be enumerated. If the mapping for a given position is multiply defined, then (if that position is in 'before') all position it maps to must be in the result. Because of this property, the behavior of this method must be taken as really defining the nature of a particular mapping (with other method's behavior being defined in terms of this one), despite the fact that it would have been more natural to take Mapping::of(Position *) as the defining behavior."

	self subclassResponsibility!

{IntegerVar} ofInt: pos {IntegerVar}
	"Unboxed version of 'this->of (xuInteger(pos))'.  See discussion in the XuInteger class 
	comment about boxed and unboxed protocols"

	^ ((self of: pos integer) quickCast: IntegerPos) asIntegerVar! !

!Mapping methodsFor: 'operations'!

{Mapping} appliedAfter: dsp {Dsp}
	"Defined by the equivalence:
		M->transformedBy(D)->of(R) isEqual (M->of(D->of(R)))
	for all regions R in the domainSpace of M. Equivalent to Dsp::compose, except that it is between a Mapping and a Dsp."
	
	self subclassResponsibility!

{Mapping CLIENT} combine: other {Mapping}
	"Essential.  Result will do both mine and other's mappings.  It will do my mapping where I am defined, and it will do the other's where his is defined.  If we are both defined over some domain positions, then the result is a multi-valued mapping.  If you think of a Mapping simply as a set of pairs (see class comment), then 'combine' yields a Mapping consisting of the union of these two sets."
	
	| result {Mapping} |
	result _ self fetchCombine: other.
	result ~~ NULL ifTrue: [^result].
	result _ other fetchCombine: self.
	result ~~ NULL
		ifTrue: [^result]
	ifFalse:
		[| set {MuSet of: Mapping} |
		set _ MuSet make.
		set store: self.
		set store: other.
		^CompositeMapping 
			privateMakeMapping: self domainSpace
			with: self rangeSpace
			with: set asImmuSet]!

{Mapping CLIENT} inverse
	"Essential. Return the inverse of this transformation. Considering the Mapping as a set of pairs (see class comment), return the Dsp which has the mirror image of all my pairs."
	
	self subclassResponsibility!

{Mapping} preCompose: dsp {Dsp}
	"There is no sensible explanation for what this message does on Mappings 
	which aren't Dsps.  In the future, we will probably retire this message,
	so don't use it."

	self subclassResponsibility!

{Mapping CLIENT} restrict: region {XnRegion}
	"Essential.  Restrict the domain.  The domain of the result will be the intersection of my domain and 'region'.  Otherwise we are the same."
	
	self subclassResponsibility!

{Mapping} restrictRange: region {XnRegion}
	"Restrict the range.  The range of the result will be the intersection of my range and 'region'.  Otherwise we are the same."
	
	self subclassResponsibility!

{Mapping} transformedBy: dsp {Dsp}
	"Defined by the equivalence:
		M->transformedBy(D)->of(R) isEqual (D->of(M->of(R)))
	for all regions R in the domainSpace of M. Equivalent to Dsp::preCompose, except that it is between a Mapping and a Dsp."
	
	self subclassResponsibility! !

!Mapping methodsFor: 'vulnerable: accessing'!

{Mapping} fetchCombine: mapping {Mapping}
	"if I know how to combine the two into a single mapping, then I do so"
	self subclassResponsibility! !

!Mapping methodsFor: 'smalltalk: passe'!

{PrimArray} export

	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Mapping class
	instanceVariableNames: ''!

(Mapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class Mapping */
friend void storeMapping (Mapping *, MuSet *);
friend class SimpleMapping;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!Mapping class methodsFor: 'pseudo constructors'!

{Mapping INLINE} make.CoordinateSpace: cs {CoordinateSpace} 
	with.CoordinateSpace: rs {CoordinateSpace} 
	"Make an empty mapping from cs to rs. The domain will consist of an 
	empty region in cs, and the range will consist of an empty region in rs"

	^EmptyMapping make: cs with: rs!

make.CoordinateSpace: cs {CoordinateSpace} with.Region: values {XnRegion}
	"Make a constant mapping from all positions in cs to all positions in values."
	
	values isEmpty
		ifTrue: [^Mapping make.CoordinateSpace: cs
			with.CoordinateSpace: values coordinateSpace]
		ifFalse: [^ConstantMapping create: cs with: values]!

{Mapping} make: cs {CoordinateSpace} 
	with: rs {CoordinateSpace} 
	with: mappings {ImmuSet of: Mapping}
	"The combine of all the mappings in 'mappings'  All domains must be 
	in cs and all ranges in rs.  cs and rs must be provided in case 
	'mappings' is empty."
	
	mappings isEmpty
		ifTrue: [^EmptyMapping make: cs with: rs ]
		ifFalse:
			[| result {MuSet of: Mapping} |
			result _ MuSet make.
			mappings stepper forEach: [ :each {Mapping} |
				CompositeMapping storeMapping: each with: result].
			^CompositeMapping privateMakeMapping: cs with: rs with: mappings]! !

!Mapping class methodsFor: 'smalltalk: smalltalk defaults'!

make: a with: b
	a cast: CoordinateSpace.
	(b isKindOf: CoordinateSpace) ifTrue:
		[^self make.CoordinateSpace: a with.CoordinateSpace: b].
	^self make.CoordinateSpace: a with.Region: (b cast: XnRegion)! !

!Mapping class methodsFor: 'smalltalk: passe'!

make.Region: region {XnRegion} with: mapping {Mapping}
	self passe! !

!Mapping class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Mapping CLIENT} combine: other {Mapping}
{XuRegion CLIENT} domain
{CoordinateSpace CLIENT} domainSpace
{Mapping CLIENT} inverse
{BooleanVar CLIENT} isComplete
{BooleanVar CLIENT} isIdentity
{Position CLIENT} of: before {Position}
{XuRegion CLIENT} ofAll: before {XuRegion}
{XuRegion CLIENT} range
{CoordinateSpace CLIENT} rangeSpace
{Mapping CLIENT} restrict: region {XuRegion}
{Stepper CLIENT of: Mapping} simplerMappings
{Mapping CLIENT} unrestricted
"! !