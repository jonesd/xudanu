'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:00 pm'!

FMBuilder subclass: #ReferenceListBuilder
	instanceVariableNames: 'myWindow {DocumentWindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
ReferenceListBuilder comment:
'Builds a vertical list of reference views, along with a DoubleClickAction to follow links and a MultiSelectionController to select them

	mySelection {SelectionObject}
		The selection model for selecting the references'!

(ReferenceListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceListBuilder methodsFor: 'build'!

{FMBuilding} build: model {Heaper as: (ListModel of: Reference)} 
	"build a link pane view for a text doc."
 
	| viewers {TableAccumulator of: Viewer} viewer {ListMultiViewer} controller {FMController} multi {MultiController} viewList {ListModel of: Viewer} listD {FMListDirector} |
	viewers _ MuArray arrayAccumulator.
	(model cast: ListModel) asTable stepper forEach: [:ref {Reference} |
		viewers step: (Scaffold fluidGet build: ref) view].
	viewer _ ListMultiViewer make: (viewList _ ListModel make: (viewers value cast: IntegerTable))
							  with: (BoundingListComp make: ListStyle defaultVertical).
	controller _
		SelectionGate make: viewer
					   with: (multi _ MultiController make:
					   		  (MuArray array: (MultiSelectionController make: viewer
					   		  											with: myWindow referencesSelection)
										with: (DoubleClickAction make: (FollowThunk make: myWindow)))).
	controller _ MultiController make: (MuArray array: controller
												with: (FMHighLevelAction make: (UInt8Array string: 'MENU')
																		  with: self actionTable)).
	listD _ FMListDirector
				make: (model basicCast: ListModel)
				with: viewList
				with: multi.
	^FMDirectorBuilding
		make: (MultiSelectionViewer
				make: viewer
				with: myWindow referencesSelection
				with: (VariableModel make: HighlightAll make))
		with: controller
		with: listD! !

!ReferenceListBuilder methodsFor: 'create'!

create: window {DocumentWindowModel}
	super create.
	myWindow _ window! !

!ReferenceListBuilder methodsFor: 'private: structures'!

{ScruTable of: PackOBits and: Thunk} actionTable
	| menuActions {MuTable of: PackOBits and: Thunk} "tThunk
{Thunk}" theVarModel {VariableModel of: FMBuilder} |

	menuActions _ MuTable make: SequenceSpace make.
	theVarModel _ (myWindow referenceBuilder cast:
FMDeferredBuilder) builderModel.
	menuActions at: (Sequence string: 'twoLineFormat') introduce: 
		(AssignmentThunk make: theVarModel with:
TwoLineReferenceBuilder make).
	menuActions at: (Sequence string: 'fullLinkFormat') introduce:
		(AssignmentThunk make: theVarModel with:
FullReferenceBuilder make).
	menuActions at: (Sequence string: 'shortLinkFormat') introduce:
		(AssignmentThunk make: theVarModel with:
ShortReferenceBuilder make).
	menuActions at: (Sequence string: 'readerLinkFormat') introduce: 
		(AssignmentThunk make: theVarModel with:
TwoLineReferenceBuilder make).
	^ menuActions
	
	"menuActions at: (PackOBits make: #twoLineFormat) introduce: 
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: TwoLineReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk))).
	menuActions at: (PackOBits make: #fullLinkFormat) introduce:
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: FullReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk))).
	menuActions at: (PackOBits make: #shortLinkFormat) introduce:
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: ShortReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk))).
	menuActions at: (PackOBits make: #readerLinkFormat) introduce: 
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: TwoLineReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk)))."! !

!ReferenceListBuilder methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<< 'myWindow = '  << myWindow! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReferenceListBuilder class
	instanceVariableNames: ''!

(ReferenceListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceListBuilder class methodsFor: 'make'!

make: window {DocumentWindowModel}
	^self create: window! !