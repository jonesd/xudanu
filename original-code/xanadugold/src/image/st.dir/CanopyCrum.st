'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:54 pm'!

Abraham subclass: #CanopyCrum
	instanceVariableNames: '
		child1 {CanopyCrum | NULL}
		child2 {CanopyCrum | NULL}
		parent {CanopyCrum | NULL}
		minH {IntegerVar}
		maxH {IntegerVar}
		myOwnFlags {UInt32}
		myFlags {UInt32}
		myRefCount {IntegerVar}'
	classVariableNames: '
		FlagEndorsements {PtrArray of: Position | XnRegion} 
		OtherClubs {IDRegion} 
		OtherEndorsements {CrossRegion} 
		TheEFlagsCache {Heaper2UInt32Cache} 
		ThePFlagsCache {Heaper2UInt32Cache} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CanopyCrum comment:
'CanopyCrums form binary trees that acrete in a balanced fashion.  No rebalancing ever happens.  Things are simply added to the tree up to the point thta the tree is balanced, then the height of the tree gets extended at the root.

Essentially, when the join of two trees is asked for, if the two trees aren''t already parts of a larger tree, the algorithm attempts to find a place in one tree into which the other tree could completely fit without violating the depth constraint on the tree.  It then returns the nearest root that contains both trees.  If it can''t put one tree into the other, then it makes a new node that joins the two trees (probably with room to add other stuff deeper down).

myRefCount is only the count of Loafs or HCrums that point at the CanopyCrum.  It doesn''t include other CanopyCrums.

12/2/92 Ravi
PropJoints have been suspended, and their function has been replaced by flag words in the CanopyCrum. Any interesting Club or endorsement gets a bit, and there is a bit for "any other Club" and "any other endorsement". Any criteria not given a bit of their own require an exhaustive search. These flags are widded by ORing up the canopy. When we start using more sophisticated hashing strategies, we will probably need to reanimate PropJoints.'!

(CanopyCrum getOrMakeCxxClassDescription)
	friends:
'friend class RecorderHoister;

';
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!CanopyCrum methodsFor: 'canopy operations'!

{CanopyCrum} computeJoin: otherBCrum {CanopyCrum} 
	"Find a canopyCrum that is an anscestor to 
	 both the receiver and otherBCrum. otherBCrum 
	 is added to the canopy in a pseudo-balanced fashion. 
	 This demonstrates the beauty and power of caching
	 in object-oriented systems."

	| otherPath {MuSet of: CanopyCrum} myRoot {CanopyCrum} otherRoot {CanopyCrum} cache {CanopyCache} |
	(self isLE: otherBCrum) ifTrue: [^self].
	cache _ self canopyCache.
	otherPath _ cache pathFor: otherBCrum.
	otherRoot _ cache rootFor: otherBCrum.
	(otherBCrum isLE: self) ifTrue: [^otherBCrum].
	otherPath stepper forEach: 
		[:bCrum {CanopyCrum} | 
		(bCrum isLE: self) ifTrue: [^bCrum]].
	myRoot _ cache rootFor: self.
	myRoot maxHeight > otherRoot maxHeight
		ifTrue: [^self makeJoin: otherRoot]
		ifFalse: [^otherBCrum makeJoin: myRoot]!

{Pair of: CanopyCrum} expand
	"split into two if possible, return the two leaves"
	
	(child1 ~~ NULL and: [child2 ~~ NULL])
		ifTrue: [^Pair make: self with: self].
	(child1 == NULL and: [child2 == NULL]) assert: 'Must be both or niether'.
	DiskManager consistent: 3 with:
		[(child1 _ self makeNew) setParent: self.
		(child2 _ self makeNew) setParent: self.
		self canopyCache updateCache: child1 forParent: self.
		self canopyCache updateCache: child2 forParent: self.
		self diskUpdate].
	^Pair make: child1 with: child2!

{void} includeCanopy: otherCanopy {CanopyCrum} 
	"Install otherCanopy at or below the receiver. If the otherCanopy fits in a lower branch, put it there. Otherwise, replace the shortest child with a new child that contains the shortest child and otherCanopy."

	"This should be a friend or private function or something."
	
	| |
	self thingToDo.
	"Propagate the children's props into their new parent"
	
	self thingToDo.	"When we have non-props to propagate, do those, too.  i.e., height is currently handle by changeCanopy and will be moved out to HeightChanger momentarily."

	child1 ~~ NULL assert: 'shouldnt get here.'.
	child1 heightDiff >= otherCanopy maxHeight
		ifTrue: [child1 includeCanopy: otherCanopy]
		ifFalse: [child2 heightDiff >= otherCanopy maxHeight
				ifTrue: [child2 includeCanopy: otherCanopy]
				ifFalse: 
					[DiskManager consistent:
						[child1 maxHeight > child2 maxHeight
							ifTrue: 
								[(child2 _ self makeNewParent: child2 with: otherCanopy) setParent: self]
							ifFalse: 
								[(child1 _ self makeNewParent: child1 with: otherCanopy) setParent: self].
						"Update the cache for the newly installed subTree
							 because of the new tree above it."
						self canopyCache updateCacheFor: otherCanopy.
						(Sequencer make: (PropChanger height: self)
							with: (PropChanger make: self)) schedule]]]!

{Boolean} isLE: other {CanopyCrum}
	"Return true if other is equal to the receiver
	 or an anscestor (through the parent links). 
	 Use caches for efficiency."

	^(self canopyCache pathFor: other) hasMember: self! !

!CanopyCrum methodsFor: 'canopy accessing'!

{void} addPointer: ignored {Heaper unused}

	"Keep a refcount of diskful pointers to myself for disk space management.  (Maybe backpointers later.)"
	
	myRefCount _ myRefCount + 1.
	myRefCount == 1 ifTrue: [self remember].
	self diskUpdate!

{CanopyCrum} fetchParent
	^parent!

{UInt32} flags
	^myFlags!

{IntegerVar} heightDiff
	^maxH - minH!

{BooleanVar} isLeaf
	^child1 == NULL and: [child2 == NULL]!

{IntegerVar}maxHeight
	^maxH!

{IntegerVar}minHeight
	^minH!

{void} removePointer: ignored {Heaper unused} 

	"Keep a refcount of diskful pointers to myself for disk space management.  (Maybe backpointers later.)
	 Forget the object if it goes to zero."
	
	self thingToDo.		"Is calling destroy a bug?"
	myRefCount _ myRefCount - 1.
	MarkM knownBug.   "refCunt going to 0 with an outstanding AgendaItem."
	"(myRefCount == IntegerVar0 and: [parent == NULL])
		ifTrue: [self forget; destroy]
		ifFalse: ["self diskUpdate!

{void} setParent: p {CanopyCrum | NULL} 
	(parent == NULL and: [p ~~ NULL])
		ifTrue: [self remember].
	parent _ p.
	(myRefCount == IntegerVar0 and: [parent == NULL])
		ifTrue: [self destroy]
		ifFalse: [self diskUpdate]! !

!CanopyCrum methodsFor: 'protected:'!

{CanopyCache wimpy} canopyCache
	self subclassResponsibility!

{void} dismantle
	parent == NULL assert: 'We can only dismantle the canopy from the root on up.'.
	self thingToDo.
	"This first needs to remove all of myOwnProps from the canopy."
	DiskManager consistent: 3 with: 
		[child1 ~~ NULL ifTrue: 
			[child1 setParent: NULL.
			child1 _ NULL].
		child2 ~~ NULL ifTrue: 
			[child2 setParent: NULL.
			child2 _ NULL].
		super dismantle]!

{CanopyCrum} fetchChild1
	^child1!

{CanopyCrum} fetchChild2
	^child2!

{CanopyCrum} makeNew
	self subclassResponsibility!

{UInt32} ownFlags
	^myOwnFlags!

{void} setOwnFlags: newFlags {UInt32}

	myOwnFlags _ newFlags.! !

!CanopyCrum methodsFor: 'create'!

create: flags {UInt32}
	"Make a canopyCrum for a root:  it has no children."
	super create.
	minH _ maxH _ 1.
	child1 _ child2 _ parent _ NULL.
	myOwnFlags _ flags.
	myFlags _ myOwnFlags.
	myRefCount _ IntegerVar0!

create: flags {UInt32} with: first {CanopyCrum} with: second {CanopyCrum}

	"prop must be empty"
	
	super create.
	"prop isEmpty assert: 'Must be empty'."
	minH _ maxH _ 1.
	child1 _ first.
	child1 setParent: self.
	child2 _ second.
	child2 setParent: self.
	parent _ NULL.
	myOwnFlags _ flags.
	myFlags _ (flags bitOr: child1 flags) bitOr: child2 flags.
	myRefCount _ IntegerVar0! !

!CanopyCrum methodsFor: 'smalltalk: verification'!

{CanopyCrum} another
	"Return another instance of the same
	 class for testing purposes."

	^CanopyCrum create!

{IntegerVar} refCount
	^myRefCount!

{CanopyCrum} verify1
	"BertCrum create verify1"

	50 timesRepeat: [self computeJoin: self another].
	^self!

{CanopyCrum} verify2
	"BertCrum create verify2."

	self verifyHeight: 5.
	self computeJoin: (self another verifyHeight: 3).
	^self!

{CanopyCrum} verifyHeight: height {IntegerVar}
	"Create a tree with maxHeight = height and minHeight = 2."
	"BertCrum create verifyHeight: 4."

	(2 raisedTo: height - 2) timesRepeat: [self computeJoin: self another].
	^self! !

!CanopyCrum methodsFor: 'smalltalk:'!

{Array of: CanopyCrum} childArray
	^child1 == NULL
		ifTrue: [#()]
		ifFalse: [child2 == NULL
				ifTrue: [Array with: child1]
				ifFalse: [Array with: child1 with: child2]]!

{Array of: CanopyCrum} children
	^child1 == NULL
		ifTrue: [#()]
		ifFalse: [child2 == NULL
				ifTrue: [Array with: child1]
				ifFalse: [Array with: child1 with: child2]]!

displayString
	^String
		streamContents: 
			[:aStream | 
			aStream print: maxH.
			maxH = minH ifFalse: [aStream nextPut: $-; print: minH]]!

inspect
	Sensor leftShiftDown
		ifTrue: [self basicInspect]
		ifFalse: 
			[| cur {CanopyCrum} |
			cur _ self.
			[cur fetchParent == NULL]
				whileFalse: [cur _ cur fetchParent].
			cur inspectSubCanopy: self]!

inspectSubCanopy: start 
	EntView openOn: (TreeBarnacle new
			buildOn: self
			gettingChildren: [:crum | crum childArray]
			gettingImage: [:crum | crum = start
					ifTrue: [crum displayString asText allBold asDisplayText]
					ifFalse: [crum displayString asDisplayText]]
			at: 0 @ 0
			vertical: true
			separation: 5 @ 10)! !

!CanopyCrum methodsFor: 'props'!

{AgendaItem} propChanger: change {PropChange unused} with: prop {Prop}

	"Return an AgendaItem to propagate properties.
	
	NOTE: The AgendaItem returned is not yet scheduled.  Doing so is up to my caller."
	
	| |
	"Atomically
		Update myOwnFlags but not myFlags (The latter includes the widded stuff)
		return a PropChanger which at each step will update myPropJoint and move to parent."
	
	DiskManager insistent: 3 with:
		[myOwnFlags _ myOwnFlags bitOr: prop flags.
		self diskUpdate.
		^PropChanger make: self]! !

!CanopyCrum methodsFor: 'testing'!

{UInt32} contentsHash
	"This is only used by the TestPacker, so it includes all persistent state whether or not
	 it is semantically interesting--myRefCount is not semantically interesting."
	^(((((((super contentsHash
		bitXor: child1 hashForEqual)
		bitXor: child2 hashForEqual)
		bitXor: parent hashForEqual)
		bitXor: (IntegerPos integerHash: minH))
		bitXor: (IntegerPos integerHash: maxH))
		bitXor: myFlags)
		bitXor: myOwnFlags)
		bitXor: (IntegerPos integerHash: myRefCount)! !

!CanopyCrum methodsFor: 'protected'!

{BooleanVar} changeCanopy
	"Figure out new props, etc. Return true if any changes may require further propagation"
	"At least one subclass adds behavior here by overriding and calling 'super changeCanopy:'"
	
	| result {BooleanVar} |
	
	"If this is a leaf
		If any of my properties are changed
			Store the modification of the props.
	else
		save current flags
		recalculate the flags from myOwnFlags and the flags of the children
	If anything changed
		flag that the change must be written to disk
	return whether anything changed (which requires propagation rootward)"
	
	self isLeaf ifTrue:
		[result := myFlags ~= myOwnFlags.
		myFlags := myOwnFlags]
	ifFalse:
		[ | before {UInt32} |
		before := myFlags.
		myFlags := (myOwnFlags bitOr: child1 flags) bitOr: child2 flags.
		result := before ~= myFlags].
	result ifTrue:
		[self diskUpdate].
	^result!

{BooleanVar} changeHeight
	"Figure out new height. Return true if changes may require further propagation"
	
	| oldMin {IntegerVar} oldMax {IntegerVar} |
	
	"If this is a leaf then it cannot have changed
	otherwise,
	recalculate the heights from the heights of the children
	If anything changed
		flag that the change must be written to disk
	return whether anything changed (which requires propagation rootward)"
	
	self isLeaf ifTrue: [^false].
	oldMin := minH.
	oldMax := maxH.
	child1 minHeight > child2 minHeight
		ifTrue: [minH := child2 minHeight + 1]
		ifFalse: [minH := child1 minHeight + 1].
	child1 maxHeight > child2 maxHeight
		ifTrue: [maxH := child1 maxHeight + 1]
		ifFalse: [maxH := child2 maxHeight + 1].
	(oldMin ~= minH or: [oldMax ~= maxH]) ifTrue:
		[self diskUpdate.
		^true]
	ifFalse:
		[^false]!

{CanopyCrum} makeNewParent: first {CanopyCrum} with: second {CanopyCrum} 
	"Make a new crum that contains both first and second.
	This method just makes a new parent whose properties are empty. My client must bring my properties up to date"

	self subclassResponsibility! !

!CanopyCrum methodsFor: 'private'!

{CanopyCrum} makeJoin: otherCanopy {CanopyCrum} 
	"Install otherCanopy as a subtree in the canopy containing the receiver. Look below 
	the receiver and then in successively higher branches for a branch that has 
	enough height difference to contain otherCanopy."

	| height {IntegerVar} cur {CanopyCrum} prev {CanopyCrum} |
	
	self thingToDo.
	"Propagate the children's props into their new parent"
	
	self thingToDo.	"When we have non-props to propagate, do those, too.  i.e., height is currently handle by changeCanopy and will be moved out to HeightChanger momentarily."

	height _ otherCanopy maxHeight.
	cur _ self.
	[cur == NULL or: [cur heightDiff >= height]]
		whileFalse: 
			[prev _ cur.
			cur _ cur fetchParent].
	cur == NULL
		ifTrue: ["join the trees at the top"
			cur _ self makeNewParent: prev with: otherCanopy.
			self canopyCache updateCache: prev forParent: cur.
			self canopyCache updateCache: otherCanopy forParent: cur.]
		ifFalse: ["found a branch that can contain
				 otherCanopy. Place it in that branch."
			cur includeCanopy: otherCanopy].
	"Cur now contains the closest parent shared between self and otherCanopy."
	^cur! !

!CanopyCrum methodsFor: 'smalltalk: suspended'!

{BooleanVar} changeCanopy: change {PropChange unused}
	"Figure out new height, props, etc. Return true if any changes may require further propagation"
	"At least one subclass adds behavior here by overriding and calling 'super changeCanopy:'"
	
	| result {BooleanVar} |
	
	"If this is a leaf
		If any of my properties are changed
			Store the modification of the props.
	else
		save current flags
		recalculate the flags from myOwnFlags and the flags of the children
		if we're changing all properties (kludge for when combining trees)
			recompute heights (min and max)
	If anything changed
		flag that the change must be written to disk
	return whether anything changed (which requires propagation rootward)"
	
	self isLeaf ifTrue:
		[result := myFlags ~= myOwnFlags.
		result ifTrue:
			[myFlags := myOwnFlags]]
	ifFalse:
		[ | before {UInt32} |
		before := myFlags.
		myFlags := (myOwnFlags bitOr: child1 flags) bitOr: child2 flags.
		change isFull ifTrue:
			[ | oldMin {IntegerVar} oldMax {IntegerVar} |
			self thingToDo.		"Need to move height calculation into a different sort of PropChanger that propagates immediately."
			oldMin := minH.
			oldMax := maxH.
			child1 minHeight > child2 minHeight
				ifTrue: [minH := child2 minHeight + 1]
				ifFalse: [minH := child1 minHeight + 1].
			child1 maxHeight > child2 maxHeight
				ifTrue: [maxH := child1 maxHeight + 1]
				ifFalse: [maxH := child2 maxHeight + 1].
			result := oldMin ~= minH or: [oldMax ~= maxH]]
		ifFalse:
			[result := false].
		result := result or: [before ~= myFlags]].
	result ifTrue:
		[self diskUpdate].
	^result!

{PropChange} fullChange
	self subclassResponsibility!

{PropJoint} joint 

	"Return the abstracted information necessary to determine whether anything leafward may pass the filtering criteria."
	
	^myPropJoint! !

!CanopyCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	child1 _ receiver receiveHeaper.
	child2 _ receiver receiveHeaper.
	parent _ receiver receiveHeaper.
	minH _ receiver receiveIntegerVar.
	maxH _ receiver receiveIntegerVar.
	myOwnFlags _ receiver receiveUInt32.
	myFlags _ receiver receiveUInt32.
	myRefCount _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: child1.
	xmtr sendHeaper: child2.
	xmtr sendHeaper: parent.
	xmtr sendIntegerVar: minH.
	xmtr sendIntegerVar: maxH.
	xmtr sendUInt32: myOwnFlags.
	xmtr sendUInt32: myFlags.
	xmtr sendIntegerVar: myRefCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CanopyCrum class
	instanceVariableNames: ''!

(CanopyCrum getOrMakeCxxClassDescription)
	friends:
'friend class RecorderHoister;

';
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!CanopyCrum class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: Heaper2UInt32Cache.
	TheEFlagsCache := Heaper2UInt32Cache make: 50.
	ThePFlagsCache := Heaper2UInt32Cache make: 50.!

linkTimeNonInherited

	FlagEndorsements := NULL.
	OtherClubs := NULL.
	OtherEndorsements := NULL.
	TheEFlagsCache := NULL.
	ThePFlagsCache := NULL.! !

!CanopyCrum class methodsFor: 'protected: flags'!

{UInt32} endorsementsFlags: endorsements {CrossRegion}
	"Flag bits corresponding to endorsements"
	
	| result {UInt32} f {UInt32} |
	result := TheEFlagsCache fetch: endorsements.
	(result ~= UInt32Zero or: [endorsements isEmpty]) ifTrue:
		[^result].
	f := self firstEndorsementsFlag.
	FlagEndorsements ~~ NULL assert: 'Must be initialized'.
	UInt32Zero almostTo: FlagEndorsements count do: [ :i {UInt32} |
		(FlagEndorsements get: i)
			cast: Position into: [ :p |
				(endorsements hasMember: p) ifTrue:
					[result := result bitOr: f]]
			cast: XnRegion into: [ :r |
				(endorsements intersects: r) ifTrue:
					[result := result bitOr: f]].
		f := f bitShift: 1].
	(endorsements intersects: OtherEndorsements) ifTrue:
		[result := result bitOr: self otherEndorsementsFlag].
	TheEFlagsCache at: endorsements cache: result.
	^result!

{UInt32} permissionsFlags: permissions {IDRegion}
	"Flag bits corresponding to permissions"
	
	| result {UInt32} |
	result := ThePFlagsCache fetch: permissions.
	result ~= UInt32Zero ifTrue:
		[^result].
	[BeGrandMap] USES.
	(permissions hasMember: CurrentGrandMap fluidGet publicClubID) ifTrue:
		[result := result bitOr: self publicClubFlag].
	OtherClubs == NULL ifTrue:
			[OtherClubs := CurrentGrandMap fluidGet publicClubID asRegion complement cast: IDRegion].
	(permissions intersects: OtherClubs) ifTrue:
		[result := result bitOr: self otherClubsFlag].
	ThePFlagsCache at: permissions cache: result.
	^result! !

!CanopyCrum class methodsFor: 'private: flags'!

{Int32} endorsementFlagLimit
	"Max number of special endorsement flags"
	
	^23 "28 bits - 2 for permissions - 1 for all other endorsements - 2 reserved"!

{UInt32} firstEndorsementsFlag
	"Rightmost flag for interesting endorsements"
	
	^16r00000008!

{UInt32} otherClubsFlag
	"The flag for any other Clubs"
	
	^16r00000002!

{UInt32} otherEndorsementsFlag
	"Flag for all uninteresting endorsements"
	
	^16r00000004!

{UInt32} publicClubFlag
	"The flag for the Universal Public Club"
	
	^16r00000001! !

!CanopyCrum class methodsFor: 'flag setup'!

{void} useEndorsementFlags: endorsements {PtrArray of: Position | XnRegion}
	"Use a special flag to look for any of the these endorsements"
	
	(FlagEndorsements == NULL or: [FlagEndorsements contentsEqual: endorsements]) ifFalse:
		[Heaper BLAST: #InvalidRequest]. "Tried to initialize twice"
	endorsements count > self endorsementFlagLimit ifTrue:
		[Heaper BLAST: #IndexOutOfBounds].
	FlagEndorsements := endorsements copy cast: PtrArray.
	OtherEndorsements := CurrentGrandMap fluidGet endorsementSpace fullRegion cast: CrossRegion.
	Int32Zero almostTo: FlagEndorsements count do: [ :i {Int32} |
		(FlagEndorsements get: i)
			cast: Position into: [ :p |
				OtherEndorsements := (OtherEndorsements without: p) cast: CrossRegion]
			cast: XnRegion into: [ :r |
				OtherEndorsements := (OtherEndorsements minus: r) cast: CrossRegion]].! !