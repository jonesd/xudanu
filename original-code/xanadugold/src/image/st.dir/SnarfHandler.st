'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:40 pm'!

Heaper subclass: #SnarfHandler
	instanceVariableNames: '
		myHandle {SnarfHandle star}
		myMapCount {Int4}
		mySpaceLeft {Int4}
		myNearest {Int4}'
	classVariableNames: '
		Flag {UInt4} 
		SizeOffset {Int4} 
		UseFences {BooleanVar} 
		Value {UInt4} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
SnarfHandler comment:
'A SnarfHandler breaks a snarf into abstract subarrays of bytes into whic flocks are stored.  These indexed flock storage areas are accessed through readStreams and writeStreams provided by the SnarfHandler.  SnarfHandlers also provide the ability to resize these flock areas and associate a couple of flag bits with them.  All access to the snarf goes through a single snarfHandler.

The beginning of the snarf is dedicated to a table that describes the locations and sizes of the contained flock areas.  Currently, we allocate space between the flock nearest the front of the snarf and the end of the mapTable.  When not enough space exists between the two, we compact the flock storage areas towards the back (highest address) of the snarf and try to allocate again.

An index in the snarfHAndler can be associated either with one of these flock storage areas or with a snarfID and index to look further for the storage of a given flock.  Right now, the SnarfHAndler keeps the forwarding information in a flock storage area, but it will soon be put into the mapTable directly.

Forwarding pointers occur when a flock outgrows a snarf, and must be moved elsewhere.  Eventually all other snarfs that have objects which point to the forwarding pointer are updated, and the forwarding pointer can be deallocated, but decisions about this must be made by objects external to the SnarfHandler.

The forwarded flag is stored on the snarfID.  The forgotten flag is stored on the size.  Both use the same Flag mask for accessing the flag, and the Value mask for accessing the value.'!

(SnarfHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SnarfHandler methodsFor: 'reading'!

{FlockLocation | NULL} fetchForward: index {Int32}
	"If the flock specified by index has been forwarded, return a FlockLocation with the SnarfID and index of its new location."

	self checkIndex: index.
	(self isForwarded: index) ifTrue:
		["Forwarded.  The info is stored in the mapCell."
		^FlockLocation make: (self getOffset: index) with: (self getSize: index)].
	^NULL!

{Int32} flockSize: index {Int32}
	"Return the number of bytes in the flock at index"
	
	^((myHandle get32: (self mapCellOffset: index) + SizeOffset) bitAnd: Value) - (SnarfHandler fenceSize * 2)!

{BooleanVar} isForgotten: index {Int32}
	"The forgotten flag is the flag bit associated with each flock.  It is set when the
	flock has been forgotten, which means that there are no more persistent pointers
	to the flock.  When a flock is forgotten AND is not in RAM, the SnarfPacker is
	free to bring the flock back into RAM and destroy it, which deletes it from the snarf.
	 
	 Return true if the forgotten flag has been set for the flock at index."
	
	^(Flag bitAnd: (myHandle get32: (self mapCellOffset: index) + SizeOffset)) == Flag!

{BooleanVar} isOccupied: index {Int32}
	"Return true if there's a flock or forwarder at index."
	
	^index >= Int32Zero and: [index < myMapCount and: [(self isForwarded: index) or: [(self getSize: index) > Int32Zero]]]!

{Int32} mapCount
	"Return the number of slots allocated in the map table."
	
	^myMapCount!

{XnReadStream} readStream: index {Int32}
	"Return a stream on the area of the snarf allocated to mapIndex.  
	 This stream must be used immediately, then thrown away."

	self checkIndex: index.
	(self isForwarded: index) ifTrue: [Heaper BLAST: #MustBeAFlock].
	^XnReadStream
		make: myHandle getDataP
		with: (self flockOffset: index)
		with: (self flockSize: index)!

{SnarfID} snarfID
	"Return the snarfID of the snarf this handle holds."
	^myHandle getSnarfID!

{Int32} spaceLeft
	"Return the amount space left in the snarf."
	
	^mySpaceLeft! !

!SnarfHandler methodsFor: 'writing'!

{void} allocateCells: indices {IntegerVar}
	"Add more cells to the mapTable.  Make sure that there is enough space for
	 those cells, then initialize.  The size is initially 0 and the offset points past 
	 the end of the snarf."
	
	| newCells {Int32} space {Int32} |
	newCells _ indices DOTasLong.
	newCells <= Int32Zero ifTrue: [^VOID].
	space _ newCells * SnarfHandler mapCellSize.
	self clearSpace: space.
	myMapCount _ myMapCount + newCells.
	mySpaceLeft _ mySpaceLeft - space.
	myMapCount-newCells almostTo: myMapCount do: [:index {Int32} |
		"Zero all the counts, just like wipeFlock."
		myHandle at: (self mapCellOffset: index) + SizeOffset put32: Int32Zero.
		self at: index storeIndex: self flocksEnd].
	self consistencyCheck.
	self checkFences!

{void} at: ind {IntegerVar} allocate: flockSize {Int32}
	"Allocate flockSize bytes for the flock at the index ind."
	
	| index {Int32} size {Int32} |
	flockSize > Int32Zero assert: 'Must allocate some space'.
	size _ flockSize + (SnarfHandler fenceSize * 2).
	index _ ind DOTasLong.
	self checkIndex: index.
	self clearSpace: size.
	(self isForwarded: index) ifFalse: [mySpaceLeft _ mySpaceLeft + (self getSize: index)].
	mySpaceLeft _ mySpaceLeft - size.
	self at: index storeIndex: self nearestFlock - size.
	self at: index storeSize: size.
	self mendFences: index.
	self consistencyCheck.
	self checkFences!

{void} at: index {Int32} storeForget: flag {BooleanVar} 
	"See the comment on isForgotten:.  Set or clear the forgetFlag for the flock at index."

	| offset {Int32} |
	self checkIndex: index.
	offset _ (self mapCellOffset: index) + SizeOffset.
	"Keep everything else the same."
	flag ifTrue: [myHandle at: offset put32: (Flag bitOr: (myHandle get32: offset))]
		ifFalse: [myHandle at: offset put32: (Value bitAnd: (myHandle get32: offset))].
	self checkFences!

{void} forward: index {IntegerVar} to: newSnarfID {SnarfID} with: newIndex {Int32}
	"Associate a forwarder with index.  Throw away whatever storage
	 was assigned to it and store the forwarder information in the mapCell."

	self wipeFlock: index.
	myHandle at: (self mapCellOffset: index DOTasLong) put32: (newSnarfID bitOr: Flag).
	myHandle at: ((self mapCellOffset: index DOTasLong) + SizeOffset) put32: (newIndex bitAnd: Value).!

{BooleanVar} isWritable
	"Return true if I represent a writable snarf. "
	
	^myHandle isWritable!

{void} makeWritable
	"Make the handle for the receiver writable."
	
	myHandle makeWritable!

{void} rewrite
	"Write out to the snarf any values held in instance variables (space 
	remaining, number of entries, etc.)."
	
	myHandle at: Int32Zero put32: myMapCount.
	myHandle at: SizeOffset put32: mySpaceLeft!

{void} wipeFlock: index {IntegerVar}
	"Deallocate all space for the flock at index.  The slot for index remains however, and can be reused for another flock."
	
	self checkIndex: index DOTasLong.
	(self isForwarded: index DOTasLong) ifFalse: [mySpaceLeft _ mySpaceLeft + (self getSize: index DOTasLong)].
	myHandle at: (self mapCellOffset: index DOTasLong) + SizeOffset put32: Int32Zero.
	self at: index DOTasLong storeIndex: self flocksEnd.
	self consistencyCheck.
	self checkFences!

{XnWriteStream} writeStream: index {IntegerVar}
	"Return a stream that can write into the bytes allocated to the flock at index. 
	 The stream must be used immediately and thrown away."

	self checkIndex: index DOTasLong.
	(self isForwarded: index DOTasLong) ifTrue: [Heaper BLAST: #MustBeAFlock].
	^XnWriteStream
		make: myHandle getDataP
		with: (self flockOffset: index DOTasLong)
		with: (self flockSize: index DOTasLong)! !

!SnarfHandler methodsFor: 'initialize'!

{void} initializeSnarf
	"Put in the minimum necessary for a starting snarf.  
	 All it needs is the number of objects and the spaceLeft.
	 This also writes the information to the real snarf."
	 
	 myMapCount _ Int32Zero.
	 mySpaceLeft _ self flocksEnd - SnarfHandler mapOverhead.
	 self rewrite! !

!SnarfHandler methodsFor: 'private: operations'!

{BooleanVar} checkFence: index {Int32} 
	"If we are using fences around flock storage areas, then return true only if the fences are still in place for the flock at index.  Fences are extra storage at the front and back of a flock storage area that contains the index of that flock.  These are used for runtime checks that one flock hasn't stepped into the space of another."
	
	UseFences
		ifTrue:
			[| offset {Int32} size {Int32} |
			(self isForwarded: index) ifTrue: [^true].
			size _ self getSize: index.
			^size <= Int32Zero
				or: [(myHandle get32: (offset _ self getOffset: index)) == index
					and: [(myHandle get32: offset + (self getSize: index) - SnarfHandler fenceSize) == index]]]
		ifFalse: [^true]!

{void} checkFences
	"See checkFence:  Check the fences for all flocks and blast if any are violated."
	
	"Int32Zero to: myMapCount-1 do:
		[:i {Int32} | (self checkFence: i) ifFalse: [SnarfHandler BLAST: #BrokenFence]]"!

{void} checkIndex: index {Int32}
	"Blast if the index is not represented in the table.  This is just simple bounds checking."
	
	(index >= myMapCount and: [index >= Int32Zero]) ifTrue: [MuTable BLAST: #NotInTable]!

{void} clearSpace: count {Int32}
	"This checks for count bytes available at the end of the mapTable.  If
	 there isn't enough, it compacts everything and tries again."

	self consistencyCheck.
	self nearestFlock < (self mapEnd + count) ifTrue: 
		[self recomputeNearest.
		self nearestFlock < (self mapEnd + count) ifTrue: 
			[self compact.
			self nearestFlock >= (self mapEnd + count)
				ifFalse: [Heaper BLAST: #MustHaveRoom]]]!

{void} compact
	"Compress flock storage areas towards the end of the snarf, leaving all
	 freespace between the end of the mapTable and the nearest flock."
	
	| sweeper {Int32} offsets {UInt32Array} indices {UInt32Array} | 
	self checkFences. 
	sweeper _ self flocksEnd.
	myNearest _ sweeper.
	"Load up all the offset into an array.  Make cells that are forwarded just point past the end of the snarf."
	offsets _ UInt32Array make: myMapCount + 1.
	Int32Zero almostTo: myMapCount do:
		[ :i {Int32} |
		(self isForwarded: i)
			ifTrue: [offsets at: i storeUInt: sweeper]
			ifFalse: [offsets at: i storeUInt: (self getOffset: i)]].
	offsets at: myMapCount storeUInt: UInt32Zero.
	indices _ SnarfHandler sort: offsets.
	Int32Zero almostTo: myMapCount do:
		[:i2 {Int32} |
		| indexToMove {Int32} offsetToMove {Int32} count {Int32} |
		indexToMove _ indices uIntAt: i2.
		offsetToMove _ offsets uIntAt: i2.
		offsetToMove < sweeper ifTrue:
			[count _ self getSize: indexToMove.
			sweeper _ sweeper - count.
			myHandle moveBytes: offsetToMove with: sweeper with: count.
			"This storeIndex will also push myNearest."
			self at: indexToMove storeIndex: sweeper]].
	self checkFences.
	offsets destroy.!

{void} consistencyCheck
	"Generic checking hook to do slow runtime consistency checking when debugging.  No checks are active currently."

	"self compact.
	mySpaceLeft == (self nearestFlock - self mapEnd) assert: 'space mismatch'."
	"| sum {Int32} |
	sum _ Int32Zero.
	Int32Zero almostTo: myMapCount do: 
		[:i {Int32} |
		(self isForwarded: i) ifFalse: [sum _ sum + (self getSize: i)]].
	sum + self mapEnd + mySpaceLeft == myHandle getDataSize assert: 'Space difference'"!

{void} mendFences: index {Int32}
	"Couldn't resist the name.  Set up the fences for the flock at index.  See checkFence:"
	
	UseFences ifTrue:
		[| offset {Int32} |
		offset _ self getOffset: index.
		myHandle at: offset put32: index.
		myHandle at: offset + (self getSize: index) - SnarfHandler fenceSize put32: index]!

{Int32} nearestFlock
	"Return the location of the nearest flock. Everything between the 
	end of the map and the nearest flock is free space. We normally 
	allocate everything from the back of the snarf forward. When we 
	run out of enough contiguous space, we simply compact.
	
	We keep a cache of the current nearest flock.  The cache maintins the invariant that it
	 *must* point to an offset less than or equal to the nearestFlock.  Thus it can be too close 
	 to the mapTable, in which case we will recompute it from scratch."

	myNearest == Int32Zero ifTrue: [self recomputeNearest].
	^myNearest!

{void} recomputeNearest
	"Recalculate the nearest flock by looking at the start of every flock and taking the min."

	myNearest _ self flocksEnd.
	Int32Zero almostTo: myMapCount do: 
		[:index {Int32} |
		((self isForwarded: index) not and: [(self getSize: index) > Int32Zero]) ifTrue: 
			[| offset {Int32} |
			offset _ self getOffset: index.
			offset < myNearest ifTrue: [myNearest _ offset]]]! !

!SnarfHandler methodsFor: 'private: layout'!

{void} at: index {Int32} storeIndex: offset {Int32}
	"Store the offset as the starting location for the data of the flock at index.  
	 Update the cache of nearestFlock.  This also clears the forwarded flag."
	
	offset < myNearest ifTrue: [myNearest _ offset].
	myHandle at: (self mapCellOffset: index) put32: (offset bitAnd: Value)!

{void} at: index {Int32} storeSize: size {Int32}
	"Store size as the number of bytes for the flock at index.  If the 
	 space is at a 0, then change the corresponding pointer to past the end of 
	 the snarf so that we don't find it in our searches."
	
	| offset {Int32} |
	offset _ (self mapCellOffset: index) + SizeOffset.
	"Keep the old flags."
	myHandle at: offset put32: ((size bitAnd: Value) bitOr: ((myHandle get32: offset) bitAnd: Flag)).
	size == Int32Zero ifTrue: [self at: index storeIndex: self flocksEnd]!

{Int32} flockOffset: index {Int32}
	"Return the index of the first byte of the actual data associated with flock number index.  This is like indexOf: except that it leaves room for fencePosts on either side of the flock storage area."
	
	^((myHandle get32: (self mapCellOffset: index)) bitAnd: Value) + SnarfHandler fenceSize!

{Int32} flocksEnd
	"Return the index of the cell one greater than the size of the entire snarf.  This is just past the end of the storage area for flocks."
	
	^myHandle getDataSize!

{Int32} getOffset: index {Int32}
	"Return the index of the first byte of the actual data associated with
	 flock number index.  This area includes space for fencePosts and whatever 
	 other things we might dream up that go with the flock in its storage area."
	
	| offset {Int32} |
	offset _ myHandle get32: (self mapCellOffset: index).
	^offset bitAnd: Value!

{Int32} getSize: index {Int32}
	"Return the number of bytes in the flock at index.  This includes space allocated internally for fencePosts and the like."
	
	| size {Int32} |
	size _ (myHandle get32: (self mapCellOffset: index) + SizeOffset) bitAnd: Value.
	^size!

{BooleanVar} isForwarded: index {Int32}
	"Return the internal bit that says whether the flock at index is represented by forwarding information or by a flock area"
	
	^(Flag bitAnd: (myHandle get32: (self mapCellOffset: index))) == Flag!

{Int32 INLINE} mapCellOffset: index {Int32}
	"Return the offset into the snarf for the mapCell that has the data for the flock at index."
	
	^(SnarfHandler mapCellSize * index) + SnarfHandler mapOverhead!

{Int32} mapEnd
	"Return the index of the cell just after the end of the map.  This is based on the number of entries in the map."
	
	^self mapCellOffset: myMapCount!

{Int32} snarfMapCount
	"Actually get from the snarf the number of map slots currently allocated, 
	including ones that are free for reuse. This is stored as the first thing in the 
	snarf."

	^myHandle get32: Int32Zero!

{Int32} snarfSpaceLeft
	"Actually get from the snarf the amount of unallocated space remaining."
	
	^myHandle get32: SizeOffset! !

!SnarfHandler methodsFor: 'protected: destruct'!

{void} destruct
	"Write my internal constants to the snarf before I go away."
	myHandle isWritable ifTrue: [self rewrite].
	myHandle destroy.
	myHandle _ NULL.
	super destruct! !

!SnarfHandler methodsFor: 'create'!

create: handle {SnarfHandle}
	super create.
	[handle ~~ nil assert: 'nil handle'] smalltalkOnly.
	myHandle _ handle.
	myMapCount _ self snarfMapCount.
	"If I'm uninitialized, then generate the necessary data."
	myMapCount == Int32Zero 
		ifTrue: [mySpaceLeft _ self flocksEnd - SnarfHandler mapOverhead]
		ifFalse: [mySpaceLeft _ self snarfSpaceLeft].
	myNearest _ Int32Zero! !

!SnarfHandler methodsFor: 'smalltalk: debugging'!

inspect
	^InspectorView open: (SnarfHandlerInspector inspect: self)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SnarfHandler class
	instanceVariableNames: ''!

(SnarfHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SnarfHandler class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	
	self hack.  "These don't use the full 32 bits so that we don't start manipulating LargeIntegers."
	Flag _ 1 bitShift: 25.
	Value _ (1 bitShift: 25) - 1"Flag - 1".
	SizeOffset _ 4   "The offset of the size from the begginging of a mapCell".
	UseFences _ false! !

!SnarfHandler class methodsFor: 'pcreate'!

make: snarfHandle {SnarfHandle}
	^self create: snarfHandle! !

!SnarfHandler class methodsFor: 'accessing'!

{Int32} fenceSize
	"The number of bytes for one fence (Each flock requires two)."
	
	UseFences ifTrue: [^4] ifFalse: [^Int32Zero]!

{Int32 INLINE} mapCellOverhead
	"Return the number of bytes for a single map record, plus the space for the 
	fence. The fence will be just the index of the flock stored at the beginning and 
	the end of the flock's memory"

	^self mapCellSize + SnarfHandler fenceSize + SnarfHandler fenceSize!

{Int32 INLINE} mapCellSize
	"Return the number of bytes for a single map record."
	
	^8!

{Int32 INLINE} mapOverhead
	"The map starts just after the basic header.  The basic header currently has
	 the number of entries in the map and total amount of free space remaining."
	
	^8! !

!SnarfHandler class methodsFor: 'smalltalk: testing'!

{Pair of: UInt32Array with: UInt32Array} sortTest: array {Array of: IntegerVar}
	"self sortTest: #(2 3 4 1).
	self sortTest: #().
	self sortTest: #(1000 1000 1000).
	self sortTest: #(1 2 3 4).
	self sortTest: #(1).
	self sortTest: #(2 2 3 3 4 4 1 1)."
	
	| offsets {UInt32Array} indices {UInt32Array} |
	offsets _ UInt32Array make: array size + 1.
	1 to: array size do: [:i {IntegerVar} |
		offsets at: i - 1 store: (array at: i)].
	offsets at: array size store: 1000.
	indices _ self sort: offsets with: (IntegerSpace make getAscending).
	^Pair make: offsets with: indices.!

{Pair of: UInt32Array with: UInt32Array} sortTestDown: array {Array of: IntegerVar}
	"self sortTestDown: #(2 3 4 1).
	self sortTestDown: #().
	self sortTestDown: #(1000 1000 1000).
	self sortTestDown: #(1 2 3 4).
	self sortTestDown: #(1).
	self sortTestDown: #(2 2 3 3 4 4 1 1)."
	
	| offsets {UInt32Array} indices {UInt32Array} |
	offsets _ UInt32Array make: array size + 1.
	1 to: array size do: [:i {IntegerVar} |
		offsets at: i - 1 store: (array at: i)].
	offsets at: array size store: 1.
	indices _ self sort: offsets with: (IntegerSpace make getDescending).
	^Pair make: offsets with: indices.! !

!SnarfHandler class methodsFor: 'private: sorting'!

{void} quickSort: offsets {UInt32Array} 
	with: indices {UInt32Array}
	with: first {Int32} 
	with: last {Int32}
	
	| part {Int32} left {Int32} right {Int32} |
	first >= last ifTrue: [^VOID].
	left _ first.
	right _ last + 1.
	self swap: offsets with: first with: (left + right) // 2.
	self swap: indices with: first with: (left + right) // 2.
	part _ offsets uIntAt: first.
	[left < right] whileTrue:
		[left _ left + 1.
		[(offsets uIntAt: left) > part] 
			whileTrue: [left _ left + 1].
		right _ right - 1.
		[part > (offsets uIntAt: right)]
			whileTrue: [right _ right -1].
		left < right ifTrue: 
			[self swap: offsets with: left with: right.
			self swap: indices with: left with: right]].
	self swap: offsets with: first with: right.
	self swap: indices with: first with: right.
	self quickSort: offsets with: indices with: first with: right - 1.
	self quickSort: offsets with: indices with: right + 1 with: last!

{void} quickSort: offsets {UInt32Array} 
	with: indices {UInt32Array}
	with: os {OrderSpec} 
	with: first {IntegerVar} 
	with: last {IntegerVar}
	
	| part {IntegerVar} left {IntegerVar} right {IntegerVar} |
	first >= last ifTrue: [^VOID].
	left _ first.
	right _ last + 1.
	self swap: offsets with: first with: (left + right) // 2.
	self swap: indices with: first with: (left + right) // 2.
	part _ offsets uIntAt: first DOTasLong.
	[left < right] whileTrue:
		[left _ left + 1.
		[os followsInt: (offsets uIntAt: left DOTasLong) with: part] 
			whileFalse: [left _ left + 1].
		right _ right - 1.
		[(os followsInt: part with: (offsets uIntAt: right DOTasLong))]
			whileFalse: [right _ right -1].
		left < right ifTrue: 
			[self swap: offsets with: left with: right.
			self swap: indices with: left with: right]].
	self swap: offsets with: first with: right.
	self swap: indices with: first with: right.
	self quickSort: offsets with: indices with: os with: first with: right - 1.
	self quickSort: offsets with: indices with: os with: right + 1 with: last!

{UInt32Array} sort: offsets {UInt32Array}
	"Sort the offsets array in place, and return an array of the same size that maps from the new index of each element to its original index.  The offsets array is *assumed* to be terminated with a guard element which is greater than or equal to all the other elements of the array according to descending order.  If this isn't true, havoc may result."
	
	| result {UInt32Array} |
	result _ UInt32Array make: offsets count.
	Int32Zero almostTo: offsets count do: [:i {Int32} |
		result at: i storeUInt: i].
	self
		quickSort: offsets
		with: result
		with: Int32Zero
		with: offsets count - 2.
	^result!

{UInt32Array} sort: offsets {UInt32Array} with: os {OrderSpec}
	"Sort the offsets array in place, and return an array of the same size that maps from the new index of each element to its original index.  The offsets array is *assumed* to be terminated with a guard element which is greater than or equal to all the other elements of the array according to the sorting order.  If this isn't true, havoc may result."
	
	| result {UInt32Array} |
	result _ UInt32Array make: offsets count.
	Int32Zero almostTo: offsets count do: [:i {Int32} |
		result at: i storeUInt: i].
	self
		quickSort: offsets
		with: result
		with: os
		with: Int32Zero
		with: offsets count - 2.
	^result!

{void INLINE} swap: array {UInt32Array} 
	with: i {IntegerVar} 
	with: j {IntegerVar}
	
	| temp {UInt32} |
	temp _ array uIntAt: i DOTasLong.
	array at: i DOTasLong storeUInt: (array uIntAt: j DOTasLong).
	array at: j DOTasLong storeUInt: temp! !