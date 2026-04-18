'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:01 pm'!

XuPromise subclass: #XuRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
XuRegion comment:
'The design of a new coordinate space consists mostly in the design of the XuRegions which can be used to describe (possibly infinite) sets of positions in that coordinate space.  It will generally not be the case (for a given coordinate space) that all mathematically describable sets of positions will be representable by an XuRegion in that space.  This should not be seen as a temporary deficiency of the current implementation of a space, but rather part of the design of what a given space *means*.  
	
	For example, in IntegerSpace, one cannot form the XuRegion whose members are exactly the even numbers.  If this were possible, other desirable properties which are part of the intent of IntegerSpaces would no longer be possible.  For example, any XuRegion should be able to break itself up into a finite number of simple XuRegions ("simple" is described below).  Were an even number region possible, this would have undesirable consequences for the definition of "simple" in this space.  If you want (for example) to be able to have a XuRegion which can represent all the even numbers, it probably makes more sense to define a whole new space in which these new XuRegions apply.
	
	XuRegions should be closed under a large set of operations, such as intersection, unionWith, complement and minus.  ("closed" means that the result of performing this operation on XuRegions of a given space is another valid XuRegion in the same space.)  Additional guarantees are documented with each operation.
	
	A XuRegion may be classified at one of three levels of "simplicity":
	
	1) The simplest are the *distinctions*.  Distinctions are those that answer with (at most) a single set containing themselves in response to the message "distinctions".  (The reason I say "at most" is that a full region (one that covers the entire coordinate space) may answer with the empty set.)  Distinctions are the simplest XuRegions of a given space out of which all other XuRegions of that space can be finitely composed.  There should probably be a message "isDistinction" for which exactly the distinctions answer "true".  The complement of a distinction is a distinction.  Three examples of distinctions in spaces are:
	
		a) in IntegerSpace, any simple inequality.  For example, all integers < 37.
		b) in one kind of 3-space, any half space (all the space on one side of some plane)
		c) in another kind of 3-space, any sphere or spherical hole.
		
	Note that "c" could not just have spheres as the distinction because distinctions must be closed under complement.  (We are here ignoring the quite substantial problems that arise in dealing with approximate (e.g., floating point) which would almost necessarily have to arise in doing any decent 3-space.  3-space is nevertheless a good intuition pump.)
	
	2) Next are the *simple regions*.  Simple regions are exactly those that say "true" to "isSimple".  All distinctions are also simple regions.  In response to the message "distinctions", and simple region must return a finite set of distinctions which, when intersected together, yield the original simple region.  Generally, one tries to define the simple regions for a space to correspond to some notion of locality in the space.  For example, it may be good for a simple region not to be able to have a hole in it.  Or perhaps a simple region is which must be connected (whatever that means in a given space).  Example non-distinction simple regions for the above example spaces would be:
	
		a) The interval from 3 inclusive to 17 exclusive (intersection of all integers >= 3 and all < 17)
		b) A convex hull (intersection of half spaces)
		c) Whatever you get by intersecting a bunch of spheres and sherical holes.
		
	The simple regions for both "a" and "b" would be connected, without holes, and even convex.  This follows directly from the definition of our distinctions.  None of these nice properties holds for "c", and this also follows directly from our decision to start with spheres.  "c" is still perfectly valid, just less preferable by some criteria.
	
	3) Finally, there are the regions of a space in general.  Any region must respond to the message "simpleRegions" with a stepper which will produce a finite number of simple regions that, when unioned together, yields the original region.  A simple region will return a stepper that will return at most itself ("at most" because an empty region (which covers no positions) may return an empty stepper).  Example non-simple regions are:
	
		a) all integers < 3 and all integers >= 17
		b) two convex hulls
		c) two disjoint spheres
		
	Note that "a" is the complement of the earlier "a" example, thereby showing why the complement of a simple region isn`t necessarily simple.  Even though the "c" space is so unconstrained in the properties of its simple regions, there is no way to interect a finite number of spheres and spherical holes to produce a pair of disjoint spheres.  Therefore the pair is non-simple.  Not all spaces must have non-simple regions (or even non-distinctions).  It is interesting to observe for "b" and "c" that even though there is a natural conversion between their respective positions, (except for the empty and full regions) there is no conversion at all between their respective regions.  The kinds of sets of positions representable in one space is completely different than those representable in the other space.
	
	We will use these three example spaces repeatedly in documenting the protocol.'!

(XuRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRegion methodsFor: 'enumerating'!

{XuRegion} chooseMany: n {XuIntValue} with: order {XuOrderSpec default: DefaultNull} 

	"If an OrderSpec is given, return the first n elements according to that OrderSpec. If no OrderSpec is given, then iff I contain at least n positions, return n of them; otherwise BLAST. This should be implemented even by regions that aren't enumerable.  Inspired by the axiom of choice."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(n isBroken) ifTrue:
		[^XuRegion makeBrokenBy: n].
	(order isBroken) ifTrue:
		[^XuRegion makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion chooseMany:n getActualIntegerVar with: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPosition} chooseOne: order {XuOrderSpec default: DefaultNull} 

	"Essential.  If an OrderSpec is given, return the first element according to that OrderSpec. If no OrderSpec is given, then iff I contain at least one position, return one of them; otherwise BLAST. This should be implemented even by regions that aren't enumerable.  Inspired by the axiom of choice."
	
	| retVal {XuPosition} |
	(self isBroken) ifTrue:
		[^XuPosition makeBrokenBy: self].
	(order isBroken) ifTrue:
		[^XuPosition makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPosition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPosition make: (self getActualXnRegion chooseOne: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} count

	"How many positions do I contain?  If I am not 'isFinite', then this message will BLAST."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualXnRegion count)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} stepper: order {XuOrderSpec default: DefaultNull} 

	"Essential.  If my positions are enumerable in the order specified, then return a stepper which will so enumerate them. If 'order' is NULL, then I may treat this as a request to enumerate according to any order I choose, except that if I am enumerable in ascending order, then I must be enumerable given NULL. For example, if I choose to regard NULL as implying ascending order, and I am only enumerable in descending order, then given NULL, I may blast even though there is an order in which I am enumerable. 
	
	In fact, right now the ability to respond to an 'order' argument is in such a to-be-implemented state that it should only be considered safe to provide a NULL argument, unless the documentation on a particular space or region says otherwise. 
	
	The eventual specification of this message is clear, and is upwards compatible from the current behavior: If I can enumerate in an order consistent with 'order', do so. If 'order' is NULL, then if I can be enumerated at all (if there is any counting sequence), then I still do so. For example, I should be able to get an (infinite) stepper for stepping through all the integers, but not all the reals. As the above example shows, being enumerable doesn't imply being finite.  
	
	Also, being able to produce a stepper that continues to yield more positions in the specified order is not sufficient to imply being enumerable.  To be enumerable, it must be the case that any given position which is a member of the region will eventually be reached by the stepper.  Not all implementations currently succeed in guaranteeing this (See UnionCrossRegion::isEnumerable).
	
	See ScruTable::stepper."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualXnRegion stepper: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPosition} theOne

	"Iff I contain exactly one position, return it.  Otherwise BLAST. The idea for this message is taken from the THE function of ONTIC (reference McAllester)"
	
	| retVal {XuPosition} |
	(self isBroken) ifTrue:
		[^XuPosition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPosition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPosition make: (self getActualXnRegion theOne)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRegion methodsFor: 'promise access'!

{XnRegion} getActualXnRegion
	self isBroken
		ifFalse: [^super actualThing cast: XnRegion.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuRegion methodsFor: 'smalltalk: defaults'!

{XuRegion} chooseMany: n {XuIntValue} 

	"This method has no comment."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(n isBroken) ifTrue:
		[^XuRegion makeBrokenBy: n].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion chooseMany:n getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPosition} chooseOne

	^self  chooseOne: DefaultNull!

{XuStepper} stepper

	^self  stepper: DefaultNull! !

!XuRegion methodsFor: 'accessing'!

{XuCoordinateSpace} coordinateSpace

	"Essential.  The coordinate space in which this is a region"
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualXnRegion coordinateSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRegion methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anXnRegion {XnRegion}
	super create: anXnRegion.! !

!XuRegion methodsFor: 'testing'!

{XuIntValue} hasMember: atPos {XuPosition} 

	"Do I contain this position? More than anything else, the behavior of this message is the defining characteristic of an XuRegion. All other messages (except for the simplicity characterization) should be specifiable in terms of the behavior of this message. What an XuRegion *is* (mostly) is a finite decision procedure for accepting or rejecting any given position."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(atPos isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: atPos].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualXnRegion hasMember: ((XuPromise getActual: atPos) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} intersects: other {XuRegion} 

	"Essential.  tell whether it has any points in common"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualXnRegion intersects: ((XuPromise getActual: other) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isEmpty

	"Every coordinate space has exactly one empty region. It is the one containing no positions. It and only it responds 'true' to this message."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualXnRegion isEmpty)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isFinite

	"Essential.  Do I contain a finite number of positions? If I do, then the 'count' message will say how many, and I will gladly provide a stepper which will step over all of them. I.e., isFinite implies isEnumerable."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualXnRegion isFinite)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isFull

	"true if this is the largest possible region in this space -- the region that contains all positions in the space. Note that in a space which has no positions (which is perfectly valid), the one XuRegion would be both empty (since it has no positions) and full (since it has all the positions in the space)."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualXnRegion isFull)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isSubsetOf: other {XuRegion} 

	"I'm a subset of other if I don't have any positions that he doesn't. Note that if we are equal, then I am still a subset of him. If you want to know if I'm a strict subset, you can ask 
	a->isSubsetOf(b) && !! a->isEqual(b)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualXnRegion isSubsetOf: ((XuPromise getActual: other) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRegion methodsFor: 'operations'!

{XuRegion} complement

	"Essential.  Return a region of containing exactly those positions not in this region. The complement of a distinction must be a distinction."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion complement)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} intersect: other {XuRegion} 

	"Essential.  The intersection of two simple regions must be simple. The intersection of two distinctions must therefore be a simple region. The result has exactly those members which both the original regions have."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuRegion makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion intersect: ((XuPromise getActual: other) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} minus: other {XuRegion} 

	"The region containing all my position which aren't in other."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuRegion makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion minus: ((XuPromise getActual: other) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} unionWith: other {XuRegion} 

	"The result has as members exactly those positions which are members of either of the original two regions. No matter how simple the two original regions are, the result may be non-simple.
	
	The only reason this is called 'unionWith' instead of 'union' is that the latter is a C++ keyword."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuRegion makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion unionWith: ((XuPromise getActual: other) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} with: pos {XuPosition} 

	"the region with one more position. Actually, if I already contain pos, then the result is just me."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(pos isBroken) ifTrue:
		[^XuRegion makeBrokenBy: pos].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion with: ((XuPromise getActual: pos) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} without: pos {XuPosition} 

	"the region with one less position. Actually if I already don't contain pos, then the result is just me."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(pos isBroken) ifTrue:
		[^XuRegion makeBrokenBy: pos].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualXnRegion without: ((XuPromise getActual: pos) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuRegion class
	instanceVariableNames: ''!

(XuRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRegion class methodsFor: 'pseudo-constructors'!

make: anXnRegion {XnRegion}
	^self create: anXnRegion!

{XuRegion} makeBroken: problem {Problem star}
	| broke {XuRegion} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuRegion} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !