'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:55 pm'!

XnModel subclass: #UserModel
	instanceVariableNames: '
		myKeyMaster {KeyMaster}
		myHomeDocument {HomeDocumentModel}
		myTableTop {TableTopModel}
		myUserDirectory {UserDirectoryModel}
		myDefaultPermission {VariableModel of: PackOBits}
		myLinkTypes {ListModel}
		myDefaultLinkType {VariableModel of: PackOBits}
		myDefaultReferencesStyle {VariableModel of: FMBuilder}
		myFilters {ListModel}
		myDefaultFilter {VariableModel of: ReferenceFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
UserModel comment:
'Represents the current identity of the user.
All permissions interactions should go through here.

		myKeyMaster {KeyMaster}
			The actual permissions object; it should never be
manipulated directly.
		myPublicHomeDocument {WaldoModel}
			The home document of the public club, mapping from
names->club IDs
		myHomeDocument {WaldoModel}
			The home document of the current user
		myTableTop {TableTopModel}
			The active window list
		myUserDirectory {UserDirectoryModel}
			The known club IDs and names
		myDefaultPermission {VariableModel of: PackOBits}
			The default permissions for newly created documents
		myLinkTypes {WaldoListModel}
			The ordered list of known link types
		myDefaultLinkType {VariableModel of: PackOBits}
			The default link type for newly created links
		myDefaultReferencesStyle {VariableModel of: FMBuilder}
			A builder that creates a pane for an individual
reference, the current default setting
		myFilters {WaldoListModel}
			The list of known filters
		myDefaultFilter {VariableModel of: ReferenceFilter}
			The default filter for new windows'!

(UserModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserModel methodsFor: 'create'!

create: km {KeyMaster} 
	| intermediateList {ListModel} |
	super create.
	[TapestryAppModel] USES.
	myKeyMaster _ km.
	myHomeDocument _ HomeDocumentModel make: km with: km getHomeDocID.
	myTableTop _ TableTopModel make: myHomeDocument.
	myUserDirectory _ UserDirectoryModel
		make: (DirectoryModel make: km
			with: (XuDirectory userDirectoryID: km
				with: km userID)
			with: true)
		with: Application fluidGet publicDirectory
		with: NULL.
	myDefaultPermission _ VariableModel make.
	"User2DefaultPermissionSchnert make: self with: myDefaultPermission."
	myLinkTypes _ WaldoListModel make.
	"Waldo2SubListSchnert make: myHomeDocument
		with: (PackOBits make: 'LinkTypes')
		with: myLinkTypes."
	myDefaultLinkType _ VariableModel make.
	"Waldo2ValueSchnert make: myHomeDocument
		with: (PackOBits make: 'DefaultLinkType')
		with: myDefaultLinkType."
	myDefaultReferencesStyle _ 
		VariableModel make: DocumentWindowModel defaultReferenceBuilder.
	myFilters _ ListModel make.
	intermediateList _ WaldoListModel make.
	"Waldo2SubListSchnert make: myHomeDocument
		with: (PackOBits make: 'Filters')
		with: intermediateList.
	ListConverterSchnert make: intermediateList
		with: ReferenceFilter
		with: myFilters
		with: TapestryFilter."
	myDefaultFilter _ VariableModel make.
	"Waldo2ValueSchnert make: myHomeDocument
		with: (PackOBits make: 'DefaultFilter')
		with: myDefaultFilter
		with: TapestryFilter"! !

!UserModel methodsFor: 'accessing'!

{VariableModel of: TapestryFilter} defaultFilter
	"the list of filters known to this user"
	^myDefaultFilter!

{VariableModel of: ID} defaultLinkType
	"the default link types for this user"
	^myDefaultLinkType!

{VariableModel of: ID} defaultPermission
	"the default permissions for documents created by this user"
	^myDefaultPermission!

{FMBuilder} defaultReferencesStyle

	^ myDefaultReferencesStyle getValue cast: FMBuilder!

{ListModel of: TapestryFilter} filters
	"the list of filters known to this user"
	^myFilters!

{WaldoModel} homeDocument
	"the home document of the user's club"
	^myHomeDocument!

{KeyMaster} keyMaster
	"the key master for this user"
	^myKeyMaster!

{ListModel} linkTypes
	"the link types known to this user"
	^myLinkTypes!

{TableTopModel} tableTop
	"the table top for this user"
	^myTableTop!

{UserDirectoryModel} userDirectory
	"the clubs and names known to this user"
	^myUserDirectory! !

!UserModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' << ' for '.
	oo << ((self userDirectory fetchName: myKeyMaster userID) convert: MuWordArray). 
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UserModel class
	instanceVariableNames: ''!

(UserModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserModel class methodsFor: 'pseudo constructors'!

make: km {KeyMaster}
	"make the appropriate subclass"
	| result {UserModel} |
	[result _ STUserModel create: km] smalltalkOnly.
	[result _ UserModel create: km] translateOnly.
	result changed: NewContentsUpdate make.
	^result! !