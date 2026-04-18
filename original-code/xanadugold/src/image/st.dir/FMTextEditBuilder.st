'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:50 pm'!

FMBuilder subclass: #FMTextEditBuilder
	instanceVariableNames: 'myLayout {AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMTextEditBuilder comment:
'This is the new official text builder for FM.  It currently builds an editable, directed text pane on a selected text model. '!

(FMTextEditBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextEditBuilder */
friend SPTR(FMTextEditBuilder) fMTextEditBuilder ();
friend SPTR(FMTextEditBuilder)  fMTextEditBuilder (AbstractLayout * withLayout);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextEditBuilder methodsFor: 'private: creation'!

create
	super create.
	myLayout _ NULL!

create: withLayout {AbstractLayout}
	super create.
	myLayout _ withLayout! !

!FMTextEditBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper as: SelectedTextModel} 

	| tv {FMTextViewer} td {FMParaDirector} stm {SelectedTextModel}
	 listM {ListModel} lmv {ListMultiViewer} bld {FMBuilding} tm {MultiController}
	 controlAcc {TableAccumulator} paraApplyDsp {FMApplyDspSelection}
	 sm {FMSplitTextModel} directedMultiController {MultiController}
	 controllers {MuArray} paraSelDsp {FMSelectDsp}
	 lineApplyDsp {FMApplyDspSelection} topModel {FMATMModel}
	 focus {FocusController} lv {Viewer} |
	 
	stm _ obj cast: SelectedTextModel.
	topModel _ FMATMModel make: stm.
	paraApplyDsp _ FMApplyDspSelection make: stm selection.
	lineApplyDsp _ FMApplyDspSelection make: paraApplyDsp.
	listM _ ListModel make.
	Scaffold fluidBind: (FMScaffold make: FMTextRunModel 
			with: (FMRunBuilder make: lineApplyDsp) 
			with: Scaffold fluidGet) 
	during: [
		sm _ FMSplitTextModel make: topModel.
		paraSelDsp _ FMSelectDsp make: sm with: paraApplyDsp.
		directedMultiController _ MultiController make: (controllers _ MuArray array).
		td _ FMParaDirector make: topModel with: listM with: sm
					with: controllers with: lineApplyDsp].
	stm addDependent: td.
	lmv _ ListMultiViewer make: listM 
					with: (BoundingListComp make: (ListStyle defaultVertical)).
	tv _ FMTextViewer make: td with: lmv with: myLayout.
	controlAcc _ MuArray arrayAccumulator.
	controlAcc step: (MultiSelectionController make: tv with: paraSelDsp).
	controlAcc step: directedMultiController.
	[controlAcc step: (ClickAction make: 
							(TranscriptThunk make: 'selected item:' 
									with: stm selection))] smalltalkOnly.
	tm _ MultiController make: (controlAcc value cast: ScruTable).
	lv _ SuperLayoutViewer make: tv with: myLayout.
	focus _ FocusController make: lv with:
				(FMTextEditor make: stm with: stm selection).
	controlAcc _ MuArray arrayAccumulator.
	controlAcc step: (SelectionGate make: lv with: tm).
	controlAcc step: focus.
	bld _ FMDirectorBuilding make: lv 
				with: (MultiController make: (controlAcc value cast: ScruTable))
									with: td.
	myLayout ~~ NULL ifTrue: [tv fixedCompose].
	^ bld! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMTextEditBuilder class
	instanceVariableNames: ''!

(FMTextEditBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextEditBuilder */
friend SPTR(FMTextEditBuilder) fMTextEditBuilder ();
friend SPTR(FMTextEditBuilder)  fMTextEditBuilder (AbstractLayout * withLayout);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextEditBuilder class methodsFor: 'pseudo constructor'!

make
	^ self create!

make: withLayout {AbstractLayout}
	^ self create: withLayout! !