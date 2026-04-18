'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:39 pm'!

Tester subclass: #ScruSetTester
	instanceVariableNames: 'myTestSets {ScruTable NOCOPY of: ScruSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(ScruSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!ScruSetTester methodsFor: 'creation'!

create
	super create.
	myTestSets _ NULL! !

!ScruSetTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}

	oo << 'Start ScruSet testing
'.
	self testScruSets stepper forEach: [:s {ScruSet} |
		self unaryCheck: s].
	self testIsEmpty: oo.
	self testhasMember: oo.
	self testContentsEqual: oo.
	self testIntersects: oo.
	self testIsSubsetOf: oo.
	
	oo << 'End of Scruset testing
'! !

!ScruSetTester methodsFor: 'tests'!

{void} testContentsEqual: oo {ostream reference}

	oo << 'testing contentsEqual() and contentsHash()
'.
	((self getScruSet: 2) contentsEqual: (self getScruSet: 3)) not
		assert: 'contentsEqual failed'.
	((self getScruSet: 2) contentsEqual: (self getScruSet: 4)) not
		assert: 'contentsEqual failed'.
	((self getScruSet: 2) contentsEqual: (self getScruSet: 6))
		assert: 'contentsEqual failed'.
	((self getScruSet: 2) contentsEqual: (self getScruSet: 8))
		assert: 'contentsEqual failed'.
	"ensure reflexive"
	((self getScruSet: 3) contentsEqual: (self getScruSet: 2)) not
		assert: 'contentsEqual failed'.
	((self getScruSet: 4) contentsEqual: (self getScruSet: 2)) not
		assert: 'contentsEqual failed'.
	((self getScruSet: 6) contentsEqual: (self getScruSet: 2))
		assert: 'contentsEqual failed'.
	((self getScruSet: 8) contentsEqual: (self getScruSet: 2))
		assert: 'contentsEqual failed'.
	((self getScruSet: 5) contentsEqual: (self getScruSet: 4)) not
		assert: 'contentsEqual failed'.
	((self getScruSet: 5) contentsEqual: (self getScruSet: 7))
		assert: 'contentsEqual failed'.
	((self getScruSet: 2) contentsHash = (self getScruSet: 6) contentsHash)
		assert: 'contentsEqual failed'.
	((self getScruSet: 5) contentsHash = (self getScruSet: 7) contentsHash)
		assert: 'contentsEqual failed'.
	oo << 'end of ContentsEqual tests
'!

{void} testhasMember: oo {ostream reference}

	| mem1 {Heaper} mem2 {Heaper} |
	oo << 'testing hasMember and theOne
'.
	mem1 _ (self getScruSet: 2) theOne.
	((self getScruSet: 2) hasMember: mem1) assert: 'hasMember failed'.
	((self getScruSet: 8) hasMember: mem1) assert: 'hasMember failed'.
	((self getScruSet: 4) hasMember: mem1) assert: 'hasMember failed'.
	mem2 _ (self getScruSet: 3) theOne.
	((self getScruSet: 3) hasMember: mem2) assert: 'hasMember failed'.
	((self getScruSet: 2) hasMember: mem2) not assert: 'hasMember failed'.
	((self getScruSet: 5) hasMember: mem2) not assert: 'hasMember failed'.

	oo << 'end of hasMember and theOne tests
'!

{void} testIntersects: oo {ostream reference}

	oo << 'testing intersects
'.
	((self getScruSet: 2) intersects: (self getScruSet: 1)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 1) intersects: (self getScruSet: 2)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 2) intersects: (self getScruSet: 3)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 3) intersects: (self getScruSet: 2)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 5) intersects: (self getScruSet: 4)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 5) intersects: (self getScruSet: 3)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 5) intersects: (self getScruSet: 2)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 5) intersects: (self getScruSet: 1)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 4) intersects: (self getScruSet: 5)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 3) intersects: (self getScruSet: 5)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 2) intersects: (self getScruSet: 5)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 1) intersects: (self getScruSet: 5)) not
		assert: 'failed intersects: test'.
	((self getScruSet: 2) intersects: (self getScruSet: 6)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 6) intersects: (self getScruSet: 2)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 7) intersects: (self getScruSet: 5)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 5) intersects: (self getScruSet: 7)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 2) intersects: (self getScruSet: 8)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 8) intersects: (self getScruSet: 2)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 9) intersects: (self getScruSet: 5)) 
		assert: 'failed intersects: test'.
	((self getScruSet: 5) intersects: (self getScruSet: 9)) 
		assert: 'failed intersects: test'.
	oo << 'end of intersects tests
'!

{void} testIsEmpty: oo {ostream reference}

	oo << 'testing isEmpty
'.
	(self getScruSet: 1) isEmpty assert: 'failed isEmpty test'.
	(self getScruSet: 2) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 3) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 4) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 5) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 6) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 7) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 8) isEmpty not assert: 'failed isEmpty test'.
	(self getScruSet: 9) isEmpty not assert: 'failed isEmpty test'.
	oo << 'end of isEmpty tests
'!

{void} testIsSubsetOf: oo {ostream reference}

	oo << 'testing isSubsetOf
'.
	((self getScruSet: 3) isSubsetOf: (self getScruSet: 2)) not 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 2) isSubsetOf: (self getScruSet: 3)) not 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 2) isSubsetOf: (self getScruSet: 4)) 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 4) isSubsetOf: (self getScruSet: 2)) not 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 8) isSubsetOf: (self getScruSet: 4)) 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 4) isSubsetOf: (self getScruSet: 8)) not 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 5) isSubsetOf: (self getScruSet: 9)) 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 9) isSubsetOf: (self getScruSet: 5)) 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 5) isSubsetOf: (self getScruSet: 4)) not 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 4) isSubsetOf: (self getScruSet: 5)) not 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 6) isSubsetOf: (self getScruSet: 2)) 
		assert: 'failed isSubsetOf test'.
	((self getScruSet: 2) isSubsetOf: (self getScruSet: 6)) 
		assert: 'failed isSubsetOf test'.
	oo << 'end of isSubsetOf tests
'!

{void} unaryCheck: a {ScruSet} 
	(a contentsEqual: a) assert: 'identity test failed.'.
	a isEmpty not == (a intersects: a) assert: 'intersects test failed.'.
	(a isSubsetOf: a) assert: 'self subset test failed.'.
	(a isEqual: a) assert: 'isEqual test failed'.

	"verify that the set knows about all members that it can deliver through a stepper"
	a stepper forEach: [:elem {Heaper} |
		(a hasMember: elem) assert: 'failed hasMember for a stepped element'].! !

!ScruSetTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartScruSetTester: rcvr {Rcvr}
	myTestSets _ NULL! !

!ScruSetTester methodsFor: 'deferred: initialization'!

{ScruSet} generateSet

	self subclassResponsibility!

{ScruSet} generateSetContaining: stuff {Stepper}

	self subclassResponsibility! !

!ScruSetTester methodsFor: 'protected: accessing'!

{ScruSet} getScruSet: number {IntegerVar}
	[IntegerPos] USES.
	^ (myTestSets get: (number - 1) integer) cast: ScruSet!

{void} setTestSets: table {ScruTable of: ScruSet}

	myTestSets _ table!

{ScruTable of: ScruSet} testScruSets
	
	myTestSets == NULL ifTrue: [myTestSets _ self generateScruSets].
	^ myTestSets! !

!ScruSetTester methodsFor: 'private: scruset generation'!

{ScruTable of: ScruSet} generateScruSets

	"generateScruSets must generate a table of sets in the following order:
	  1) an empty set
	  2) a set containing one element
	  3) a set containing one element which is different from that in set 2
	  4) a set containing at least two elements, one equal to the element in set 2
	  5) a set containing at least two elements, different from all previous elements
	  6) a set with the same contents as set 2 not generated by copy()
	  7) a set with the same contents as set 5 not generated by copy()
	  8) a set generated by set 2 copy
	  9) a set generated by set 5 copy
	  other sets are optional and will only be tested with general tests (check).
	  "
	
	| settab {Accumulator} idTab1 {Accumulator} idTab2 {Accumulator}
	 idTab3 {ScruTable} |
	"settab is an accumulator for a table of sets to return.
	idTab1,2 are accumulators on tables used to generate a set containing
	desired elements for testing."
	
	settab _ MuArray arrayAccumulator.
	idTab1 _ MuArray arrayAccumulator.
	idTab2 _ MuArray arrayAccumulator.
	
	settab step: self generateSet. "#1"
	idTab1 step: (UInt8Array string: 'One').
	idTab3 _ (idTab1 value cast: ScruTable) asImmuTable.
	settab step: (self generateSetContaining: (idTab1 value cast: ScruTable) stepper). "#2"
	idTab2 step: (UInt8Array string: 'Two').
	settab step: (self generateSetContaining: (idTab2 value cast: ScruTable) stepper). "#3"
	idTab1 step: (UInt8Array string: 'Three').
	settab step: (self generateSetContaining: (idTab1 value cast: ScruTable) stepper). "#4"
	idTab2 destroy.
	idTab2 _ MuArray arrayAccumulator.
	idTab2 step: (UInt8Array string: 'Four').
	idTab2 step: (UInt8Array string: 'Five').
	idTab2 step: (UInt8Array string: 'Six').
	settab step: (self generateSetContaining: (idTab2 value cast: ScruTable) stepper). "#5"
	settab step: (self generateSetContaining: idTab3 stepper). "#6"
	settab step: (self generateSetContaining: (idTab2 value cast: ScruTable)  stepper). "#7"
	settab step: (((settab value cast: ScruTable) get: 1 integer) cast: ScruSet) copy. "#8"
	settab step: (((settab value cast: ScruTable) get: 4 integer) cast: ScruSet) copy. "#9"
	^ settab value cast: ScruTable! !

!ScruSetTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartScruSetTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScruSetTester class
	instanceVariableNames: ''!

(ScruSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!ScruSetTester class methodsFor: 'smalltalk: smalltalk initialization'!

suppressInitTimeInherited!

suppressLinkTimeInherited! !