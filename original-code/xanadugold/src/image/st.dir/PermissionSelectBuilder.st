'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:53 pm'!

FMBuilder subclass: #PermissionSelectBuilder
	instanceVariableNames: '
		myEditorsModel {PermissionsModel}
		myReadersModel {PermissionsModel}
		myUserDirectory {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(PermissionSelectBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionSelectBuilder */
friend SPTR(PermissionSelectBuilder)  permissionSelectBuilder (Pair OF1(PermissionsModel) * pp, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionSelectBuilder methodsFor: 'private: creation'!

create: permPair {Pair} with: directory {UserDirectoryModel}

	super create.
	myEditorsModel _ permPair left cast: PermissionsModel.
	myReadersModel _ permPair right cast: PermissionsModel.
	myUserDirectory _ directory! !

!PermissionSelectBuilder methodsFor: 'private: building'!

{Pair of: FMBuilding} buildCheckPanes: id {ID}

	| editB {BooleanModel} readB {BooleanModel} 
	  editSel {BooleanModel} readSel {BooleanModel}
	  editP {Viewer} readP{Viewer} 
	  editC {FMController} readC {FMController} |
	  
	editB _ BooleanModel make: (myEditorsModel members hasMember: id).
	readB _ BooleanModel make: 
		((myEditorsModel members asImmuSet unionWith: myReadersModel members) hasMember: id).
	ModifyEditorsSchnert make: myEditorsModel with: editB with: id.
	ModifyReadersSchnert make: myReadersModel with: editB with: readB with: id.
	editSel _ BooleanModel make.
	readSel _ BooleanModel make.
	Editors2SelSchnert make: myEditorsModel 
						with: editB with: editSel 
						with: (myUserDirectory superClubsOf: id).
	editP _ self buildSelPane: editB with: editSel.
	Readers2SelSchnert make: myEditorsModel with: myReadersModel 
						with: readB with: readSel
						with: (myUserDirectory superClubsOf: id).
	readP _ self buildSelPane: readB with: readSel.
	editC _ self buildControl: editB with: readB with: editP with: true.
	readC _ self buildControl: readB with: editB with: readP with: false.
	^ Pair make: (FMBuilding make: editP with: editC)
			with: (FMBuilding make: readP with: readC)!

{FMController} buildControl: bool2toggle {BooleanModel} with: bool2Set {BooleanModel} with: vu {Viewer} with: tf {Boolean}

	| toggle {Thunk} tfthunk {Thunk} mt {Thunk} |
	toggle _ ToggleThunk make: bool2toggle.
	tf 
		ifTrue: [tfthunk _ TrueThunk make: bool2Set]
		ifFalse: [tfthunk _ FalseThunk make: bool2Set].
	mt _ MultiThunk make: (MuArray array: toggle with: tfthunk).
	^ SelectionGate make: vu with: (ClickAction make: mt)!

{Viewer} buildSelPane: imageB {BooleanModel} with: sel {BooleanModel}

	| imageM {VariableModel of: Image} vuPane {Viewer} 
	  hi {VariableModel of: Highlight} selPane {Viewer} |
	[FMResourceManager] USES.
	imageM _ VariableModel make.
	BoolM2ImageSchnert make: imageB with: imageM with: 
		(Pair make: (Resources fluidGet getImage: 'checkedBox') 
			  with: (Resources fluidGet getImage: 'box')).
	vuPane _ VariableImageViewer make: imageM.
	hi _ VariableModel make: HighlightAll make.
	selPane _ ItemSelectionViewer make: vuPane with: sel with: hi.
	^ selPane!

{FMBuilding} buildTextSide: ofClub {ID} with: selM {BooleanModel}
 
	| aHighM {VariableModel of: Highlight} aTextM {AttributedTextModel}
	 aTextV {Viewer} aHighV {Viewer} |
	 [Converter] USES.
	aHighM _ VariableModel make: HighlightAll make.
	aTextM _ (((myUserDirectory getName: ofClub) convert: MuWordArray) 
			convert: AttributedTextModel) cast: AttributedTextModel.
	aTextV _ (Scaffold fluidGet build: aTextM) view.
	aHighV _ ItemSelectionViewer make: aTextV with: selM with: aHighM.
	^ FMBuilding make: aHighV with: NULL!

{FMScaffold} scaffold 
	^FMScaffold
		make: AttributedTextModel
		with: (FMTextBuilder make: (ExtentLayout make: (PointPos make: 2000 with: 12)))
		with: Scaffold fluidGet! !

!PermissionSelectBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 

	| checkSide {Pair} editBldg {FMBuilding} readBldg {FMBuilding}
	  readVu {ItemSelectionViewer} readSelM {BooleanModel}
	  textSide {FMBuilding} vuz {ListModel} lmv {Viewer} cz {MuArray}
	  mc {FMController} |
	  [Converter] USES.
	Scaffold fluidBind: self scaffold during: [
	checkSide _ self buildCheckPanes: (obj basicCast: ID).
	editBldg _ checkSide left cast: FMBuilding.
	readBldg _ checkSide right cast: FMBuilding.
	readVu _ readBldg view cast: ItemSelectionViewer.
	readSelM _ readVu selectionModel.
	textSide _ self buildTextSide: (obj basicCast: ID) with: readSelM.
	vuz _ (MuArray array: editBldg view with: readVu with: textSide view) convert: ListModel.
	lmv _ ListMultiViewer make: vuz with: 
				(BoundingListComp make: ListStyle defaultHorizontal).
	cz _ MuArray array: editBldg controller with: readBldg controller.
	mc _ MultiController make: cz].
	^ FMBuilding make: lmv with: mc! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionSelectBuilder class
	instanceVariableNames: ''!

(PermissionSelectBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionSelectBuilder */
friend SPTR(PermissionSelectBuilder)  permissionSelectBuilder (Pair OF1(PermissionsModel) * pp, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionSelectBuilder class methodsFor: 'make'!

make: pp {Pair of: PermissionsModel} with: ud {UserDirectoryModel}

	^ self create: pp with: ud! !