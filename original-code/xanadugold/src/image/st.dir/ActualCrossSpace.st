'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:06 pm'!

CrossSpace subclass: #ActualCrossSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
ActualCrossSpace comment:
'Default implementation of cross coordinate space'!

(ActualCrossSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #OBSOLETE; add: #SMALLTALK.ONLY; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!ActualCrossSpace methodsFor: 'making'!

{Mapping} crossOfMappings: subMappings {(PtrArray of: Mapping | NULL) default: NULL}

	subMappings == NULL ifTrue:
		[^CrossMapping make: self].
	Int32Zero almostTo: subMappings count do: [:i {Int32} |
		| subM {Mapping | NULL} |
		subM := (subMappings fetch: i) cast: Mapping.
		(subM ~~ NULL and: [(subM isKindOf: Dsp) not]) ifTrue:
			[MarkM shouldImplement]].
	^CrossMapping make: self with: subMappings!

{CrossOrderSpec} crossOfOrderSpecs: subOrderings {(PtrArray of: OrderSpec | NULL) default: NULL}
	with: subSpaceOrdering {PrimIntArray default: NULL}
	
	^CrossOrderSpec make: self with: subOrderings with: subSpaceOrdering!

{Tuple} crossOfPositions: coordinates {PtrArray of: Position}
	
	^ActualTuple make: coordinates!

{CrossRegion} crossOfRegions: subRegions {PtrArray of: XnRegion | NULL}
	
	| result {CrossRegion} |
	result := self fullRegion cast: CrossRegion.
	Int32Zero almostTo: subRegions count do: [:i {Int32} |
		| sub {XnRegion | NULL} |
		sub := (subRegions fetch: i) cast: XnRegion.
		sub ~~ NULL ifTrue:
			[result := (result intersect: (self extrusion: i with: sub)) cast: CrossRegion]].
	^result!

{CrossRegion} extrusion: dimension {Int32} with: subRegion {XnRegion}
	
	| projs {PtrArray of: XnRegion} |
	subRegion isEmpty ifTrue: [^self emptyRegion].
	projs := PtrArray nulls: mySubSpaces count.
	Int32Zero almostTo: mySubSpaces count do: [ :i {Int32} |
		i = dimension ifTrue:
			[projs at: i store: subRegion]
		ifFalse:
			[projs at: i
				store: ((mySubSpaces fetch: i) cast: CoordinateSpace) fullRegion]].
	^GenericCrossRegion make: self with: 1 with: projs! !

!ActualCrossSpace methodsFor: 'smalltalk: passe'!

create: subSpaces {PtrArray of: CoordinateSpace}
	self passe.
	super create.
	mySubSpaces := subSpaces! !

!ActualCrossSpace methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualCrossSpace class
	instanceVariableNames: ''!

(ActualCrossSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #OBSOLETE; add: #SMALLTALK.ONLY; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!ActualCrossSpace class methodsFor: 'pseudoconstructors'!

{CrossSpace} make: subSpaces {PtrArray of: CoordinateSpace}

	^self create: subSpaces! !