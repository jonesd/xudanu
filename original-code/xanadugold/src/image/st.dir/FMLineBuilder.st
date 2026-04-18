'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:45 pm'!

FMBuilder subclass: #FMLineBuilder
	instanceVariableNames: '
		mySelDsp {FMSelectDsp}
		myListStyle {ListStyle}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMLineBuilder comment:
'The purpose of FMLineBuilder is, of course, to build lines.  It is created with a FMSelectDsp selection which is created by the FMTextBuilder.  This select dsp is wired to properly update a FMApplyDspSelection when there is a mouseDown in the listmultiviewer created by this builder.  Simple enough?  ok, ok, what is going on with controllers is that a hierarchy that approximately matches the viewer hierarchy must be created.  As part of this, a FMSelectDsp selection object is created for each listmultiview in the text pane.  These selections map the pane index of the listmultiview into a dsp corresponding to the origin of the text in that pane.  So, if there are multiple runs in a line, the FMSelectDsp created for that line chooses the correct dsp for the start of the run.  This dsp is then used in later calculations to figure out which character in the (global) text was being pointed at when the event occurred.'!

(FMLineBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMLineBuilder methodsFor: 'creation'!

create: aSelect {FMSelectDsp}
	super create.
	mySelDsp _ aSelect.
	myListStyle _ ListStyle make: Orientation xAxis with: IntegerVar0.
	myListStyle setSpacing: IntegerVar0.! !

!FMLineBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 
	| aLineM {FMSplitTextModel} aDirector {FMLineDirector} aViewer {Viewer}
	 aController {FMController} vlm {ListModel of: Viewer} ca {MuArray} |
	aLineM _ obj cast: FMSplitTextModel.
	vlm _ ListModel make.
	"list of run viewers"
	aViewer _ ListMultiViewer make: vlm with: (BoundingListComp make: myListStyle).
	mySelDsp == NULL
		ifTrue: [aController _NULL. ca _ NULL]
		ifFalse: [
			"array for controllers"
			ca _ MuArray array.
			aController _ MultiController make: (MuArray array: 
								(MultiSelectionController make: aViewer with: mySelDsp)
							with: (MultiController make: ca))].
	aDirector _ FMLineDirector make: aLineM with: vlm with: ca.
	^FMDirectorBuilding make: aViewer with: aController with: aDirector! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMLineBuilder class
	instanceVariableNames: ''!

(FMLineBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMLineBuilder class methodsFor: 'pseudo constructors'!

make: selDsp {FMSelectDsp}
	^ self create: selDsp! !