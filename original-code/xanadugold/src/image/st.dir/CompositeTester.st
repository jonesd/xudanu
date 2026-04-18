'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:05 pm'!

RegionTester subclass: #CompositeTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!CompositeTester methodsFor: 'init'!

{void} combineRegions: regions {ImmuSet of: XnRegion} 
	with: result {SetAccumulator of: XnRegion}
	regions stepper forEach: [ :one {XnRegion} |
		regions stepper forEach: [ :two {XnRegion} |
			one hashForEqual < two hashForEqual ifTrue:
				[result step: (one unionWith: two).
				result step: (one intersect: two)]]]!

{void} createCompositeRegions: space {CoordinateSpace} 
	with: key {Position} 
	with: subRegions {ImmuSet of: XnRegion}
	with: result {SetAccumulator of: XnRegion}
	subRegions stepper forEach: [ :sub {XnRegion} |
		result step: (CompositeRegion compositeSliceRegion: space with: key with: sub).
		result step: (CompositeRegion compositeGapRegion: space with: key with: sub)]!

{ImmuSet of: XnRegion} initExamples
	| result {SetAccumulator} space {CompositeSpace} 
	  ints {ImmuSet of: XnRegion} ids {ImmuSet of: XnRegion} trees {ImmuSet of: XnRegion} |
	space _ CompositeSpace make: (MuArray array: IntegerSpace make
		with: IDSpace make
		with: TreeSpace make).
	result _ SetAccumulator make.
	result step: (IntegerRegion make).
	result step: (IntegerRegion make: 1 with: 7).
	result step: (IntegerRegion make: 5 with: 9).
	self combineRegions: (result value cast: ImmuSet) with: result.
	ints _ (result value cast: ImmuSet).
	result _ SetAccumulator make.
	result step: IDRegion make.
	result step: ((IDRegion make.ID: (ID key: 'alpha'))
		with: (ID key: 'gamma')).
	result step: ((IDRegion make.ID: (ID key: 'beta'))
		with: (ID key: 'xi')).
	self combineRegions: (result value cast: ImmuSet) with: result.
	ids _ (result value cast: ImmuSet).
	result _ SetAccumulator make.
	result step: TreeRegion make.
	result step: ((TreePosition make turn: 1) asRegion
		with: ((TreePosition make turn: 3) turn: 7)).
	result step: ((TreePosition make turn: 2) asRegion
		with: ((TreePosition make turn: 4) turn: 2)).
	self combineRegions: (result value cast: ImmuSet) with: result.
	trees _ (result value cast: ImmuSet).
	result _ SetAccumulator make.
	self createCompositeRegions: space with: Integer0 with: ints with: result.
	self createCompositeRegions: space with: 1 integer with: ids with: result.
	self createCompositeRegions: space with: 2 integer with: trees with: result.
	self combineRegions: (result value cast: ImmuSet) with: result.
	^result value cast: ImmuSet! !

!CompositeTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !