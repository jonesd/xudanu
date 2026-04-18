'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:24 pm'!

RegionTester subclass: #PointRegionTester
	instanceVariableNames: 'myExamplePoints {ImmuSet NOCOPY of: PointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(PointRegionTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!PointRegionTester methodsFor: 'creation'!

create
	super create.
	myExamplePoints _ NULL.! !

!PointRegionTester methodsFor: 'init'!

{ImmuSet of: XnRegion} initExamples
	"a test array of integer regions"
	| result {SetAccumulator} 
	  temp {SetAccumulator} 
	  exampleIntegers {ImmuSet of: Integer}
	  exampleIntegerRegions {ImmuSet of: IntegerRegion} |
	  
	result _ SetAccumulator make.
	result step: 2 integer.
	result step: 3 integer.
	result step: 5 integer.
	result step: 7 integer.
	result step: 11 integer.
	exampleIntegers _ result value cast: ImmuSet.
	
	result _ SetAccumulator make.
	result step: IntegerRegion make complement.
	result step: (IntegerRegion make: 3 with: 7).
	result step: (IntegerRegion make: 3 with: 7) complement.
	result step: (IntegerRegion make: 7 with: 10).
	result step: (IntegerRegion make: 7 with: 10) complement.
	result step: (IntegerRegion make: 10 with: 20).
	result step: (IntegerRegion make: 10 with: 20) complement.
	result step: ((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion make: 10 with: 20)).
	result step: ((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion make: 10 with: 20)) complement.
	result step: (IntegerRegion after: 1).
	result step: (IntegerRegion before: 1).
	result step: (IntegerRegion after: 3).
	result step: (IntegerRegion before: 3).
	result step: (IntegerRegion after: 5).
	result step: (IntegerRegion before: 5).
	exampleIntegerRegions _ result value cast: ImmuSet.
	
	result _ SetAccumulator make.
	temp _ SetAccumulator make.
	temp step: Integer0.
	temp step: -100001 integer.
	temp step: 100001 integer.
	temp step: 100000 integer.
	temp step: 5000 integer.
	temp step: -5000 integer.
	(exampleIntegers unionWith: (temp value cast: ImmuSet)) stepper forEach: [:x {IntegerPos} |
		(exampleIntegers unionWith: (temp value cast: ImmuSet)) stepper forEach: [:y {IntegerPos} |
			result step: (PointPos make: x asIntegerVar with: y asIntegerVar)]].
	myExamplePoints _ result value cast: ImmuSet.
	
	result _ SetAccumulator make.
	result step: PointRegion make.
	exampleIntegerRegions stepper forEach: [:xRegion {IntegerRegion} |
		exampleIntegerRegions stepper forEach: [:yRegion {IntegerRegion} |
			result step: (PointRegion make.IntegerRegion: xRegion with: yRegion)]].
	^result value cast: ImmuSet! !

!PointRegionTester methodsFor: 'tests'!

{void} allTestsOn: oo {ostream reference}
	"PointRegionTester runTest"
	super allTestsOn: oo.
	
	self exampleRegions stepper forEach: [:one {XnRegion} | 
		myExamplePoints stepper forEach: [:pt {PointPos} |
			self check: one withPoint: pt]].
	oo << 'PointRegion consistency checks succeeded
'!

{void} binaryCheck: a {XnRegion} with: b {XnRegion}
	| asub {XnRegion} aub {XnRegion} |
	super binaryCheck: a with: b.
	
	asub _ a simpleUnion: b.
	aub _ a unionWith: b.
	(asub isEqual: (b simpleUnion: a)) assert: 'simpleUnion test failed.'.
	(aub isSubsetOf: asub) assert: 'simpleUnion/subset test failed.'.
	asub isSimple assert: 'simpleUnion/isSimple test failed.'.!

{void} check: a {XnRegion} withPoint: b {PointPos}
	| br {XnRegion} anb {XnRegion} |
	anb _ a intersect: (br _ PointRegion make.XuPoint: b).
	(anb isEqual: (br intersect: a)) assert: 'intersect test failed.'.
	(anb isSubsetOf: a) assert: 'intersect/subset test failed.'. 
	(anb isSubsetOf: br) assert: 'intersect/subset test failed.'.

	anb isEmpty not 
		ifTrue: [(a hasMember: b) assert: 'hasMember test failed']!

{void} unaryCheck: a {XnRegion}
	"| myUnion {XuRegion} empty {XuRegion} |"
	super unaryCheck: a.
	
	a isSimple == ((a simpleUnion: a) isEqual: a) assert: 'isSimple/simpleUnion test failed.'.
	a isSimple == (a asSimpleRegion isEqual: a) assert: 'isSimple/asSimpleRegion test failed.'.
	a isEmpty == a asSimpleRegion isEmpty assert: 'empty simple region test failed.'.

	"empty _ a minus: a.
	myUnion _ empty.
	a simpleRegions forEach: [:piece {XuRegion} | myUnion _ myUnion unionWith: piece].
	(a isEqual: myUnion) assert: 'simpleRegions/union test failed.'."! !

!PointRegionTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartPointRegionTester: rcvr {Rcvr unused default: NULL}
	myExamplePoints _ NULL.! !

!PointRegionTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartPointRegionTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !