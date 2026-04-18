'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:01 pm'!

WindowModel subclass: #LoginWindowModel
	instanceVariableNames: '
		myResultKeyMaster {VariableModel of: KeyMaster}
		myUDM {UserDirectoryModel}
		mySelection {SelectionObject}
		myClubListPane {FMBuilding}
		mySelectedClub {VariableModel of: PackOBits}
		myLock {VariableModel of: Lock}
		myIDList {ListModel of: PackOBits}
		myNameList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!
LoginWindowModel comment:
'This window model is used for maintaining a login pane.  It uses a UDM to provide a list of names (this is normally the public UDM).  It then allows the user to select an id to login to and to provide the correct authentication.'!

(LoginWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginWindowModel methodsFor: 'create'!

create: km {KeyMaster} with: kmModel {VariableModel of: KeyMaster} with: udm {UserDirectoryModel}
	|tmp {Int32}|
	super create.
	
	[XView] USES. 
	
	
	myResultKeyMaster _ kmModel.
	myUDM _ udm.
	mySelection _ ListSelection make: (IntegerRegion make).
	mySelection addDependent: self.
	myLock _ VariableModel make.
	cerr << 'mySelection = ' << mySelection << 'in create: LoginWindowModel'.
	mySelectedClub _ VariableModel make.
	ID2LockSchnert make: km with: mySelectedClub with: myLock.
	myClubListPane _ self makeCLPane.
	[mySTWindowModel _ self createSmalltalkWindow] smalltalkOnly.
	XVIEW ifdef: [
	["cxx:   
	setBaseWindow (tmp  = (Xv_opaque)xv_create(NULL,FRAME,FRAME_LABEL,""fake base"",0));
	 
	//setBaseWindow (tmp  =NULL);"] translateOnly.
	
	
	 self setMyXViewWindowModel:  (self createXViewWindow )].! !

!LoginWindowModel methodsFor: 'accessing'!

{ID} fetchID

	^ mySelectedClub fetchValue cast: ID!

{KeyMaster} fetchKeyMaster
	^ myResultKeyMaster fetchValue cast: KeyMaster!

{Lock} fetchLock

	^ myLock fetchValue cast: Lock!

{VariableModel of: Lock} lockVar

	^ myLock!

{ListModel} nameList  
	^ myNameList!

{SelectionObject} selection  
^ mySelection! !

!LoginWindowModel methodsFor: 'actions'!

{void} boo
	"Attempt a boo login"

	| newKM {KeyMaster} |
	self fetchLock == NULL ifTrue: [^VOID].
	newKM _ (self fetchLock cast: BooLock) boo.
	newKM == NULL ifTrue: [^VOID].
	myResultKeyMaster setValue: newKM!

{void} match: password {PackOBits} 
	"Attempt a match login"

	| newKM {KeyMaster} |
	self fetchLock == NULL ifTrue: [^VOID].
	newKM _ (self fetchLock cast: MatchLock) password: password.
	newKM == NULL ifTrue: [^VOID].
	myResultKeyMaster setValue: newKM! !

!LoginWindowModel methodsFor: 'windows'!

{FMBuilding} listBuilding
	^myClubListPane! !

!LoginWindowModel methodsFor: 'private: creations'!

{FMBuilding} makeCLPane 
	| nameList {ListModel} lpm {ListPaneModel} bld {FMBuilding} newTab {TableAccumulator} |
	[ImmuSet] USES.
	[Converter] USES.
	newTab _ TableAccumulator make.
	myUDM allIDs stepper forEach: [:id {ID} | newTab step: id].
	myIDList _ ((newTab value cast: ScruTable) asMuTable) convert: ListModel.
	nameList _ ListModel make. 
	List2ListLookupSchnert
		make: myIDList
		with: nameList
		with: (ID2ClubNameLookup make: myUDM).
	lpm _ ListPaneModel make: nameList with: mySelection.
	Scaffold fluidBind: self scaffold during: [bld _ Scaffold fluidVar build: lpm].
	myNameList _ nameList.
	^bld!

{FMScaffold} scaffold 
	| scafTab {MuTable of: FMBuilder} layout {AbstractLayout} |
	layout _ ExtentLayout make: (PointPos make: 2000 with: 12). "This'll do fer now. fix"
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: UInt8Array)
		introduce: PackOBuilder make.
	scafTab at: (HeaperAsPosition make: AttributedTextModel) 
		introduce: (FMTextBuilder make: layout).
	scafTab at: (HeaperAsPosition make: ListModel)
		introduce: (FMDirectedListBuilder make: 
						(BoundingListComp make: ListStyle defaultVertical)).
	scafTab at: (HeaperAsPosition make: ListPaneModel)
		introduce: (LPMBuilder make: (VariableModel make: HighlightAll make)).
	^FMScaffold make: scafTab with: Scaffold fluidVar! !

!LoginWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow

	"create a corresponding smalltalk window object"
	^STLoginWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!LoginWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	mySelection selection count == 1 ifFalse: [^ VOID].
	cerr << 'my selection = ' << mySelection << 'mySelectionPoint' <<mySelection selectionPoint << 'cast to XuInteger' << (mySelection selectionPoint cast: IntegerPos) << ' foo \n'.
	mySelectedClub setValue: 
		(myIDList fetch: (mySelection selectionPoint cast: IntegerPos) asIntegerVar).! !

!LoginWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewLoginWindowModel create: self!

{void} openXViewWindow
	((self myXViewWindowModel) cast: XViewLoginWindowModel) open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LoginWindowModel class
	instanceVariableNames: ''!

(LoginWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginWindowModel class methodsFor: 'make'!

make: km {KeyMaster} with: kmModel {VariableModel of: KeyMaster} with: udm {UserDirectoryModel}

	^ self create: km with: kmModel with: udm! !