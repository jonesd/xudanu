'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:48 pm'!

FMBuilder subclass: #FMStaticTextBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMStaticTextBuilder comment:
'This text builder creates a non-editable (and perhaps non-directed) text pane.  There will be no controllers.'!

(FMStaticTextBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMStaticTextBuilder */
friend SPTR(FMStaticTextBuilder) fMStaticTextBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMStaticTextBuilder methodsFor: 'private: creation'!

create
	super create! !

!FMStaticTextBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper as: AttributedTextModel} 
	
	| tv {FMTextViewer} td {FMParaDirector} atm {AttributedTextModel} listM {ListModel}
	 lmv {ListMultiViewer} bld {FMBuilding} sm {FMSplitTextModel} topModel {FMATMModel} |
	
	atm _ obj cast: SelectedTextModel.
	topModel _ FMATMModel make: atm.
	listM _ ListModel make.
	Scaffold fluidBind: (FMScaffold make: FMTextRunModel 
			with: (FMRunBuilder make) 
			with: Scaffold fluidGet) 
	during: [
		sm _ FMSplitTextModel make: topModel.
		td _ FMParaDirector make: topModel with: listM with: sm.
		atm addDependent: td.
		lmv _ ListMultiViewer make: listM with: (BoundingListComp make: (ListStyle defaultVertical)).
		tv _ FMTextViewer make: td with: lmv.
		bld _ FMDirectorBuilding make: tv with: NULL with: td].
	^ bld! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMStaticTextBuilder class
	instanceVariableNames: ''!

(FMStaticTextBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMStaticTextBuilder */
friend SPTR(FMStaticTextBuilder) fMStaticTextBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMStaticTextBuilder class methodsFor: 'pseudo constructor'!

make
	^ self create! !