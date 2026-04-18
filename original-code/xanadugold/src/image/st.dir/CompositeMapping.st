'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:51 pm'!

Mapping subclass: #CompositeMapping
	instanceVariableNames: '
		myCS {CoordinateSpace}
		myRS {CoordinateSpace}
		myMappings {ImmuSet of: Mapping}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces'!

(CompositeMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class CompositeMapping */
friend SPTR(Mapping) mapping(Mapping*, Mapping*);
friend SPTR(Mapping)  privateMakeMapping (CoordinateSpace *, CoordinateSpace *, ImmuSet OF1(Mapping) *);';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!CompositeMapping methodsFor: 'operations'!

{Mapping} appliedAfter: dsp {Dsp}

	| result {SetAccumulator of: Mapping} |
	result _ SetAccumulator make.
	myMappings stepper forEach: [ :each {Mapping} |
		result step: (each appliedAfter: dsp)].
	^CompositeMapping
		privateMakeMapping: self coordinateSpace
		with: self rangeSpace
		with: (result value cast: ImmuSet)!

{Mapping} inverse

	| result {Mapping} |
	Ravi thingToDo. "can this be done more efficiently by taking advantage of invariants?"
	result := Mapping make.CoordinateSpace: self rangeSpace with: self domainSpace.
	myMappings stepper forEach: [ :sub {Mapping} |
		result := result combine: sub inverse].
	^result!

{Mapping} preCompose: dsp {Dsp}

	| result {SetAccumulator of: Mapping} |
	result _ SetAccumulator make.
	myMappings stepper forEach: [ :each {Mapping} |
		result step: (each preCompose: dsp)].
	^CompositeMapping
		privateMakeMapping: self coordinateSpace
		with: self rangeSpace
		with: (result value cast: ImmuSet)!

{Mapping} restrict: region {XnRegion}

	| result {MuSet of: Mapping} |
	result _ MuSet make.
	myMappings stepper forEach: [ :each {Mapping} | 
		| restricted {Mapping} |
		restricted _ each restrict: region.
		restricted domain isEmpty ifFalse:
			[result store: restricted]].
	^CompositeMapping
		privateMakeMapping: self coordinateSpace
		with: self rangeSpace
		with: result asImmuSet!

{Mapping} restrictRange: region {XnRegion}

	| result {MuSet of: Mapping} |
	result _ MuSet make.
	myMappings stepper forEach: [ :each {Mapping} | 
		| restricted {Mapping} |
		restricted _ each restrictRange: region.
		restricted domain isEmpty ifFalse:
			[result store: restricted]].
	^CompositeMapping
		privateMakeMapping: self coordinateSpace
		with: self rangeSpace
		with: result asImmuSet!

{Mapping} transformedBy: dsp {Dsp}

	| result {SetAccumulator of: Mapping} |
	result _ SetAccumulator make.
	myMappings stepper forEach: [ :each {Mapping} |
		result step: (each transformedBy: dsp)].
	^CompositeMapping
		privateMakeMapping: self coordinateSpace
		with: self rangeSpace
		with: (result value cast: ImmuSet)! !

!CompositeMapping methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^myCS!

{XnRegion} domain
	
	| result {XnRegion} |
	result _ self coordinateSpace emptyRegion.
	myMappings stepper forEach: [ :each {Mapping} |
		result _ result unionWith: each domain].
	^result!

{Dsp | NULL} fetchDsp
	^NULL!

{BooleanVar} isComplete

	^false "blast?"!

{BooleanVar} isIdentity

	^false!

{XnRegion} range
	| result {XnRegion} |
	result _ self rangeSpace emptyRegion.
	myMappings stepper forEach: [ :each {Mapping} |
		result _ result unionWith: each range].
	^result!

{CoordinateSpace} rangeSpace

	^myRS!

{ImmuSet of: Mapping} simpleMappings
	^myMappings!

{ImmuSet of: Mapping} simpleRegionMappings

	| simpleMappings {MuSet of: Mapping} eachSimple {Mapping} |
	
	simpleMappings _ MuSet make.
	myMappings stepper forEach: [ :each {Mapping} | 
		each domain isSimple 
			ifTrue:
				[simpleMappings store: each]
			ifFalse:
				[each domain simpleRegions forEach: [:simpleRegion {XnRegion} |
					eachSimple _ each restrict: simpleRegion.
					simpleMappings store: eachSimple]]].
	^(ImmuSet make.MuSet: simpleMappings)! !

!CompositeMapping methodsFor: 'transforming'!

{Position} inverseOf: pos {Position}

	| result {Position} |
	result _ NULL.
	myMappings stepper forEach: [ :each {Mapping} |
		(each range hasMember: pos) ifTrue:
			[result == NULL
				ifTrue: [result _ each inverseOf: pos]
				ifFalse: [Heaper BLAST: #MultiplePreImages]]].
	result == NULL
		ifTrue: [Heaper BLAST: #NotInRange].
	^result!

{XnRegion} inverseOfAll: reg {XnRegion}

	| result {XnRegion} |
	result _ self coordinateSpace emptyRegion.
	myMappings stepper forEach: [ :each {Mapping} |
		result _ result unionWith: (each inverseOfAll: reg)].
	^result!

{Position} of: pos {Position}

	| result {Position} |
	result _ NULL.
	myMappings stepper forEach: [ :each {Mapping} |
		(each domain hasMember: pos) ifTrue:
			[result == NULL
				ifTrue: [result _ each of: pos]
				ifFalse: [Heaper BLAST: #MultipleImages]]].
	result == NULL
		ifTrue: [Heaper BLAST: #NotInDomain].
	^result!

{XnRegion} ofAll: reg {XnRegion}

	| result {XnRegion} |
	result _ self rangeSpace emptyRegion.
	myMappings stepper forEach: [ :each {Mapping} |
		result _ result unionWith: (each ofAll: reg)].
	^result! !

!CompositeMapping methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << self getCategory name.
	myMappings printOnWithSimpleSyntax: stream with: '(' with: ', ' with: ')'! !

!CompositeMapping methodsFor: 'private: private creation'!

create: cs {CoordinateSpace} with: rs {CoordinateSpace} with: mappings {ImmuSet of: Mapping}
	super create.
	myCS _ cs.
	myRS _ rs.
	myMappings _ mappings! !

!CompositeMapping methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.CompositeMapping hashForEqual bitXor: myMappings hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: CompositeMapping into: [:cm |
			^cm simpleMappings isEqual: myMappings]
		others: [^false].
	^false "fodder"! !

!CompositeMapping methodsFor: 'protected: protected'!

{Mapping} fetchCombine: mapping {Mapping}

	(mapping isKindOf: EmptyMapping)
		ifTrue: [  ^ self ]
		ifFalse:
			[| result {MuSet of: Mapping} |
			result _ myMappings asMuSet.
			(mapping isKindOf: CompositeMapping) ifTrue:
				[mapping simpleMappings stepper forEach: [ :each {Mapping} |
					CompositeMapping storeMapping: each with: result]]
				ifFalse:
					[CompositeMapping storeMapping: mapping with: result].
			^CompositeMapping privateMakeMapping: myCS with: myRS with: result asImmuSet]! !

!CompositeMapping methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.
	myRS _ receiver receiveHeaper.
	myMappings _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.
	xmtr sendHeaper: myRS.
	xmtr sendHeaper: myMappings.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompositeMapping class
	instanceVariableNames: ''!

(CompositeMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class CompositeMapping */
friend SPTR(Mapping) mapping(Mapping*, Mapping*);
friend SPTR(Mapping)  privateMakeMapping (CoordinateSpace *, CoordinateSpace *, ImmuSet OF1(Mapping) *);';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!CompositeMapping class methodsFor: 'functions'!

{Mapping} privateMakeMapping: cs {CoordinateSpace} 
	with: rs {CoordinateSpace} 
	with: mappings {ImmuSet of: Mapping}
	
	mappings isEmpty
		ifTrue: [^EmptyMapping make: cs with: rs]
		ifFalse:
			[mappings count = 1
				ifTrue: [^mappings theOne cast: Mapping]
				ifFalse: [^CompositeMapping create: cs with: rs with: mappings]]!

{void} storeMapping: map {Mapping} with: maps {MuSet of: Mapping}
	"store a map into the set, checking to see if it can be combined with another"
	maps stepper forEach: [ :each {Mapping} | | combined {Mapping} |
		combined _ map fetchCombine: each.
		combined ~~ NULL ifTrue:
			[combined _ each fetchCombine: map].
		combined ~~ NULL ifTrue:
			[maps remove: each.
			maps introduce: combined.
			^VOID]].
	maps introduce: map! !