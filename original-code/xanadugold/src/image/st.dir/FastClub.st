'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:30 pm'!

Abraham subclass: #FastClub
	instanceVariableNames: '
		myBert {Bert}
		amSignificant {BooleanVar}
		myMembers {MuSet of: ID}
		myImmediateSuperClubs {MuSet of: ID}
		myReadables {MuSet of: IObject}
		myEditables {MuSet of: IObject}
		myWallFlag {BooleanVar}
		myControlledClub {Bert}
		myControlledClubDesc {Stamp}
		myControllableClubDesc {Stamp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backend'!

(FastClub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!FastClub methodsFor: 'creation'!

create: bert {Bert}
	super create.
	myBert _ bert.
	amSignificant := false.
	myMembers _ MuSet make.
	myImmediateSuperClubs := MuSet make.
	myReadables _ MuSet make.
	myEditables _ MuSet make.
	myWallFlag _ true.
	myControlledClub _ NULL.
	myControlledClubDesc _ NULL.
	myControllableClubDesc _ NULL.
	self newShepherd.
	self remember! !

!FastClub methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self iD << ')'! !

!FastClub methodsFor: 'accessing'!

{void} addEditable: iObj {IObject} 
	
	DiskManager consistent: 1 with:
		[self isPermanentlyBlocked not
			ifTrue: [myEditables store: iObj].
		self diskUpdate]!

{void} addReadable: iObj {IObject} 
	
	DiskManager consistent: 1 with:
		[self isPermanentlyBlocked not
			ifTrue: [myReadables store: iObj].
		self diskUpdate]!

{void} beSignificant
	"Make this be a significant club"
	
	amSignificant
		ifFalse: 
			[DiskManager consistent: myMembers count + 1 with:
				[amSignificant := true.
				myMembers stepper forEach: [:mem {ID} | 
					(myBert grandMap getClub: mem) introduceImmediateSuperClub: self iD].
				self diskUpdate]]!

{void} consistencyCheck
	| clubPhantom {ActualClubManager}
	  ls {LockSmith}
	  rcid {ID}
	  ecid {ID} |
	
	clubPhantom _ (myBert grandMap zul
				open: myBert iD
				with: (Sequence string: 'ActualClubManager')
				with: OpenTemporaryVariant)
			cast: ActualClubManager.
	(myMembers contentsEqual: (clubPhantom membersRegion cast: IDRegion) positions) assert.
	
	ls _ clubPhantom fetchLockSmith.
	ls == NULL
		ifTrue: [myWallFlag assert]
		ifFalse: [(myWallFlag == (ls workType isEqual: (Sequence string: 'WallLockSmith'))) assert].
		
	rcid _ clubPhantom fetchReadClubID.
	rcid == NULL
		ifTrue: [(myBert readClubID isEqual: myBert iD) assert]
		ifFalse: [(myBert readClubID isEqual: rcid) assert].

	ecid _ clubPhantom fetchEditClubID.
	ecid == NULL
		ifTrue: [(myBert editClubID isEqual: myBert iD) assert]
		ifFalse: [(myBert editClubID isEqual: ecid) assert].

	myReadables stepper forEach: [:readable {IObject} |
		(readable readClubID isEqual: myBert iD) assert].
	myEditables stepper forEach: [:editable {IObject} |
		(editable editClubID isEqual: myBert iD) assert].!

{Orgl} controllableClubDesc
	myControllableClubDesc == NULL
		ifTrue: [self makeControlled].
	^myControllableClubDesc orgl!

{Orgl} controlledClubDesc
	myControlledClubDesc == NULL
		ifTrue: [self makeControlled].
	^myControlledClubDesc orgl!

{ID} controlledClubID
	myControlledClub == NULL
		ifTrue: [self makeControlled].
	^myControlledClub iD!

{ImmuSet of: IObject} editables
	^myEditables asImmuSet!

{ID} iD
	^myBert iD!

{ImmuSet of: ID} immediateSuperClubs
	"The clubs which list this club as a member"
	^myImmediateSuperClubs asImmuSet!

{void} introduceImmediateSuperClub: iD {ID} 
	"Add a super club to the set of immediate super clubs"
	
	DiskManager consistent: 1 with:
		[myImmediateSuperClubs introduce: iD.
		self diskUpdate]!

{BooleanVar} isBlocked
	^myMembers isEmpty and: [myWallFlag]!

{BooleanVar} isPermanentlyBlocked
	"A Club is permanentlyBlocked if it is blocked and can't be unblocked.  
	A blocked club can't be unblocked iff
		1) it is self edit,
		2) its edit club is the null club,
		or 3) its edit club is itself permanentlyBlocked.
	We don't check for #3 yet, because we would have to detect circularities 
	(to avoid infinite recursion).  In an editClub cycle of blocked clubs, in fact they all
	are permanentlyBlocked, even if this method doesn't yet say so.  Notice that both #1
	and #2 are actually just easy special cases of #3."
	
	^self isBlocked 
		and: [(myBert editClubID isEqual: myBert iD)
			or: [myBert editClubID isEqual: myBert grandMap emptyClubID]]!

{ImmuSet of: ID} members
	^myMembers asImmuSet!

{XnRegion of: ID} permittedClubIDs
	self isBlocked
		ifTrue: [^IDRegion make]
		ifFalse: [^(IDRegion make.ScruSet: self members) with: myBert iD]!

{ImmuSet of: IObject} readables
	^myReadables asImmuSet!

{void} removeEditable: iObj {IObject} 
	
	DiskManager consistent: 1 with:
		[myEditables wipe: iObj.
		self diskUpdate]!

{void} removeImmediateSuperClub: iD {ID} 
	"Remove a super club from the set of immediate super clubs"
	
	DiskManager consistent: 1 with:
		[myImmediateSuperClubs remove: iD.
		self diskUpdate]!

{void} removeReadable: iObj {IObject} 
	
	DiskManager consistent: 1 with:
		[myReadables wipe: iObj.
		self diskUpdate]!

{ImmuSet of: ID} superClubs: filter {Filter of: ID}
	"All significant clubs which list this one as a member (or list one which does...) and pass the given filter."
	| result {MuSet of: ID} |
	result := MuSet make.
	FastClub findSuperClubs: self iD
		with: filter with: result
		with: MuSet make
		with: myBert grandMap.
	^result asImmuSet!

{void} updateFromBert
	| clubDesc {ScruTable of: ID with: Heaper}
	  oldMembers {ImmuSet of: ID}
	  newMembers {ImmuSet of: ID}
	  mems {Orgl}
	  ls {Orgl}
	  ecid {ID} 
	  rcid {ID}
	  sigReg {XnRegion} |
	
	DiskManager consistent: 16 with:
		[sigReg _ KeyMaster significantClubID asRegion.
		clubDesc _ myBert orgl asTable.

		oldMembers := myMembers asImmuSet.
		myMembers destroy.
		mems _ (clubDesc fetch: (ID key: 'Members')) cast: Orgl.
		mems == NULL ifTrue:
			[myMembers _ MuSet make.
			newMembers := ImmuSet make]
		ifFalse:
			[newMembers := (mems domain cast: SetRegion) positions.
			myMembers _ newMembers asMuSet].
		myMembers stepper forEach: [:memID {ID} |
			myBert grandMap zul endorse: memID with: sigReg.
			(myBert grandMap getClub: memID) beSignificant].
		amSignificant ifTrue:
			[(oldMembers minus: newMembers) stepper forEach: [ :lost {ID} |
				(myBert grandMap getClub: lost) removeImmediateSuperClub: myBert iD].
			(newMembers minus: oldMembers) stepper forEach: [ :gained {ID} |
				(myBert grandMap getClub: gained) introduceImmediateSuperClub: myBert iD]].
	
		ls _ (clubDesc fetch: (ID key: 'LockSmith')) cast: Orgl.
		ls == NULL
			ifTrue: [myWallFlag _ true]
			ifFalse: [myWallFlag _ (XuServer currentServer
					waldoFilter: (Sequence string: 'WallLockSmith'))
				match: ls endorsements].
		myWallFlag ifFalse: [
			myBert addEndorsements: sigReg].
	
		ecid _ (clubDesc fetch: (ID key: 'EditClubID')) cast: ID.
		ecid == NULL
			ifTrue: [ecid _ myBert iD].
		myBert setEditClubID: ecid.
		(ecid isEqual: myBert iD)
			ifFalse: [myBert grandMap zul endorse: ecid with: sigReg].
	
		rcid _ (clubDesc fetch: (ID key: 'ReadClubID')) cast: ID.
		rcid == NULL
			ifTrue: [rcid _ myBert iD].
		myBert setReadClubID: rcid.
		(rcid isEqual: myBert iD)
			ifFalse: [myBert grandMap zul endorse: rcid with: sigReg].
	
		((myReadables asImmuSet unionWith: myEditables asImmuSet) with: myBert)
			stepper forEach: [:iObj {IObject} |
				iObj permissionsChanged].

		self isPermanentlyBlocked
			ifTrue: [myReadables destroy.
				myReadables _ MuSet make.
				myEditables destroy.
				myEditables _ MuSet make].
		self diskUpdate]! !

!FastClub methodsFor: 'private: accessing'!

{void} makeControlled
	| gm {GrandMap}
	  aTable {MuTable of: ID with: Heaper}
	  aRoot {OrglRoot}
	  bTable {MuTable of: ID with: Heaper}
	  bRoot {OrglRoot} 
	  bDesc {Stamp} bClub {Bert} aDesc {Stamp} |
	
	gm _ myBert grandMap.
	aTable _ MuTable make: IDSpace make.
	bTable _ MuTable make: IDSpace make.
	(myBert iD isEqual: gm emptyClubID) not ifTrue: 
		[| members {IDSet} |
		members _ IDSet make: gm zul with: (ImmuSet make with: myBert iD).
		bTable at: (ID key: 'Members') introduce: members].

	bRoot _ gm newOrglRootFromTable: bTable.
	bDesc _ gm makeStamp: bRoot.
	bClub _ gm makeClubBert: bDesc orgl.
	
	aTable at: (ID key: 'EditClubID') introduce: bClub iD.
	aRoot _ gm newOrglRootFromTable: aTable.
	aDesc _ gm makeStamp: aRoot.
		
	DiskManager consistent: 1 with:
		[myControlledClubDesc _ bDesc.
		myControlledClub _ bClub.
		myControllableClubDesc _ aDesc.
		self diskUpdate].! !

!FastClub methodsFor: 'testing'!

{UInt32} contentsHash

	^((((((((super contentsHash
		bitXor: myBert hashForEqual)
		bitXor: (amSignificant ifTrue: [3721103] ifFalse: [UInt32Zero]))
		bitXor: myMembers contentsHash)
		bitXor: myImmediateSuperClubs contentsHash)
		bitXor: myReadables contentsHash)
		bitXor: myEditables contentsHash)
		bitXor: myControlledClub hashForEqual)
		bitXor: myControlledClubDesc hashForEqual)
		bitXor: myControllableClubDesc hashForEqual! !

!FastClub methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBert _ receiver receiveHeaper.
	amSignificant _ receiver receiveBooleanVar.
	myMembers _ receiver receiveHeaper.
	myImmediateSuperClubs _ receiver receiveHeaper.
	myReadables _ receiver receiveHeaper.
	myEditables _ receiver receiveHeaper.
	myWallFlag _ receiver receiveBooleanVar.
	myControlledClub _ receiver receiveHeaper.
	myControlledClubDesc _ receiver receiveHeaper.
	myControllableClubDesc _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBert.
	xmtr sendBooleanVar: amSignificant.
	xmtr sendHeaper: myMembers.
	xmtr sendHeaper: myImmediateSuperClubs.
	xmtr sendHeaper: myReadables.
	xmtr sendHeaper: myEditables.
	xmtr sendBooleanVar: myWallFlag.
	xmtr sendHeaper: myControlledClub.
	xmtr sendHeaper: myControlledClubDesc.
	xmtr sendHeaper: myControllableClubDesc.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FastClub class
	instanceVariableNames: ''!

(FastClub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!FastClub class methodsFor: 'pseudo constructors'!

make: bert {Bert}

	[BertProp] USES.
	(bert localProp endorsements hasMember: ActualGateKeeper clubEndorsementID) ifFalse:
		[self BLAST: #NotAClubBert].
	^self create: bert! !

!FastClub class methodsFor: 'private: accessing'!

{void} findSuperClubs: iD {ID}
	with: filter {Filter}
	with: result {MuSet of: ID}
	with: checked {MuSet of: ID}
	with: grandMap {GrandMap}
	"Find all super clubs of the given club that match the filter, accumulating a result and a list of all clubs that have been checked (to avoid circularities) as we go along."
	(filter match: (grandMap getBert: iD with: IDSpace openIDFilter) prop endorsements)
		ifTrue: [result store: iD].
	checked store: iD.
	(grandMap getClub: iD) immediateSuperClubs stepper forEach: [ :superClub {ID} |
		(checked hasMember: superClub) ifFalse:
			[self findSuperClubs: superClub
				with: filter
				with: result
				with: checked
				with: grandMap]].! !