'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:03 pm'!

STWindowModel subclass: #STDocumentWindowModel
	instanceVariableNames: '
		wasShifted {BooleanVar}
		myController {StandardSystemController}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STDocumentWindowModel methodsFor: 'pinning'!

{void} pin: n {Integer}
	"set this user's pin status"
	n ~= 0 ifTrue:
		[Application fluidVar user tableTop trailingWindowCount setValue: (#(0 1 2 4 8 -1) at: n) integer]!

{Integer} pinMask
	self window pinStatus getValue ifTrue: [^Form black] ifFalse: [^Form gray]!

pinMenu
	^PopUpMenu labels: '0\1\2\4\8\all' withCRs!

pinWindow
	"toggle the pin status of this window"
	self window pinStatus setValue: self window pinStatus getValue not! !

!STDocumentWindowModel methodsFor: 'sensors'!

attachSensor
	"attach a Tapestry sensor to the document and all its contents"
	"(create all links, low-level sensors, etc)"
	self window document attachSensor! !

!STDocumentWindowModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {Heaper}
	model == self window pinStatus ifTrue:
		[self changed: #pinMask]
	ifFalse: [model == self window document fetchReadPermissions ifTrue:
		[self changed: #reader]
	ifFalse: [model == self window document fetchEditPermissions ifTrue:
		[self changed: #writer]
	ifFalse: [model == self window referenceFilter ifTrue:
		[self changed: #filter]]]]! !

!STDocumentWindowModel methodsFor: 'filters'!

{DisplayObject} filter
	"get the name of the user's current filter"
	^"(((self window referenceFilter getValue cast: TapestryFilter) name cast: XuText) asDataTable cast: XuWordArray) asString asParagraph" 'NoFilter' asParagraph!

filter: n
	"set the user's current filter to the n'th filter on the filter menu"
	n > 0 ifTrue:
		[self window referenceFilter setValue: (Application fluidVar user filters get: n - 1)]!

{PopUpMenu} filterMenu
	"the menu of the user's list of filters"
	^Application fluidVar user filtersMenu getValue! !

!STDocumentWindowModel methodsFor: 'link ends'!

{void} linkEnd: n {Integer}
	"open the link end editing / link creation window"
	n > 0 ifTrue:
		[LinkMakerWindowModel make open]!

{PopUpMenu} linkEndMenu
	^PopUpMenu labels: 'link end window'!

{void} rememberLinkEnd
	"create a link end from the current selection of my document"
	"add it to the end of the link end list"
	Cursor wait showWhile:
		[Application fluidVar linkEnds store: self window createLinkEnd]! !

!STDocumentWindowModel methodsFor: 'private: setting'!

{void} attachIconsTo: top {StandardSystemView} above: v {Float}
	| n {Float} m {Float} |
	n _ v.
	m _ (1 - (6 * n)) / 3.0.
	
	top addSubView: ((CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #attachSensor)
			form: #attachSensorForm))
		in: (0@0 extent: n@v) borderWidth: (1@1 corner: 0@1).
	top addSubView: ((CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #rememberLinkEnd
				menu: #linkEndMenu
				action: #linkEnd:)
			form: #createLinkEndForm))
		in: (n@0 extent: n@v) borderWidth: (0@1 corner: 0@1).
	top addSubView: ((CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #createLink
				menu: #createLinkMenu
				action: #createLink:)
			form: #createLinkForm))
		in: (2*n@0 extent: n@v) borderWidth: (0@1 corner: 0@1).
	top addSubView: ((CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #attachNote
				menu: #attachNoteMenu
				action: #attachNote:)
			form: #attachNoteForm))
		in: (3*n@0 extent: n@v) borderWidth: (0@1 corner: 1@1).
	
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #setPermissions
				menu: nil
				action: nil)
			form: #editors)
		in: (n*4@0 extent: m@v) borderWidth: (1@1 corner: 0@1).
	top addSubView: ((CenteredFormView on: self
			with: NoController new
			form: #arrowForm))
		in: (n*4+m@0 extent: n@v) borderWidth: (0@1 corner: 0@1).
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #setPermissions
				menu: nil
				action: nil)
			form: #readers)
		in: (n*5+m@0 extent: m@v) borderWidth: (0@1 corner: 1@1).
	
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: nil
				menu: #filterMenu
				action: #filter:)
			form: #filter)
		in: (1-n-m@0 extent: m@v) borderWidth: 1.
	top addSubView: ((CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #pinWindow
				menu: #pinMenu
				action: #pin:)
			form: #pinForm
			mask: #pinMask))
		in: (1-n@0 extent: n@v) borderWidth: 1.!

{ID} linkTypeChoice: n {Integer}
	"get the link type corresponding to a menu choice"
	n = 0
		ifTrue: [^Application fluidVar user defaultLinkType getValue cast: ID]
		ifFalse: [^(Application fluidVar user linkTypes get: (n - 1 // 2)) cast: ID]!

{Boolean} linkTypeEndsSwapped: n {Integer}
	^n // 2 = 1!

{ID} permissionsChoice: n {Integer}
	"get the user's list of clubs and make a menu"
	n = 0
		ifTrue: [^Application fluidVar user defaultPermission getValue]
		ifFalse: [^(Application fluidVar user userDirectory clubIDs get: n - 1) cast: ID]! !

!STDocumentWindowModel methodsFor: 'permissions'!

{DisplayObject} editors
	"get the edit club members & endorsements of the current document"

	| editors {ScruSet of: ID} anEditor {PackOBits} |

	editors _ self window document editors.
	anEditor _ Application fluidVar user userDirectory fetchName: editors stepper get.
	^(anEditor convert: MuWordArray) asString asParagraph!

{DisplayObject} reader
	"get the read club members & endorsements of the current document"

	| readers {ScruSet of: ID} aReader {PackOBits} |
	readers _ self window document readers.
	aReader _ Application fluidVar user userDirectory fetchName: readers stepper get.
	^(aReader convert: MuWordArray) asString asParagraph!

{DisplayObject} readers
	"get the read club members & endorsements of the current document"

	| readers {ScruSet of: ID} aReader {PackOBits} |
	readers _ self window document readers.
	aReader _ Application fluidVar user userDirectory fetchName: readers stepper get.
	^(aReader convert: MuWordArray) asString asParagraph!

setEditors
	"open a window to change the edit club"

	"| ep rp |
	ep _ self window document fetchEditPermissions.
	rp _ self window document fetchReadPermissions.
	(ep ~~ NULL and: [rp ~~ NULL])
		ifTrue: [(PermissionWindowModel
				make: ep
				with: rp
				with: self window document
				with: Application fluidVar user userDirectory) open]"!

setPermissions
	"open a window to change the permissions"
	"| ep rp |
	ep _ self window document fetchEditPermissions.
	rp _ self window document fetchReadPermissions.
	(ep ~~ NULL and: [rp ~~ NULL])
		ifTrue: [(PermissionWindowModel
				make: ep
				with: rp
				with: self window document
				with: Application fluidVar user userDirectory) open]"!

{DisplayObject} writer
	"get the edit club members & endorsements of the current document"

	| editors {ScruSet of: ID} anEditor {PackOBits} |
	editors _ self window document editors.
	anEditor _ Application fluidVar user userDirectory fetchName: editors stepper get.
	^(anEditor convert: MuWordArray) asString asParagraph! !

!STDocumentWindowModel methodsFor: 'windowing'!

{void} open
	| wname {Waldo} name {String} top {StandardSystemView} |
	wname _ self window document name.
	(wname isKindOf: XuText)
		ifTrue: [name _ (wname asDataTable asMuTable cast: MuWordArray) asString]
		ifFalse: [name _ '<' , wname getCategory name , '>'].
	top  _ FMMVCWindow create: self with: name with: 400@275.
	self attachIconsTo: top above: 0.075.
	self attachPanesTo: top below: 0.075.
	myController _ top controller.
	myController initialize; open! !

!STDocumentWindowModel methodsFor: 'notes'!

attachNote
	"create a new passage"
	"link it to the selection using the default link type and permissions"
	"open a window on the new passage using default window style"
	Cursor wait showWhile:
		[self window attachNote: (self linkTypeChoice: 0)
			with: false
			with: (self permissionsChoice: 0)
			with: Sensor leftShiftDown]!

attachNote: n
	"create a new passage"
	"link it to the selection using the chosen link type and permissions"
	"open a window on the new passage withe default window style"
	n ~= 0 ifTrue:
		[ | perms |
		perms _ Application fluidVar user permissionsMenu getValue startUp.
		perms ~= 0 ifTrue:
			[Cursor wait showWhile:
				[self window attachNote: (self linkTypeChoice: n)
					with: false
					with: (self permissionsChoice: perms)
					with: wasShifted]]]!

{PopUpMenu} attachNoteMenu
	"get user's list of link types and make a menu"
	wasShifted _ Sensor leftShiftDown.
	^Application fluidVar user linkTypesMenu getValue! !

!STDocumentWindowModel methodsFor: 'links'!

{void} createLink
	"create a link end from current selection and document"
	"(where does the descriptor come from?)"
	"link it to the last link end created with the default link type"
	"(bring up a confirmation box OK/Cancel/Edit?)"
	Cursor wait showWhile:
	[Application fluidVar createLink: Application fluidVar linkEnds lastEnd
		with: self window createLinkEnd
		with: (self linkTypeChoice: 0)
		with: (self permissionsChoice: 0)]!

{void} createLink: n {Integer}
	"get the user's list of permission groups and make a menu"
	"create a link from the last link end in the list to the current selection
	 using the selected link type"
	n ~= 0 ifTrue:
		[ | perm {Integer} |
		perm _ Application fluidVar user permissionsMenu getValue startUp.
		perm ~= 0 ifTrue:
			[ | a {LinkEnd} b {LinkEnd} |
			a _ Application fluidVar linkEnds lastEnd.
			b _ self window createLinkEnd.
			(self linkTypeEndsSwapped: n) ifTrue: [ | t | t _ a. a _ b. b _ t].
			Cursor wait showWhile:
				[Application fluidVar createLink: a with: b
					with: (self linkTypeChoice: n)
					with: (self permissionsChoice: perm)]]]!

{PopUpMenu} createLinkMenu
	"get the user's list of link types and make a menu"
	^Application fluidVar user linkTypesMenu getValue! !

!STDocumentWindowModel methodsFor: 'icons'!

arrowForm
	^Resources fluidVar fetchResource: 'Editors2Readers'!

attachNoteForm
	^Resources fluidVar fetchResource: 'CreateNote'!

attachSensorForm
	^Resources fluidVar fetchResource: 'CreateSensor'!

createLinkEndForm
	^Resources fluidVar fetchResource: 'CreateLinkEnd'!

createLinkForm
	^Resources fluidVar fetchResource: 'CreateLink'!

pinForm
	^Resources fluidVar fetchResource: 'Pin'! !

!STDocumentWindowModel methodsFor: 'create'!

create: window {WindowModel}
	super create: window.
	window pinStatus addDependent: self.
	"self window referenceFilter addDependent: self"!

{void} destruct

	self window pinStatus removeDependent: self.
	self window referenceFilter removeDependent: self.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STDocumentWindowModel class
	instanceVariableNames: ''!



!STDocumentWindowModel class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: TapestryAppModel.
	self REQUIRES: FMResourceManager. 
	Resources fluidGet storeResource: 'CreateSensor'
		with: (Form extent: 12 @ 11
				fromArray: #(1024 2592 2496 2240 1088 1056 2832 4592 8416 32704 16320 )
				offset: 0 @ 0).
	Resources fluidGet storeResource: 'CreateLinkEnd'
		with: (Form extent: 11 @ 12
				fromArray: #(1536 1536 1280 31872 49216 40128 48576 46976 45824 45056 57344 0 )
				offset: 0 @ 0).
	Resources fluidGet storeResource: 'CreateLink'
		with: (Form extent: 11 @ 11
				fromArray: #(65280 33152 64704 32448 704 3808 2080 1120 736 448 128 )
				offset: 0 @ 0).
	Resources fluidGet storeResource: 'CreateNote'
		with: (Form extent: 12 @ 10
				fromArray: #(2016 1072 31792 49200 39984 48176 47088 46064 45056 57344 )
				offset: 0 @ 0).
	Resources fluidGet storeResource: 'Editors2Readers'
		with: (Form extent: 13 @ 11
				fromArray: #(512 768 896 65472 65504 65520 65504 65472 896 768 512 )
				offset: 0 @ 0).
	Resources fluidGet storeResource: 'Pin'
		with: (Form extent: 14 @ 12
				fromArray: #(992 2032 3896 4056 4056 4088 4088 4080 7136 12288 24576 49152 )
				offset: 0 @ 0).! !