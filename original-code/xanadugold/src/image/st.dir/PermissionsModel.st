'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:25 pm'!

WaldoModel subclass: #PermissionsModel
	instanceVariableNames: '
		myMembersCache {ImmuSet of: PackOBits}
		myCachedName {PackOBits}'
	classVariableNames: '
		MyCantReadPermissions {PermissionsModel} 
		MyPMCache {MuTable of: PermissionsModel} '
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
PermissionsModel comment:
'A model for a ClubManager.
*Eventually, all interactions to read or change permissions should go through this'!

(PermissionsModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsModel methodsFor: 'create'!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	super create: km with: id with: worktype with: phantom.
	myMembersCache _ NULL.
	myCachedName _ NULL! !

!PermissionsModel methodsFor: 'accessing'!

{PackOBits} clubName
	"the name used to show the (external) identity of this club"
	| dName {PackOBits} |
	[TapestryAppModel] USES.
	"myCachedName == NULL
		ifTrue: [| dName {PackOBits} |
	dName _ Application fluidVar user userDirectory fetchName: self iD.
	dName ~= NULL
		ifTrue: [myCachedName _ dName]
		ifFalse: [myCachedName _ Sequence string: 'UNKNOWN']].
	^ myCachedName"
	dName _ Application fluidGet user userDirectory fetchName: self iD.
	dName == NULL
		ifTrue: [dName _ Sequence string: 'UNKNOWN'].
	^dName!

{HomeDocumentModel} homeDocument

	^HomeDocumentModel make: self keyMaster 
		with: (self waldo cast: ClubManager) getHomeDocID 
		with: true!

{ScruSet of: PackOBits} memberNames

	| dir {UserDirectoryModel} names {SetAccumulator} |
	
	dir _ Application fluidGet user userDirectory.
	names _ SetAccumulator make.
	self members stepper forEach: [:memberID {ID} | | tName {PackOBits} |
		tName _ dir fetchName: memberID.
		tName ~~ NULL ifTrue: [names step: tName]].
	^ names value cast: ScruSet! !

!PermissionsModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' on (' << (self clubName convert: MuWordArray).
	oo << ')'! !

!PermissionsModel methodsFor: 'membership'!

{void} addAll: members {ScruSet of: ID}

	members stepper forEach: [:memID {ID} |
		self addMember: memID]!

{void} addMember: id {ID}

	self bertIsGrabbed 
		ifFalse: [self makeEditable ifFalse: [Heaper BLAST: #CANNOTGRABBERT]].
	(self waldo cast: ClubManager) addMember: id.
	myMembersCache _ myMembersCache with: id.
	self changed: (NewContentsUpdate make)!

{ScruSet of: ID} members
	[IDSet] USES.
	myMembersCache == NULL 
		ifTrue: [myMembersCache _ (self waldo cast: ClubManager) members asSet].
	^ myMembersCache!

{void} removeMember: id {ID}
 
	self bertIsGrabbed 
		ifFalse: [self makeEditable ifFalse: [Heaper BLAST: #CANNOTGRABBERT]].
	(self waldo cast: ClubManager) removeMember: id.
	myMembersCache _ myMembersCache without: id.
	self changed: (NewContentsUpdate make)!

{ScruSet of: ID} transitiveMembers

	"This method collects all members of this club by walking transitively through
	all readable clubs.  Note that if a club is not readable by the current
	keyMaster, the club will be skipped and its members will not show up.
	We need to provide information (somehow) about which clubs could not be
	read."
	
	^self collectMembersExcept: (ImmuSet make with: self iD)! !

!PermissionsModel methodsFor: 'private: internals'!

{ScruSet of: ID} collectMembersExcept: theseIDs {ScruSet} 
	"This method a set of all of this club's member clubs (recursively). 
	It also ensures that mutually containing clubs don't cause an infinite 
	loop."

	| members {ImmuSet} tbd {ImmuSet} resultUnion {UnionRecruiter} |
	members _ self members cast: ImmuSet.
	tbd _ members minus: theseIDs.
	resultUnion _ UnionRecruiter make.
	resultUnion step: members.
	resultUnion step: theseIDs.
	tbd stepper forEach: [:memberID {ID} | | pm {PermissionsModel} |
		pm _ PermissionsModel fetchPermissionsModel: self waldo keyMaster with: memberID.
		pm ~~ NULL 
			ifTrue: [resultUnion step: 
						(pm collectMembersExcept: (resultUnion value cast: ScruSet)).
					pm destroy]].
	^resultUnion value cast: ScruSet! !

!PermissionsModel methodsFor: 'permissions'!

{ID} editClubID

	^ (self waldo cast: ClubManager) getEditClubID!

{ID} readClubID

	^ (self waldo cast: ClubManager) getReadClubID! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionsModel class
	instanceVariableNames: ''!

(PermissionsModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsModel class methodsFor: 'safe make'!

{PermissionsModel} fetchPermissionsModel: km {KeyMaster} with: id {ID} 
	| pm {PermissionsModel} |
	pm _ (MyPMCache fetch: id) cast: PermissionsModel.
	pm == NULL ifTrue: [pm _ self fetchPM: km with: id.
		pm == NULL ifFalse: [MyPMCache at: id introduce: pm]].
	^pm! !

!PermissionsModel class methodsFor: 'private: make'!

{PermissionsModel} fetchPM: km {KeyMaster} with: id {ID}

	KeyMaster problems.OpenFailed handle: [:ex {Exception} |
		^ NULL] do: [^ PermissionsModel make: km with: id]!

make: km {KeyMaster} with: id {ID} 
	^ self create: km with: id with: (Sequence string: 'ClubManager') with: true! !

!PermissionsModel class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited

	self REQUIRES: IDSpace.
	"MyPMCache _ MuTable make: IDSpace global"!

linkTimeNonInherited

	MyPMCache _ NULL! !