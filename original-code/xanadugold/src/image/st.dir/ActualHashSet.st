'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:32 pm'!

HashSet subclass: #ActualHashSet
	instanceVariableNames: '
		myHashValues {UInt32Array NOCOPY}
		myHashEntries {SharedPtrArray NOCOPY}
		myTally {Int32}'
	classVariableNames: '
		AddOver {IntegerVar smalltalk} 
		AddTallys {Array smalltalk} 
		DeleteOver {IntegerVar smalltalk} 
		DeleteTallys {Array smalltalk} 
		NewSetCount {IntegerVar smalltalk} 
		SetKillCount {IntegerVar smalltalk} 
		StepperCount {IntegerVar smalltalk} 
		StepperOver {IntegerVar smalltalk} 
		StepperTally {Array smalltalk} 
		TestOver {IntegerVar smalltalk} 
		TestTallys {Array smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!

(ActualHashSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class ActualHashSet */
friend class HashSetTester;';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualHashSet methodsFor: 'testing'!

{UInt32} contentsHash
	| hashResult {UInt32} |
	hashResult _ UInt32Zero.
	UInt32Zero almostTo: myHashEntries count do: [:idx {UInt32} | 
		(myHashEntries fetch: idx) ~~ NULL 
			ifTrue: [hashResult _ hashResult + (myHashValues uIntAt: idx)]].
	^hashResult! !

!ActualHashSet methodsFor: 'accessing'!

{IntegerVar} count
	
	^ myTally!

{BooleanVar} hasMember: someone {Heaper}
	[self class countTest: myTally] smalltalkOnly.
	^(self hashFind: someone) >= Int32Zero!

{BooleanVar} isEmpty
	^ myTally == UInt32Zero! !

!ActualHashSet methodsFor: 'creation'!

{ScruSet} copy
	^ActualHashSet create: myTally with: myHashValues with: myHashEntries! !

!ActualHashSet methodsFor: 'protected: creation'!

create: newTally {Int32} with: entries {SharedPtrArray}
	super create.
	myTally _ newTally.
	myHashValues _ UInt32Array make: entries count.
	myHashEntries _ entries.
	myHashEntries shareMore.
	[NewSetCount _ NewSetCount + 1] smalltalkOnly.!

create: newTally {Int32} with: hashValues {UInt32Array} with: entries {SharedPtrArray}
	super create.
	myTally _ newTally.
	myHashValues _ hashValues.
	myHashEntries _ entries.
	myHashEntries shareMore.
	[NewSetCount _ NewSetCount + 1] smalltalkOnly.!

{void} destruct
	myHashEntries shareLess.
	super destruct! !

!ActualHashSet methodsFor: 'enumerating'!

{Stepper} stepper
	[StepperCount _ StepperCount + 1.
	self class countStepper: myTally] smalltalkOnly.
	^ HashSetStepper make: myHashEntries!

{Heaper} theOne
	myTally ~~ 1 ifTrue: [Heaper BLAST: #NotOneElement].
	Int32Zero almostTo: myHashEntries count do: [:i {Int32} |
		(myHashEntries fetch: i) ~~ NULL ifTrue: [^myHashEntries fetch: i]].
	^NULL! !

!ActualHashSet methodsFor: 'operations'!

{void} storeAll: other {ScruSet} 
	"union equivalent"
	| haveStored {BooleanVar} |
	haveStored _ false.
	other stepper forEach: [:elem {Heaper wimpy} | 
		(self hashFind: elem) < Int32Zero ifTrue:
			[haveStored ifFalse:
				[haveStored _ true.
				[self class countAdd: myTally] smalltalkOnly.
				self checkSize: other count DOTasLong].
			self hashStore: elem with: myHashValues with: myHashEntries.
			myTally _ myTally + 1]].!

{void} wipeAll: other {ScruSet} 
	"Sort of minus.  Wipe from myself all elements from other.
	Turn myself into my current self minus other."
	"Maintainance note: this duplicates some code in wipe: for efficiency"
	| loc {Int32} haveWritten {BooleanVar} |

	myTally = UInt32Zero ifTrue: [^ VOID].
	haveWritten _ false.
	other stepper forEach: [:elem {Heaper wimpy} |
		(loc _ self hashFind: elem) >= Int32Zero ifTrue:
			[haveWritten ifFalse:
				[self aboutToWrite.
				haveWritten _ true.
				[self class countDelete: myTally] smalltalkOnly.].
			self hashRemove: (loc basicCast: UInt32).
			myTally _ myTally - 1]]! !

!ActualHashSet methodsFor: 'adding-removing'!

{void} introduce: anElement {Heaper}
	[self class countAdd: myTally] smalltalkOnly.
	self checkSize: 1.
	(self hashFind: anElement) >= Int32Zero
		ifTrue: [Heaper BLAST: #AlreadyInSet]
		ifFalse: [self hashStore: anElement with: (myHashValues basicCast: UInt32Array) with: (myHashEntries basicCast: PtrArray).
			myTally _ myTally + 1]!

{void} remove: anElement {Heaper}
	| loc {Int32} |
	[self class countDelete: myTally] smalltalkOnly.
	self aboutToWrite.
	(loc _ self hashFind: anElement) >= Int32Zero
		ifTrue: [self hashRemove: (loc basicCast: UInt32).
			myTally _ myTally - 1]
		ifFalse: [Heaper BLAST: #NotInSet]!

{void} store: anElement {Heaper}
	"maintainance note: storeAll: has a copy of the code starting at self hashFind:... for efficiency."
	(self hashFind: anElement) < Int32Zero ifTrue:
		[self checkSize: 1.
		self hashStore: anElement with: (myHashValues basicCast: UInt32Array) with: (myHashEntries basicCast: PtrArray).
		[self class countAdd: myTally] smalltalkOnly.
		myTally _ myTally + 1]!

{void} wipe: anElement {Heaper}
	| loc {Int32} |
	myTally = UInt32Zero ifTrue: [^ VOID].
	(loc _ self hashFind: anElement) >= Int32Zero ifTrue:
		[[self class countDelete: myTally] smalltalkOnly.
		self aboutToWrite.
		self hashRemove: (loc basicCast: UInt32).
		myTally _ myTally - 1]! !

!ActualHashSet methodsFor: 'private: housekeeping'!

{void INLINE} aboutToWrite
	"If my contents are shared, and I'm about to change them, make a copy of them."
	myHashEntries shareCount > 1 ifTrue:
		[self actualAboutToWrite]!

{void} actualAboutToWrite

	| newValues {UInt32Array} newEntries {SharedPtrArray}  |
	newValues _ myHashValues copy cast: UInt32Array.
	newEntries _ myHashEntries copy cast: SharedPtrArray.
	myHashEntries shareLess.
	myHashValues _ newValues.
	myHashEntries _ newEntries.
	myHashEntries shareMore!

{void} checkSize: byAmount {Int32}

	| newSize {Int32} newValues {UInt32Array} newEntries {SharedPtrArray} he {Heaper wimpy} |
	
	"Leave a third of free space."
	(((myTally + byAmount) * 5) bitShiftRight: 2) < myHashEntries count ifTrue:
		[self aboutToWrite.
		^VOID].

	newSize _ LPPrimeSizeProvider make uInt32PrimeAfter: ((myHashValues count * 2) + byAmount).
	newValues _ UInt32Array make: newSize.
	newEntries _ SharedPtrArray make: newSize.
	Int32Zero almostTo: myHashValues count do: [:from {Int32 register} |
		(he _ myHashEntries fetch: from) ~~ NULL 
			ifTrue: [self hashStore: he with: newValues with: newEntries]].
	myHashEntries shareCount > 1
		ifTrue: [myHashEntries shareLess]
		ifFalse: [myHashValues destroy.
			myHashEntries destroy].
	myHashValues _ newValues.
	myHashEntries _ newEntries.
	myHashEntries shareMore!

{Int32} distanceFromHome: loc {UInt32} with: home {UInt32} with: modulus {UInt32}
	| dist {Int32} |
	[^ (loc - home) \\ modulus] smalltalkOnly.

	"alternate coding if modulus doesn't handle negatives the same as smalltalk 
		(positive remainder only)"
	
	[dist _ (loc - home).
	dist < Int32Zero ifTrue: [dist _ dist + modulus].
	^ dist] translateOnly! !

!ActualHashSet methodsFor: 'private: hash resolution'!

{Int32} hashFind: item {Heaper}

	"Starting at the item's preferred location and iterating (not recurring!!) around the set's
	 storage while the slots we're examining are occupied...
	   If the current slot's occupant is the target item, return a hit 
	   if the current occupant is closer to it's preferred location, return a miss.
	   If we've gone all the way around, return a miss."
	
	| tSize {UInt32} current {UInt32}
	 currentValue {UInt32} currentEntry {Heaper} currentHome {UInt32}
	 targetValue {UInt32} targetHome {UInt32} |
	 
	tSize _ myHashValues count.
	targetValue _ item hashForEqual.
	targetHome _ current _ targetValue \\ tSize.
	
	[(currentEntry _ myHashEntries fetch: current) ~~ NULL]
		whileTrue: [
			currentValue _ myHashValues uIntAt: current.
			
			currentValue = targetValue ifTrue:
				[(currentEntry isEqual: item) ifTrue: [^current]].						"Found it."
				
			currentHome _ currentValue \\ tSize.

			(self distanceFromHome: current with: targetHome with: tSize) >
			(self distanceFromHome: current with: currentHome with: tSize)
				ifTrue: [^ -1].							"Would have seen it by now."
				
			current _ current + 1 \\ tSize.
			current = targetHome ifTrue: [^ -1].		"All the way around."
	].
	^ -1												"Found an empty slot."!

{void} hashRemove: from {UInt32} 

	"Remove the indicated item from the set.
	 Iteratively (not recursively!!) move other items up until one is NULL or happier where it is."

	| tSize {UInt32} current {UInt32} next {UInt32} nextValue {UInt32} nextEntry {Heaper} |
	
	current _ from.
	tSize _ myHashValues count.
	
	[(nextEntry _ myHashEntries fetch: (next _ current + 1 \\ tSize)) ~~ NULL
	and: [((nextValue _ myHashValues uIntAt: next) \\ tSize) ~= next]]
		whileTrue: [
			myHashEntries at: current store: nextEntry.
			myHashValues at: current storeUInt: nextValue.
			current _ next.
		].
		
	myHashEntries at: current store: NULL.
	myHashValues at: current storeUInt: UInt32Zero.!

{void} hashStore: item {Heaper} with: values {UInt32Array} with: entries {PtrArray}

	"Starting at the new item's preferred location and iterating (not recurring!!) around the set's storage while the slots we're examining are occupied.  (Caller assures us there IS a vacant slot) if the current occupant is no closer to it's preferred location, exchange it with the 'new' one.  Bail out if the current occupant IS the new one.
	 Store the currently 'new' item."

	| tSize {UInt32} current {UInt32} itemValue {UInt32} 
	  movingValue {UInt32} movingEntry {Heaper} movingEntrysHome {UInt32}
	  sittingValue {UInt32} sittingEntry {Heaper} sittingEntrysHome {UInt32} |
	
	tSize _ values count.
	movingEntry _ item.
	movingValue _ itemValue _ movingEntry hashForEqual.
	movingEntrysHome _ current _ movingValue \\ tSize.
	
	[(sittingEntry _ entries fetch: current) ~~ NULL]
		whileTrue: [
			sittingValue _ values uIntAt: current.

			
			sittingEntrysHome _ sittingValue \\ tSize.
			
			"If the test below is >, new items are stored as far as possible from their desired location, giving the better slots to previous entries.  If it is >=, new items are stored as close as possible to their desired locations, with older items moved farther down, giving the better slots to the more recent items.
			 
			 (Changing this test to > requires moving the duplicate item test.)"
			 
			(self distanceFromHome: current with: movingEntrysHome with: tSize) >=
			(self distanceFromHome: current with: sittingEntrysHome with: tSize)
				ifTrue: [								"Bump the old occupant to another slot."
					entries at: current store: movingEntry.
					values at: current storeUInt: movingValue.
					movingEntry _ sittingEntry.
					movingValue _ sittingValue.
					movingEntrysHome _ sittingEntrysHome.
					
					"If we just picked up the same thing we were originally trying to add,
					 we were trying to insert a duplicate.  We may have reordered the
					 collision set, or we may have just swapped the item with itself, but
					 either way we're done.  (Perhaps we should return an indication that
					 the duplicate was found????)"
					
					((movingValue = itemValue) and: [movingEntry isEqual: item])
						ifTrue: [^ VOID ].				"item already in set, return."
				].
						
			current _ current + 1 \\ tSize.
		].
		
	entries at: current store: movingEntry.				"Empty slot found.  Drop the new entry into it."
	values at: current storeUInt: movingValue.! !

!ActualHashSet methodsFor: 'private: testing access'!

{UInt32} entryTableSize

	^ myHashEntries count!

{void} printInternals: oo {ostream reference}

	"This method is for regression testing."
	
	| tSize {UInt32} tValue {UInt32} |
	
	tSize _ myHashValues count.
	oo << 'tally == ' << myTally << '
'.
	UInt32Zero almostTo: myHashEntries count do: [:idx {UInt32} |
		oo << idx << ':	(' << ((tValue _ myHashValues uIntAt: idx) \\ tSize).
		oo << ', ' << (self distanceFromHome: idx with: tValue with: tSize) << ') '.
		[ tValue printOn: oo base: 16.] smalltalkOnly.
		'{
			char	buffer[9];
			sprintf(buffer, "%X", tValue);
			oo << buffer;
		}' translateOnly.
		oo << ',	' << (myHashEntries fetch: idx) << '
'].
	oo << '
'! !

!ActualHashSet methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveHashSet: rcvr {Rcvr} 
	"Make myHashEntries large enough that we won't grow."
	
	| count {Int32} |
	count _ LPPrimeSizeProvider make uInt32PrimeAfter: (myTally * 2).
	myHashEntries _ SharedPtrArray make: count.
	myHashEntries shareMore.
	myHashValues _ UInt32Array make: count.
	myTally timesRepeat: [self hashStore: rcvr receiveHeaper with: myHashValues with: myHashEntries]!

{void SEND.HOOK} sendHashSet: xmtr {Xmtr}
	"This currently doesn't take advantage of the optimizations in TableEntries.  It should."
	
	| count {Int32} |
	count _ Int32Zero.
	self stepper forEach: [:value {Heaper} |
		xmtr sendHeaper: value.
		count _ count + 1].
	count == myTally assert: 'Must write every element'.! !

!ActualHashSet methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myTally _ receiver receiveInt32.
	self receiveHashSet: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myTally.
	self sendHashSet: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualHashSet class
	instanceVariableNames: ''!

(ActualHashSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class ActualHashSet */
friend class HashSetTester;';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualHashSet class methodsFor: 'smalltalk: initialization'!

cleanupGarbage
	[AddTallys _ nil.
	DeleteTallys _ nil.
	TestTallys _ nil.
	StepperTally _ nil] smalltalkOnly.!

initTimeNonInherited
	self REQUIRES: LPPrimeSizeProvider.
	"((5 - 10) + 17) == ((5 - 10) \\ 17) assert: 
		'incorrect modulus - change HashSet distanceFromHome'"!

linkTimeNonInherited

	[AddTallys _ Array new: 500 withAll: 0.
	DeleteTallys _ Array new: 500 withAll: 0.
	TestTallys _ Array new: 500 withAll: 0.
	StepperTally _ Array new: 500 withAll: 0.
	AddOver _ DeleteOver _ TestOver _ StepperOver _ 0.
	StepperCount _ NewSetCount _ SetKillCount _ 0.] smalltalkOnly! !

!ActualHashSet class methodsFor: 'pseudo constructors'!

make
	^ActualHashSet create: Int32Zero with: (SharedPtrArray make: 7)!

make.Heaper: something {Heaper}
	
	| set {ActualHashSet} |
	set _ ActualHashSet make.IntegerVar: 1.
	set store: something.
	^ set!

make.IntegerVar: someSize {IntegerVar}
	^ActualHashSet create: Int32Zero with: (SharedPtrArray make: (LPPrimeSizeProvider make uInt32PrimeAfter: someSize DOTasLong))! !

!ActualHashSet class methodsFor: 'smalltalk: instrumentation'!

{String} arrayStats: array {Array}
	| oo minIdx maxIdx idx medCnt mode modeVal totCnt avg |
	oo _ '' asText writeStream.
	minIdx _ 0.
	maxIdx _ 0.
	idx _ 1.
	[minIdx = 0 and: [idx < array size]] whileTrue: [
		(array at: idx) > 0 ifTrue: [minIdx _ idx]
		ifFalse: [idx _ idx + 1]].
	idx _ array size.
	[maxIdx = 0 and: [idx > 0]] whileTrue: [
		(array at: idx) > 0 ifTrue: [maxIdx _ idx]
			ifFalse: [idx _ idx - 1]].
	medCnt _ 0.
	mode _ 0. modeVal _ 0.
	minIdx to: maxIdx do: [:i | | cv |
		cv _ array at: i.
		medCnt _ medCnt + (cv * i).
		totCnt _ totCnt + cv.
		cv > modeVal ifTrue: [mode _ i. modeVal _ cv]].
	avg _ totCnt / (maxIdx - minIdx).!

{void} countAdd: tally {IntegerVar}
	tally < AddTallys size
		ifTrue: [AddTallys at: tally+1 put: ((AddTallys at: tally+1) + 1)]
		ifFalse: [AddOver _ AddOver + 1]!

{void} countDelete: tally {IntegerVar}

	tally < DeleteTallys size
		ifTrue: [DeleteTallys at: tally+1 put: ((DeleteTallys at: tally+1) + 1)]
		ifFalse: [DeleteOver _ DeleteOver + 1]!

{void} countStepper: tally {IntegerVar}
	tally < StepperTally size
		ifTrue: [StepperTally at: tally+1 put: ((StepperTally at: tally+1) + 1)]
		ifFalse: [StepperOver _ StepperOver + 1]!

{void} countTest: tally {IntegerVar}

	tally < TestTallys size
		ifTrue: [TestTallys at: tally+1 put: ((TestTallys at: tally+1) + 1)]
		ifFalse: [TestOver _ TestOver + 1]! !