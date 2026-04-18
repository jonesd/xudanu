'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:49 pm'!

FMBuilder subclass: #FMTextBuilder
	instanceVariableNames: 'myLayout {AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMTextBuilder comment:
'This text builder creates a non-editable, but directed text pane.  This pane will therefore automatically update when the text changes, but there will be no controllers, hence no way to alter the text directly through this pane.'!

(FMTextBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextBuilder */
friend SPTR(FMTextBuilder) fMTextBuilder ();
friend SPTR(FMTextBuilder)  fMTextBuilder (AbstractLayout * withLayout);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextBuilder methodsFor: 'private: creation'!

create
	super create.
	myLayout _ NULL!

create: withLayout {AbstractLayout}
	super create.
	myLayout _ withLayout! !

!FMTextBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper as: AttributedTextModel}
	| tv {FMTextViewer} td {FMParaDirector} atm {AttributedTextModel} listM {ListModel} lmv {ListMultiViewer} bld {FMBuilding} sm {FMSplitTextModel} topModel {FMATMModel} |
	atm _ obj cast: AttributedTextModel.
	topModel _ FMATMModel make: atm.
	listM _ ListModel make.
	Scaffold fluidBind: (FMScaffold 
			make: FMTextRunModel
			with: FMRunBuilder make
			with: Scaffold fluidGet)
		during: 
			[sm _ FMSplitTextModel make: topModel.
			td _ FMParaDirector
						make: topModel
						with: listM
						with: sm.
			atm addDependent: td.
			lmv _ ListMultiViewer make: listM with: (BoundingListComp make: ListStyle defaultVertical).
			tv _ FMTextViewer
						make: td
						with: lmv
						with: myLayout.
			bld _ FMDirectorBuilding
						make: tv
						with: NULL
						with: td].
	myLayout ~~ NULL ifTrue: [tv fixedCompose].
	^bld! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMTextBuilder class
	instanceVariableNames: ''!

(FMTextBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextBuilder */
friend SPTR(FMTextBuilder) fMTextBuilder ();
friend SPTR(FMTextBuilder)  fMTextBuilder (AbstractLayout * withLayout);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextBuilder class methodsFor: 'pseudo constructor'!

make
	^ self create!

make: withLayout {AbstractLayout}
	^ self create: withLayout! !