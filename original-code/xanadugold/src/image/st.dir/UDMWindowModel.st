'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:03 pm'!

WindowModel subclass: #UDMWindowModel
	instanceVariableNames: '
		myUDM {UserDirectoryModel}
		mySelection {SelectionObject}
		myClubListPane {FMBuilding}
		myClubManagerPane {ClubManagerPaneModel}
		mySelectedClub {VariableModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UDMWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UDMWindowModel methodsFor: 'creation'!

create: onUDM {UserDirectoryModel} with: sel {SelectionObject}
	super create.
	[mySTWindowModel _ STUDMWindowModel create: self] smalltalkOnly.
	XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].
	myUDM _ onUDM.
	mySelection _ sel.
	myClubListPane _ NULL.
	mySelection addDependent: self.
	mySelectedClub _ VariableModel make.
	myClubManagerPane _ ClubManagerPaneModel create: myUDM with: mySelectedClub.!

{void} destruct

	self close.
	myClubListPane destroy.
	myClubListPane _ NULL.
	myClubManagerPane destroy.
	myClubManagerPane _ NULL.
	mySelectedClub destroy.
	mySelectedClub _ NULL.
	super destruct! !

!UDMWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow

	"UDMWindowModel create open"
	"create a corresponding smalltalk window object"
	^STUDMWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!UDMWindowModel methodsFor: 'accessing'!

{ClubManagerPaneModel} clubManagerPane

	^ myClubManagerPane!

{SelectionObject} selection
	^ mySelection!

{UserDirectoryModel} userDirectoryModel
	^ myUDM! !

!UDMWindowModel methodsFor: 'buildings'!

{FMScaffold} listScaffold 
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
	^FMScaffold make: scafTab with: Scaffold fluidVar!

{FMBuilding} udmListBuilding 
	myClubListPane == NULL 
		ifTrue: [Scaffold fluidBind: self listScaffold during: 
			[myClubListPane _ LPMBuilder make build: 
				(ListPaneModel make: myUDM clubNames with: mySelection)]].
	^myClubListPane! !

!UDMWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}
 
	(sender == (myClubManagerPane basicCast: XnModel))
		ifTrue: [(ur isKindOf: WindowCloseUpdate)
			ifTrue: [myClubManagerPane _ NULL]]
		ifFalse: [(sender == (mySelection basicCast: XnModel))
			ifTrue: [self updateFromSelection]]! !

!UDMWindowModel methodsFor: 'window operations'!

{void} close

	mySelection _ NULL.
	myUDM _ NULL.
	super close! !

!UDMWindowModel methodsFor: 'private: updating'!

{void} updateFromSelection

	| pos {IntegerVar} id {ID} |
	mySelection selection count = 1 
		ifTrue: [pos _ (mySelection selection theOne cast: IntegerPos) asIntegerVar.
			id _ (myUDM clubIDs fetch: pos) cast: ID.
			mySelectedClub setValue: id]
		ifFalse: [mySelectedClub setValue: NULL]! !

!UDMWindowModel methodsFor: 'actions'!

{void} deleteClub
	"This deletes a club from the directory, rather than just removing it 
	from the list of clubs in the menu"!

{void} newClub

	| nuClub {PermissionsModel} clubList {ListModel} |
	[TapestryAppModel] USES.
	((myClubManagerPane namePack isEqual: (Sequence string: ''))
		or: [(myUDM fetchLocalClubID: myClubManagerPane namePack) ~~ NULL])
		ifTrue: [Heaper BLAST: #ClubNameAlreadyExists. ^ VOID].
	nuClub _ Application fluidVar makeUserClub: (Application fluidVar user keyMaster).
	clubList _ myUDM clubIDs.
	myUDM at: myClubManagerPane namePack storeClubID: nuClub iD.
	clubList insert: clubList count with: nuClub iD.
	nuClub destroy.!

{void} rearrangeList: distance {IntegerVar} 
	| ul {ListModel} dSel {XnRegion} cut1 {IntegerVar} cut2 {IntegerVar} cut3 {IntegerVar} |
	ul _ myUDM clubIDs.
	dSel _ mySelection selection.
	dSel simpleRegions forEach: [:sr {IntegerRegion} | 
			cut1 _ sr start.
			cut2 _ sr stop.
			distance > IntegerVar0
				ifTrue: [cut3 _ cut2 + distance]
				ifFalse: 
					[cut3 _ cut2.
					cut2 _ cut1.
					cut1 _ cut1 + distance].
			cut1 < IntegerVar0 ifTrue: [cut1 _ IntegerVar0].
			cut3 > ul count ifTrue: [cut3 _ ul count].
			ul rearrange: cut1 with: cut2 with: cut3]!

{void} removeClub
	| dSel {XnRegion} ul {ListModel} |
	dSel _ mySelection selection.
	ul _ myUDM clubIDs.
	dSel isEmpty ifTrue: [^VOID].
	mySelectedClub setValue: NULL.
	ul wipe: dSel!

{void} renameClub

	| cID {ID} |
	(cID _ mySelectedClub fetchValue cast: ID) == NULL ifTrue: [^ VOID].
	((myClubManagerPane namePack isEqual: (Sequence string: ''))
		or: [(myUDM fetchLocalClubID: myClubManagerPane namePack) ~~ NULL])
		ifTrue: [Heaper BLAST: #ClubNameAlreadyExists. ^ VOID].
	
	myUDM at: myClubManagerPane namePack storeClubID: cID! !

!UDMWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewUDMWindowModel create: self!

{void} openXViewWindow
self myXViewWindowModel open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UDMWindowModel class
	instanceVariableNames: ''!

(UDMWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UDMWindowModel class methodsFor: 'make'!

make: onUDM {UserDirectoryModel} with: sel {SelectionObject default: NULL}

	sel == NULL	
		ifTrue: [^ self create: onUDM with: (ListSelection make: IntegerRegion make)]
		ifFalse: [^ self create: onUDM with: sel]! !

!UDMWindowModel class methodsFor: 'smalltalk: make'!

make: onUDM {UserDirectoryModel}
	^ self make: onUDM with: NULL! !