'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:18 pm'!

Tester subclass: #RegionTester
	instanceVariableNames: 'myExampleRegions {ImmuSet NOCOPY of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(RegionTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!RegionTester methodsFor: 'deferred: init'!

{ImmuSet of: XnRegion} initExamples
	self subclassResponsibility! !

!RegionTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	myExampleRegions _ self initExamples.
	self testExtraOn: oo.
	self testUnaryRegionOpsOn: oo.
	self testBinaryRegionOpsOn: oo.!

{void} binaryCheck: a {XnRegion} with: b {XnRegion}
	| anb {XnRegion} amb {XnRegion} aub {XnRegion} |
	anb _ a intersect: b.
	(anb isEqual: (b intersect: a)) assert: 'intersect test failed.'.
	(anb isSubsetOf: a) assert: 'intersect/subset test failed.'.
	(anb isSubsetOf: b) assert: 'intersect/subset test failed.'.

	(a intersects: b) == anb isEmpty not assert: 'intersects test failed.'.
	amb _ a minus: b.
	(amb intersects: b) not assert: 'minus/intersect test failed.'.
	(amb isSubsetOf: a) assert: 'minus/subset test failed.'.
	
	aub _ a unionWith: b.
	(aub isEqual: (b unionWith: a)) assert: 'unionWith test failed.'.
	(a isSubsetOf: aub) assert: 'union/subset test failed.'.
	(b isSubsetOf: aub) assert: 'union/subset test failed.'.
	
	(((a isSubsetOf: b) and: [b isSubsetOf: a]) == (a isEqual: b)) assert: 'subset/equals test failed.'.!

{void} testBinaryRegionOpsOn: oo {ostream reference}
	myExampleRegions stepper forEach: [:one {XnRegion} |
		myExampleRegions stepper forEach: [:two {XnRegion} |
			one hashForEqual <= two hashForEqual ifTrue: [
				Heaper problems.AllBlasts
					handle: [ :ex |
						| prob {Problem} |
						'prob = &PROBLEM(ex);' translateOnly.
						[prob _ Problem create: ex PROBLEM with: ex parameter
									with: ex initialContext sender printString with: 0] smalltalkOnly.
						[cerr <<prob] smalltalkOnly .
						'operator<<(cerr,prob);'translateOnly.
						cerr << '
'.
						oo << 'problem checking binary ops of ' << one << ' and ' << two << '
'.
						ex return]
					do: [self binaryCheck: one with: two]]]].
	oo << 'binary regions tests succeeded
'!

{void} testExtraOn: oo {ostream reference}!

{void} testUnaryRegionOpsOn: oo {ostream reference}
	myExampleRegions stepper forEach: [:one {XnRegion} |
		Heaper problems.AllBlasts
			handle: [ :ex |
				| prob {Problem} |
				'prob = &PROBLEM(ex);' translateOnly.
				[prob _ Problem create: ex PROBLEM with: ex parameter
							with: ex initialContext sender printString with: 0] smalltalkOnly.
					[cerr <<prob] smalltalkOnly .
						'operator<<(cerr,prob);'translateOnly.
						cerr << '
'.

				oo << 'problem checking unary ops of ' << one << '
'.
				ex return]
			do: [self unaryCheck: one]].
	oo << 'unary regions tests succeeded
'!

{void} unaryCheck: a {XnRegion}
	(a isEqual: a) assert: 'identity test failed.'.
	a isEmpty not == (a intersects: a) assert: 'intersects test failed.'.
	(a minus: a) isEmpty assert: 'self minus/isEmpty failed.'.
	(a isSubsetOf: a) assert: 'self subset test failed.'.
	((a intersect: a) isEqual: a) assert: 'intersect/isEqual test failed.'.
	a isFull == a complement isEmpty assert: 'infinity inverse test failed.'.
	(a intersect: a complement) isEmpty assert: 'intersect/complement test failed.'.
	((a minus: a complement) isEqual: a) assert: 'minus/complement test failed.'.
	(a complement complement isEqual: a) assert: 'double complement test failed.'.
	(a unionWith: a complement) isFull assert: 'union/complement test failed.'.! !

!RegionTester methodsFor: 'protected: accessing'!

{ImmuSet of: XnRegion} exampleRegions
	^myExampleRegions! !

!RegionTester methodsFor: 'protected: creation'!

create
	super create.
	myExampleRegions _ NULL.! !

!RegionTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartRegionTester: rcvr {Rcvr unused default: NULL}
	myExampleRegions _ NULL.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RegionTester class
	instanceVariableNames: ''!

(RegionTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!RegionTester class methodsFor: 'smalltalk: initialization'!

suppressInitTimeInherited!

suppressLinkTimeInherited! !