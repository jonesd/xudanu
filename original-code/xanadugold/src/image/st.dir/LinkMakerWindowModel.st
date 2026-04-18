'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:57 pm'!

WindowModel subclass: #LinkMakerWindowModel
	instanceVariableNames: '
		myEndList {ListModel of: LinkEnd}
		myEndListSelection {SelectionObject}
		myCurrentEditors {ListModel of: ID}
		myCurrentReaders {ListModel of: ID}
		myCurrentEndDescription {AttributedTextModel}
		myCurrentFromEndSet {ListModel of: LinkEnd}
		myCurrentTooEndSet {ListModel of: LinkEnd}
		myCurrentLinkType {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
LinkMakerWindowModel comment:
'This is the FM representation of a link maker
window.  This model is responsible for coordinating the
efforts and actions of the various components of the
window.'!

(LinkMakerWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkMakerWindowModel */
friend SPTR(LinkMakerWindowModel)  linkMakerWindowModel
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerWindowModel methodsFor: 'private: creation'!

create
	super create.
	[mySTWindowModel _ self createSmalltalkWindow]
smalltalkOnly.
XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].
	myEndList _ Application fluidVar linkEnds descriptionList.
	myCurrentEndDescription _ NULL.
	myCurrentEditors _ NULL.
	myCurrentReaders _ NULL.
	myCurrentLinkType _ (self linkTypes asTable
intFetch: IntegerVar0) cast: ID.
	myCurrentFromEndSet _ ListModel make.
	myCurrentFromEndSet addDependent: self.
	myCurrentTooEndSet _ ListModel make.
	myCurrentTooEndSet addDependent: self.
	myEndListSelection _ SelectionRange make.
	myEndListSelection addDependent: self.
	List2SelectionSchnert make: myEndList with:
myEndListSelection.
	EndList2DescriptionListSchnert make: Application fluidVar
linkEnds with: myEndList!

{void} destruct

	myCurrentFromEndSet removeDependent: self.
	myCurrentTooEndSet removeDependent: self.
	myEndListSelection removeDependent: self.
	myEndList _ NULL.
	myEndListSelection _ NULL.
	myCurrentFromEndSet _ NULL.
	myCurrentTooEndSet _ NULL.
	myCurrentEndDescription _ NULL.
	myCurrentEditors _ NULL.
	myCurrentReaders _ NULL.
	myCurrentLinkType _ NULL.
	super destruct! !

!LinkMakerWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewLinkMakerWindowModel create: self!

{void} openXViewWindow
self myXViewWindowModel open! !

!LinkMakerWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^STLinkMakerWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!LinkMakerWindowModel methodsFor: 'accessing'!

{AttributedTextModel} currentEndDescription
	myCurrentEndDescription == NULL
		ifTrue: [^AttributedTextModel make.WordArray: (MuWordArray make.charVector: '')]
		ifFalse: [^myCurrentEndDescription]!

{ListModel of: ID} editors

	^ myCurrentEditors!

{ListModel of: LinkEnd} endList
	^myEndList!

{FMBuilding} fromEndBuilding 
	 [FMResourceManager] USES.
	XVIEW ifndef: [^ FMBuilding make: (FormViewer make: (Resources fluidVar
fetchImage: 'End0')) with: NULL]. 
XVIEW ifdef: [^ FMBuilding make: (FormViewer make: NULL) with: NULL].!

{ListModel of: LinkEnd} fromEnds

	^ myCurrentFromEndSet!

{ListModel of: ID} linkTypes
	"This method returns a listmodel of link types"
	[TapestryAppModel, UserModel] USES.
	^ Application fluidVar user linkTypes!

{ListModel of: ID} readers

	^ myCurrentReaders!

{SelectionObject} selectedEnds

	^ myEndListSelection!

{FMBuilding} tooEndBuilding 

XVIEW ifndef: [	^ FMBuilding make: (FormViewer make: (Resources fluidVar
fetchImage: 'End0')) with: NULL].
XVIEW ifndef: [	^ FMBuilding make: (FormViewer make: NULL) with: NULL].!

{ListModel of: LinkEnd} tooEnds

	^ myCurrentTooEndSet!

{ListModel of: AttributedTextModel} users
	"This method returns a listmodel of user names as 
	attributedtextmodels, ready for display as a list of names."

	| nameList {ListModel of: PackOBits} newATMs {Accumulator} |
	[Converter] USES.
	nameList _ Application fluidVar user userDirectory clubNames.
	newATMs _ MuArray arrayAccumulator.
	nameList stepper forEach: [:name {PackOBits} | 
		newATMs step: (AttributedTextModel make.WordArray: (name convert: MuWordArray))].
	^ListModel make: (newATMs value cast: IntegerTable)! !

!LinkMakerWindowModel methodsFor: 'buildings'!

{FMBuilding} currentEndBuilding 
	| eb {FMBuilding} |
	Scaffold fluidBind: self scaffold during: [eb _ Scaffold fluidVar build: self currentEndDescription].
	^eb!

{FMBuilding} endlistBuilding 
	| eb {FMBuilding} mcs {Accumulator} msv {MultiSelectionViewer} |
	Scaffold fluidBind: self listScaffold during: [eb _ Scaffold fluidVar build: self endList].
	myEndListSelection _ ListSelection make: IntegerRegion make.
	myEndListSelection addDependent: self.
	mcs _ MuArray arrayAccumulator.
	eb controller ~~ NULL ifTrue: [mcs step: eb controller].
	mcs step: (MultiSelectionController make: eb view with: myEndListSelection).
	"[mcs step: (ClickAction make: (TranscriptThunk make: 'end list selection: ' with: myEndListSelection))] smalltalkOnly."
	msv _ MultiSelectionViewer make: eb view
				with: myEndListSelection
				with: (VariableModel make: HighlightAll make).
	^FMBuilding make: msv with: (SelectionGate make: eb view with: (MultiController make: (mcs value cast: ScruTable)))!

{FMScaffold} listScaffold 
	| table {MuTable of: FMBuilder} layout {AbstractLayout} |
	layout _ ExtentLayout make: (PointPos make: 2000 with: 12). "This'll do fer now. fix"
	table _ MuTable make: HeaperSpace make.
	table at: (HeaperAsPosition make: AttributedTextModel) introduce: (FMTextBuilder make: layout).
	table at: (HeaperAsPosition make: ListModel)
		introduce: (FMDirectedListBuilder make: (BoundingListComp make: ListStyle defaultVertical)).
	^FMScaffold make: table with: Scaffold fluidVar! !

!LinkMakerWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel}

	(myEndListSelection basicCast: XnModel) == sender 
		ifTrue: [
		myEndListSelection selection isEmpty
			ifTrue: [myCurrentEndDescription _ NULL]
			ifFalse: [myCurrentEndDescription _ (myEndList fetch:
						((myEndListSelection selectionPoint cast: IntegerPos)
							asIntegerVar)) cast: AttributedTextModel].
		self changed: (RegionUR make: (Sequence string: 'CurrentEnd') asRegion)].
	(myCurrentFromEndSet basicCast: XnModel) == sender
		ifTrue: [self changed: (RegionUR make: (Sequence string: 'FromEnds')  asRegion)].
	(myCurrentTooEndSet basicCast: XnModel) == sender
		ifTrue: [self changed: (RegionUR make: (Sequence string: 'TooEnds')  asRegion)]! !

!LinkMakerWindowModel methodsFor: 'actions'!

{void} clearAll

	myCurrentFromEndSet wipe: myCurrentFromEndSet domain.
	myCurrentTooEndSet wipe: myCurrentTooEndSet domain.
	myEndListSelection select: IntegerRegion make.!

{void} linkTypeChoice: index {IntegerVar} 
	"This method receives the index in the linkTypesList for
the selected 
	link type."

	myCurrentLinkType _ (self linkTypes fetch: index) cast:
ID.!

{void} makeFromEnd

	| realEnds {LinkEndsModel} |
	[TapestryAppModel] USES.
	myEndListSelection selection isEmpty ifTrue: [^ VOID].
	realEnds _ Application fluidVar linkEnds.
	myEndListSelection selection stepper forEach: [:pos
{IntegerPos} |
		myCurrentFromEndSet insert: (myCurrentFromEndSet count)
with: (realEnds fetch: pos asIntegerVar)].
	^ VOID!

{void} makeLink

	(myCurrentFromEndSet isEmpty and: [myCurrentFromEndSet isEmpty])
		ifTrue: [^ VOID].
	
	IntegerVar0 almostTo: myCurrentFromEndSet count do: [:fromIdx {IntegerVar} | | from {LinkEnd} |
		from _ (myCurrentFromEndSet fetch: fromIdx) cast: LinkEnd.
		IntegerVar0 almostTo: myCurrentTooEndSet count do: [:tooIdx {IntegerVar} | | to {LinkEnd} |
			to _ (myCurrentTooEndSet fetch: tooIdx) cast: LinkEnd.
			Application fluidVar createLink: from with: to with: myCurrentLinkType with: NULL]]!

{void} makeTooEnd

	| realEnds {LinkEndsModel} |
	myEndListSelection selection isEmpty ifTrue: [^ VOID].
	realEnds _ Application fluidVar linkEnds.
	myEndListSelection selection stepper forEach: [:pos
{IntegerPos} |
		myCurrentTooEndSet insert: (myCurrentTooEndSet count)
with: (realEnds fetch: pos asIntegerVar)].
	^ VOID! !

!LinkMakerWindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	super printOn: oo.
	oo	<< 'myEndList'  << myEndList
		<< 'myEndListSelection'  << myEndListSelection  
		<< 'myCurrentEditors' << myCurrentEditors 
		<< 'myCurrentReaders'  << myCurrentReaders
		<< 'myCurrentEndDescription'  << myCurrentEndDescription 
		<< 'myCurrentFromEndSet'  << myCurrentFromEndSet 
		<< 'myCurrentTooEndSet'  << myCurrentTooEndSet  
		<< 'myCurrentLinkType'  << myCurrentLinkType << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkMakerWindowModel class
	instanceVariableNames: ''!

(LinkMakerWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkMakerWindowModel */
friend SPTR(LinkMakerWindowModel)  linkMakerWindowModel
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerWindowModel class methodsFor: 'pseudoConstructors'!

make
	^ self create! !