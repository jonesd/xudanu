'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 15 March 1995 at 2:35:45 pm'!

((CxxSystemOrganization tree childNamed: 'canopy') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'canopy') destroyFiles]!

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
	self REQUIRES: PrimeSizeProvider.! !AgendaItem subclass: #PropChanger
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
		[^self create: crum]! !
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

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'canopy' value: #file) yourself))!