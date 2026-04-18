'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:18 pm'!

Heaper subclass: #Joint
	instanceVariableNames: '
		myUnioned {XnRegion}
		myIntersected {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filter'!
Joint comment:
'Joints are used to prune searches through trees of Regions. Each Joint summarizes the Joints and Regions at its node and its children using their intersection and union. If you maintain this information at each each node in the tree, then you can search for Regions in the tree efficiently using Filter::pass() to adapt the search criteria to the contents of the subtree. See also Filter::pass(Joint *).'!

(Joint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!Joint methodsFor: 'creation'!

create: unioned {XnRegion} with:  intersected{XnRegion}
	super create.
	myUnioned _ unioned.
	myIntersected _ intersected.! !

!Joint methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(union: ' << myUnioned << '; intersected: ' << myIntersected << ')'! !

!Joint methodsFor: 'accessing'!

{XnRegion INLINE} intersected
	"The intersection of the regions at all child nodes in the tree."

	^myIntersected!

{Joint INLINE} join: other {Joint}
	"A Joint that is a parent of this Joint and the given one."
	
	^Joint make.Joint: self with: other!

{XnRegion INLINE} unioned
	"The union of the regions at all child nodes in the tree."

	^myUnioned!

{Joint} with: region {XnRegion}
	"A Joint that is a parent of this one and the given region."
	
	^Joint make.XnRegion: (myUnioned unionWith: region)
		with: (myIntersected intersect: region)! !

!Joint methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myUnioned hashForEqual + myIntersected hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	
	other cast: Joint into: [:o {Joint} |
			^(myUnioned isEqual: o unioned) and:
				[myIntersected isEqual: o intersected]]
		others: [^false].
	^false "fodder"! !

!Joint methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myUnioned _ receiver receiveHeaper.
	myIntersected _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myUnioned.
	xmtr sendHeaper: myIntersected.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Joint class
	instanceVariableNames: ''!

(Joint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!Joint class methodsFor: 'pseudo constructors'!

make.CoordinateSpace: space {CoordinateSpace}
	"An empty Joint in the given coordinate space."
	
	^Joint create: space emptyRegion with: space fullRegion!

make.Joint: left {Joint} with: right {Joint}
	"A joint that is a parent of the two given Joints."
	
	^Joint create: (left unioned unionWith: right unioned)
		with: (left intersected intersect: right intersected)!

make.ScruSet: subs {ScruSet of: Joint}
	"A Joint that is a parent of all of the Joints in the set."
	
	| unioned {XnRegion} intersected {XnRegion} subStepper {Stepper} |
	subStepper _ subs stepper.
	unioned _ (subStepper get cast: Joint) unioned.
	intersected _ (subStepper fetch cast: Joint) intersected.
	subStepper step.
	subStepper forEach: [ :sub {Joint} |
		unioned _ unioned unionWith: sub unioned.
		intersected _ intersected intersect: sub intersected].
	^Joint create: unioned with: intersected!

make.XnRegion: both {XnRegion}
	"A Joint containing only the given region."
	
	^Joint create: both with: both!

make.XnRegion: unioned {XnRegion} with: intersected {XnRegion}
	"A Joint with the given union and intersection regions."
	
	^Joint create: unioned with: intersected! !

!Joint class methodsFor: 'smalltalk: smalltalk defaults'!

make: something
	(something isKindOf: XnRegion) ifTrue:
		[^self make.XnRegion: something].
	(something isKindOf: CoordinateSpace) ifTrue:
		[^self make.CoordinateSpace: something].
	^self make.ScruSet: (something cast: ScruSet)!

make: something with: other
	(something isKindOf: Joint) ifTrue:
		[^self make.Joint: something with: other].
	^self make.XnRegion: (something cast: XnRegion) with: other! !