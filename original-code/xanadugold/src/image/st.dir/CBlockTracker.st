'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:33 pm'!

Heaper subclass: #CBlockTracker
	instanceVariableNames: '
		myFileName {char star | NULL}
		myLineNo {Int4}
		myMaxDirty {IntegerVar}
		myLimit {IntegerVar}
		myDirtySoFar {IntegerVar}
		myTrulyDirtySoFar {IntegerVar}
		myDirtyInfos {MuSet of: IntegerPos}
		myDirtyInfosCount {IntegerVar}
		myOuterTracker {CBlockTracker | NULL}
		myOccurencesCount {IntegerVar}'
	classVariableNames: 'TheTrackerList {CBlockTracker | NULL} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(CBlockTracker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CBlockTracker methodsFor: 'creation'!

create: dirty {IntegerVar} with: outer {CBlockTracker | NULL} 
	
	super create.
	dirty = -1
		ifTrue: [myMaxDirty _ 1000]
		ifFalse: [myMaxDirty _ dirty].
	myOuterTracker _ outer.
	myFileName _ NULL.
	myLineNo _ Int32Zero.
	myDirtySoFar _ Int32Zero.
	myTrulyDirtySoFar _ Int32Zero.
	myDirtyInfos _ MuSet make.
	myDirtyInfosCount _ Int32Zero.
	myOccurencesCount _ 1.
	outer == NULL
		ifTrue: [myLimit _ myMaxDirty]
		ifFalse: [myLimit _ outer slack min: myMaxDirty]! !

!CBlockTracker methodsFor: 'accessing'!

{void} dirty: info {FlockInfo | NULL} 
	
	myDirtySoFar _ myDirtySoFar + 1.
	myTrulyDirtySoFar _ myTrulyDirtySoFar + 1.
	(info ~~ NULL) assert.
	myDirtyInfos store: (IntegerPos make: info getShepherd hashForEqual).
	myDirtyInfosCount _ myDirtyInfos count.
	self reportProblems!

{CBlockTracker | NULL} fetchUnwrapped
	
	| result {CBlockTracker | NULL} stored {CBlockTracker | NULL} |
	result _ myOuterTracker.
	result ~~ NULL
		ifTrue: 
			[result innerDirtied: myMaxDirty.
			result innerTrulyDirtied: myTrulyDirtySoFar.
			result innerDirtyInfos: myDirtyInfos.
			result reportProblems].
	myFileName ~~ NULL
		ifTrue: 
			[(TheTrackerList == NULL 
			  or: [(stored _ TheTrackerList fetchMatch: self) == NULL])
				ifTrue: 
					[myOuterTracker _ TheTrackerList.
					myDirtyInfos _ MuSet make.
					TheTrackerList _ self]
				ifFalse: [stored updateFrom: self]].
	^result!

{void} track: fileName {char star} with: lineNo {Int32}

	myFileName _ fileName.
	myLineNo _ lineNo.! !

!CBlockTracker methodsFor: 'printing'!

{void} printAllOn: oo {ostream reference} 
	
	oo << self << '
'.
	myOuterTracker ~~ NULL
		ifTrue: [myOuterTracker printAllOn: oo]!

{void} printOn: oo {ostream reference}

	oo << '"' << myFileName << '"' << ', line ' << myLineNo << ': ' << self getCategory name << '('.
	oo << myMaxDirty << ',	' 
		<< myLimit << ',	' 
		<< myDirtySoFar << ',	' 
		<< myTrulyDirtySoFar << ', ' 
		<< myDirtyInfosCount << ', '
		<< myOccurencesCount << ')'! !

!CBlockTracker methodsFor: 'private: accessing'!

{IntegerVar} dirtyInfosCount

	^myDirtyInfosCount!

{IntegerVar} dirtySoFar

	^myDirtySoFar!

{CBlockTracker | NULL} fetchMatch: other {CBlockTracker} 
	
	(myFileName ~~ NULL
	 and: [other fileName ~~ NULL
	 and: [(String strcmp: myFileName with: other fileName) = Int32Zero 
	 and: [myLineNo = other lineNo]]])
		ifTrue: [^self]
		ifFalse: 
			[myOuterTracker == NULL
				ifTrue: [^NULL]
				ifFalse: [^myOuterTracker fetchMatch: other]]!

{char star | NULL} fileName

	^myFileName!

{void} innerDirtied: dirty {IntegerVar} 
	
	myDirtySoFar _ myDirtySoFar + dirty!

{void} innerDirtyInfos: dirties {MuSet of: IntegerPos}

	myDirtyInfos storeAll: dirties.
	myDirtyInfosCount _ myDirtyInfos count!

{void} innerTrulyDirtied: dirty {IntegerVar}

	myTrulyDirtySoFar _ myTrulyDirtySoFar + dirty!

{IntegerVar} limit

	^myLimit!

{Int32} lineNo

	^myLineNo!

{IntegerVar} maxDirty

	^myMaxDirty!

{IntegerVar} occurencesCount
	^ myOccurencesCount!

{void} reportProblems
	
	^VOID
	"(myLimit < 1000 
	 and: [myDirtyInfosCount > myMaxDirty 
	 		""((myDirtySoFar max: myTrulyDirtySoFar) max: myDirtyInfosCount) > myLimit""])
		ifTrue: 
			[cerr << '
Limit exceeded [
'.
			self printAllOn: cerr.
			[cerr endEntry.
			""myDirtyInfosCount > myMaxDirty
				ifTrue: [self halt]""] smalltalkOnly]"!

{IntegerVar} slack

	^myLimit - myDirtySoFar!

{IntegerVar} trulyDirtySoFar

	^myTrulyDirtySoFar!

{void} updateFrom: other {CBlockTracker}

	myMaxDirty _ myMaxDirty max: other maxDirty.
	myLimit _ myLimit min: other limit.
	myDirtySoFar _ myDirtySoFar max: other dirtySoFar.
	myTrulyDirtySoFar _ myTrulyDirtySoFar max: other trulyDirtySoFar.
	myDirtyInfosCount _ myDirtyInfosCount max: other dirtyInfosCount.
	myOccurencesCount _ myOccurencesCount + other occurencesCount! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CBlockTracker class
	instanceVariableNames: ''!

(CBlockTracker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CBlockTracker class methodsFor: 'creation'!

make: dirty {IntegerVar} with: outer {CBlockTracker | NULL}

	^self create: dirty with: outer! !

!CBlockTracker class methodsFor: 'smalltalk: init'!

linkTimeNonInherited

	TheTrackerList _ NULL! !

!CBlockTracker class methodsFor: 'printing'!

{void} printTrackersOn: oo {ostream reference} 
	"CBlockTracker printTrackersOn: cerr. cerr endEntry"
	
	oo << '

Consistent-Block Behavior

'.
	TheTrackerList ~~ NULL
		ifTrue: [TheTrackerList printAllOn: oo].
	oo << '
'.! !