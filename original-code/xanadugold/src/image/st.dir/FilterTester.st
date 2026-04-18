'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:54 pm'!

RegionTester subclass: #FilterTester
	instanceVariableNames: 'myBaseRegions {ImmuSet NOCOPY of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(FilterTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!FilterTester methodsFor: 'creation'!

create
	super create.
	myBaseRegions _ NULL.! !

!FilterTester methodsFor: 'init'!

{ImmuSet of: XnRegion} initExamples
	| acc {SetAccumulator of: XnRegion} 
	  result {SetAccumulator of: Filter} 
	  space {FilterSpace} 
	  simple {ImmuSet} |
	acc _ SetAccumulator make.
	acc step: (IntegerRegion make).
	acc step: (IntegerRegion make: 3).
	acc step: (IntegerRegion make: 1 with: 7).
	acc step: (IntegerRegion make: 5 with: 7).
	acc step: (IntegerRegion make: 5 with: 9).
	(acc value cast: ImmuSet) stepper forEach: [ :each {XnRegion} |
		acc step: each complement].
	myBaseRegions _ (acc value cast: ImmuSet).
	result _ SetAccumulator make.
	space _ FilterSpace make: IntegerSpace make.
	myBaseRegions stepper forEach: [ :region {XnRegion} |
		result step: (Filter subsetFilter: space with: region).
		result step: (Filter notSubsetFilter: space with: region).
		result step: (Filter supersetFilter: space with: region).
		result step: (Filter notSupersetFilter: space with: region)].
	simple _ (result value cast: ImmuSet).
	simple stepper forEach: [ :one {Filter} |
		simple stepper forEach: [ :two {Filter} |
			one hashForEqual < two hashForEqual ifTrue:
				[result step: (one unionWith: two).
				result step: (one intersect: two)]]].
	^(result value cast: ImmuSet)! !

!FilterTester methodsFor: 'testing'!

{void} binaryCheck: a {XnRegion} with: b {XnRegion}
	| af {Filter} bf {Filter} |
	af _ a cast: Filter.
	bf _ b cast: Filter.
	super binaryCheck: af with: bf.

	(af isSubsetOf: bf) ifTrue:
		[myBaseRegions stepper forEach: [ :each {XnRegion} |
			((af match: each) not or: [bf match: each]) assert: 'subset/match test failed']]!

{void} unaryCheck: a {XnRegion}
	super unaryCheck: a.

	myBaseRegions stepper forEach: [ :each {XnRegion} |
		(((a cast: Filter) match: each) ~~ ((a complement cast: Filter) match: each)) assert: 'complement/match test failed']! !

!FilterTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartFilterTester: rcvr {Rcvr unused default: NULL}
	myBaseRegions _ NULL.! !

!FilterTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartFilterTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !