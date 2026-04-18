'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:29 pm'!

XnModel subclass: #WaldoModel
	instanceVariableNames: '
		myWaldo {Waldo}
		myID {ID}
		myWorkType {PackOBits}
		myGrabbed {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
WaldoModel comment:
'A WaldoModel holds onto a kind of waldo and handles changes to it. Subclasses can hold onto particular kinds of waldos and provide messages for changing them that also produce update records. The superclass takes care of: (or will when it''s finished)
-- grabbing and releasing a waldo
-- if it is not grabbed, keeping a sensor on the bert to watch for changes to the document
-- switching the model to a completely different waldo'!

(WaldoModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoModel methodsFor: 'create'!

create
	super create.
	myWaldo _ NULL.
	myID _ NULL.
	myWorkType _ NULL.
	myGrabbed _ false!

create: waldo {Waldo} 
	super create.
	myWaldo _ waldo.
	myID _ waldo fetchID.
	myGrabbed _ (myID == NULL) not.
	myWorkType _ waldo workType!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits default: NULL} with: phantom {BooleanVar default: true}
	super create.
	myWaldo _ NULL.
	myID _ NULL.
	myWorkType _ NULL.
	myGrabbed _ false.
	self setWaldo: id with: worktype with: phantom with: km!

{void} destroy
	"This destroy() member function blocks calls to the model's destructor,
	but does make sure that the bert is released.  This should cause no problems because
	the bert will be regrabbed if necessary."

	self releaseBert!

{void} destruct

	myWaldo destroy.
	myID _ NULL.
	myWorkType _ NULL.
	super destruct! !

!WaldoModel methodsFor: 'accessing'!

{ID} iD
	"the ID of this waldo - if no bert ID yet, grab to create one..."

	myID == NULL ifTrue: [self makeEditable ifFalse: [Heaper BLAST: #NOID].
		self releaseBert].
	^myID!

{KeyMaster} keyMaster
	^ self waldo keyMaster!

{void} setWaldo: id {ID}
		with: workType {PackOBits default: NULL}
		with: phantom {BooleanVar default: true}
		with: km {KeyMaster default: NULL}
	"switch to a different document"
	(myID ~~ NULL and: [(id isEqual: myID)
			and: [workType == NULL or: [myWorkType ~~ NULL and: [myWorkType isEqual: workType]]]])
		ifFalse: [ | old {ID} newWorkType {PackOBits} newKM {KeyMaster} |
			old _ myID.
			workType ~~ NULL ifTrue:
				[myWorkType _ workType].
			myWorkType == NULL
				ifTrue: [newWorkType _ Sequence string: 'Waldo'"  with: true"]
				ifFalse: [newWorkType _ myWorkType].
			km == NULL
				ifTrue: [newKM _ myWaldo keyMaster]
				ifFalse: [newKM _ km].
			"myWaldo _ newKM open: id
				with: newWorkType
				with: (phantom ifTrue: [OpenTemporaryVariant] ifFalse: [OpenOriginalDocument])."
			self unimplemented.
			myID _ id.
			myGrabbed _ phantom not.
			self changed: (SingleReplaceUR make: old with: id)]!

{Waldo} waldo
	myWaldo == NULL ifTrue:
		[Heaper BLAST: #InvalidRequest].
	^myWaldo! !

!WaldoModel methodsFor: 'smalltalk: smalltalk defaults'!

create: km with: id
	^self create: km with: id with: NULL with: true!

create: km with: id with: type
	^self create: km with: id with: type with: true!

setWaldo: id
	self setWaldo: id with: NULL with: true with: NULL!

setWaldo: id with: type
	self setWaldo: id with: type with: true with: NULL!

setWaldo: id with: type with: phantom
	self setWaldo: id with: type with: phantom with: NULL! !

!WaldoModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' myWaldo = ' << myWaldo << '
 	myID = ' << myID << '
 	myWorkType = ' << myWorkType! !

!WaldoModel methodsFor: 'permissions'!

{ScruSet of: ID} editors

	| pm {PermissionsModel} res {ScruSet} |
	pm _ self fetchEditPermissions.
	pm == NULL ifTrue: [^ ImmuSet make].
	res _ pm members.
	pm destroy.
	^ res!

{PermissionsModel} fetchEditPermissions
	"the model controlling the edit permissions for this document"
	"verify the cache is up to date"
	^PermissionsModel fetchPermissionsModel: self waldo keyMaster
						with: (XuServer currentServer editClubIDFor: self iD)!

{PermissionsModel} fetchReadPermissions
	"the model controlling the edit permissions for this document"

	"verify the cache is up to date"
	^PermissionsModel fetchPermissionsModel: self waldo keyMaster
								with: (XuServer currentServer readClubIDFor: self iD)!

{PermissionsModel} getEditPermissions
	"the model controlling the edit permissions for this document"

	| pm {PermissionsModel} |
	pm _ self fetchEditPermissions.
	pm == NULL ifTrue: [Heaper BLAST: #CannotGetEditClub. ^ NULL].
	^ pm!

{PermissionsModel} getReadPermissions
	"the model controlling the read permissions for this document"

	| pm {PermissionsModel} |
	pm _ self fetchReadPermissions.
	pm == NULL ifTrue: [Heaper BLAST: #CannotGetReadClub. ^ NULL].
	^ pm!

{ScruSet of: ID} readers
	| rp {PermissionsModel} res {ScruSet} |
	rp _ self fetchReadPermissions.
	rp == NULL
		ifTrue: [^self editors].
	res _ rp members.
	rp destroy.
	^res asImmuSet unionWith: self editors! !

!WaldoModel methodsFor: 'protected: policy'!

{BooleanVar} bertIsGrabbed

	^ myGrabbed!

{BooleanVar} makeEditable

	"This method attempts to grab the bert... returns false if it fails"
	myGrabbed ifFalse: [
		myID == NULL 
			ifTrue: [
				myWaldo := myWaldo copy: true.
				myID := myWaldo getID.
				^ (myGrabbed := true)]
			ifFalse: [ | nw {Waldo} |
				KeyMaster problems.DocumentInUse
					handle: [ :boom | ^ (myGrabbed := false)]
					do: [nw := myWaldo keyMaster open: myID
						with: myWaldo workType].
				(myWaldo editionID isEqual: nw editionID)
					ifFalse: [nw replaceWith: myWaldo. "hop to the current state"].
						myWaldo := nw]].
	^ (myGrabbed := true)!

{void} releaseBert
	"This method insures that the bert is not held by this model."
	
	| old {Waldo} |
	myGrabbed ifFalse: [^ VOID].
	old _ myWaldo.
	myWaldo _ myWaldo copy: true.
	old destroy.
	myGrabbed _ false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoModel class
	instanceVariableNames: ''!

(WaldoModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoModel class methodsFor: 'pseudo constructors'!

make
	^self create!

make: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	^self create: km with: id with: worktype with: phantom! !