'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 15 March 1995 at 2:35:23 pm'!

((CxxSystemOrganization tree childNamed: 'entcanopy') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'entcanopy') destroyFiles]!

Heaper subclass: #CanopyCache
	instanceVariableNames: '
		myCachedCrum {CanopyCrum}
		myCachedRoot {CanopyCrum}
		myCachedPath {MuSet of: CanopyCrum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!

(CanopyCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CanopyCache methodsFor: 'protected: creation'!

create
	super create.
	myCachedCrum _ NULL.
	myCachedRoot _ NULL.
	myCachedPath _ MuSet make! !

!CanopyCache methodsFor: 'operations'!

{void} clearCache
	"Clear the cache because the canopy has
	 changed.  This ought to destroy the cachedPath. 
	 This must be cleared after every episode!!!!!!"

	myCachedCrum _ NULL.
	myCachedRoot _ NULL.
	myCachedPath _ MuSet make.!

{MuSet of: CanopyCrum} pathFor: canopyCrum {CanopyCrum} 
	"Return the set of all crums from canopyCrum 
	(inclusive) to the top of canopyCrum's canopy."

	(myCachedCrum basicCast: Heaper star) == canopyCrum
		ifFalse: 
			[| cur {CanopyCrum} |
			cur _ canopyCrum.
			myCachedCrum _ canopyCrum.
			myCachedRoot _ canopyCrum.
			myCachedPath _ MuSet make.
			[cur ~~ NULL]
				whileTrue: 
					[myCachedRoot _  cur.
					myCachedPath store: cur.
					cur _ cur fetchParent]].
	^myCachedPath!

{CanopyCrum} rootFor: bertCrum {CanopyCrum} 
	"Return the crum at the top of canopyCrum's canopy."

	self pathFor: bertCrum.
	^myCachedRoot!

{void} updateCache: childCrum {CanopyCrum} forParent: parentCrum {CanopyCrum} 
	"If the cache contains childCrum it must be made 
	to contain childCrum's new parent: parentCrum. 
	Also update CachedRoot." 

	(myCachedPath hasMember: childCrum) ifTrue: 
		[myCachedPath store: parentCrum.
		 (myCachedRoot basicCast: Heaper star) == childCrum 
			ifTrue: [myCachedRoot _ parentCrum]]!

{void} updateCacheFor: canopyCrum {CanopyCrum} 
	"If the cache contains canopyCrum, it must be updated 
	because canopyCrum has new parents. For now, just 
	invalidate the cache." 

	(myCachedCrum basicCast: Heaper star) == canopyCrum
		ifTrue: [self clearCache]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CanopyCache class
	instanceVariableNames: ''!

(CanopyCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CanopyCache class methodsFor: 'make'!

make
	^ self create! !Abraham subclass: #CanopyCrum
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
				OtherEndorsements := (OtherEndorsements minus: r) cast: CrossRegion]].! !CanopyCrum subclass: #BertCrum
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BertCrum comment:
'This implementation tracks the endorsement information with 
a strictly binary tree.  The tree gets heuristically balanced 
upon insertion of new elements in such a way that the ocrums 
pointing at a particular canopyCrum need not be updated.  
Therefore we should not bother storing backpointers.  I''m 
doing so currently in case we change algorithms.

Deletion may require backpointers to eliminate joins 
with the deleted crums.'!

(BertCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BertCrum methodsFor: 'private: creation'!

create
	"Make a canopyCrum for a root:  it has no children."

	super create: UInt32Zero.
	self newShepherd! !

!BertCrum methodsFor: 'protected:'!

{CanopyCache wimpy} canopyCache
	"should have one per Ent"
	^CurrentBertCanopyCache fluidGet!

{CanopyCrum} makeNew
	^BertCrum create! !

!BertCrum methodsFor: 'smalltalk:'!

{CanopyCrum} another
	"BertCrum create verify2."

	^BertCrum create!

inspectHCrums
	| owners |
	owners _ self allOwners select: [ :each | each isKindOf: HistoryCrum].
	owners isEmpty ifTrue:
		[Transcript show: 'Nobody'; cr]
	ifFalse: [owners size = 1 ifTrue:
		[owners first inspect]
	ifFalse:
		[owners inspect]]!

inspectMenuArray
	^#(
		('inspect hcrums'	inspectHCrums	'') )!

printOn: aStream 
	aStream << self getCategory name << '(' << self children size << ')'.
	"child1 = NULL
		ifTrue: [aStream << (self flags printStringRadix: 2)]
		ifFalse: 
			[aStream nextPut: $(;
				 print: child1;
				 nextPut: $,;
				 print: child2;
				 nextPut: $)]"!

showOn: oo
	oo print: self maxHeight.
	self maxHeight == self minHeight 
		ifFalse: [oo nextPut: $-; print: self minHeight].
	oo print: (self flags printStringRadix: 2)! !

!BertCrum methodsFor: 'protected'!

{CanopyCrum} makeNewParent: first {CanopyCrum} with: second {CanopyCrum}

	DiskManager consistent: 3 with:
		[^BertCrum create: (first cast: BertCrum)
			with: (second cast: BertCrum)]! !

!BertCrum methodsFor: 'instance creation'!

create: first {BertCrum} with: second {BertCrum} 
	"Create a new parent for two BertCrums.
	My client must bring my properties up to date.  This constructor just makes a new parent whose properties are empty"
	| |
	"Have the super do the basic creation."

	super create: UInt32Zero with: first with: second.
	self newShepherd.
	self canopyCache updateCache: self fetchChild1 forParent: self.
	self canopyCache updateCache: self fetchChild2 forParent: self! !

!BertCrum methodsFor: 'smalltalk: suspended'!

{PropChange} fullChange
	^PropChange bertPropChange! !

!BertCrum methodsFor: 'accessing'!

{BooleanVar} isNotPartializable

	^(self flags bitAnd: BertCrum isNotPartializableFlag) ~= UInt32Zero!

{BooleanVar} isSensorWaiting

	^(self flags bitAnd: BertCrum isSensorWaitingFlag) ~= UInt32Zero! !

!BertCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BertCrum class
	instanceVariableNames: ''!

(BertCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BertCrum class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited
	
	CanopyCache defineFluid: #CurrentBertCanopyCache with: DiskManager emulsion with: [CanopyCache make]! !

!BertCrum class methodsFor: 'instance creation'!

make
	DiskManager consistent: 1 with: [
		^BertCrum create]! !

!BertCrum class methodsFor: 'flags'!

{UInt32} flagsFor: permissions {IDRegion | NULL}
	with: endorsements {CrossRegion | NULL}
	with: isNotPartializable {BooleanVar}
	with: isSensorWaiting {BooleanVar}
	"The flag word corresponding to the given props"
	
	| result {UInt32} |
	result := UInt32Zero.
	permissions ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum permissionsFlags: permissions)].
	endorsements ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum endorsementsFlags: endorsements)].
	isNotPartializable ifTrue:
		[result := result bitOr: self isNotPartializableFlag].
	isSensorWaiting ifTrue:
		[result := result bitOr: self isSensorWaitingFlag].
	^result!

{UInt32 constFn} isNotPartializableFlag
	"Flag bit for active Editions" 
	^16r08000000!

{UInt32 constFn} isSensorWaitingFlag
	"Flag bit for active Editions" 
	^16r04000000! !CanopyCrum subclass: #SensorCrum
	instanceVariableNames: 'myBackfollowRecorders {ImmuSet of: RecorderFossil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorCrum comment:
'This implementation is the same as BertCrums.  This will require 
pointers into the ent to implement delete (for archiving).  Canopy 
reorganization could be achieved by removing several orgls, then 
re-adding them (archive then restore).'!

(SensorCrum getOrMakeCxxClassDescription)
	friends:
'friend class RecorderHoister;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SensorCrum methodsFor: 'private: creation'!

create
	"Make a canopyCrum for a root:  it has no children."
	super create: UInt32Zero.
	myBackfollowRecorders _ ImmuSet make.
	self newShepherd!

create: flags {UInt32}

	"Make a canopyCrum for a root:  it has no children."
	super create: flags.
	myBackfollowRecorders _ ImmuSet make.
	self newShepherd! !

!SensorCrum methodsFor: 'smalltalk:'!

{CanopyCrum} another
	"SensorCrum create verify2."

	^SensorCrum create!

displayString
	^String
		streamContents: 
			[:aStream | 
			aStream print: self maxHeight.
			self maxHeight == self minHeight 
				ifFalse: [aStream nextPut: $-; print: self minHeight]]!

inspectMenuArray
	^#(
		('inspect oparts'	inspectOParts		''))!

inspectOParts
	| owners |
	owners _ self allOwners select: [ :each | each isKindOf: OPart].
	owners isEmpty ifTrue:
		[Transcript show: 'Nobody'; cr]
	ifFalse: [owners size = 1 ifTrue:
		[owners first inspect]
	ifFalse:
		[owners inspect]]!

{void} printOn: aStream 
	[myBackfollowRecorders == nil ifTrue: [
		aStream << self getCategory name << '(nil)'. ^ VOID]] smalltalkOnly.
		
	aStream << self getCategory name << '(' << (self flags printStringRadix: 2) << ')'.
	myBackfollowRecorders isEmpty ifFalse:
		[aStream << ' *']! !

!SensorCrum methodsFor: 'protected:'!

{CanopyCache wimpy} canopyCache
	"should have one per Ent"
	^CurrentSensorCanopyCache fluidGet!

{CanopyCrum} makeNew

	Dean thingToDo. "is this right? I want to preserve the partiality flag when a partial loaf splits /ravi/5/7/92/"
	self isPartial ifTrue:
		[^SensorCrum create: SensorCrum isPartialFlag]
	ifFalse:
		[^SensorCrum create]! !

!SensorCrum methodsFor: 'accessing'!

{PropFinder} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	"Set off all recorders that respond to the change either in me or in any of my ancestors up to but not including sCrum
	(If I am the same as sCrum, skip me as well.)
	(If sCrum is null, search through all my ancestors to a root of the sensor canopy.)
	return simplest finder for looking at children"
	
	| next {SensorCrum | NULL} |
	
	"from self rootward until told to stop (at sCrum or the root)
		trigger any matching recorders
	return a simplified finder for examining children."
	
	next := self.
	[next ~~ NULL] whileTrue:
		[next := next fetchNextAfterTriggeringRecorders: finder with: scrum].
	^finder pass: self!

{SensorCrum | NULL} fetchNextAfterTriggeringRecorders: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
	"Set off all recorders in me that respond to the change, if appropriate
	(If I am the same as sCrum, skip me.)
	If sCrum is null or not me, return my parent so caller can iterate through my ancestors to sCrum or a root."
	
	|  |
	
	"One step of the leafward walk of the O-plane, triggering recorders:
	Walk rootward on the sensor canopy, where many steps may correspond to this single leafward step."
	
	"If we're the designated sCrum (where this work was already done)
	 	return without doing anything.  We're done.
	For each of our recorders
		if it hasn't gone extinct
			reanimate it long enough to
				trigger it, recording stamp if finder matches.
	Return a pointer to our parent (so caller can iterate this operation rootward)."
	
	(sCrum ~~ NULL and: [self isEqual: sCrum]) ifTrue:
		[^NULL].
	myBackfollowRecorders stepper forEach: [ :fossil {RecorderFossil} |
		fossil isExtinct ifFalse:
			[fossil reanimate: [:recorder {ResultRecorder} |
				recorder triggerIfMatching: finder with: fossil]]].
	^self fetchParent cast: SensorCrum.!

{BooleanVar} isPartial

	^(self flags bitAnd: SensorCrum isPartialFlag) ~= UInt32Zero!

{ImmuSet of: RecorderFossil} recorders
	^myBackfollowRecorders!

{AgendaItem} recordingAgent: recorder {RecorderFossil}
	"NOTE: The AgendaItem returned is not yet scheduled.  Doing so is up to my caller."
	
	|  |
	
	"If the recorder we're adding isn't already present here
		pack up the fossil for shipment to the hoister
		atomically
			Install the recorder here
			return a RecorderHoister to propagate the side-effects and anneal the canopy
			(The RecorderHoister will update myFlags)
	return an empty agenda (to satisfy our contract)"
	
	(myBackfollowRecorders hasMember: recorder) ifFalse:
		[ | cargo {ImmuSet of: RecorderFossil} |
		cargo := ImmuSet make with: recorder.
		DiskManager consistent: 2 with:
			[self installRecorders: cargo.
			self diskUpdate.
			^RecorderHoister make: self with: cargo]].
	^Agenda make!

{void} removeRecorders: recorders {ImmuSet of: RecorderFossil}
	"Remove recorders because they have migrated rootward.
	Recalculate myOwnFlags and myFlags."
	
	| f {UInt32} |
	myBackfollowRecorders _ myBackfollowRecorders minus: recorders.
	self diskUpdate.
	f := UInt32Zero.
	myBackfollowRecorders stepper forEach: [ :fossil {RecorderFossil} |
		fossil isExtinct ifFalse:
			[fossil reanimate: [:recorder {ResultRecorder} |
				f := f bitOr: recorder sensorProp flags]]].
	self setOwnFlags: f.
	self changeCanopy! !

!SensorCrum methodsFor: 'private:'!

{void} installRecorders: recorders {ImmuSet of: RecorderFossil}
	"Installs the recorders in my set and updates myOwnProp accordingly.
	The caller has already checked that none of these recorders are already installed here.
	The caller also handles updating myFlags.
	The caller also handles all issues of rootward propagation of these changes.
	The caller also does the 'diskUpdate'.
	
	This is a separate method because it's called once by the code that installs a new recorder, and again by the code that recursively hoists recurders up the canopy.
	
	add the new recorders to my set
	for each new recorder
		if it hasn't gone extinct
			extract its properties
			union them into my own"

	myBackfollowRecorders _ myBackfollowRecorders unionWith: recorders.
	recorders stepper forEach: [ :fossil {RecorderFossil} |
		fossil isExtinct ifFalse: [ | prop {Prop} |
			fossil reanimate: [:recorder {ResultRecorder} |
				prop := recorder sensorProp].
			self setOwnFlags: (self ownFlags bitOr: prop flags)]]! !

!SensorCrum methodsFor: 'protected'!

{CanopyCrum} makeNewParent: first {CanopyCrum} with: second {CanopyCrum}

	DiskManager consistent: 3 with:
		[^SensorCrum create: (first cast: SensorCrum)
	 		with: (second cast: SensorCrum)]! !

!SensorCrum methodsFor: 'smalltalk: passe'!

{PropFinder} checkRecorders: stamp {BeEdition} 
	with: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
self passe "fewer args"!

{SensorCrum | NULL} fetchNextAfterTriggeringRecorders: stamp {BeEdition} 
	with: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
	self passe "fewer args"!

{void} record: recorder {RecorderFossil}
	
	self passe. "equivalent to '(self recordingAgent: recorder) schedule"!

{void} triggerRecorders: stamp {Stamp} 
	with: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
	self passe.	"Use fetchNextAfterTriggeringRecorders:with:with:"! !

!SensorCrum methodsFor: 'instance creation'!

create: first {SensorCrum} with: second {SensorCrum}
	"Create a new parent for two SensorCrums.
	This constructor just makes a new parent whose properties are empty. My client must bring my properties up to date."
	| |
	"Have the super do the basic creation."
	
	super create: UInt32Zero with: first with: second.
	self newShepherd.
	myBackfollowRecorders _ ImmuSet make.
	self canopyCache updateCache: self fetchChild1 forParent: self.
	self canopyCache updateCache: self fetchChild2 forParent: self! !

!SensorCrum methodsFor: 'smalltalk: suspended'!

changeCanopy: f!

{PropChange} fullChange
	^PropChange sensorPropChange! !

!SensorCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBackfollowRecorders _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBackfollowRecorders.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SensorCrum class
	instanceVariableNames: ''!

(SensorCrum getOrMakeCxxClassDescription)
	friends:
'friend class RecorderHoister;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SensorCrum class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	
	CanopyCache defineFluid: #CurrentSensorCanopyCache with: DiskManager emulsion with: [CanopyCache make]! !

!SensorCrum class methodsFor: 'pseudo constructors'!

make
	DiskManager consistent: 2 with: [
		^SensorCrum create]!

{SensorCrum} partial
	DiskManager consistent: 1 with: [
		^SensorCrum create: SensorCrum isPartialFlag]! !

!SensorCrum class methodsFor: 'flags'!

{UInt32} flagsFor: permissions {IDRegion | NULL}
	with: endorsements {CrossRegion | NULL}
	with: isPartial {BooleanVar}
	"The flag word corresponding to the given props"
	
	| result {UInt32} |
	result := UInt32Zero.
	permissions ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum permissionsFlags: permissions)].
	endorsements ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum endorsementsFlags: endorsements)].
	isPartial ifTrue:
		[result := result bitOr: self isPartialFlag].
	^result!

{UInt32 constFn} isPartialFlag
	"Flag bit for existence of partiality" 
	^16r08000000! !Heaper subclass: #Heaper2UInt32Cache
	instanceVariableNames: '
		myKeys {PtrArray}
		myValues {UInt32Array}
		myEmptyValue {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-canopy'!
Heaper2UInt32Cache comment:
'Caches a mapping from Heapers (using isEqual / hashForEqual) to UInt32s. Returns myEmptyValue if there is no cached mapping.'!

(Heaper2UInt32Cache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Heaper2UInt32Cache methodsFor: 'accessing'!

{void} at: key {Heaper} cache: value {UInt32}
	"Cache a value for a key"
	
	| index {Int32} |
	index := key hashForEqual \\ myKeys count.
	myKeys at: index store: key.
	myValues at: index storeUInt: value.!

{UInt32} fetch: key {Heaper}
	"Return the cached value for the key, or my empty value if there is none"
	
	| index {Int32} k {Heaper} |
	index := key hashForEqual \\ myKeys count.
	k := myKeys fetch: index.
	(k ~~ NULL and: [k == key or: [k isEqual: key]])
		ifTrue: [^myValues uIntAt: index]
		ifFalse: [^myEmptyValue]!

{UInt32} get: key {Heaper}
	"Return the cached value for the key, or BLAST if there is none"
	
	| index {Int32} k {Heaper} |
	index := key hashForEqual \\ myKeys count.
	k := myKeys fetch: index.
	(k ~~ NULL and: [k == key or: [k isEqual: key]])
		ifFalse: [Heaper BLAST: #NotInTable].
	^myValues uIntAt: index! !

!Heaper2UInt32Cache methodsFor: 'create'!

create: count {Int32} with: empty {UInt32}

	super create.
	myKeys := PtrArray nulls: count.
	myValues := UInt32Array make: count.
	myEmptyValue := empty.
	empty ~~ UInt32Zero ifTrue:
		[myValues storeAll: (PrimIntValue make: empty)]! !

!Heaper2UInt32Cache methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Heaper2UInt32Cache class
	instanceVariableNames: ''!

(Heaper2UInt32Cache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Heaper2UInt32Cache class methodsFor: 'smalltalk: defaults'!

make: n
	^self make: n with: 0! !

!Heaper2UInt32Cache class methodsFor: 'create'!

make: count {Int32} with: empty {UInt32 default: UInt32Zero}

	^self create: (PrimeSizeProvider make uInt32PrimeAfter: count) with: empty! !

!Heaper2UInt32Cache class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: PrimArray.
	self REQUIRES: PrimeSizeProvider.! !Heaper subclass: #Prop
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
Prop comment:
'A collection of properties which are to be found by navigating a Canopy.  PropJoints are the union/intersection style abstraction of the properties which provide for such navigation.'!

(Prop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Prop methodsFor: 'accessing'!

{UInt32} flags
	"The flags used in the Canopy to tag this prop"
	
	self subclassResponsibility!

{Prop} with: other {Prop}
	self subclassResponsibility! !

!Prop methodsFor: 'smalltalk: suspended'!

{PropJoint} joint

	"Returns the filtering information from this one prop as a PropJoint. "
	
	self subclassResponsibility! !Prop subclass: #BertProp
	instanceVariableNames: '
		myPermissions {XnRegion of: ID}
		myEndorsements {XnRegion of: ID}
		mySensorWaitingFlag {BooleanVar}
		myCannotPartializeFlag {BooleanVar}'
	classVariableNames: 'TheIdentityBertProp {BertProp} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
BertProp comment:
'The properties which are nevigable towards using the Bert Canopy.  All of these are properties of the Stamps at the leaves of the Bert Canopy.'!

(BertProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!BertProp methodsFor: 'accessing'!

{CrossRegion} endorsements
	^myEndorsements cast: CrossRegion!

{UInt32} flags

	^BertCrum flagsFor: (myPermissions cast: IDRegion)
		with: (myEndorsements cast: CrossRegion)
		with: myCannotPartializeFlag
		with: mySensorWaitingFlag!

{BooleanVar} isNotPartializable
	^myCannotPartializeFlag!

{BooleanVar} isSensorWaiting
	^mySensorWaitingFlag!

{XnRegion of: ID} permissions
	^myPermissions!

{Prop} with: other {Prop}
	| o {BertProp} |
	o _ other cast: BertProp.
	^BertProp make: (myPermissions unionWith: o permissions)
		with: (myEndorsements unionWith: o endorsements)
		with: (mySensorWaitingFlag or: [o isSensorWaiting])
		with: (myCannotPartializeFlag or: [o isNotPartializable])! !

!BertProp methodsFor: 'creation'!

create: permissions {XnRegion of: ID} 
	with: endorsements {XnRegion of: ID} 
	with: isSensorWaiting {BooleanVar} 
	with: isNotPartializable {BooleanVar}
	super create.
	myPermissions _ permissions.
	myEndorsements _ endorsements.
	mySensorWaitingFlag _ isSensorWaiting.
	myCannotPartializeFlag _ isNotPartializable.! !

!BertProp methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myPermissions hashForEqual bitXor: myEndorsements hashForEqual!

{BooleanVar} isEmpty
	"Does this do the right thing."
	
	self knownBug.
	^myEndorsements isEmpty and: [myPermissions isEmpty]!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: BertProp into: [:b |
			^(b endorsements isEqual: myEndorsements)
			 and: [(b permissions isEqual: myPermissions)
			 and: [b isSensorWaiting == mySensorWaitingFlag
			 and: [b isNotPartializable == myCannotPartializeFlag]]]]
		others: [^false].
	^ false "compiler fodder"! !

!BertProp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(P: ' << myPermissions << '; E: ' << myEndorsements.
	mySensorWaitingFlag ifTrue: [oo << '; sensor'].
	myCannotPartializeFlag ifTrue: [oo << '; cannot partialize'].
	oo << ')'! !

!BertProp methodsFor: 'smalltalk: suspended'!

{PropJoint} joint
	^BertPropJoint
		make: (Joint make: myPermissions)
		with: (Joint make: myEndorsements)
		with: mySensorWaitingFlag
		with: myCannotPartializeFlag! !

!BertProp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.
	mySensorWaitingFlag _ receiver receiveBooleanVar.
	myCannotPartializeFlag _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsements.
	xmtr sendBooleanVar: mySensorWaitingFlag.
	xmtr sendBooleanVar: myCannotPartializeFlag.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BertProp class
	instanceVariableNames: ''!

(BertProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!BertProp class methodsFor: 'creation'!

{BertProp} cannotPartializeProp
	[BeGrandMap] USES.
	^BertProp make: IDSpace global emptyRegion
		with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
		with: false
		with: true!

{BertProp} detectorWaitingProp

	^BertProp make: CurrentGrandMap fluidGet globalIDSpace emptyRegion
			with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
			with: true
			with: false!

{BertProp} endorsementsProp: endorsements {XnRegion}

	^BertProp make: IDSpace global emptyRegion
		with: endorsements
		with: false
		with: false!

{BertProp} make

	TheIdentityBertProp == NULL ifTrue:
		[TheIdentityBertProp := BertProp make: IDSpace global emptyRegion
			with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
			with: false
			with: false].
	^TheIdentityBertProp!

make: permissions {XnRegion of: ID} 
	with: endorsements {XnRegion} 
	with: isSensorWaiting {BooleanVar} 
	with: isNotPartializable {BooleanVar} 
	^self
		create: permissions
		with: endorsements
		with: isSensorWaiting
		with: isNotPartializable!

{BertProp} permissionsProp: iDs {XnRegion of: ID}
	^BertProp make: iDs
		with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
		with: false
		with: false! !

!BertProp class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	TheIdentityBertProp _ NULL.! !

!BertProp class methodsFor: 'smalltalk: passe'!

{BertProp} sensorWaitingProp

	self passe! !Prop subclass: #SensorProp
	instanceVariableNames: '
		myRelevantPermissions {IDRegion}
		myRelevantEndorsements {CrossRegion of: IDRegion and: IDRegion}
		myPartialFlag {BooleanVar}'
	classVariableNames: '
		TheIdentitySensorProp {SensorProp} 
		ThePartialSensorProp {SensorProp} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
SensorProp comment:
'The properties which are nevigable towards using the Sensor Canopy.  The permissions and endorsements are those whose changes may affect the triggering of the recorders that decorate the canopy.  myPartialFlag is a property of the o-leaf-stuff which are at the leaves of the Sensor Canopy.'!

(SensorProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SensorProp methodsFor: 'creation'!

create: relevantPermissions {IDRegion} 
	with: relevantEndorsements {CrossRegion of: IDRegion and: IDRegion} 
	with: isPartial {BooleanVar}
	
	super create.
	myRelevantPermissions _ relevantPermissions.
	myRelevantEndorsements _ relevantEndorsements.
	myPartialFlag _ isPartial.! !

!SensorProp methodsFor: 'accessing'!

{UInt32} flags

	^SensorCrum flagsFor: myRelevantPermissions
		with: myRelevantEndorsements
		with: myPartialFlag!

{BooleanVar} isPartial
	^myPartialFlag!

{CrossRegion} relevantEndorsements

	^myRelevantEndorsements!

{IDRegion} relevantPermissions

	^myRelevantPermissions!

{Prop} with: other {Prop}
	
	other cast: SensorProp into: [ :o |
		^SensorProp make: ((myRelevantPermissions
				unionWith: o relevantPermissions) cast: IDRegion)
			with: ((myRelevantEndorsements
				unionWith: o relevantEndorsements) cast: CrossRegion)
			with: (myPartialFlag or: [o isPartial])].
	^ NULL "compiler fodder"! !

!SensorProp methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myRelevantPermissions hashForEqual
		bitXor: myRelevantEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper
		cast: SensorProp into: [ :prop |
			^(myRelevantEndorsements isEqual: prop relevantEndorsements)
				and: [(myRelevantPermissions isEqual: prop relevantPermissions)
				and: [myPartialFlag == prop isPartial]]]
		others:
			[^false].
	^ false "compiler fodder"! !

!SensorProp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'SensorProp(P: ' << myRelevantPermissions
		<< '; E: ' << myRelevantEndorsements.
	myPartialFlag ifTrue: [oo << '; partial'].
	oo << ')'! !

!SensorProp methodsFor: 'smalltalk: passe'!

{Filter of: (XuRegion of: ID)} endorsementsFilter

	self passe!

{Filter of: (XuRegion of: ID)} permissionsFilter

	self passe! !

!SensorProp methodsFor: 'smalltalk: suspended'!

{PropJoint} joint

	Ravi thingToDo. "implement proper simpleRegions so we can use simpleUnion"
	^SensorPropJoint make: (myRelevantPermissions "asSimpleRegion" cast: IDRegion)
		with: (myRelevantEndorsements "asSimpleRegion" cast: CrossRegion)
		with: myPartialFlag! !

!SensorProp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRelevantPermissions _ receiver receiveHeaper.
	myRelevantEndorsements _ receiver receiveHeaper.
	myPartialFlag _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRelevantPermissions.
	xmtr sendHeaper: myRelevantEndorsements.
	xmtr sendBooleanVar: myPartialFlag.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SensorProp class
	instanceVariableNames: ''!

(SensorProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SensorProp class methodsFor: 'creation'!

make
	"returns an empty SensorProp"
	
	TheIdentitySensorProp == NULL ifTrue:
		[TheIdentitySensorProp := self
			create: (CurrentGrandMap fluidGet globalIDSpace emptyRegion cast: IDRegion)
			with: (CurrentGrandMap fluidGet endorsementSpace emptyRegion cast: CrossRegion)
			with: false].
	^TheIdentitySensorProp!

make: relevantPermissions {IDRegion} 
	with: relevantEndorsements {CrossRegion} 
	with: isPartial {BooleanVar}

	^self create: relevantPermissions with: relevantEndorsements with: isPartial!

{SensorProp} partial

	"returns an empty SensorProp with the partial flag on"
	ThePartialSensorProp == NULL ifTrue:
		[ThePartialSensorProp := self
			create: (CurrentGrandMap fluidGet globalIDSpace emptyRegion cast: IDRegion)
			with: (CurrentGrandMap fluidGet endorsementSpace emptyRegion cast: CrossRegion)
			with: true].
	^ThePartialSensorProp! !

!SensorProp class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	TheIdentitySensorProp _ NULL.
	ThePartialSensorProp _ NULL.! !Heaper subclass: #PropChange
	instanceVariableNames: ''
	classVariableNames: '
		TheBertPropChange {PropChange} 
		TheCannotPartializeChange {PropChange} 
		TheDetectorWaitingChange {PropChange} 
		TheEndorsementsChange {PropChange} 
		ThePermissionsChange {PropChange} 
		TheSensorPropChange {PropChange} '
	poolDictionaries: ''
	category: 'Xanadu-props'!
PropChange comment:
'Each concrete class has just one canonical instance and no state.  A PropChange is used to represent which property aspect changed (such as permission vs endorsement vs both).'!

(PropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	self subclassResponsibility!

{Prop} changed: old {Prop} with: a {Prop}
	"Return a Prop which is the same as 'old' for aspects which I don't represent as changing, and 'a' for aspects that I do represent as changing.
	
	 This is used to replace Props with minimum effort, given that the 'a' parameter has only new props which are of the aspect this change replaces, while the 'old' parameter starts as the original set of Props, perhaps including other aspects.
	 
	 See also: with:with:, which unions rather than replacing."
	
	self subclassResponsibility!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	"return a finder looking for this change from before to after, in addition to whatever oldFinder is looking for (assumes this changes is a subset of oldFinder's change)"
	
	self subclassResponsibility!

{BooleanVar} isFull
	"whether this is a complete change of props"
	self subclassResponsibility!

{Prop} with: old {Prop} with: a {Prop}
	"Return a Prop which is the same as 'old' for aspects which I don't represent as changing, and the union of 'old' and 'a' for aspects that I do represent as changing.
	
	 This is used to accumulate changes to Props with minimum effort, given that the 'a' parameter has only new props which are of the aspect this change changes, while the 'old' parameter starts as the original set of Props, perhaps including other aspects.
	 
	 See also changed:with:, which replaces rather than unioning."
	
	self subclassResponsibility! !

!PropChange methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self takeOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!PropChange methodsFor: 'smalltalk: passe'!

{PropFinder} fetchFinder: before {Prop} with: after {Prop}

	self passe "extra args"!

{PropFinder} finderPartFrom: finder {PropFinder}

	self passe! !

!PropChange methodsFor: 'smalltalk: defaults'!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	
	^self fetchFinder: before with: after with: element with: NULL! !

!PropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	
	self subclassResponsibility!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	"Return a PropJoint which is the same as 'old' for aspects which I don't represent as changing, and 'a' for aspects that I do represent as changing.
	
	 This is used to replace PropJoints with minimum effort, given that the 'a' parameter has only new PropJoints which are of the aspect this change replaces, while the 'old' parameter starts as the original set of PropJoints, perhaps including other aspects.
	 
	 See also: change:with:, which does this for Props rather than PropJoints."
	
	self subclassResponsibility!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	self subclassResponsibility!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	self subclassResponsibility!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropChange class
	instanceVariableNames: ''!

(PropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropChange class methodsFor: 'pseudo constructors'!

{PropChange} bertPropChange
	^TheBertPropChange!

{PropChange} cannotPartializeChange
	^TheCannotPartializeChange!

{PropChange} detectorWaitingChange
	^TheDetectorWaitingChange!

{PropChange} endorsementsChange
	^TheEndorsementsChange!

{PropChange} permissionsChange
	^ThePermissionsChange!

{PropChange} sensorPropChange
	"Returns the canonical PropChange object for propagating the properties that result from installing a recorder (permissions and endorsement filters).  A better name would be recorderPropChange"
	
	^TheSensorPropChange! !

!PropChange class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	TheCannotPartializeChange _ CannotPartializeChange create.
	TheDetectorWaitingChange _ DetectorWaitingChange create.
	TheEndorsementsChange _ EndorsementsChange create.
	TheBertPropChange _ BertPropChange create.
	TheSensorPropChange _ SensorPropChange create.
	ThePermissionsChange _ PermissionsChange create.!

linkTimeNonInherited
	TheCannotPartializeChange _ NULL.
	TheDetectorWaitingChange _ NULL.
	TheEndorsementsChange _ NULL.
	TheBertPropChange _ NULL.
	TheSensorPropChange _ NULL.
	ThePermissionsChange _ NULL! !PropChange subclass: #CannotPartializeChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
CannotPartializeChange comment:
'The "Cannot Partialize" property is a Bert Canopy property to remember that a Stamp is actively being viewed (by a session level Orgl) and therefore cannot be poured-out (made more partial).  Should probably not be a Prop(erty), by rather a NOCOPY session level bit in the BertCrums.'!

(CannotPartializeChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CannotPartializeChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) isNotPartializable == (b cast: BertProp) isNotPartializable!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	bp isNotPartializable == abp isNotPartializable ifTrue: [^old].
	^BertProp make: bp permissions
		with: bp endorsements
		with: bp isSensorWaiting
		with: abp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	(bp isNotPartializable or: [abp isNotPartializable not])
		ifTrue: [^old]
		ifFalse: [^BertProp make: bp permissions
			with: bp endorsements
			with: bp isSensorWaiting
			with: abp isNotPartializable]! !

!CannotPartializeChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) isNotPartializable == (b cast: BertPropJoint) isNotPartializable!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	bpj isNotPartializable == one isNotPartializable
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) isNotPartializable == (b cast: BertProp) isNotPartializable!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	bpj isNotPartializable == (one isNotPartializable
			or: [two isNotPartializable])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} p {BertProp wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	p _ prop cast: BertProp.
	bpj isNotPartializable == (one isNotPartializable
			or: [two isNotPartializable
			or: [p isNotPartializable]])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]! !

!CannotPartializeChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #DetectorWaitingChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
DetectorWaitingChange comment:
'The "Detector Waiting" property is a Bert Canopy property to remember that an Edition has a Detector waiting for PlaceHolders to be filled in.'!

(DetectorWaitingChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!DetectorWaitingChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) isSensorWaiting == (b cast: BertProp) isSensorWaiting!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	bp isSensorWaiting == abp isSensorWaiting ifTrue: [^old].
	^BertProp make: bp permissions
		with: bp endorsements
		with: abp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL!

{BooleanVar} isFull

	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	(bp isSensorWaiting or: [abp isSensorWaiting not])
		ifTrue: [^old]
		ifFalse: [^BertProp make: bp permissions
			with: bp endorsements
			with: abp isSensorWaiting
			with: bp isNotPartializable]! !

!DetectorWaitingChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) isSensorWaiting == (b cast: BertPropJoint) isSensorWaiting!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	bpj isSensorWaiting == one isSensorWaiting
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: one isSensorWaiting
				with: bpj isNotPartializable]!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}

	^(a cast: BertPropJoint) isSensorWaiting == (b cast: BertProp) isSensorWaiting!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}

	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	bpj isSensorWaiting == (one isSensorWaiting
			or: [two isSensorWaiting])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting not
				with: bpj isNotPartializable]!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}

	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} p {BertProp wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	p _ prop cast: BertProp.
	bpj isSensorWaiting == (one isSensorWaiting
			or: [two isSensorWaiting
			or: [p isSensorWaiting]])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting not
				with: bpj isNotPartializable]! !

!DetectorWaitingChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #EndorsementsChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
EndorsementsChange comment:
'Used when the Endorsement part of a BertProp changed'!

(EndorsementsChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!EndorsementsChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) endorsements isEqual: (b cast: BertProp) endorsements!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: bp permissions
		with: (a cast: BertProp) endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	before cast: BertProp into: [ :b |
	after cast: BertProp into: [ :a |
		| result {PropFinder} delta {RegionDelta}
		  any {PropFinder} anys {ImmuSet}
		  simple {PropFinder} simples {ImmuSet} |
		delta := RegionDelta make: b endorsements with: a endorsements.
		delta isSame ifTrue:
			[^NULL].
		any := AnyRecorderEFinder make: (a permissions cast: IDRegion) with: delta.
		any isEmpty
			ifTrue: [anys := ImmuSet make]
			ifFalse: [anys := ImmuSet newWith: any].
		simple := OriginalResultRecorderEFinder make: element
			with: (a permissions cast: IDRegion)
			with: delta.
		simple isEmpty
			ifTrue: [simples := ImmuSet make]
			ifFalse: [simples := ImmuSet newWith: simple].
		oldFinder == NULL ifTrue:
			[result := CumulativeRecorderFinder
				make: anys
				with: simples
				with: ImmuSet make]
		ifFalse:
			[oldFinder cast: CumulativeRecorderFinder into: [ :crf |
				result := CumulativeRecorderFinder
					make: anys
					with: simples
					with: (crf current unionWith: crf others)]].
		result isEmpty
			ifTrue: [^NULL]
			ifFalse: [^result]]].
	^NULL "fodder"!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: bp permissions
		with: ((a cast: BertProp) endorsements unionWith: bp endorsements)
		with: bp isSensorWaiting
		with: bp isNotPartializable! !

!EndorsementsChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) endorsementsJoint isEqual: (b cast: BertPropJoint) endorsementsJoint!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bertprop {BertPropJoint wimpy} |
	bertprop _ old cast: BertPropJoint.
	^BertPropJoint make: bertprop  permissionsJoint
		with: (a cast: BertPropJoint) endorsementsJoint
		with: bertprop isSensorWaiting
		with: bertprop isNotPartializable!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) endorsementsJoint unioned isEqual: (b cast: BertProp) endorsements!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bertprop {BertPropJoint wimpy} |
	bertprop _ old cast: BertPropJoint.
	^BertPropJoint make: bertprop  permissionsJoint
		with: ((a cast: BertPropJoint) endorsementsJoint join: (b cast: BertPropJoint) endorsementsJoint)
		with: bertprop isSensorWaiting
		with: bertprop isNotPartializable!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	^BertPropJoint make: bpj  permissionsJoint
		with: (((a cast: BertPropJoint) endorsementsJoint
			join: (b cast: BertPropJoint) endorsementsJoint)
			with: (prop cast: BertProp) endorsements)
		with: bpj isSensorWaiting
		with: bpj isNotPartializable! !

!EndorsementsChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #FullPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
FullPropChange comment:
'Use this to indicate that all aspects of the Prop may have changed.'!

(FullPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!FullPropChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^a isEqual: b!

{Prop} changed: old {Prop unused} with: a {Prop}

	^a!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	self subclassResponsibility!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^true!

{Prop} with: old {Prop} with: a {Prop}

	^old with: a! !

!FullPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^a isEqual: b!

{PropJoint} changedJoint: old {PropJoint unused} with: a {PropJoint}
	
	^a!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	self subclassResponsibility!

{PropJoint} join: old {PropJoint unused} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	^a join: b!

{PropJoint} joinProp: old {PropJoint unused} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	^(a join: b) with: prop! !FullPropChange subclass: #BertPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
BertPropChange comment:
'Use when it is fine to consider that all aspects of the BertProp may have changed'!

(BertPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BertPropChange methodsFor: 'accessing'!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	| p {PropFinder} e {PropFinder} |
	p := PropChange permissionsChange
			fetchFinder: before with: after with: element with: oldFinder.
	e := PropChange endorsementsChange
			fetchFinder: before with: after with: element with: oldFinder.
	p == NULL ifTrue: [^e].
	e == NULL ifTrue: [^p].
	p cast: CumulativeRecorderFinder into: [ :pcrf |
	e cast: CumulativeRecorderFinder into: [ :ecrf |
		^CumulativeRecorderFinder
			make: (pcrf generators unionWith: ecrf generators)
			with: (pcrf current unionWith: ecrf current)
			with: (pcrf others unionWith: ecrf others)]].
	^NULL "fodder"! !

!BertPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	| bpj {BertPropJoint wimpy} bp {BertProp wimpy} |
	bpj _ a cast: BertPropJoint.
	bp _ b cast: BertProp.
	^(bpj endorsementsJoint unioned isEqual: bp endorsements)
		and: [(bpj permissionsJoint unioned isEqual: bp permissions)
		and: [bpj isSensorWaiting == bp isSensorWaiting
		and: [bpj isNotPartializable == bp isNotPartializable]]]! !

!BertPropChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !FullPropChange subclass: #SensorPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
SensorPropChange comment:
'Use when it is fine to consider that all aspects of the SensorProp may have changed'!

(SensorPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SensorPropChange methodsFor: 'accessing'!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL! !

!SensorPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	
	a cast: SensorPropJoint into: [ :spj |
	b cast: SensorProp into: [ :sp |
		^(spj relevantEndorsements isEqual: sp relevantEndorsements)
			and: [(spj relevantPermissions isEqual: sp relevantPermissions)
			and: [spj isPartial == sp isPartial]]]].
	^false "fodder"! !

!SensorPropChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #PermissionsChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
PermissionsChange comment:
'Used when the Permissions part of a BertProp changed'!

(PermissionsChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!PermissionsChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) permissions isEqual: (b cast: BertProp) permissions!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: (a cast: BertProp) permissions
		with: bp endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	before cast: BertProp into: [ :b |
	after cast: BertProp into: [ :a |
		| result {PropFinder} delta {RegionDelta}
		  any {PropFinder} anys {ImmuSet}
		  simple {PropFinder} simples {ImmuSet} |
		delta := RegionDelta make: b permissions with: a permissions.
		delta isSame ifTrue:
			[^NULL].
		any := AnyRecorderPFinder make: delta.
		any isEmpty
			ifTrue: [anys := ImmuSet make]
			ifFalse: [anys := ImmuSet newWith: any].
		simple :=ResultRecorderPFinder make: element
			with: delta
			with: a endorsements.
		simple isEmpty
			ifTrue: [simples := ImmuSet make]
			ifFalse: [simples := ImmuSet newWith: simple].
		oldFinder == NULL ifTrue:
			[result := CumulativeRecorderFinder
				make: anys
				with: simples
				with: ImmuSet make]
		ifFalse:
			[oldFinder cast: CumulativeRecorderFinder into: [ :crf |
				result := CumulativeRecorderFinder
					make: anys
					with: simples
					with: (crf current unionWith: crf others)]].
		result isEmpty
			ifTrue: [^NULL]
			ifFalse: [^result]]].
	^NULL "fodder"!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: ((a cast: BertProp) permissions unionWith: bp permissions)
		with: bp endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable! !

!PermissionsChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) permissionsJoint isEqual: (b cast: BertPropJoint) permissionsJoint!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bp {BertPropJoint wimpy} |
	bp _ old cast: BertPropJoint.
	^BertPropJoint make: (a cast: BertPropJoint) permissionsJoint
		with: bp endorsementsJoint
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) permissionsJoint unioned isEqual: (b cast: BertProp) permissions!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bp {BertPropJoint wimpy} |
	bp _ old cast: BertPropJoint.
	^BertPropJoint make: ((a cast: BertPropJoint) permissionsJoint join: (b cast: BertPropJoint) permissionsJoint)
		with: bp endorsementsJoint
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	^BertPropJoint make: (((a cast: BertPropJoint) permissionsJoint
			join: (b cast: BertPropJoint) permissionsJoint)
			with: (prop cast: BertProp) permissions)
		with: bpj endorsementsJoint
		with: bpj isSensorWaiting
		with: bpj isNotPartializable! !

!PermissionsChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !AgendaItem subclass: #PropChanger
	instanceVariableNames: 'myCrum {CanopyCrum | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
PropChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(PropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!PropChanger methodsFor: 'protected: accessing'!

{CanopyCrum | NULL} fetchCrum

	^myCrum!

{void} setCrum: aCrum {CanopyCrum | NULL}
	"Move our placeholding finger to a new crum, updating refcounts accordingly"
	
	| |
	
	"atomically (though we've probably already gone nuclear)
		If there is a new crum
			bump its refcount.
		If there is an old crum
			unbump its refcount.
		Remember the new crum."
		
	DiskManager consistent: 3 with:
		[aCrum ~~ NULL ifTrue:
			[aCrum addPointer: self].
		myCrum ~~ NULL ifTrue:
			[myCrum removePointer: self].
		myCrum := aCrum.
		self diskUpdate].! !

!PropChanger methodsFor: 'accessing'!

{BooleanVar} step
	"propagate some prop(erty) change one step parentwards, until it gets to a local root or no further propagation in necessary."
	
	self subclassResponsibility! !

!PropChanger methodsFor: 'creation'!

create: crum {CanopyCrum | NULL}

	super create.
	myCrum _ crum.
	myCrum == NULL ifTrue:
		[myCrum addPointer: self].!

create: crum {CanopyCrum | NULL} with: hash {UInt32}
	"Special constructor for becoming this class"

	super create: hash.
	myCrum _ crum.
	"I don't 'myCrum addPointer: self' because, in becoming, my old self is presumed to already have pointed at the crum"!

{void} dismantle

	DiskManager consistent: 2 with:
		[myCrum ~~ NULL
			ifTrue:
				[myCrum removePointer: self.
				myCrum _ NULL].
		super dismantle]! !

!PropChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropChanger class
	instanceVariableNames: ''!

(PropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!PropChanger class methodsFor: 'creation'!

{PropChanger} height: crum {CanopyCrum | NULL}
	
	DiskManager consistent: 3 with:
		[^HeightChanger create: crum]!

make: crum {CanopyCrum | NULL}
	
	DiskManager consistent: 2 with:
		[^ActualPropChanger create: crum]! !

!PropChanger class methodsFor: 'smalltalk: suspended'!

make: crum {CanopyCrum | NULL} with: change {PropChange}

	self suspended.
	self thingToDo. " Separate out different things to be propagatated into different PropChanger-like classes."
	
	DiskManager consistent: 3 with:
		[^ActualPropChanger create: crum with: change]! !PropChanger subclass: #ActualPropChanger
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
ActualPropChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(ActualPropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!ActualPropChanger methodsFor: 'creation'!

create: crum {CanopyCrum}

	super create: crum.
	self newShepherd.!

create: crum {CanopyCrum | NULL} with: hash {UInt32} with: info {FlockInfo}
	"Special constructor for becoming this class"

	super create: crum with: hash.
	self flockInfo: info.
	self diskUpdate.! !

!ActualPropChanger methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of property changing.
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"

	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[(self fetchCrum changeCanopy)
			ifTrue: [self setCrum: self fetchCrum fetchParent]
			ifFalse: [self setCrum: NULL]].
	^self fetchCrum ~~ NULL! !

!ActualPropChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChanger subclass: #HeightChanger
	instanceVariableNames: 'myChange {PropChange}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
HeightChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(HeightChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!HeightChanger methodsFor: 'creation'!

create: crum {CanopyCrum}

	super create: crum.
	self newShepherd.!

create: crum {CanopyCrum | NULL} with: hash {UInt32} with: info {FlockInfo}
	"Special constructor for becoming this class"

	super create: crum with: hash.
	self flockInfo: info.
	self diskUpdate.! !

!HeightChanger methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of height recalculation.
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"
	
	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[self fetchCrum changeHeight
			ifTrue: [self setCrum: self fetchCrum fetchParent]
			ifFalse: [self setCrum: NULL]].
	^self fetchCrum ~~ NULL! !

!HeightChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myChange _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myChange.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeightChanger class
	instanceVariableNames: ''!

(HeightChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!HeightChanger class methodsFor: 'creation'!

make: crum {CanopyCrum} with: change {PropChange unused}
	
	self knownBug.	"BOGUS"
	DiskManager consistent: 3 with:
		[^self create: crum]! !Heaper subclass: #PropFinder
	instanceVariableNames: 'myFlags {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PropFinder comment:
'For filtering by canopies.  Matches against Props and CanopyCrum flags'!

(PropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create.
	myFlags := flags.! !

!PropFinder methodsFor: 'accessing'!

{BooleanVar} doesPass: parent {CanopyCrum}
	"return whether the propJoint passes the finder"

	^(myFlags bitOr: parent flags) ~= UInt32Zero!

{PropFinder} findPast: stamp {BeEdition}
	"During a southwards walk of a multi-Edition (aka multi-Stamp), normally we simplify the finder by using PropFinder>>pass:.  However, when we cross an internal Edition boundary and are about to walk into the O-plane of that contained edition we call this method (findPast:) to get the new PropFinder."
	
	self subclassResponsibility!

{UInt32} flags

	^myFlags!

{BooleanVar} isEmpty
	"Overridden only in ClosedPropFinder"
	^false!

{BooleanVar} isFull
	"Overridden only in OpenPropFinder"
	^false!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility!

{PropFinder} pass: parent {CanopyCrum}
	"return a simple enough finder for looking at the children"

	(self doesPass: parent)
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropFinder class
	instanceVariableNames: ''!

(PropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropFinder class methodsFor: 'creation'!

{PropFinder} backfollowFinder: permissionsFilter {Filter of: (XnRegion of: ID)}
	permissionsFilter isEmpty
		ifTrue: [^PropFinder closedPropFinder]
		ifFalse: [^BackfollowPFinder 
			create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: NULL
				with: false
				with: false)
			with: permissionsFilter]!

{PropFinder} backfollowFinder: permissionsFilter {Filter of: (XnRegion of: ID)} 
	with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	(permissionsFilter isEmpty or: [endorsementsFilter isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	endorsementsFilter isFull ifTrue:
		[^BackfollowPFinder create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: NULL
				with: false
				with: false)
			with: permissionsFilter].
	^BackfollowFinder create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: (endorsementsFilter relevantRegion cast: CrossRegion)
				with: false
				with: false)
			with: permissionsFilter
			with: endorsementsFilter!

{PropFinder} cannotPartializeFinder
	^CannotPartializeFinder create!

{PropFinder} closedPropFinder
	^ClosedPropFinder create!

{PropFinder} openPropFinder
	^OpenPropFinder create!

{PropFinder} sensorFinder
	^SensorFinder create! !

!PropFinder class methodsFor: 'smalltalk: passe'!

{PropFinder} partialityFinder

	self passe!

{PropFinder} recorderFinder.RegionDelta: permissionsDelta {RegionDelta of: (XuRegion of: ID)} 
	with.RegionDelta: endorsementsDelta {RegionDelta of: (XuRegion of: ID)} 

	self passe.!

{PropFinder} recorderFinder.RegionDelta: permissionsDelta {RegionDelta of: (XuRegion of: ID)} 
	with.XuRegion: endorsements {XuRegion of: ID} 

	self passe.!

{PropFinder} recorderFinder.XuRegion: permissions {XuRegion of: ID} 
	with.RegionDelta: endorsementsDelta {RegionDelta of: (XuRegion of: ID)} 

	self passe.!

{PropFinder} recorderPFinder: element {BeRangeElement}
	with: permissionsDelta {RegionDelta of: IDRegion}
	with: endorsements {CrossRegion of: IDRegion and: IDRegion}
	
	self passe! !PropFinder subclass: #BertPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BertPropFinder comment:
'Used to filter by the bert canopy'!

(BertPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!BertPropFinder methodsFor: 'create'!

create
	super create "for comm"!

create: flags {UInt32}

	super create: flags! !

!BertPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!BertPropFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	self subclassResponsibility! !BertPropFinder subclass: #BackfollowFinder
	instanceVariableNames: '
		myPermissionsFilter {Filter of: (XnRegion of: ID)}
		myEndorsementsFilter {Filter of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BackfollowFinder comment:
'Finder used to filter the htree walk by the bert canopy when doing a backFollow which uses both permissions and endorsement filters'!

(BackfollowFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowFinder methodsFor: 'creation'!

create: flags {UInt32}
	with: permissionsFilter {Filter of: (XnRegion of: ID)} 
	with: endorsementsFilter {Filter of: (CrossRegion of: ID)}
	
	super create: flags.
	myPermissionsFilter _ permissionsFilter.
	myEndorsementsFilter _ endorsementsFilter! !

!BackfollowFinder methodsFor: 'accessing'!

{Filter of: (XnRegion of: ID)} endorsementsFilter
	^myEndorsementsFilter!

{PropFinder} findPast: edition {BeEdition}

	| canSee {BooleanVar} endorsements {XnRegion} |
	Ravi thingToDo. "use regions in finder so that we don't need to create intermediate objects"
	canSee := false.
	endorsements := edition endorsements.
	edition currentWorks stepper forEach: [ :work {BeWork} |
		((work fetchReadClub ~~ NULL
			and: [myPermissionsFilter match: work fetchReadClub asRegion])
		or:
			[work fetchEditClub ~~ NULL
				and: [myPermissionsFilter match: work fetchEditClub asRegion]])
			ifTrue:
				[canSee := true.
				endorsements := endorsements unionWith: work endorsements]].
	(myEndorsementsFilter match: endorsements) ifTrue:
		[canSee ifTrue:
			[^PropFinder openPropFinder]
		ifFalse:
			[^PropFinder backfollowFinder: myPermissionsFilter]].
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	| p {BertProp wimpy} |
	p _ prop cast: BertProp.
	^(myPermissionsFilter match: p permissions) and: [myEndorsementsFilter match: p endorsements]!

{Filter of: (XnRegion of: ID)} permissionsFilter
	^myPermissionsFilter! !

!BackfollowFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(self getCategory hashForEqual bitXor: myPermissionsFilter hashForEqual)
	  bitXor: myEndorsementsFilter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: BackfollowFinder into: [:o |
			^(myPermissionsFilter isEqual: o permissionsFilter) 
			 and: [myEndorsementsFilter isEqual: o endorsementsFilter]]
		others:
			[^false].
	^false "fodder"! !

!BackfollowFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint} 
	"return a simple enough finder for looking at the children"

	| p {BertPropJoint wimpy} |
	p _ parent cast: BertPropJoint.
	^PropFinder  
		backfollowFinder: (myPermissionsFilter pass: p permissionsJoint)
		with: (myEndorsementsFilter pass: p endorsementsJoint)! !

!BackfollowFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.
	myEndorsementsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.
	xmtr sendHeaper: myEndorsementsFilter.! !BertPropFinder subclass: #BackfollowPFinder
	instanceVariableNames: 'myPermissionsFilter {Filter of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BackfollowPFinder comment:
'Finder used to filter the htree walk by the bert canopy when doing a backFollow which uses just permissions filters'!

(BackfollowPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowPFinder methodsFor: 'creation'!

create: flags {UInt32}
	with: permissionsFilter {Filter of: (XnRegion of: ID)}
	super create: flags.
	myPermissionsFilter _ permissionsFilter! !

!BackfollowPFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition}

	Ravi thingToDo. "use regions in finder so that we don't need to create intermediate objects"
	edition currentWorks stepper forEach: [ :work {BeWork} |
		((work fetchReadClub ~~ NULL
			and: [myPermissionsFilter match: work fetchReadClub asRegion])
		or:
			[work fetchEditClub ~~ NULL
				and: [myPermissionsFilter match: work fetchEditClub asRegion]])
			ifTrue: [^PropFinder openPropFinder]].
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^myPermissionsFilter match: (prop cast: BertProp) permissions!

{Filter of: (XnRegion of: ID)} permissionsFilter
	^myPermissionsFilter! !

!BackfollowPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual bitXor: myPermissionsFilter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: BackfollowPFinder into: [:o |
			^myPermissionsFilter isEqual: o permissionsFilter]
		others:
			[^false].
	^false "fodder"! !

!BackfollowPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint} 
	"return a simple enough finder for looking at the children"
	^PropFinder backfollowFinder: (myPermissionsFilter pass: (parent cast: BertPropJoint) permissionsJoint)! !

!BackfollowPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.! !BertPropFinder subclass: #CannotPartializeFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CannotPartializeFinder comment:
'Used to figure out which Stamps have Orgls on them so that the archiver can knw that they cannot be partialized.  Will go away because the state described is session level state and therefore should be store in NOCOPY variables instead of in the Canopy''s Props.'!

(CannotPartializeFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CannotPartializeFinder methodsFor: 'create'!

create

	super create: BertCrum isNotPartializableFlag! !

!CannotPartializeFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^self "inability to partialize is transitive"!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: BertProp) isNotPartializable! !

!CannotPartializeFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: CannotPartializeFinder! !

!CannotPartializeFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: BertPropJoint) isNotPartializable
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!CannotPartializeFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !BertPropFinder subclass: #SensorFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorFinder comment:
'Currently unused but will be re-instated.  Used to find which containing Editions have WaitForCompletionDetectors installed on them so that they can be rung when placegholders get filled in.'!

(SensorFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SensorFinder methodsFor: 'create'!

create

	super create: BertCrum isSensorWaitingFlag! !

!SensorFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^PropFinder closedPropFinder "Dont look for Detectors past an Edition boundary"!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: BertProp) isSensorWaiting! !

!SensorFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: SensorFinder! !

!SensorFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: BertPropJoint) isSensorWaiting
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!SensorFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropFinder subclass: #ClosedPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ClosedPropFinder comment:
'The finder which matches nothing.  Used to indicate that this subtree is known to be useless (no matches possible below here).'!

(ClosedPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ClosedPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} isEmpty
	"Overridden only here"
	^true!

{BooleanVar} match: prop {Prop unused}
	"tell whether a prop matches this filter"
	^false!

{PropFinder} pass: crum {CanopyCrum unused}

	^self! !

!ClosedPropFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: ClosedPropFinder! !

!ClosedPropFinder methodsFor: 'create'!

create

	super create: UInt32Zero! !

!ClosedPropFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropFinder subclass: #OpenPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
OpenPropFinder comment:
'The finder which matches everything.  Used to indicate that everything below here necessarily matches.'!

(OpenPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OpenPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} isFull
	
	^true!

{BooleanVar} match: prop {Prop unused}
	"tell whether a prop matches this filter"
	^true!

{PropFinder} pass: crum {CanopyCrum unused}

	^self! !

!OpenPropFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: OpenPropFinder! !

!OpenPropFinder methodsFor: 'create'!

create

	super create: UInt32Zero bitInvert! !

!OpenPropFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropFinder subclass: #SensorPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorPropFinder comment:
'Used to filter by the sensor canopy'!

(SensorPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!SensorPropFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!SensorPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!SensorPropFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: crum {CanopyCrum}

	self subclassResponsibility! !SensorPropFinder subclass: #AbstractRecorderFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AbstractRecorderFinder comment:
'The finders used to find recorders in the sensor canopy in response to some change in props of a Stamp.'!

(AbstractRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!AbstractRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!AbstractRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}
	"While doing one step of a southward walk in the O-tree,
	 filtered by the sensor canopy,
	 looking for recorders that represent queries that are newly passed by the change of properties,
	 where the object that changed properties and the change itself are represented by my state,
	 record my object into the recorder if it newly passes the recorder's filtering criteria.
	 
	 See class comments of the various subclasses for details on the purpose of each kindOf AbstractRecorderFinder."
	
	self subclassResponsibility! !

!AbstractRecorderFinder methodsFor: 'smalltalk: passe'!

{void} checkStamp: stamp {BeEdition} with: recorder {TransclusionRecorder}
	"record the stamp into the recorder if I pass this recorder's filters"
	
	self passe!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {RecorderFossil}
	"While doing one step of a southward walk in the O-tree,
	 filtered by the sensor canopy,
	 looking for recorders that represent queries that are newly passed by the change of properties in the Stamp
	 (said change in properties being represented by my state),
	 record the stamp into the recorder if the stamp newly passes the fossil's filtering criteria.
	 
	 See class comments of the various subclasses for details on the purpose of each kindOf AbstractRecorderFinder."
	
	self passe! !

!AbstractRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: crum {CanopyCrum}

	self subclassResponsibility! !AbstractRecorderFinder subclass: #AnyRecorderFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderFinder comment:
'NOT.A.TYPE A general superclass for finders that looks for all recorders, and all elements they might find, resulting from a given change.'!

(AnyRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AnyRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!AnyRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	"do nothing"! !

!AnyRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}

	self subclassResponsibility!

{PropFinder} nextFinder: edition {BeEdition}
	"An additional finder to use below the given Edition"
	
	self subclassResponsibility! !

!AnyRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	self subclassResponsibility! !AnyRecorderFinder subclass: #AnyRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderEFinder comment:
'Generates finders for recorders triggered by an increase in endorsements. Also remembers the (approximate) permissions on the object whose endorsements changed'!

(AnyRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissions)
			and: [p relevantEndorsements intersects: myNewEndorsements]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{PropFinder} nextFinder: edition {BeEdition}

	^ContainedEditionRecorderEFinder make: edition
		with: myPermissions
		with: myEndorsementsDelta
		with: myNewEndorsements!

{IDRegion} permissions

	^myPermissions! !

!AnyRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!AnyRecorderEFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myPermissions hashForEqual
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: AnyRecorderEFinder into: [ :other |
		^(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]
	others:
		[^false].
	^false "fodder"! !

!AnyRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^AnyRecorderEFinder make: ((p relevantPermissions intersect: myPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((p relevantEndorsements intersect: myNewEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!AnyRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AnyRecorderEFinder class
	instanceVariableNames: ''!

(AnyRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	^self make: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum flagsFor: permissions
			with: newEndorsements
			with: false)
		with: permissions with: endorsementsDelta with: newEndorsements! !AnyRecorderFinder subclass: #AnyRecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta of: IDRegion}
		myPermissions {IDRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderPFinder comment:
'Generates finders for recorders triggered by an increase in permissions'!

(AnyRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderPFinder methodsFor: 'accessing'!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^p relevantPermissions intersects: myPermissions].
	^false "fodder"!

{PropFinder} nextFinder: edition {BeEdition}

	^ResultRecorderPFinder make: edition
		with: myPermissionsDelta
		with: myPermissions
		with: edition totalEndorsements!

{IDRegion} permissions 
	
	^myPermissions!

{RegionDelta of: IDRegion} permissionsDelta
	
	^myPermissionsDelta! !

!AnyRecorderPFinder methodsFor: 'create'!

create: flags {UInt32}
	with: permissionsDelta {RegionDelta of: IDRegion}
	with: permissions {IDRegion}
	
	super create: flags.
	myPermissionsDelta := permissionsDelta.
	myPermissions := permissions.! !

!AnyRecorderPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myPermissionsDelta hashForEqual
		bitXor: myPermissions hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: AnyRecorderPFinder into: [ :other |
		^(myPermissionsDelta isEqual: other permissionsDelta)
			and: [myPermissions isEqual: other permissions]]
	others:
		[^false].
	^false "fodder"! !

!AnyRecorderPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^AnyRecorderPFinder make: myPermissionsDelta
			with: ((p relevantPermissions intersect: myPermissions) cast: IDRegion)].
	^NULL "fodder"! !

!AnyRecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myPermissions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myPermissions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AnyRecorderPFinder class
	instanceVariableNames: ''!

(AnyRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderPFinder class methodsFor: 'create'!

{PropFinder} make: permissionsDelta {RegionDelta of: IDRegion}
	
	^self make: permissionsDelta
		with: ((permissionsDelta after minus: permissionsDelta before) cast: IDRegion)!

{PropFinder} make: permissionsDelta {RegionDelta of: IDRegion}
	with: newPermissions {IDRegion}
	
	newPermissions isEmpty ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum flagsFor: newPermissions with: NULL with: false)
		with: permissionsDelta with: newPermissions.! !AbstractRecorderFinder subclass: #CumulativeRecorderFinder
	instanceVariableNames: '
		myGenerators {ImmuSet of: AnyRecorderFinder}
		myCurrent {ImmuSet of: SimpleRecorderFinder}
		myOthers {ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CumulativeRecorderFinder comment:
'Propagates a change to all recorders which might be interested in it, and picking up all elements which might newly be made visible by it. The generators make new finders as we pass by additional Edition boundaries. Also holds onto a collection of simple finders looking for recorders triggered by specific Works or Editions. The current set contains those which might record the current edition, and are passed to all Recorders. The others are only passed to Recorders with the directContainersOnly flag off.'!

(CumulativeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CumulativeRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	myCurrent stepper forEach: [ :current {SimpleRecorderFinder} |
		current checkRecorder: recorder with: fossil].
	recorder isDirectOnly ifFalse:
		[myOthers stepper forEach: [ :other {SimpleRecorderFinder} |
			other checkRecorder: recorder with: fossil]]! !

!CumulativeRecorderFinder methodsFor: 'create'!

create: flags {UInt32}
	with: generators {ImmuSet of: AnyRecorderFinder}
	with: current {ImmuSet of: SimpleRecorderFinder}
	with: others {ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder}
	
	super create: flags.
	myGenerators := generators.
	myCurrent := current.
	myOthers := others.! !

!CumulativeRecorderFinder methodsFor: 'accessing'!

{ImmuSet of: AnyRecorderFinder} current

	^myCurrent!

{PropFinder} findPast: edition {BeEdition}
	
	| newCurrent {SetAccumulator} |
	newCurrent := SetAccumulator make.
	myGenerators stepper forEach: [ :gen {AnyRecorderFinder} |
		| next {PropFinder} |
		next := gen nextFinder: edition.
		next isEmpty ifFalse:
			[newCurrent step: (next cast: SimpleRecorderFinder) "cast will catch algorithm bugs in a place from which they are easier to fix" ]].
	^CumulativeRecorderFinder
		make: myGenerators
		with: (newCurrent value cast: ImmuSet)
		with: (myOthers unionWith: myCurrent)!

{ImmuSet of: AnyRecorderFinder} generators

	^myGenerators!

{BooleanVar} match: prop {Prop}

	myGenerators stepper forEach: [ :gen {PropFinder} |
		(gen match: prop) ifTrue: [^true]].
	^false!

{ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder} others

	^myOthers!

{PropFinder} pass: parent {CanopyCrum}

	parent cast: SensorCrum into: [ :p |
		| newGenerators {SetAccumulator} newCurrent {SetAccumulator}
		  newOthers {SetAccumulator} past {PropFinder} |
		newGenerators := SetAccumulator make.
		myGenerators stepper forEach: [ :gen {PropFinder} |
			past := gen pass: p.
			past isEmpty ifFalse:
				[newGenerators step: past]].
		(newGenerators value cast: ImmuSet) isEmpty ifTrue:
			[^PropFinder closedPropFinder].
		newCurrent := SetAccumulator make.
		myCurrent stepper forEach: [ :current {PropFinder} |
			past := current pass: p.
			past isEmpty ifFalse:
				[newCurrent step: past]].
		newOthers := SetAccumulator make.
		myOthers stepper forEach: [ :other {PropFinder} |
			past := other pass: p.
			past isEmpty ifFalse:
				[newOthers step: past]].
		^CumulativeRecorderFinder
			make: (newGenerators value cast: ImmuSet)
			with: (newCurrent value cast: ImmuSet)
			with: (newOthers value cast: ImmuSet)].
	^NULL "fodder"! !

!CumulativeRecorderFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myGenerators hashForEqual
		bitXor: myCurrent hashForEqual)
		bitXor: myOthers hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: CumulativeRecorderFinder into: [ :other |
		^(myGenerators isEqual: other generators)
			and: [(myCurrent isEqual: other current)
			and: [myOthers isEqual: other others]]]
	others:
		[^false].
	^false "fodder"! !

!CumulativeRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myGenerators _ receiver receiveHeaper.
	myCurrent _ receiver receiveHeaper.
	myOthers _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myGenerators.
	xmtr sendHeaper: myCurrent.
	xmtr sendHeaper: myOthers.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CumulativeRecorderFinder class
	instanceVariableNames: ''!

(CumulativeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CumulativeRecorderFinder class methodsFor: 'create'!

{PropFinder} make: generators {ImmuSet of: SimpleRecorderFinder}
	with: current {ImmuSet of: SimpleRecorderFinder}
	with: others {ImmuSet of: SimpleRecorderFinder}
	
	| f {UInt32} |
	generators isEmpty ifTrue:
		[^PropFinder closedPropFinder].
	Ravi thingToDo. "since current & generators can have at most two elements, represent them explicitly as two OR(NULL) pointers? or make special SmallImmuSet class?"
	f := UInt32Zero.
	generators stepper forEach: [ :g {AnyRecorderFinder} |
		f := f bitOr: g flags].
	current stepper forEach: [ :c {SimpleRecorderFinder} |
		f := f bitOr: c flags].
	others stepper forEach: [ :o {AbstractRecorderFinder} |
		f := f bitOr: o flags].
	^self create: f
		with: generators
		with: current
		with: others! !AbstractRecorderFinder subclass: #SimpleRecorderFinder
	instanceVariableNames: 'myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SimpleRecorderFinder comment:
'A finder which holds onto a RangeElement and looks for ResultRecorders which might want to record it NOT.A.TYPE '!

(SimpleRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!SimpleRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}

	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	((recorder accepts: self rangeElement) and: [self shouldTrigger: recorder with: fossil]) ifTrue:
		[(RecorderTrigger make: fossil with: myRangeElement) schedule]!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}
	"Whether the recorder should be triggered with my RangeElement"
	
	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}
	with: element {BeRangeElement}

	super create: flags.
	myRangeElement := element.! !

!SimpleRecorderFinder methodsFor: 'protected:'!

{BeEdition} edition

	^myRangeElement cast: BeEdition!

{BeRangeElement} rangeElement

	^myRangeElement!

{BeWork} work

	^myRangeElement cast: BeWork! !

!SimpleRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRangeElement _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRangeElement.! !SimpleRecorderFinder subclass: #ContainedEditionRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ContainedEditionRecorderEFinder comment:
'Looks for recorders which might be triggered by an increase in endorsements in something containing my edition. Keep the total endorsements on my edition for quick reject?'!

(ContainedEditionRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ContainedEditionRecorderEFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	recorder cast: EditionRecorder into: [ :er |
		[FeServer] USES.
		CurrentKeyMaster fluidBind: er keyMaster during:
			[^(er indirectFilter isSwitchedOnBy: myEndorsementsDelta)
				and: [(er directFilter match: self edition visibleEndorsements)
				and: [self edition anyPasses: (PropFinder
					backfollowFinder: er permissionsFilter)]]]].
	^false "fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissions)
			and: [p relevantEndorsements intersects: myNewEndorsements]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{IDRegion} permissions 
	
	^myPermissions! !

!ContainedEditionRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags with: element.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!ContainedEditionRecorderEFinder methodsFor: 'testing'!

{UInt32	} actualHashForEqual

	^((self rangeElement hashForEqual
		bitXor: myPermissions hashForEqual)
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: ContainedEditionRecorderEFinder into: [ :other |
		^(self rangeElement isEqual: other rangeElement)
			and: [(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^ContainedEditionRecorderEFinder
			make: self edition
			with: ((myPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((myNewEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ContainedEditionRecorderEFinder class
	instanceVariableNames: ''!

(ContainedEditionRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ContainedEditionRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	Ravi thingToDo. "Separate out relevant endorsements from new endorsements; relevant is those on contained edition - so you can exclude paths which would never care to record that Edition. At the moment all spawned Contained...Finders will vanish at the same time, i.e. when noone cares about the new endorsements any more. Putting in the relevant endorsements as well allows them to vanish earlier. This could also be done by testing self edition totalEndorsements in match and pass."
	
	^self make: element
		with: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: permissions
			with: newEndorsements
			with: false)
		with: element
		with: permissions
		with: endorsementsDelta
		with: newEndorsements.! !SimpleRecorderFinder subclass: #OriginalResultRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
OriginalResultRecorderEFinder comment:
'Looks for recorders which might be triggered by an increase in endorsements on my RangeElement itself'!

(OriginalResultRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OriginalResultRecorderEFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	 recorder cast: EditionRecorder into: [ :er |
	 	^(er directFilter isSwitchedOnBy: myEndorsementsDelta)
	 		and: [self edition anyPasses: (PropFinder
	 			backfollowFinder: er permissionsFilter
	 			with: er indirectFilter)]]
	 cast: WorkRecorder into: [ :wr |
	 	^(wr endorsementsFilter isSwitchedOnBy: myEndorsementsDelta)
	 		and: [self work canBeReadBy: wr keyMaster]].
	^false "fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantEndorsements intersects: myNewEndorsements)
			and: [p relevantPermissions intersects: myPermissions]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{IDRegion} permissions 
	
	^myPermissions! !

!OriginalResultRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags with: element.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!OriginalResultRecorderEFinder methodsFor: 'testing'!

{UInt32	} actualHashForEqual

	^((self rangeElement hashForEqual
		bitXor: myPermissions hashForEqual)
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: OriginalResultRecorderEFinder into: [ :other |
		^(self rangeElement isEqual: other rangeElement)
			and: [(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^OriginalResultRecorderEFinder
			make: self rangeElement
			with: ((myPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((myNewEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OriginalResultRecorderEFinder class
	instanceVariableNames: ''!

(OriginalResultRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OriginalResultRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	^self make: element
		with: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: permissions
			with: newEndorsements
			with: false)
		with: element
		with: permissions
		with: endorsementsDelta
		with: newEndorsements.! !SimpleRecorderFinder subclass: #ResultRecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta}
		myNewPermissions {IDRegion}
		myEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ResultRecorderPFinder comment:
'Looks for records which might be triggered by in increase in visibility of my RangeElement'!

(ResultRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ResultRecorderPFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: newPermissions {IDRegion}
	with: endorsements {CrossRegion}

	super create: flags with: element.
	myPermissionsDelta := permissionsDelta.
	myNewPermissions := newPermissions.
	myEndorsements := endorsements.! !

!ResultRecorderPFinder methodsFor: 'accessing'!

{CrossRegion} endorsements

	^myEndorsements!

{BooleanVar} match: prop {Prop} 

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissionsDelta after)
			and: [p relevantEndorsements intersects: myEndorsements]].
	^false "fodder"!

{IDRegion} newPermissions 
	
	^myNewPermissions!

{RegionDelta of: IDRegion} permissionsDelta
	
	^myPermissionsDelta! !

!ResultRecorderPFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	(recorder permissionsFilter isSwitchedOnBy: myPermissionsDelta) ifTrue:
		[recorder cast: EditionRecorder into: [ :er |
			CurrentKeyMaster fluidBind: er keyMaster during:
				[^er directFilter match: self edition visibleEndorsements]]
		cast: WorkRecorder into: [ :wr |
			^wr endorsementsFilter match: self work endorsements]]
	ifFalse:
		[^false].
	^false "fodder"! !

!ResultRecorderPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myPermissionsDelta hashForEqual
		bitXor: myNewPermissions hashForEqual)
		bitXor: myEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: ResultRecorderPFinder into: [ :other |
		^(myPermissionsDelta isEqual: other permissionsDelta)
			and: [(myNewPermissions isEqual: other newPermissions)
			and: [myEndorsements isEqual: other endorsements]]]
	others:
		[^false].
	^false "fodder"! !

!ResultRecorderPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^ResultRecorderPFinder make: self rangeElement
			with: myPermissionsDelta
			with: ((myNewPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: ((myEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!ResultRecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myNewPermissions _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myNewPermissions.
	xmtr sendHeaper: myEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ResultRecorderPFinder class
	instanceVariableNames: ''!

(ResultRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ResultRecorderPFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: endorsements {CrossRegion}

	^self make: element
		with: permissionsDelta
		with: ((permissionsDelta after minus: permissionsDelta before) cast: IDRegion)
		with: endorsements.!

{PropFinder} make: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: newPermissions {IDRegion}
	with: endorsements {CrossRegion}

	(newPermissions isEmpty or: [endorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: newPermissions
			with: endorsements
			with: false)
		with: element with: permissionsDelta with: newPermissions with: endorsements.! !SensorPropFinder subclass: #PartialityFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PartialityFinder comment:
'When walking the o-plane to separate out the "partial" part of an Edition, this finder is used to filter the walk according to the sensor canopy.'!

(PartialityFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SMALLTALK.ONLY; add: #OBSOLETE; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!PartialityFinder methodsFor: 'create'!

create

	super create: SensorCrum isPartialFlag! !

!PartialityFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: SensorProp) isPartial! !

!PartialityFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: PartialityFinder! !

!PartialityFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: SensorPropJoint) isPartial
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!PartialityFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
(CxxSystemOrganization fileNamed: 'canopy')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'canopy')
	addClass: CanopyCrum
getOrMakeCxxClassDescription in: #public;
	addClass: SensorCrum
getOrMakeCxxClassDescription in: #public;
	addClass: BertCrum
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'canopy')
	addClass: PropChanger
getOrMakeCxxClassDescription in: #protected;
	addClass: ActualPropChanger
getOrMakeCxxClassDescription in: #protected!


(CxxSystemOrganization getOrMakeFileNamed: 'canopy')
	addClass: HeightChanger
getOrMakeCxxClassDescription in: #private;
	addClass: Heaper2UInt32Cache
getOrMakeCxxClassDescription in: #private;
	addClass: CanopyCache
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'props')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'props')
	addClass: PropFinder
getOrMakeCxxClassDescription in: #public;
	addClass: Prop
getOrMakeCxxClassDescription in: #public;
	addClass: BertProp
getOrMakeCxxClassDescription in: #public;
	addClass: SensorProp
getOrMakeCxxClassDescription in: #public;
	addClass: PropChange
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'props')
	addClass: CannotPartializeChange
getOrMakeCxxClassDescription in: #private;
	addClass: DetectorWaitingChange
getOrMakeCxxClassDescription in: #private;
	addClass: FullPropChange
getOrMakeCxxClassDescription in: #private;
	addClass: SensorPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: OpenPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: BertPropChange
getOrMakeCxxClassDescription in: #private;
	addClass: EndorsementsChange
getOrMakeCxxClassDescription in: #private;
	addClass: AbstractRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: ClosedPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: PermissionsChange
getOrMakeCxxClassDescription in: #private;
	addClass: BertPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: SimpleRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: AnyRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: ContainedEditionRecorderEFinder
getOrMakeCxxClassDescription in: #private;
	addClass: ResultRecorderPFinder
getOrMakeCxxClassDescription in: #private;
	addClass: PartialityFinder
getOrMakeCxxClassDescription in: #private;
	addClass: BackfollowFinder
getOrMakeCxxClassDescription in: #private;
	addClass: AnyRecorderEFinder
getOrMakeCxxClassDescription in: #private;
	addClass: CannotPartializeFinder
getOrMakeCxxClassDescription in: #private;
	addClass: SensorPropChange
getOrMakeCxxClassDescription in: #private;
	addClass: SensorFinder
getOrMakeCxxClassDescription in: #private;
	addClass: CumulativeRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: BackfollowPFinder
getOrMakeCxxClassDescription in: #private;
	addClass: AnyRecorderPFinder
getOrMakeCxxClassDescription in: #private;
	addClass: OriginalResultRecorderEFinder
getOrMakeCxxClassDescription in: #private!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'entcanopy' value: nil)
 addChild: ((CxxTreeAssociation key: 'canopy' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'props' value: #file) yourself); yourself))!