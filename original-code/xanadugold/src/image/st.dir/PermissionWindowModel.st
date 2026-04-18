'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:00 pm'!

WindowModel subclass: #PermissionWindowModel
	instanceVariableNames: '
		myReadPermissionsModel {PermissionsModel}
		myEditPermissionsModel {PermissionsModel}
		myDirectory {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(PermissionWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionWindowModel */
friend SPTR(PermissionWindowModel)  permissionWindowModel (PermissionsModel * edit, PermissionsModel * read, WaldoModel * doc, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionWindowModel methodsFor: 'accessing'!

{ListModel of: PackOBits} clubNames

	^ myDirectory clubNames!

{FMBuilding} permissionsListBuilding 
	| build {FMBuilding} |
	Scaffold fluidBind: self scaffold during: [
		build _ Scaffold fluidVar build: self permissionsPair].
	^ build!

{Pair of: PermissionsModel and: PermissionsModel} permissionsPair
	^ Pair make: myEditPermissionsModel with: myReadPermissionsModel! !

!PermissionWindowModel methodsFor: 'private: create'!

create: onEdit {PermissionsModel} with: onRead {PermissionsModel} with: document {WaldoModel} with: userDir {UserDirectoryModel}

	super create.
	[mySTWindowModel _ self createSmalltalkWindow] smalltalkOnly.
	XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].
	myEditPermissionsModel _ onEdit.
	myReadPermissionsModel _ onRead.
	myDirectory _ userDir!

{void} destruct
	"The permissions models are destroyed here as the only logical place... i hope..."
	myEditPermissionsModel destroy.
	myReadPermissionsModel destroy.
	myDirectory _ NULL.
	super destruct! !

!PermissionWindowModel methodsFor: 'private: setup'!

{FMScaffold} scaffold
	^FMScaffold
		make: Pair
		with: (PermissionsBuilder make: myDirectory)
		with: super scaffold! !

!PermissionWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow
	"PermissionsWindowModel create open"
	"create a corresponding smalltalk window object"

	^STPermissionsWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!PermissionWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel unused}

	self changed: ur! !

!PermissionWindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	super printOn: oo.
	oo	<< '
	myReadPermissionsModel: ' << myReadPermissionsModel
		<< '
	myEditPermissionsModel: ' << myEditPermissionsModel
		<< '
	myUserDirectory: ' << myDirectory! !

!PermissionWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewPermissionWindowModel create: self!

{void} openXViewWindow
	self myXViewWindowModel open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionWindowModel class
	instanceVariableNames: ''!

(PermissionWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionWindowModel */
friend SPTR(PermissionWindowModel)  permissionWindowModel (PermissionsModel * edit, PermissionsModel * read, WaldoModel * doc, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionWindowModel class methodsFor: 'make'!

make: edit {PermissionsModel} with: read {PermissionsModel} with: doc {WaldoModel} with: ud {UserDirectoryModel}

	^ self create: edit with: read with: doc with: ud! !