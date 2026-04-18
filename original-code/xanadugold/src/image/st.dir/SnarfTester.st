'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:47 pm'!

Tester subclass: #SnarfTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(SnarfTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SnarfTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"SnarfTester runTest."
	self testAllocationsOn: oo.!

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

{void} testAllocationsOn: oo {ostream reference}
	"packer _ snarfPacker create: UrdiVew create."
	| handle handler index |
	handle _ SnarfHandle create: 1 with: 5000.
	handler _ SnarfHandler create: handle.
	index _ handler allocate: 100.
	(handler refit: index with: 1000) assert: 'refit failed'.
	(handler refit: index with: 10) assert: 'refit failed'.
	(handler refit: index with: IntegerVar0) assert: 'refit failed'.!

{void} testBinaryRegionOpsOn: oo {ostream reference}
	myExampleRegions stepper forEach: [:one {XnRegion} |
		myExampleRegions stepper forEach: [:two {XnRegion} |
			one hashForEqual <= two hashForEqual ifTrue:
				[[oo << 'checking binary ops of ' << one << ' and ' << two << '
'] translateOnly. "smalltalk runs out of space"
				self binaryCheck: one with: two]]].
	oo << 'binary regions tests succeeded
'!

{void} testUnaryRegionOpsOn: oo {ostream reference}
	myExampleRegions stepper forEach: [:one {XnRegion} |
		[oo << 'checking unary ops of ' << one << '
'] translateOnly. "smalltalk runs out of space"
		self unaryCheck: one].
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

!SnarfTester methodsFor: 'protected: accessing'!

{ImmuSet of: XnRegion} exampleRegions
	^myExampleRegions! !

!SnarfTester methodsFor: 'protected: creation'!

create: name {char star}
	super create: name.
	myExampleRegions _ NULL.! !

!SnarfTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !