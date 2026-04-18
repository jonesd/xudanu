'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:10 pm'!

CrossSpace subclass: #GenericCrossSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
GenericCrossSpace comment:
'Default implementation of cross coordinate space.
was NOT.A.TYPE but that prevented compilation'!

(GenericCrossSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!GenericCrossSpace methodsFor: 'making'!

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
	
	| result {PtrArray of: XnRegion} |
	result := subRegions copy cast: PtrArray.
	Int32Zero almostTo: result count do: [ :dimension {Int32} |
		(result fetch: dimension) == NULL ifTrue:
			[result at: dimension
				store: (self axis: dimension) fullRegion]
		ifFalse: [((result fetch: dimension) cast: XnRegion) isEmpty ifTrue:
			[^self emptyRegion cast: CrossRegion]]].
	^GenericCrossRegion make: self with: 1 with: result!

{CrossRegion} extrusion: dimension {Int32} with: subRegion {XnRegion}
	
	| projs {PtrArray of: XnRegion} |
	subRegion isEmpty ifTrue: [^self emptyRegion cast: CrossRegion].
	projs := PtrArray nulls: mySubSpaces count.
	Int32Zero almostTo: mySubSpaces count do: [ :i {Int32} |
		i = dimension ifTrue:
			[projs at: i store: subRegion]
		ifFalse:
			[projs at: i
				store: ((mySubSpaces fetch: i) cast: CoordinateSpace) fullRegion]].
	^GenericCrossRegion make: self with: 1 with: projs! !

!GenericCrossSpace methodsFor: 'private: creation'!

create: subSpaces {PtrArray of: CoordinateSpace}
	
	super create: subSpaces.
	self finishCreate: (GenericCrossRegion empty: self)
		with: (GenericCrossRegion full: self with: subSpaces)
		with: (GenericCrossDsp identity: self with: subSpaces)
		with: (CrossOrderSpec fetchAscending: self with: subSpaces)
		with: (CrossOrderSpec fetchDescending: self with: subSpaces).! !

!GenericCrossSpace methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << '<'.
	Int32Zero almostTo: mySubSpaces count do: [ :i {Int32} |
		i > Int32Zero ifTrue: [oo << ' x '].
		oo << (mySubSpaces fetch: i)].
	oo << '>'! !

!GenericCrossSpace methodsFor: 'hooks:'!

{void SEND.HOOK} sendGenericCrossSpaceTo: xmtr {Xmtr}

	xmtr sendHeaper: mySubSpaces.! !

!GenericCrossSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}
	
	self sendGenericCrossSpaceTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GenericCrossSpace class
	instanceVariableNames: ''!

(GenericCrossSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!GenericCrossSpace class methodsFor: 'rcvr pseudoconstructors'!

{Heaper} make.Rcvr: rcvr {Rcvr}

	^(GenericCrossSpace new.Become: ((rcvr cast: SpecialistRcvr) makeIbid: GenericCrossSpace))
		 create: (rcvr receiveHeaper cast: PtrArray)! !

!GenericCrossSpace class methodsFor: 'pseudoconstructors'!

{CrossSpace} make: subSpaces {PtrArray of: CoordinateSpace}

	^GenericCrossSpace create: subSpaces! !