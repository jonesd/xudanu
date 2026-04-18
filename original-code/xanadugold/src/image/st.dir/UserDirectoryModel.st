'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:23 pm'!

XnModel subclass: #UserDirectoryModel
	instanceVariableNames: '
		myOccludedDirectory {UserDirectoryModel}
		myDirectory {DirectoryModel}
		myClubIDs {ListModel of: PackOBits}
		myClubNames {ListModel of: PackOBits}
		mySuperClubsDirectory {MuTable of: PackOBits and: (ImmuSet of: PackOBits)}
		myTransitiveMembers {MuTable of: PackOBits and: (ImmuSet of: PackOBits)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Models'!
UserDirectoryModel comment:
'Maintains a list of the club IDs that the user knows about, and a corresponding list of club names'!

(UserDirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryModel methodsFor: 'accessing'!

{ImmuSet of: ID} allIDs
	| start {ImmuSet of: PackOBits} |
	[ListModel] USES.
	myOccludedDirectory == NULL
		ifTrue: [start _ ImmuSet make]
		ifFalse: [start _ myOccludedDirectory allIDs].
	^start unionWith: (myDirectory clubIDs asTable range)!

{void} at: name {PackOBits} storeClubID: clubID {ID}

	(self fetchLocalClubID: name) ~~ NULL
		ifTrue: [| oldName {PackOBits} |
			oldName _ self fetchName: clubID.
			myDirectory removeName: oldName].
	myDirectory at: name storeClubID: clubID!

{ListModel of: ID} clubIDs
	"the ordered list of club IDs"
	^myClubIDs!

{ListModel of: PackOBits} clubNames
	"the ordered list of club names"
	^myClubNames!

{ID} fetchClubID: name {PackOBits}
	"This method looks up a name in the local directory to find the corresponding ID.
	 If not found, it attempts to look it up in the occluded directory."
	 
	| iD {ID} |
	iD _ myDirectory fetchClubID: name.
	(iD == NULL and: [myOccludedDirectory ~~ NULL]) 
		ifTrue: [iD _ myOccludedDirectory fetchClubID: name].
	^ iD!

{ID} fetchLocalClubID: name {PackOBits}
	"This method looks up a name ONLY in the local directory.
	 If not found locally, it will return NULL."
	 
	^ myDirectory fetchClubID: name!

{PackOBits} fetchLocalName: club {ID} 
	"find a name to show for the given club ID"
	"check first in my list, then in the public directory."

	^ myDirectory fetchClubName: club!

{PackOBits} fetchName: club {ID} 
	"find a name to show for the given club ID"
	"check first in my list, then in the public directory."

	| name {PackOBits} |
	name _ myDirectory fetchClubName: club.
	(name == NULL and: [myOccludedDirectory ~~ NULL]) ifTrue: 
			[name _ myOccludedDirectory fetchName: club].
	^name!

{ID} getClubID: name {PackOBits}
	"This method looks up a name in the local directory to find the corresponding ID.
	 If not found, it attempts to look it up in the occluded directory."
	 
	| iD {ID} |
	iD _ self fetchClubID: name.
	(iD == NULL) ifTrue: [Heaper BLAST: #ClubNameNotFound].
	^ iD!

{PackOBits} getName: club {ID}
	"find a name to show for the given club ID"
	| result {PackOBits} |
	result _ self fetchName: club.
	result == NULL ifTrue:
		[Heaper BLAST: #NoNameForClub].
	^result!

{KeyMaster} keyMaster
	^Application fluidGet user keyMaster!

{ScruSet of: ID} superClubsOf: clubID {ID} 
	"^(mySuperClubsDirectory get: clubID) cast: ScruSet"
	^ ImmuSet make! !

!UserDirectoryModel methodsFor: 'create'!

create: aDirectory {DirectoryModel} with: occluded {UserDirectoryModel} with: list {ListModel of: ID} 
	super create.
	myOccludedDirectory _ occluded.
	myDirectory _ aDirectory.
	list == NULL
		ifTrue: [myClubIDs _ ListModel make]
		ifFalse: [myClubIDs _ list].
	myClubIDs addDependent: self.
	myClubNames _ ListModel make.
	"List2ListLookupSchnert
		make: myClubIDs
		with: myClubNames
		with: (ID2ClubNameLookup make: self)."
	mySuperClubsDirectory _ MuTable make: FeServer current globalIDSpace.
	myTransitiveMembers _ MuTable make: FeServer current globalIDSpace.
	self updateTransitiveMembers.
	self updateSuperClubs!

{void} destruct
	super destruct! !

!UserDirectoryModel methodsFor: 'private: accessing'!

{ScruTable of: ID and: (ScruSet of: ID)} calculateSuperClubs

	"| membersTable {ScruTable} supersTable {MuTable}
	 superStepper {TableStepper} memberStepper {TableStepper} |
	membersTable _ self transitiveMembersDirectory.
	supersTable _ MuTable make: IDSpace make.
	self clubIDs asTable stepper forEach: [:clubID {ID} |
		supersTable at: clubID store: (MuSet make)].
	(superStepper _ supersTable stepper cast: TableStepper) forEach: [:supers {MuSet} |
		(memberStepper _ membersTable stepper cast: TableStepper) forEach: [:members {ScruSet} |
			(members hasMember: superStepper key)
				ifTrue: [supers store: memberStepper key]]].
	^ supersTable"!

{ScruTable of: ID and: (ScruSet of: ID)} transitiveMembersDirectory

	"| membersTable {MuTable} |
	membersTable _ MuTable make: IDSpace make.
	self clubIDs asTable stepper forEach: [:userID {ID} | | pm {PermissionsModel} |
		pm _ PermissionsModel fetchPermissionsModel: myDirectory waldo keyMaster with: userID.
		pm ~~ NULL ifTrue: [membersTable at: userID store: pm transitiveMembers]].
	^ membersTable"!

{void} updateSuperClubs

	"| memberStepper {TableStepper} |
	self clubIDs asTable stepper forEach: [:clubID {ID} |
		((mySuperClubsDirectory includesKey: clubID) not 
				or: [((mySuperClubsDirectory get: clubID) cast: MuSet) isEmpty])
			ifTrue: [| supers {MuSet} |
				supers _ MuSet make.
				(memberStepper _ myTransitiveMembers stepper cast: TableStepper) 
					forEach: [:members {ScruSet} |
						(members hasMember: clubID)
							ifTrue: [supers store: memberStepper key]].
				mySuperClubsDirectory at: clubID store: supers]]."!

{void} updateTransitiveMembers
	"self clubIDs asTable stepper forEach: [:userID {ID} | | pm {PermissionsModel} |
		(myTransitiveMembers includesKey: userID) not ifTrue: [pm _ PermissionsModel fetchPermissionsModel: myDirectory waldo keyMaster with: userID.
			pm ~~ NULL ifTrue: [myTransitiveMembers at: userID store: pm transitiveMembers]]]"! !

!UserDirectoryModel methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel unused}
	self updateTransitiveMembers.
	self updateSuperClubs! !

!UserDirectoryModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name 
		<< '(' << myClubNames << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UserDirectoryModel class
	instanceVariableNames: ''!

(UserDirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryModel class methodsFor: 'pseudo constructors'!

make: dir {DirectoryModel} with: occluded {UserDirectoryModel} with: list {ListModel of: ID}

	^ self create: dir with: occluded with: list! !