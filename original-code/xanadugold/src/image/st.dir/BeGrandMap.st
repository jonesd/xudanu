'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:39 pm'!

Abraham subclass: #BeGrandMap
	instanceVariableNames: '
		myIdentifier {Sequence}
		myGlobalIDSpace {IDSpace}
		myLocalIDSpaceCounter {Counter}
		myGlobalIDFilterSpace {FilterSpace of: IDSpace}
		myEndorsementSpace {CrossSpace}
		myEndorsementFilterSpace {FilterSpace of: CrossSpace}
		myIDHolders {MuTable of: ID with: IDHolder}
		myIDCounters {MuTable of: (Tuple of: Sequence with: IntegerPos)
	with: Counter}
		myRangeElements {MuTable of: ID with: BeRangeElement}
		myRangeElementIDs {MuTable of: (HeaperAsPosition of: BeRangeElement)
	with: IDRegion | ID}
		myEnt {Ent}
		myEmptyClubID {ID}
		myPublicClubID {ID}
		myAdminClubID {ID}
		myArchiveClubID {ID}
		myAccessClubID {ID}
		myClubDirectoryID {ID}
		myGateLockSmithEdition {BeEdition}
		myWrapperEndorsements {ImmuTable of: Sequence with: CrossRegion}
		myEndorsementFlags {PtrArray of: Tuple | CrossRegion}
		myPurgeable {BooleanVar NOCOPY}
		myGrants {BeEdition of: Club}
		myAcceptingConnectionsFlag {BooleanVar NOCOPY}'
	classVariableNames: 'BackendCount {IntegerVar smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!
BeGrandMap comment:
'Rewrite notes
3/7/92 ravi
- we had decided to have myRangeElementIDs be a GrandSetTable, but for now its just a Table onto IDRegions, since that is what we have implemented right now'!

(BeGrandMap getOrMakeCxxClassDescription)
	friends:
'friend class BackendBootMaker;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeGrandMap methodsFor: 'private: booting'!

{void} clubConsistencyCheck
	"Check that the BeClub structure matches the Editions underneath them"
	
	Ravi thingToDo!

{void} coldBoot
	
	| emptyDesc {FeEdition} emptyClub {BeClub}
	  publicDesc {FeEdition} publicClub {BeClub}
	  adminClub {BeClub} archiveClub {BeClub}
	  clubNames {BeEdition} 
	  endorsements {MuTable of: Sequence and: CrossRegion} number {IntegerVar}
	  iDSpace {IDSpace}  endorseTokenWorks {BeEdition} |
	
	"set up the initial set of Clubs"
	myEmptyClubID := ID make: NULL with: NULL with: -1.
	myPublicClubID := ID make: NULL with: NULL with: -2.
	self thingToDo. "ensure that the following IDs are deterministic"
	myAdminClubID := myGlobalIDSpace newID.
	myArchiveClubID := myGlobalIDSpace newID.
	myAccessClubID := myGlobalIDSpace newID.
	
	"figure out the IDs of the Wrapper endorsement Works"
	endorsements := MuTable make: SequenceSpace make.
	number := -3.
	FeWrapperSpec knownWrappers stepper forEach: [ :name {Sequence} |
		| iD {ID}  |
		Ravi thingToDo. "put something more descriptive here"
		iD := ID make: NULL with: NULL with: number.
		number := number - 1.
		endorsements at: name
			introduce: (myEndorsementSpace
				crossOfRegions: ((PrimSpec pointer
					arrayWithTwo: myArchiveClubID asRegion
					with: iD asRegion) cast: PtrArray))].
	myWrapperEndorsements := endorsements asImmuTable.
	
	"set up the special flag bits used by the canopy"
	myEndorsementFlags := PtrArray nulls: 5+10.
	myEndorsementFlags at: UInt32Zero
		store: ((endorsements get: (Sequence string: 'Text')) cast: XnRegion) theOne.
	myEndorsementFlags at: 1
		store: ((endorsements get: (Sequence string: 'HyperLink')) cast: XnRegion) theOne.
	myEndorsementFlags at: 2
		store: ((endorsements get: (Sequence string: 'HyperRef')) cast: XnRegion) theOne.
	myEndorsementFlags at: 3
		store: ((endorsements get: (Sequence string: 'SingleRef')) cast: XnRegion) theOne.
	myEndorsementFlags at: 4
		store: ((endorsements get: (Sequence string: 'MultiRef')) cast: XnRegion) theOne.
	"generate some IDs to use as endorsement tokens"
	5 almostTo: myEndorsementFlags count do: [ :i {Int32} |
		myEndorsementFlags at: i store: (myEndorsementSpace
			crossOfRegions: ((PrimSpec pointer
					arrayWithTwo: myGlobalIDSpace fullRegion
					with: myGlobalIDSpace newID asRegion) cast: PtrArray))].
	CanopyCrum useEndorsementFlags: myEndorsementFlags.
	
	CurrentAuthor fluidSet: myEmptyClubID.
	InitialReadClub fluidSet: myPublicClubID.
	InitialEditClub fluidSet: myEmptyClubID.
	InitialOwner fluidSet: myEmptyClubID.
	InitialSponsor fluidSet: myEmptyClubID.  Dean knownBug.  "Who sponsors clubs?"

	emptyDesc := (self carrier: (self newEmptyEdition: SequenceSpace make)) makeFe cast: FeEdition.
	emptyClub := self newClub: emptyDesc with: myEmptyClubID.
	emptyClub setEditClub: NULL.

	publicDesc := (self carrier: (self
		newEditionWith: (Sequence string: 'ClubDescription:LockSmith')
			with: (self carrier:
					(self newDataEdition: (UInt8Array string: 'boo')
						with: (IntegerRegion make: IntegerVarZero with: 3)
						with: IntegerSpace make getAscending)))) makeFe cast: FeEdition.
	publicClub := self newClub: publicDesc with: myPublicClubID.
	publicClub setEditClub: NULL.
	
	emptyClub sponsor: (myPublicClubID asRegion cast: IDRegion).
	publicClub sponsor: (myPublicClubID asRegion cast: IDRegion).
	InitialSponsor fluidSet: myPublicClubID.
	
	InitialReadClub fluidSet: myAdminClubID.
	InitialEditClub fluidSet: myAdminClubID.
	InitialOwner fluidSet: myAdminClubID.  self thingToDo.  "This should probably still be the Null Club."
	adminClub := self newClub: publicDesc with: myAdminClubID.
	
	InitialReadClub fluidSet: myArchiveClubID.
	InitialEditClub fluidSet: myArchiveClubID.
	InitialOwner fluidSet: myArchiveClubID.
	archiveClub := self newClub: publicDesc with: myArchiveClubID.
	
	CurrentKeyMaster fluidSet: (FeKeyMaster make: self publicClubID).
	InitialReadClub fluidSet: myAdminClubID.
	InitialEditClub fluidSet: myAdminClubID.
	iDSpace := IDSpace unique.
	self newClub: ((self carrier: (self
			newEditionWith: (Sequence string: 'ClubDescription:Membership')
			with: (self carrier: (((self
					newEditionWith: iDSpace newID with: (self carrier: publicClub))
					with: iDSpace newID with: (self carrier: adminClub))
					with: iDSpace newID with: (self carrier: archiveClub))))) makeFe cast: FeEdition)
		with: myAccessClubID.
	
	InitialReadClub fluidSet: myPublicClubID.
	InitialSponsor fluidSet: myAdminClubID.
	InitialEditClub fluidSet: myAdminClubID.
	
	clubNames := (((self newEditionWith: (Sequence string: 'System Admin') with:  (self carrier: adminClub))
		combine: (self newEditionWith: (Sequence string: 'System Archive') with: (self carrier: archiveClub)))
		combine: (self newEditionWith: (Sequence string: 'Universal Null') with: (self carrier: emptyClub)))
		combine: (self newEditionWith: (Sequence string: 'Universal Public') with:  (self carrier: publicClub)).
	myClubDirectoryID := self assignID: (self newWork: (FeEdition on: clubNames)).
	
	"actually create the Wrapper description Works"
	endorsements stepper forPositions: [ :name {Sequence} :end {CrossRegion} |
		Ravi thingToDo. "put something more descriptive in the Work"
		self at: (((end theOne cast: Tuple) coordinate: 1) cast: ID)
			tryIntroduce: (self
				newWork: (FeEdition on: (self
					newDataEdition: name integers
					with: (IntegerRegion make: IntegerVarZero with: name integers count)
					with: IntegerSpace make ascending)))].
	"actually create the endorsement token Works"
	iDSpace := IDSpace unique.
	endorseTokenWorks := self newEmptyEdition: iDSpace.
	5 almostTo: myEndorsementFlags count do: [ :i {Int32} | | work {BeWork} |
		work := self newWork: emptyDesc. "contents don't matter"
		self at: (((((myEndorsementFlags get: i) cast: CrossRegion)
				projection: 1) cast: IDRegion) theOne cast: ID)
			tryIntroduce: work.
		endorseTokenWorks := endorseTokenWorks
			with: iDSpace newID
			with: (self carrier: work)].
	"attach & endorse them so they can be found"
	InitialReadClub fluidBind: myAdminClubID during:
	[InitialEditClub fluidBind: NULL during:
		[ | edition {BeEdition} |
		edition := (self
			newEditionWith: (Sequence string: 'Universal Public')
				with: (self carrier: publicClub))
			with: (Sequence string: 'Fast Tokens')
				with: (self carrier: endorseTokenWorks).
		self newWork: (FeEdition on: edition).
		edition endorse: (myEndorsementSpace
			crossOfRegions: ((PrimSpec pointer
					arrayWithTwo: myEmptyClubID asRegion
					with: myEmptyClubID asRegion) cast: PtrArray))]].
	
	myGateLockSmithEdition := self
		newDataEdition: (UInt8Array string: 'wall')
		with: (IntegerRegion make: IntegerVarZero with: 4)
		with: IntegerSpace make ascending.
	myGrants := self newEditionWithAll: myGlobalIDSpace fullRegion
		with: (self carrier: adminClub).
	
	InitialOwner fluidSet: (NULL basicCast: ID).
	InitialSponsor fluidSet: (NULL basicCast: ID).
	InitialReadClub fluidSet: myEmptyClubID.
	InitialEditClub fluidSet: (NULL basicCast: ID).
	CurrentAuthor fluidSet: (NULL basicCast: ID).
	CurrentKeyMaster fluidSet: (NULL basicCast: FeKeyMaster).! !

!BeGrandMap methodsFor: 'private: create'!

create: identifier {Sequence}

	super create.
	DiskManager consistent:
		[ | counter {Counter} |
		self newShepherd. 
		"newShepherd must be first in GrandMap so that it is the boot object."
		myPurgeable := false.  "The GrandMap cannot be purged until it is explicitly allowed."
		myEnt := Ent make. 
		myIdentifier := identifier. 
		"The counters table must be setup before we try to make any IDSpaces"
		myIDCounters := MuTable make: (CrossSpace
			make: SequenceSpace make with: IntegerSpace make).
		counter := Counter make: 1 with: 20.
		myGlobalIDSpace := IDSpace make: NULL with: -1 with: counter.
		myIDCounters at: (Tuple two: Sequence zero with: -1 integer)
			introduce: counter.
		myLocalIDSpaceCounter := Counter make: 1 with: 256.
		myGlobalIDFilterSpace := FilterSpace make: (myGlobalIDSpace cast: CoordinateSpace).
		
		myEndorsementSpace := CrossSpace make: ((PrimSpec pointer
			arrayWithTwo: myGlobalIDSpace with: myGlobalIDSpace) cast: PtrArray).
		myEndorsementFilterSpace := FilterSpace make: (myEndorsementSpace cast: CoordinateSpace).
		
		myRangeElements := GrandHashTable make: myGlobalIDSpace.
		myIDHolders := GrandHashTable make: myGlobalIDSpace.
		myRangeElementIDs := GrandHashTable make: HeaperSpace make.

		self hack. "how does this connect"
		CurrentGrandMap fluidBind: self during:
			[self coldBoot].
		self remember].
	CurrentGrandMap fluidBind: self during:
		[self clubConsistencyCheck].
	myPurgeable _ false.
	myAcceptingConnectionsFlag _ true.! !

!BeGrandMap methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartBeGrandMap: rcvr {Rcvr unused}
	myPurgeable _ false.
	myAcceptingConnectionsFlag _ true.
	CanopyCrum useEndorsementFlags: myEndorsementFlags! !

!BeGrandMap methodsFor: 'purging'!

{void} bePurgeable
	"Allow the GrandMap to be purged.  The GrandMap should NOT be used after this is called."
	myPurgeable := true.!

{BooleanVar} isPurgeable
	"The Grandmap never gets purged unless explicitly allowed by calling bePurgeable."
	
	^ myPurgeable! !

!BeGrandMap methodsFor: 'testing'!

{UInt32} contentsHash

	^(((((super contentsHash
		bitXor: myIdentifier hashForEqual)
		bitXor: myLocalIDSpaceCounter hashForEqual)
		bitXor: myEnt hashForEqual)
		bitXor: myEmptyClubID hashForEqual)
		bitXor: myPublicClubID hashForEqual)
		bitXor: myAdminClubID hashForEqual! !

!BeGrandMap methodsFor: 'accessing'!

{void} acceptConnections: open {BooleanVar}
	"See FeAdminer"
	
	myAcceptingConnectionsFlag := open!

{ID} assignID: value {BeRangeElement}
	"Remember the two way association between value and its new ID."
	
	| iD {ID} |
	Ravi knownBug. "what if the ID has already been assigned by the grantee?"
	iD _ self newID.
	(self at: iD tryIntroduce: value) ifFalse: [Heaper BLAST: #IDAlreadyUsed].
	^iD!

{BooleanVar} at: iD {ID} tryIntroduce: value {BeRangeElement}
	"Remember the two way association between value and the supplied ID."
	
	(myRangeElements includesKey: iD) ifTrue: [^false].
	self hack.  "The number below comes frojm my memory of how big a GrandMap assign can be."
	DiskManager consistent: 6 with:
		[| hap {HeaperAsPosition} already {IDRegion | NULL} |
		self thingToDo. "Decide about multiple IDs"
		hap := HeaperAsPosition make: value.
		already := (myRangeElementIDs fetch: hap) cast: IDRegion.
		already == NULL
			ifTrue: [myRangeElementIDs at: hap introduce: iD asRegion]
			ifFalse: 
				[(value isKindOf: BeClub) ifTrue: [Heaper BLAST: #ClubMustHaveUniqueID].
				myRangeElementIDs at: hap replace: (already with: iD)].
		myRangeElements at: iD introduce: value].
	^true!

{ID} clubDirectoryID

	^myClubDirectoryID!

{FilterSpace} endorsementFilterSpace

	^myEndorsementFilterSpace!

{CrossSpace} endorsementSpace

	^myEndorsementSpace!

{BeRangeElement | NULL} fetch: iD {ID}
	"The actual BeRangeElement at that ID, or NULL if there is none"
	
	^(myRangeElements fetch: iD) cast: BeRangeElement!

{BeClub | NULL} fetchClub: iD {ID | NULL}
	"If there is a club at the given ID, return it."
	
	iD == NULL ifTrue: [^NULL].
	(self get: iD) cast: BeClub into: [:club | ^club] others: [].
	^NULL!

{FeEdition} gateLockSmithEdition

	^FeEdition on: (myGateLockSmithEdition)!

{BeRangeElement} get: iD {ID}
	"The actual BeRangeElement at that ID, or blast if there is none"
	
	^(myRangeElements get: iD) cast: BeRangeElement!

{BeClub} getClub: iD {ID}
	"Get a BeClub from the GrandMap."
	
	^(self get: iD) cast: BeClub!

{FeRangeElement} getFe: iD {ID}
	"Get what is at the the given ID as a front end object; blast if there is nothing there"
	
	self knownBug.  "This doesn't supply a label for Editions."
	^(self get: iD) makeFe: NULL!

{Counter} getOrMakeIDCounter: backend {Sequence | NULL} with: number {IntegerVar}
	"Get a canonical Counter for an IDSpace, or make a new one"
	
	| result {Counter} theBackend {Sequence} |
	backend ~~ NULL ifTrue:
		[theBackend := backend]
	ifFalse: [number < IntegerVarZero ifTrue:
		[theBackend := Sequence zero]
	ifFalse:
		[theBackend := self identifier]].
	result := (myIDCounters fetch: (Tuple two: theBackend with: number integer)) cast: Counter.
	result == NULL ifTrue:
		[self thingToDo. "figure out good batching"
		result := Counter make: 1 with: 20.
		myIDCounters at: (Tuple two: theBackend with: number integer) introduce: result].
	^result!

{BeIDHolder} getOrMakeIDHolder: iD {ID}
	"If there is already an IDHolder for the ID then return it, otherwise make one"
	
	| result {BeIDHolder} |
	result := (myIDHolders fetch: iD) cast: BeIDHolder.
	result == NULL ifTrue:
		["Make one and remember it for canonicalization"
		CurrentPacker fluidGet consistent: 666 with:
			[result := BeIDHolder make: iD.
			myIDHolders at: iD introduce: result]].
	^result!

{FilterSpace} globalIDFilterSpace
	"The FilterSpace on global IDSpace"
	
	^myGlobalIDFilterSpace!

{IDSpace} globalIDSpace
	"The global IDSpace"
	
	^myGlobalIDSpace!

{void} grant: clubID {ID} with: globalIDs {IDRegion}
	"See FeAdminer"
	
	| newGrants {BeEdition} |
	newGrants := myGrants replace: (self
		newEditionWithAll: globalIDs
		with: (self carrier: (self getClub: clubID))).
	DiskManager consistent: 1 with:
		[myGrants := newGrants.
		self diskUpdate]!

{ID} grantAt: iD {ID}
	"Who has been granted authority to assign that ID"
	
	^self iDOf: (myGrants get: iD) getOrMakeBe!

{TableStepper of: ID and: IDRegion} grants: clubIDs {IDRegion | NULL}
	with: globalIDs {IDRegion | NULL}
	"See FeAdminer"
	
	| theEdition {BeEdition} |
	globalIDs == NULL
		ifTrue: [theEdition := myGrants]
		ifFalse: [theEdition := myGrants copy: globalIDs].
	^GrantStepper make: theEdition with: clubIDs!

{Sequence} identifier

	^myIdentifier!

{ID} iDOf: value {BeRangeElement}
	"Find the ID of a BeRangeElement. Blast if there is no ID or if there is more than one"
	
	| result {IDRegion | NULL} |
	result := (myRangeElementIDs fetch: (HeaperAsPosition make: value)) cast: IDRegion.
	result == NULL ifTrue: [Heaper BLAST: #DoesNotHaveAnID].
	result count == 1 ifFalse: [Heaper BLAST: #HasMultipleIDs].
	^result theOne cast: ID!

{IDRegion} iDsOf: value {BeRangeElement}
	"Find the IDs of a BeRangeElement, whether there are none, one, or several"
	
	| result {IDRegion | NULL} |
	result := (myRangeElementIDs fetch: (HeaperAsPosition make: value)) cast: IDRegion.
	result == NULL ifTrue: [^myGlobalIDSpace emptyRegion cast: IDRegion].
	^result!

{BooleanVar} isAcceptingConnections
	"See FeAdminer"
	
	^myAcceptingConnectionsFlag!

{ID} newID

	^myGlobalIDSpace newID!

{IDSpace} newIDSpace
	"Make a new globally unique IDSpace"
	
	^IDSpace make: self identifier with: myLocalIDSpaceCounter increment!

{ID} placeOwnerID: iD {ID}
	"The ID of the Club which owns whatever is at the given ID"

	| value {BeRangeElement} |
	value := self fetch: iD.
	value ~~ NULL ifTrue: [^value owner].
	Ravi shouldImplement "Figure out who owns PlaceHolders".
	^NULL "fodder"!

{void} setGateLockSmithEdition: edition {FeEdition}

	(FeLockSmith spec certify: edition) ifFalse:
		[Heaper BLAST: #MustBeValidLockSmith].
	myGateLockSmithEdition := edition beEdition.!

{ScruTable of: Sequence with: CrossRegion} wrapperEndorsements
	"A mapping from wrapper names to endorsements"
	
	Ravi thingToDo."Figure out if there is a better way to do this"
	^myWrapperEndorsements! !

!BeGrandMap methodsFor: 'making editions'!

{BeEdition} newDataEdition: values {PrimDataArray}
	with: keys {XnRegion}
	with: ordering {OrderSpec}
	"Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between the keys and the indices in the array.
	The Region must have the same count as the array.
	You must give an owner for the newly created DataHolders."
	
	| result {OrglRoot} offset {IntegerVar} remainder {XnRegion} |
	keys isEmpty ifTrue:
		[^self newEmptyEdition: keys coordinateSpace].
	CurrentTrace fluidBind: myEnt newTrace during: 
	[CurrentBertCrum fluidBind: BertCrum make during: 
		[values count <= Ent tableSegmentMaxSize DOTasLong ifTrue:
			[^BeEdition make: (OrglRoot makeData: keys with: ordering with: values)].
		result _ OrglRoot make.CoordinateSpace: ordering coordinateSpace.
		offset _ Int32Zero.
		remainder _ keys.
		[offset < values count] whileTrue:
			[| count {Int32} oroot {OrglRoot} array {PrimDataArray} region {XnRegion} |
			count _ Ent tableSegmentMaxSize DOTasLong  min: values count - offset DOTasLong .
			array _ (values copy: count with: offset DOTasLong) cast: PrimDataArray.
			region _ remainder chooseMany: count with: ordering.
			oroot _ 
				OrglRoot 
					makeData: ((IntegerMapping make: offset negated) ofAll: region)
					with: ordering
					with: array.
			result _ result combine: (oroot transformedBy: (IntegerMapping make: offset)).
			remainder _ remainder minus: region.
			offset _ offset + count].
		^BeEdition make: result]]!

{BeEdition} newEditionWith: key {Position} with: value {BeCarrier}
	"A single key-value mapping"
	[HistoryCrum] USES.
	Dean hack.  "What should the bertCrum be?"
	CurrentTrace fluidBind: value rangeElement hCrum hCut newSuccessor
		during: [CurrentBertCrum fluidBind: value rangeElement bertCrum
		during: [| region {XnRegion} |
				region _ key asRegion.
				^BeEdition make: 
					(ActualOrglRoot 
						make: (Loaf make.Region: region with: value)
						with: region)]]!

{BeEdition} newEditionWithAll: keys {XnRegion} with: value {BeCarrier}
	"A single key-value mapping"
	
	Dean hack.  "What should the bertCrum be?"
	keys isEmpty ifTrue:
		[^self newEmptyEdition: keys coordinateSpace].
	CurrentTrace fluidBind: value rangeElement hCrum hCut newSuccessor
		during: [CurrentBertCrum fluidBind: value rangeElement bertCrum
		during: [^BeEdition make: 
					(ActualOrglRoot 
						make: (Loaf make.Region: keys with: value)
						with: keys)]]!

{BeEdition} newEmptyEdition: cs {CoordinateSpace}
	"Create an empty Edition.  This should really be canonicalized."
	
	CurrentTrace fluidBind: myEnt newTrace during: [
		CurrentBertCrum fluidBind: BertCrum make during: [
			DiskManager consistent: 4 with: [
				^BeEdition make: (OrglRoot make.CoordinateSpace: cs)]]]!

{BeEdition} newPlaceHolders: region {XnRegion}
	"Make an Edition with a region full of unique PlaceHolders"
	
	Ravi thingToDo. "rename to newPlaceHolders"
	region isEmpty ifTrue:
		[^self newEmptyEdition: region coordinateSpace].
	CurrentTrace fluidBind: myEnt newTrace
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [^BeEdition make: (OrglRoot make.XnRegion: region)]]!

{BeEdition} newValueEdition: values {PtrArray of: FeRangeElement}
	with: keys {XnRegion}
	with: ordering {OrderSpec}
	"Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between the keys and the indices in the array.
	The Region must have the same count as the array."
	
	"compute the join of the existing traces and bert crums in the table"
	"make new ones if there are none"
	| trace {TracePosition} crum {CanopyCrum} rangeElement {BeRangeElement} |
	keys count ~~ values count ifTrue: [Heaper BLAST: #CountMismatch].
	keys isEmpty ifTrue: [^self newEmptyEdition: keys coordinateSpace].
	(values fetch: Int32Zero) 
		notNULL: [:fe {FeRangeElement} | rangeElement _ fe getOrMakeBe]
		else: [Heaper BLAST: #MustNotHaveNullElements].
	trace _ rangeElement hCrum hCut.
	crum _ rangeElement bertCrum.
	1 almostTo: values count do:
		[:i {Int32} |
		(values fetch: i) 
			notNULL: [:fe {FeRangeElement} | rangeElement _ fe getOrMakeBe]
			else: [Heaper BLAST: #MustNotHaveNullElements].
		"Neither of these should need a consistent block."
		trace _ trace newSuccessorAfter: rangeElement hCrum hCut.
		crum _ crum computeJoin: rangeElement bertCrum].
	CurrentTrace fluidBind: trace
		during: [CurrentBertCrum fluidBind: (crum cast: BertCrum)
		during: [ ^BeEdition make: (OrglRoot make: keys with: ordering with: values)]]! !

!BeGrandMap methodsFor: 'making other things'!

{BeCarrier} carrier: element {BeRangeElement}
	"Return a carrier that has the rangeElement with a new Label if appropriate."
	
	(element isKindOf: BeEdition) 
		ifTrue: [^BeCarrier make: self newLabel with: element]
		ifFalse: [^BeCarrier make: element]!

{BeClub} newClub: desc {FeEdition} with: iD {ID default: NULL}
	"Make a new Club assigned to either iD or a generated ID id iD is NULL."
	
	| result {BeClub} |
	CurrentTrace fluidBind: myEnt newTrace
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [result := BeClub make: desc]].
	DiskManager consistent: 
		[iD == NULL
			ifTrue: [self assignID: result]
			ifFalse: [(self at: iD tryIntroduce: result) ifFalse: [Heaper BLAST: #IllegalID]].
		"If we allow multiple IDs for clubs, we'll have to do this in the grandMap."
		result updateTransitiveMemberIDs.
		result updateTransitiveSuperClubIDs].
	^result!

{BeDataHolder} newDataHolder: value {PrimValue}
	"Make a new DataHolder with the given contents."
	
	CurrentTrace fluidBind: myEnt newTrace
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [
			DiskManager consistent: 1 with: [
				^BeDataHolder create: value]]]!

{BeIDHolder} newIDHolder: iD {ID}
	"Make a new IDHolder for the given ID. Uses an existing one if it exists."
	
	| result {BeIDHolder} |
	result := (myIDHolders fetch: iD) cast: BeIDHolder.
	result == NULL ifTrue:
		[DiskManager consistent:
			[CurrentTrace fluidBind: myEnt newTrace
			during: [CurrentBertCrum fluidBind: BertCrum make
			during:
				[result := BeIDHolder make: iD.
				myIDHolders at: iD introduce: result]]]].
	^result!

{BeLabel} newLabel
	"Make a new label."
	
	CurrentTrace fluidBind: myEnt newTrace
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [
			DiskManager consistent: 1 with: [^BeLabel create]]]!

{BePlaceHolder} newPlaceHolder
	"Make a new PlaceHolder."
	
	CurrentTrace fluidBind: myEnt newTrace
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [DiskManager consistent: 3 with: [^BePlaceHolder create]]]!

{BeWork} newWork: contents {FeEdition}
	"Make a new Work (without an ID) with the given contents.  Everything 
	 else comes from the fluid environment."
	
	CurrentTrace fluidBind: myEnt newTrace
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [^BeWork make: contents]]! !

!BeGrandMap methodsFor: 'clubs'!

{ID} accessClubID

	^myAccessClubID!

{ID} adminClubID

	^myAdminClubID!

{ID} archiveClubID

	^myArchiveClubID!

{ID} emptyClubID

	^myEmptyClubID!

{ID} publicClubID

	^myPublicClubID! !

!BeGrandMap methodsFor: 'smalltalk: defaults'!

{BeClub} newClub: desc {FeEdition}
	^self newClub: desc with: NULL! !

!BeGrandMap methodsFor: 'smalltalk: passe'!

{FeRangeElement} getOrMakeFe: iD {ID}
	"Get what is at the the given ID as a front end object; if there is nothing there, then make the appropriate PlaceHolder"
	
	| result {BeRangeElement} |
	result := self fetch: iD.
	self knownBug.  "This doesn't supply a label for Editions."
	result ~~ NULL
		ifTrue: [^result makeFe: NULL]
		ifFalse: [^FePlaceHolder grand: iD]!

{IDSpace} iDSpace: identifier {Sequence}
	"Recreate an old IDSpace from externally stored numbers"
	
	self passe "IDSpace::import"! !

!BeGrandMap methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myIdentifier _ receiver receiveHeaper.
	myGlobalIDSpace _ receiver receiveHeaper.
	myLocalIDSpaceCounter _ receiver receiveHeaper.
	myGlobalIDFilterSpace _ receiver receiveHeaper.
	myEndorsementSpace _ receiver receiveHeaper.
	myEndorsementFilterSpace _ receiver receiveHeaper.
	myIDHolders _ receiver receiveHeaper.
	myIDCounters _ receiver receiveHeaper.
	myRangeElements _ receiver receiveHeaper.
	myRangeElementIDs _ receiver receiveHeaper.
	myEnt _ receiver receiveHeaper.
	myEmptyClubID _ receiver receiveHeaper.
	myPublicClubID _ receiver receiveHeaper.
	myAdminClubID _ receiver receiveHeaper.
	myArchiveClubID _ receiver receiveHeaper.
	myAccessClubID _ receiver receiveHeaper.
	myClubDirectoryID _ receiver receiveHeaper.
	myGateLockSmithEdition _ receiver receiveHeaper.
	myWrapperEndorsements _ receiver receiveHeaper.
	myEndorsementFlags _ receiver receiveHeaper.
	myGrants _ receiver receiveHeaper.
	self restartBeGrandMap: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myIdentifier.
	xmtr sendHeaper: myGlobalIDSpace.
	xmtr sendHeaper: myLocalIDSpaceCounter.
	xmtr sendHeaper: myGlobalIDFilterSpace.
	xmtr sendHeaper: myEndorsementSpace.
	xmtr sendHeaper: myEndorsementFilterSpace.
	xmtr sendHeaper: myIDHolders.
	xmtr sendHeaper: myIDCounters.
	xmtr sendHeaper: myRangeElements.
	xmtr sendHeaper: myRangeElementIDs.
	xmtr sendHeaper: myEnt.
	xmtr sendHeaper: myEmptyClubID.
	xmtr sendHeaper: myPublicClubID.
	xmtr sendHeaper: myAdminClubID.
	xmtr sendHeaper: myArchiveClubID.
	xmtr sendHeaper: myAccessClubID.
	xmtr sendHeaper: myClubDirectoryID.
	xmtr sendHeaper: myGateLockSmithEdition.
	xmtr sendHeaper: myWrapperEndorsements.
	xmtr sendHeaper: myEndorsementFlags.
	xmtr sendHeaper: myGrants.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeGrandMap class
	instanceVariableNames: ''!

(BeGrandMap getOrMakeCxxClassDescription)
	friends:
'friend class BackendBootMaker;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeGrandMap class methodsFor: 'private: pseudo constructors'!

make

	^self create: (Sequence two: 666 with: 42)! !

!BeGrandMap class methodsFor: 'smalltalk: init'!

staticTimeNonInherited

	BeGrandMap defineFluid: #CurrentGrandMap with: DiskManager emulsion with: [NULL]! !

!BeGrandMap class methodsFor: 'global: time'!

{IntegerVar} xuTime
	"Seconds since the beginning of time"
	
	self knownBug.
	'return 3;' translateOnly.
	[^Time xuTime] smalltalkOnly! !