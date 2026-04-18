'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:44 pm'!

Abraham subclass: #GrandMap
	instanceVariableNames: '
		myID {ID}
		myLocalIDCounter {Counter}
		myIDHRoots {MuTable of: ID with: HRoot}
		myRangeElements {MuTable of: ID with: BeRangeElement}
		myRangeElementIDs {MuTable of: (HeaperAsPosition of: BeRangeElement)
	with: IDRegion | ID}
		myEnt {Ent}
		myNullClubID {ID}
		myPublicClubID {ID}
		myAdminClubID {ID}
		myBackupClubID {ID}
		myPurgeable {BooleanVar NOCOPY}'
	classVariableNames: 'BackendCount {IntegerVar smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!
GrandMap comment:
'The GrandMap stores a table mapping IDs to a (IObject, OBottomLoaf) pair. Either of these can be NULL. It is possible to add a OBottomLoaf for an existing IObject, but not vice versa. (I.E. You can put an existing IObject into an orgl and thus create an OBottomLoaf for it, but you cannot create an IObject with an existing ID.)

Rewrite notes
3/7/92 ravi
- we had decided to have myRangeElementIDs be a GrandSetTable, but for now its just a Table onto IDRegions, since that is what we have implemented right now'!

(GrandMap getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandMap methodsFor: 'testing'!

{UInt32} contentsHash

	^(((((super contentsHash
		bitXor: myID hashForEqual)
		bitXor: myLocalIDCounter hashForEqual)
		bitXor: myEnt hashForEqual)
		bitXor: myNullClubID hashForEqual)
		bitXor: myPublicClubID hashForEqual)
		bitXor: myAdminClubID hashForEqual!

{BooleanVar} isPurgeable
	"We need to be explicitly told that we can be purged.  Purgeability comes up
	disabled, and is enabled once."
	
	^myPurgeable! !

!GrandMap methodsFor: 'accessing'!

{void} at: id {ID} introduceIDHRoot: hroot {HRoot}
	"add a new HRoot for an ID"
	| iObject {IObject} |
	myIDHRoots at: id introduce: hroot.
	(iObject _ self fetch: id with: IDSpace openIDFilter) ~~ NULL ifTrue:
		[iObject iDHRoot: hroot]!

{void} at: iD {ID} introduceIObject: iObject {IObject}
	"remember the association between an EXID and its IObject.
	Tell the XID about it; assume IObject already knows, since it called me"
	| xID {ActualXID} hroot {HRoot} |
	xID _ iD cast: ActualXID.
	xID iObject: iObject.
	myRangeElements at: xID pairID store: iObject.
	(hroot _ self fetchIDHRoot: iD) ~~ NULL ifTrue:
		[iObject iDHRoot: hroot]!

{IObject} fetch: iD {ID} with: filter {Filter of: (XnRegion of: ID)} 
	"Only return if matches permissions in localProp (== myOwnProp).  Whether it should
	be 'localProp' or 'prop' should be rethought carefully."
	| result {IObject} |
	iD
		cast: ActualXID into: [:axid |
			result _ axid fetchIObject]
		others: [^NULL].
	result == NULL ifTrue: [^NULL].
	self hack. "Ravi: please read.  -- MarkM"
	((PropFinder backfollowFinder: filter with: IDSpace openIDFilter)
			match: result localProp)
		ifTrue: [^result] 
		ifFalse: [^NULL]!

{Bert} fetchBert: iD {ID} with: filter {Filter} 
	
	(self fetch: iD with: filter) 
		cast: Bert into: [:bert | ^bert]
		others: [^NULL]!

{HRoot} fetchIDHRoot: id {ID}
	"Look up the HRoot for an ID"
	^ (myIDHRoots fetch: id) cast: HRoot!

{IObject} fetchIObjectForXID: xID {EXID}
	"Look up the IObject when an XID comes into core"
	^(myRangeElements fetch: (xID cast: ActualXID) pairID) cast: IObject!

{Stamp} fetchStamp: iD {ID} with: filter {Filter} 
	
	(self fetch: iD with: filter) 
		cast: Stamp into: [:stamp | ^stamp]
		others: [^NULL]!

{IObject} get: iD {ID} with: filter {Filter}
	| result {IObject} | 
	result _ self fetch: iD with: filter.
	result == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^ result!

{Bert} getBert: iD {ID} with: filter {Filter}
	^ (self get: iD with: filter) cast: Bert!

{HRoot} getOrMakeHRoot: value {Heaper as: (Manipulator | ActualOrgl | IObject | ID | PackOBits)}

	| result {HRoot} |
	value 
		cast: Manipulator into: [:manip |
			^self getOrMakeHRoot: ((manip tip cast: Hand) orgl cast: ActualOrgl) stamp]
		cast: ActualOrgl into: [:aOrgl |
			^self getOrMakeHRoot: aOrgl stamp]
		cast: IObject into: [:iObj |
			result _ iObj fetchHRoot.
			result == NULL ifTrue:
				[result _ HRoot make.IObject: iObj.
				iObj hRoot: result]]
		cast: ID into: [:iD |
			result _ self fetchIDHRoot: iD.
			result == NULL ifTrue:
				[result _ HRoot make.ID: iD.
				self at: iD introduceIDHRoot: result]]
		"cast: PackOBits into: [:pob |
			result _ HRoot make.PackOBits: pob]".
	^result!

{Stamp} getStamp: iD {ID} with: filter {Filter}
	^ (self get: iD with: filter) cast: Stamp!

{ID} newID
	^ID make: (myID cast: IDPair) left with: myLocalIDCounter increment!

{OrglRoot} newOrglRootFromTable: table {ScruTable of: (Manipulator | ActualOrgl | IObject | ID | PackOBits)}
	"make a new orgl root but don't install it into the grandmap yet"
	
	| result {OrglRoot} offset {IntegerVar} |
	((table isKindOf: MuWordArray) not or: [table count <= Ent tableSegmentMaxSize])
		ifTrue: [^myEnt newOrglRoot: table with: self].
		
	result _ myEnt newOrglRoot: MuWordArray make with: self.
	offset _ Int32Zero.
	[offset < table count] whileTrue:
		[| count {IntegerVar} tab {MuWordArray} oroot {OrglRoot} |
		count _ Ent tableSegmentMaxSize min: table count - offset.
		tab _ ((table subTable: (IntegerRegion make: offset with: offset + count))
				transformedBy: (IntegerMapping make: offset negated)) cast: MuWordArray.
		oroot _ myEnt newOrglRoot: tab with: self.
		result _ result combine: (oroot transformedBy: (IntegerMapping make: offset)).
		offset _ offset + count].
	^result!

{OrglRoot} newPartialOrglRoot: region {XnRegion}
	"make a new orgl root but don't install it into the grandmap yet"
	
	DiskManager consistent: 13 with:
		[^myEnt newPartialOrglRoot: region]!

{ActualXID} newXID
	^ActualXID make: (myID cast: IDPair) left with: myLocalIDCounter increment!

{void} removeIDHRoot: iD {ID} 
	"remove an old HRoot for an ID"

	DiskManager insistent: 9 with:
		[myIDHRoots remove: iD.
		iD 
			cast: ActualXID into: [:xID |
				xID fetchIObject ~~ NULL ifTrue: 
					[myIObjects remove: xID pairID.
					xID fetchIObject removeIDHRoot]]
			others: []]!

{void} removeIObject: iD {ID}
	"remove the association between an EXID and its IObject.
	Tell the XID about it; assume IObject already knows, since it called me"
	| xID {ActualXID} |
	xID _ iD cast: ActualXID.
	myRangeElements remove: xID pairID.
	xID iObject: NULL! !

!GrandMap methodsFor: 'creation'!

create: grandID {ID} 	  

	super create.
	DiskManager consistent:
		[self newShepherd. 
		"newShepherd must be first in GrandMap so that it is the boot object."
		myEnt := Ent make. 
		myID := grandID. 
		myLocalIDCounter := Counter make: 1 with: 256.

		myRangeElements := GrandHashTable make: IDSpace make.
		myIDHRoots := GrandHashTable make: IDSpace make.
		myRangeElementIDs := GrandHashTable make: HeaperSpace make.

		self coldBoot.
		self remember].
	self clubConsistencyCheck.! !

!GrandMap methodsFor: 'clubs'!

{ID} adminClubID
	^myAdminClubID!

{void} clubConsistencyCheck
	myClubs stepper forEach: [:club {FastClub} |
		club consistencyCheck].
	myRangeElements stepper forEach: [:iObj {IObject} |
		iObj clubConsistencyCheck].!

{FastClub} fetchClub: iD {ID}
	^(myClubs fetch: (iD cast: ActualXID) pairID) cast: FastClub!

{FastClub} getClub: iD {ID}
	 ^(myClubs get: (iD cast: ActualXID) pairID) cast: FastClub!

{ID} nullClubID
	^myNullClubID!

{ID} publicClubID
	^myPublicClubID! !

!GrandMap methodsFor: 'cache accessing'!

{Zul} zul
	^ myZul! !

!GrandMap methodsFor: 'smalltalk: smalltalk defaults'!

{Bert} makeClubBert: orgl {Orgl}
	^self makeClubBert: orgl with: NULL!

{Stamp} makeStamp: orglRoot {OrglRoot} 
	^self makeStamp: orglRoot with: NULL with: NULL!

{Stamp} makeStamp: orglRoot {OrglRoot} 
	with: readClubDesc {Orgl default: NULL}
	^self makeStamp: orglRoot with: readClubDesc with: NULL!

{void} restartGrandMap

	self restartGrandMap: NULL! !

!GrandMap methodsFor: 'IObject creation'!

{Bert} makeClubBert: orgl {Orgl} with: iD {ID default: NULL}

	| result {Bert} 
	  aFastClub {FastClub} 
	  clubID {ActualXID} |
	  
	iD == NULL
		ifTrue: [clubID _ self newXID]
		ifFalse: [clubID _ iD cast: ActualXID].
		
	DiskManager consistent: 196 with:
		[result _ Bert make: orgl with: clubID.
		result propChange: PropChange endorsementsChange
			with: (BertProp endorsementsProp: (IDRegion make: ActualGateKeeper clubEndorsementID)).
		"myIObjects at: clubID pairID introduce: result."
		aFastClub _ FastClub make: result.
		myClubs at: clubID pairID introduce: aFastClub.
		aFastClub updateFromBert].
	^result!

{Bert} makeNonClubBert: orgl {Orgl} 
	with: readClubDesc {Orgl} 
	with: editClubDesc {Orgl}
	
	| result {Bert} |
	DiskManager consistent: 76 with:
		[result _ Bert make: orgl with: self newXID.
		"myIObjects at: (result iD cast: ActualXID) pairID introduce: result."
		result setReadClubID: (self makeClubBert: readClubDesc) iD.
		result setEditClubID: (self makeClubBert: editClubDesc) iD.
		result permissionsChanged].
	^result!

{Stamp} makeStamp: orglRoot {OrglRoot} 
	with: readClubDesc {Orgl default: NULL}
	with: editClubDesc {Orgl default: NULL}
	"create a new stamp and install it in the grand map"

	| result {Stamp} rcid {ID} ecid {ID} |
	  
	readClubDesc == NULL
		ifTrue: [rcid _ myNullClubID]
		ifFalse: [Heaper BLAST: #NoReadClubsOnStamps].
		
	editClubDesc == NULL
		ifTrue: [ecid _ myNullClubID]
		ifFalse: [ecid _ (self makeClubBert: editClubDesc) iD].
		
	DiskManager consistent: 7 with:
		[result _ Stamp make: self with: orglRoot.
		"myIObjects at: (result iD cast: ActualXID) pairID introduce: result."
		[myEnt installORoot: orglRoot] smalltalkOnly.
		result setReadClubID: rcid.
		result setEditClubID: ecid.
		result permissionsChanged].
	^result! !

!GrandMap methodsFor: 'purge control'!

{void} bePurgeable
	myPurgeable _ true! !

!GrandMap methodsFor: 'private: booting'!

{void} coldBoot
	| publicClub {ClubManager} 
	  nullClub {ClubManager} 
	  adminClub {ClubManager}
	  table {MuTable of: PackOBits with: ID}
	  nullDescTable {MuTable of: ID with: Heaper}
	  nullDescRoot {OrglRoot}
	  nullDesc {Orgl} 
	  adminGK {GateKeeper}
	  bls {LockSmith} |

	ActualServer make: self.
	
	myNullClubID _ self newXID.
	nullDescTable _ MuTable make: IDSpace make.
	nullDescRoot _ self newOrglRootFromTable: nullDescTable.
	nullDesc _ (self makeStamp: nullDescRoot) orgl.
	self makeClubBert: nullDesc with: myNullClubID.

	myPublicClubID _ (publicClub _ myZul makeClub) top getID.
	myAdminClubID _ (adminClub _ myZul makeClub) top getID.

	nullClub _ (myZul open: myNullClubID with: (Sequence string: 'ClubManager')) 
		cast: ClubManager. 
	
	bls _ (myZul makeEmptyWaldo: (Sequence string: 'BooLockSmith')) cast: LockSmith.
	publicClub lockSmith: bls.
	adminClub lockSmith: bls.
	
	table _ MuTable make: SequenceSpace make.
	table at: (Sequence string: 'System Admin') introduce: myAdminClubID.
	table at: (Sequence string: 'System Null') introduce: myNullClubID.
	table at: (Sequence string: 'System Public') introduce: myPublicClubID.

	adminGK _ ((XuServer currentServer login: myAdminClubID) cast: BooLock) boo cast: GateKeeper.
	GrandMap buildPublicHomeDoc: adminGK with: table with: publicClub.
	
	nullClub setReadClubID: myPublicClubID.
	publicClub setEditClubID: myNullClubID.

	publicClub destroy.
	nullClub destroy.
	adminClub destroy.
	bls destroy.! !

!GrandMap methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myLocalIDCounter << ')'! !

!GrandMap methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartGrandMap: rcvr {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	myZul _ Zul make: self.
	myPurgeable _ false.! !

!GrandMap methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myID _ receiver receiveHeaper.
	myLocalIDCounter _ receiver receiveHeaper.
	myIDHRoots _ receiver receiveHeaper.
	myRangeElements _ receiver receiveHeaper.
	myRangeElementIDs _ receiver receiveHeaper.
	myEnt _ receiver receiveHeaper.
	myNullClubID _ receiver receiveHeaper.
	myPublicClubID _ receiver receiveHeaper.
	myAdminClubID _ receiver receiveHeaper.
	myBackupClubID _ receiver receiveHeaper.
	self restartGrandMap: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myID.
	xmtr sendHeaper: myLocalIDCounter.
	xmtr sendHeaper: myIDHRoots.
	xmtr sendHeaper: myRangeElements.
	xmtr sendHeaper: myRangeElementIDs.
	xmtr sendHeaper: myEnt.
	xmtr sendHeaper: myNullClubID.
	xmtr sendHeaper: myPublicClubID.
	xmtr sendHeaper: myAdminClubID.
	xmtr sendHeaper: myBackupClubID.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandMap class
	instanceVariableNames: ''!

(GrandMap getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandMap class methodsFor: 'smalltalk: hold for awhile'!

{ID} clubNamesDocID: table {MuTable of: PackOBits with: ID}
		with: adminGK {GateKeeper}
	"We've made this a function just to be sure that it is only doing things which the adminGK authorizes it to do"
	
	| publicDocHand {Hand} 
	  publicDocID {ID}
	  publicDocRCID {ID}
	  publicDocsReadClub {ClubManager} 
	  publicDirectoryOrgl {Orgl}
	  publicDocTable {MuTable of: ID with: Orgl}
	  publicDocOrgl {Orgl}
	  publicUserDirectoryOrgl {Orgl}
	  publicDirectoryTable {UNKNOWN}
	  publicDirectoryHand {Hand}
	  publicDirectoryID {ID} |
	 
	publicUserDirectoryOrgl := adminGK makeOrglFromTable: table.
	adminGK endorse: publicUserDirectoryOrgl stampID
		with: (IDRegion make: (ID key: 'SImpleRecord')).
	publicDirectoryTable := MuTable make: IDSpace make.
	publicDirectoryTable at: (ID key: 'ClubName2ClubIDDirectory')
		store: publicUserDirectoryOrgl.
	publicDirectoryTable at: (ID key: 'ClubName2DirectoryIDDirectory')
		store: (adminGK makeOrglFromTable: (MuTable make: SequenceSpace make)).
	publicDirectoryOrgl := adminGK makeOrglFromTable: publicDirectoryTable.
	adminGK endorse: publicDirectoryOrgl stampID
		with: (IDRegion make: (Sequence string: 'XuDirectory')).
	publicDirectoryHand := adminGK grabOrgl: publicDirectoryOrgl with: true.
	publicDirectoryID := publicDirectoryHand getID.
	publicDocTable := MuTable make: IDSpace make.
	publicDocTable at: (ID key: 'Directory') introduce: publicDirectoryID.
	publicDocOrgl := adminGK makeOrglFromTable: publicDocTable.
	adminGK endorse: publicDocOrgl stampID
		with: ((Sequence string: 'XuHomeDocument') asRegion).
	publicDocHand := adminGK grabOrgl: publicDocOrgl with: true.
	publicDocID := publicDocHand getID.
	publicDocHand destroy.
	
	publicDocRCID := XuServer currentServer readClubIDFor: publicDocID.
	publicDocsReadClub := (adminGK open: publicDocRCID with: (Sequence string: 'ClubManager'))
		cast: ClubManager.
	publicDocsReadClub addMember: XuServer currentServer publicClubID.
	publicDocsReadClub destroy.
	^publicDocID!

{ID} clubNamesDocID: table {MuTable of: PackOBits with: ID} with: adminGK {GateKeeper} with: sysPublicKey {PackOBits}
	"We've made this a function just to be sure that it is only doing 
	things which 
	the adminGK authorizes it to do"

	| publicDocHand {Hand} 
	 publicDocID {ID}
	 publicDocRCID {ID} 
	 publicDocsReadClub {ClubManager} 
	 publicDirectoryOrgl {Orgl} 
	 publicDocTable {MuTable of: ID with: Orgl} 
	 publicDocOrgl {Orgl} 
	 publicUserDirectoryOrgl {Orgl}
	 publicDirectoryTable {MuTable}
	 publicDirectoryHand {Hand}
	 publicDirectoryID {ID} 
	 publicDirectoryDirectoryTable {MuTable} |
	publicUserDirectoryOrgl _ adminGK makeOrglFromTable: table.
	adminGK endorse: publicUserDirectoryOrgl stampID with: ((ID key: 'Map')
			asRegion).
	publicDirectoryTable _ MuTable make: IDSpace make.
	publicDirectoryTable at: (ID key: 'ClubName2ClubIDDirectory')
		store: publicUserDirectoryOrgl.
	publicDirectoryOrgl _ adminGK makeOrglFromTable: publicDirectoryTable.
	adminGK endorse: publicDirectoryOrgl stampID with: ((Sequence string: 'XuDirectory')
			asRegion).
	publicDirectoryHand _ adminGK grabOrgl: publicDirectoryOrgl with: true.
	publicDirectoryID _ publicDirectoryHand getID.
	publicDirectoryDirectoryTable _ MuTable make: SequenceSpace make.
	publicDirectoryDirectoryTable at: sysPublicKey store: publicDirectoryID.
	publicDirectoryTable _ MuTable make: IDSpace make.
	publicDirectoryTable at: (ID key: 'ClubName2DirectoryIDDirectory')
		store: (adminGK makeOrglFromTable: publicDirectoryDirectoryTable).
	publicDirectoryOrgl _ adminGK makeOrglFromTable: publicDirectoryTable.
	publicDirectoryHand hop: (publicDirectoryHand orgl combine: publicDirectoryOrgl).
	publicDocTable _ MuTable make: IDSpace make.
	publicDocTable at: (ID key: 'Directory')
		introduce: publicDirectoryID.
	publicDocOrgl _ adminGK makeOrglFromTable: publicDocTable.
	adminGK endorse: publicDocOrgl stampID with: ((Sequence string: 'XuHomeDocument')
			asRegion).
	publicDocHand _ adminGK grabOrgl: publicDocOrgl with: true.
	publicDocID _ publicDocHand getID.
	publicDocHand destroy.
	publicDocRCID _ XuServer currentServer readClubIDFor: publicDocID.
	publicDocsReadClub _ (adminGK open: publicDocRCID with: (Sequence string: 'ClubManager'))
				cast: ClubManager.
	publicDocsReadClub addMember: adminGK publicKeyMaster userID.
	publicDocsReadClub destroy.
	^publicDocID!

{ID} makeHomeDoc: table {MuTable of: PackOBits with: ID} with: adminGK {GateKeeper} with: sysPublicKey {PackOBits}
	"We've made this a function just to be sure that it is only doing 
	things which 
	the adminGK authorizes it to do"

	| publicDocHand {Hand} 
	 publicDocID {ID}
	 publicDocRCID {ID} 
	 publicDocsReadClub {ClubManager} 
	 publicDirectoryOrgl {Orgl} 
	 publicDocTable {MuTable of: ID with: Orgl} 
	 publicDocOrgl {Orgl} 
	 tempDirOrgl {Orgl}
	 pubDirTable {MuTable}
	 pubDirHand {Hand}
	 pubDirID {ID} 
	 pubDirDirTable {MuTable} |

	tempDirOrgl _ adminGK makeOrglFromTable: table.
	adminGK endorse: tempDirOrgl stampID with: ((ID key: 'Map') asRegion).
	pubDirTable _ MuTable make: IDSpace make.
	pubDirTable at: (ID key: 'ClubName2ClubIDDirectory') store: tempDirOrgl.
	publicDirectoryOrgl _ adminGK makeOrglFromTable: pubDirTable.
	pubDirHand _ adminGK grabOrgl: publicDirectoryOrgl with: true.
	pubDirID _ pubDirHand getID.
	pubDirDirTable _ MuTable make: SequenceSpace make.
	pubDirDirTable at: sysPublicKey store: pubDirID.
	tempDirOrgl _ adminGK makeOrglFromTable: pubDirDirTable.
	adminGK endorse: tempDirOrgl stampID with: ((ID key: 'Map') asRegion).
	pubDirTable _ MuTable make: IDSpace make.
	pubDirTable at: (ID key: 'ClubName2DirectoryIDDirectory') store: tempDirOrgl.
	publicDirectoryOrgl _ adminGK makeOrglFromTable: pubDirTable.
	pubDirHand hop: (pubDirHand orgl combine: publicDirectoryOrgl).
	adminGK endorse: pubDirHand editionID with: ((Sequence string: 'XuDirectory') asRegion).
	pubDirHand destroy.
	publicDocTable _ MuTable make: IDSpace make.
	publicDocTable at: (ID key: 'Directory') introduce: pubDirID.
	publicDocOrgl _ adminGK makeOrglFromTable: publicDocTable.
	adminGK endorse: publicDocOrgl stampID with: ((Sequence string: 'XuHomeDocument')
			asRegion).
	publicDocHand _ adminGK grabOrgl: publicDocOrgl with: true.
	publicDocID _ publicDocHand getID.
	publicDocHand destroy.
	publicDocRCID _ XuServer currentServer readClubIDFor: publicDocID.
	publicDocsReadClub _ (adminGK open: publicDocRCID with: (Sequence string: 'ClubManager'))
				cast: ClubManager.
	publicDocsReadClub addMember: adminGK publicKeyMaster userID.
	publicDocsReadClub destroy.
	^publicDocID! !

!GrandMap class methodsFor: 'safe initializing'!

{void} buildPublicHomeDoc: adminGK {GateKeeper}
	with: names {MuTable of: PackOBits with: ID}
	with: publicClub {ClubManager}
	"Build the home document for the System Public club, and any associated documents and links.
	We've made this a function just to be sure that it is only doing things which the adminGK authorizes it to do"

	| dirLinkType {ID} dir {XuDirectory} dirID {ID} linkID {ID}
	  hd {IndexedWaldo} hdID {ID} club {ClubManager} |
	
	"Make the link type for attaching directories to user clubs."
	dirLinkType := LinkTypeDescription linkType: adminGK
		with.Waldo: (XuText make: adminGK with: 'User Club')
		with.Waldo: (XuText make: adminGK with: 'User Directory')
		with: (IDRegion make: publicClub getID).
	
	"Make the home document for the public club and store it there."
	hd := (adminGK makePersistentWaldo: (Sequence string: 'DirectRecord')) cast: IndexedWaldo.
	hd at: XuDirectory userDirectoryLinkTypeKey store: dirLinkType.
	hdID := hd getID.
	hd destroy.
	publicClub homeDocID: hdID.
	
	dir := (adminGK makeWaldoFromTable: (Sequence string: 'XuDirectory')
		with: names with: true) cast: XuDirectory.
	dirID := dir getID.
	dir destroy.
	
	"Make both documents readable by the public club"
	((ImmuSet make with: hdID) with: dirID) stepper forEach: [ :docID {ID} |
		club := (adminGK open: (XuServer currentServer readClubIDFor: docID)
			with: (Sequence string: 'ClubManager')) cast: ClubManager.
		club addMember: publicClub getID.
		club destroy].
	
	linkID := XuDirectory addUserDirectory: adminGK with: publicClub getID with: dirID.
	club := (adminGK open: (XuServer currentServer readClubIDFor: linkID)
		with: (Sequence string: 'ClubManager')) cast: ClubManager.
	club addMember: publicClub getID.
	club destroy.! !

!GrandMap class methodsFor: 'instance creation'!

make
	[BackendCount isInteger
		ifTrue: [BackendCount _ BackendCount + 1]
		ifFalse: [BackendCount _ 665].
	^self make: (ID make: BackendCount with: -1)] smalltalkOnly.
	[^self make: (ID make: 999 with: -1)] translateOnly!

{GrandMap} make: grandID {ID}
	^self create: grandID! !

!GrandMap class methodsFor: 'smalltalk: initialization'!

cleanupGarbage  
	CurrentGrandMap _ NULL!

initialize
	"This creates the global variable the first time we file this in."
	"Set the BackendCount to a fixed number.  This is so we can 
	distinguish objects made in different runs of the backend."
	
	BackendCount _ 666.
	Smalltalk at: #CurrentGrandMap put: NULL!

staticTimeNonInherited

	GrandMap defineFluid: #TheGrandMap with: DiskManager emulsion with: [NULL]! !

GrandMap initialize!
