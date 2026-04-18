'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:26 pm'!

XnModel subclass: #TapestryAppModel
	instanceVariableNames: '
		myPublicDirectory {UserDirectoryModel}
		myKeyMaster {KeyMaster}
		myUser {UserModel}
		myLinkEnds {LinkEndsModel}
		myDocuments {MuTable of: PackOBits and: DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
TapestryAppModel comment:
'The central model for an active application
Maintains a list of active document models to avoid duplication or grab failure
Kept in the fluid "Application"

		myUser {UserModel}
			The user model
		myLinkEnds {LinkEndsModel}
			A list of link ends
		myDocuments {MuTable of: ID and: DocumentModel}
			A mapping from bert IDs to active document models'!

(TapestryAppModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryAppModel methodsFor: 'accessing'!

{DocumentModel} fetchDocument: id {ID}
	"get the model for the given ID; return existing model if there is one"

	| waldo {Waldo} result {DocumentModel} |
	(self documents includesKey: id)
		ifTrue: [^(self documents get: id) cast: DocumentModel].
	KeyMaster problems.OpenFailed
		handle: [ :boom | ^NULL]
		do: [waldo := self user keyMaster open: id].
	(Converter fetchConverter: waldo getCategory with: DocumentModel) == NULL 
		ifTrue: [waldo destroy. ^NULL].
	result := waldo convert: DocumentModel.
	self documents at: waldo getID introduce: result.
	^result!

{DocumentModel} getDocument: id {ID}
	"get the model for the given ID; return existing model if there is one"

	| result {DocumentModel} |
	result _ self fetchDocument: id.
	result == NULL
		ifTrue: [Heaper BLAST: #CouldNotGetDocument].
	^result!

{LinkEndsModel} linkEnds
	"the link end document model"
	^myLinkEnds!

{UserDirectoryModel} publicDirectory
	^ myPublicDirectory!

{UserModel} user
	(myUser == NULL) ifTrue: [Heaper BLAST: #NotLoggedIn. ^ NULL].
	^myUser! !

!TapestryAppModel methodsFor: 'operations'!

{void} createLink: left {LinkEnd} with: right {LinkEnd} with: type {ID} with: permissions {ID}
	"create a new link"
	self hack. "permissions ignored"
	((XuLink make: self keyMaster
		with: (ImmuSet make with: left)
		with: (self computeDescriptor: left
			with: XuLink leftID
			with: type)
		with: (ImmuSet make with: right)
		with: (self computeDescriptor: right
			with: XuLink rightID
			with: type)
		with: type) copy: true) destroy!

{OutlineModel} createOutline: permissions {ID unused}
	"create a new, empty outline"
	self unimplemented.
	^NULL!

{PassageModel} createPassage: permissions {ID unused}
	"create a new, empty passage"
	self hack. "ignoring permissions"
	^(self getDocument: (self user keyMaster
		makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true)
			editionID) cast: PassageModel!

{PassageModel} createPassage: editors {ScruSet default: NULL} with: readers {ScruSet default: NULL} 
	"create a new, empty passage"

	^(self createDocModel: (Sequence string: 'XuText')
		with: editors
		with: readers)
		cast: PassageModel!

{void} openWindow: model {Heaper}
	"open a window on some kind of model "
	(model convert: WindowModel) open!

{void} openWindowAt: model {Heaper} with: initial {XnRegion}
	"open a window on some kind of model with an initial selection "
	| window {WindowModel} |
	"MessageTally mySpy: ["
		window _ model convert: WindowModel.
		window
			cast: DocumentWindowModel into: [:dwm |
				[SelectionObject, SelectionRange] USES.
				dwm documentSelection select: initial]
			others: []"]".
	window open! !

!TapestryAppModel methodsFor: 'protections'!

{void} login
	"This method presents a login window to the user to allow them to 
	select an id and provide authentication."

	| kmVar {VariableModel of: KeyMaster} loginWindow {WindowModel} |
	kmVar _ VariableModel make: NULL.
	LoginSchnert make: kmVar with: self.
	loginWindow _ LoginWindowModel
				make: self keyMaster
				with: kmVar
				with: myPublicDirectory.
	[loginWindow open] translateOnly.
	[[loginWindow open] fork] smalltalkOnly!

{void} setKeyMaster: newKM {KeyMaster} 
	"This method is used to change the keymaster, and therefore the 
	current user of the application."
	[TableTopModel] USES.
	
	"First, cleanup any old login stuff."
	myUser == NULL ifFalse: [myUser destroy].
	myLinkEnds destroy.
	myDocuments stepper forEach: [:doc {DocumentModel} | doc destroy].
	myDocuments _ MuTable make: FeServer current globalIDSpace.
	myKeyMaster destroy.
	myKeyMaster _ newKM combine: XuServer currentServer publicKeyMaster.
	"do the new login stuff"
	myUser _ UserModel make: myKeyMaster.
	myLinkEnds _ LinkEndsModel make.
	myUser tableTop openSaved! !

!TapestryAppModel methodsFor: 'private: private'!

{XuText} computeDescriptor: end {LinkEnd} with: which {ID} with: type {ID}
	"compute a simple descriptor from the contents"
	| result {XuText} context {XuText} typeDoc {LinkTypeDescription} |
	typeDoc _ LinkTypeDescription
		defaultDescription: self user keyMaster
		with: type.
	result _ ((typeDoc labels get: which) cast: Waldo) copy cast: XuText.
	result insert: result count with: (MuWordArray make.charVector: ': ').
	end fetchEndContext == NULL ifTrue:
		[result insert: result count with: (MuWordArray make.charVector: 'EVERYTHING')]
	ifFalse: [(end getEndContext isKindOf: XuText) not ifTrue:
		[result insert: result count with: (MuWordArray make.charVector: 'NON-TEXT')]
	ifFalse: [(context _ end getEndContext quickCast: XuText) usedDomain isEmpty ifTrue:
		[result insert: result count with: (MuWordArray make.charVector: 'NOTHING')]
	ifFalse:
		[result vcopy: result count
			with: context
			with: (IntegerRegion
				integerExtent: (context usedDomain cast: IntegerRegion) start
				with: 20)]]].
	^result!

{DocumentModel} createDocModel: ofType {PackOBits} with: editors {ScruSet default: NULL} with: readers {ScruSet default: NULL}
	
	"Create a new document model of the type specified and enter it into my list of documents.  This is done to keep a waldo on the document in case there is no bert on the document (and therefore making it inaccessible, except through the original waldo)."
	
	| newWaldo {Waldo} docModel {DocumentModel} |
	newWaldo _ self user keyMaster makePersistentWaldo: ofType.
	docModel _ newWaldo convert: DocumentModel.
	(editors ~~ NULL and: [editors isEmpty not]) 
		ifTrue: [docModel getEditPermissions addAll: editors].
	(readers ~~ NULL and: [readers isEmpty not])
		ifTrue: [docModel getReadPermissions addAll: readers].
	self documents at: docModel iD introduce: docModel.
	^ docModel!

{MuTable of: PackOBits and: DocumentModel} documents
	^myDocuments!

{KeyMaster} keyMaster
	^myKeyMaster! !

!TapestryAppModel methodsFor: 'create'!

create: km {KeyMaster} 

	super create.
	myPublicDirectory _ UserDirectoryModel
		make: (DirectoryModel make: km
			with: XuDirectory userDirectoryID
			with: true)
		with: NULL
		with: NULL.
	myKeyMaster _ km.
	myUser _ NULL.
	myLinkEnds _ LinkEndsModel make.
	myDocuments _ MuTable make: FeServer current globalIDSpace! !

!TapestryAppModel methodsFor: 'smalltalk: defaults'!

{DocumentModel} createDocModel: ofType {PackOBits}

	^ self createDocModel: ofType with: NULL with: NULL!

{DocumentModel} createDocModel: ofType {PackOBits} with: editors {ScruSet default: NULL}

	^ self createDocModel: ofType with: editors with: NULL!

createLink: end1 with: end2 with: type
	^self createLink: end1 with: end2 with: type with: NULL!

{PassageModel} createPassage
	"create a new, empty passage"
	
	^ self createPassage: NULL with: NULL! !

!TapestryAppModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' 
		<< ' MyUser = ' << myUser 
		<< ' link ends = ' << myLinkEnds 
		<< ' MyDocuments = ' << myDocuments << ')'! !

!TapestryAppModel methodsFor: 'clubs'!

{PermissionsModel} makeUserClub: km {KeyMaster}

	| nuClub {ClubManager} nuDir {XuDirectory}
	  nuHome {Waldo} nuID {ID} |
	nuClub _ km makeClub.
	nuClub lockSmith: (LockSmith booLockSmith: km).
	nuDir _ XuDirectory userDirectory: km with: nuClub getID.
	nuDir destroy.
	nuHome _ km makePersistentWaldo: (Sequence string: 'DirectRecord').
	nuClub homeDocID: nuHome getID.
	nuHome destroy.
	nuID _ nuClub getID.
	nuClub destroy.
	^PermissionsModel fetchPermissionsModel: km with: nuID! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TapestryAppModel class
	instanceVariableNames: ''!

(TapestryAppModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryAppModel class methodsFor: 'pseudo constructors'!

make: km {KeyMaster}
	^self create: km! !

!TapestryAppModel class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage
	"TapestryAppModel cleanupGarbage"
	Application _ nil! !

!TapestryAppModel class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	TapestryAppModel
		defineFluid: #Application
		with: Emulsion globalEmulsion
		with: [NULL]! !