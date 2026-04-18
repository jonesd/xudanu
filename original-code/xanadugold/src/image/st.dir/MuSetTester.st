'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:38 pm'!

ScruSetTester subclass: #MuSetTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(MuSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!MuSetTester methodsFor: 'deferred: initialization'!

{ScruSet} generateSet

	self subclassResponsibility!

{ScruSet} generateSetContaining: stuff {Stepper}

	self subclassResponsibility! !

!MuSetTester methodsFor: 'tests'!

{void} binaryCheck: a {MuSet} with: b {MuSet}
	| anb {MuSet} bna {MuSet} amb {MuSet} aub {MuSet} bua {MuSet} |
	anb _ a copy cast: MuSet.
	anb restrictTo: b.
	bna _ b copy cast: MuSet.
	bna restrictTo: a.
	(anb contentsEqual: bna) assert: 'intersect test failed.'.
	(anb isSubsetOf: a) assert: 'intersect/subset test failed.'.
	(anb isSubsetOf: b) assert: 'intersect/subset test failed.'.
	(bna isSubsetOf: a) assert: 'intersect/subset test failed.'.
	(bna isSubsetOf: b) assert: 'intersect/subset test failed.'.

	(a intersects: b) == (anb isEmpty not) assert: 'intersects test failed.'.
	amb _ a copy cast: MuSet.
	amb wipeAll: b.
	(amb intersects: b) not assert: 'minus/intersect test failed.'.
	(amb isSubsetOf: a) assert: 'minus/subset test failed.'.
	aub _ a copy cast: MuSet.
	aub storeAll: b.
	bua _ b copy cast: MuSet.
	bua storeAll: a.
	(aub contentsEqual: bua) assert: 'unionWith test failed.'.
	(a isSubsetOf: aub) assert: 'union/subset test failed.'.
	(b isSubsetOf: aub) assert: 'union/subset test failed.'.
	
	(((a isSubsetOf: b) and: [b isSubsetOf: a]) == (a contentsEqual: b)) assert: 'subset/equals test failed.'.!

{void} binarySetTestsOn: oo {ostream reference} 
	oo << 'start binary tests
'. 
	self testMuSets stepper forEach: [:setone {MuSet} | 
		self testMuSets stepper forEach: [:settwo {MuSet} | 
			self binaryCheck: setone with: settwo]].
	oo << 'end binary tests
'!

{void} unaryCheck: a {ScruSet} 
	| ta {MuSet} |
	
	super unaryCheck: a.
	ta _ a copy cast: MuSet.
	ta wipeAll: a.
	ta isEmpty assert: 'self minus/isEmpty failed.'.
	ta _ a copy cast: MuSet.
	ta restrictTo: a.
	(ta contentsEqual: a) assert: 'intersect/isEqual test failed.'! !

!MuSetTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	oo << 'MuSet testing
'.
	super allTestsOn: oo.
	self binarySetTestsOn: oo.
	oo << 'End of MuSet testing
'! !

!MuSetTester methodsFor: 'protected: accessing'!

{ScruTable of: MuSet} testMuSets

	^ self testScruSets! !

!MuSetTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MuSetTester class
	instanceVariableNames: ''!

(MuSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!MuSetTester class methodsFor: 'smalltalk: smalltalk initialization'!

suppressInitTimeInherited!

suppressLinkTimeInherited! !