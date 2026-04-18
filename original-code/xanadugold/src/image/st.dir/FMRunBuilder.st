'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:47 pm'!

FMBuilder subclass: #FMRunBuilder
	instanceVariableNames: 'myApplyDsp {FMApplyDspSelection}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMRunBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMRunBuilder */
friend SPTR(FMRunBuilder) fMRunBuilder (FMApplyDspSelection * onApply);
friend SPTR(FMRunBuilder) fMRunBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMRunBuilder methodsFor: 'building'!

{FMBuilding} build: obj {Heaper} 
	| aRunM {FMTextRunModel} aDirector {FMRunDirector} aViewer {FMTextRunViewer}
	 aController {FMController} |
	 [FMComposer] USES.
	aRunM _ obj cast: FMTextRunModel.
	aViewer _ FMTextRunViewer make: aRunM with: (FMComposer fMComposer: aRunM attributes).
	aDirector _ FMRunDirector make: aRunM with: aViewer.
	myApplyDsp == NULL
		ifTrue: [aController _ NULL]
		ifFalse: [aController _ MultiSelectionController make: aViewer with: myApplyDsp].
	^FMDirectorBuilding make: aViewer with: aController with: aDirector! !

!FMRunBuilder methodsFor: 'protected: creation'!

create: applyDsp {FMApplyDspSelection}

	super create.
	myApplyDsp _ applyDsp! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMRunBuilder class
	instanceVariableNames: ''!

(FMRunBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMRunBuilder */
friend SPTR(FMRunBuilder) fMRunBuilder (FMApplyDspSelection * onApply);
friend SPTR(FMRunBuilder) fMRunBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMRunBuilder class methodsFor: 'pseudoconstructors'!

make
	^ self create: NULL!

make: onApply {FMApplyDspSelection}
	^ self create: onApply! !