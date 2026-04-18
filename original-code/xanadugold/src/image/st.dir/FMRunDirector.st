'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:47 pm'!

FMTextDirector subclass: #FMRunDirector
	instanceVariableNames: '
		myRun {FMTextRunModel}
		myRunView {FMTextRunViewer}
		myLayout {AbstractLayout}
		myComposer {FMComposer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMRunDirector getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMRunDirector */
friend SPTR(FMRunDirector) fMRunDirector (FMTextRunModel * onRun, FMTextRunViewer * viewer);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMRunDirector methodsFor: 'accessing'!

{FMComposer} composer
	^ myComposer!

{FMComposition} composition
	^ myRunView composition! !

!FMRunDirector methodsFor: 'composing'!

{FMComposition} breakPosition
	"This method is invoked by a line director to find an appropriate 
	break position within the line. The line director is then responsible 
	for setting the correct lengths of the runs."

	^ myComposer uncompose: myRun composedChars with: myRunView composition!

{void} composeWith: layout {AbstractLayout} 
	"This method is used to compose the model into the layout. Internal 
	state is set during the layout process to allow later display or 
	recompose."
	
	myLayout _ layout.
	self compose: myRun chars
		with: myRun attributes
		with: layout!

{void} setComposition: newComposition {FMComposition}
	"This method is invoked by a line director to force a composition on a run director."

	myRun setCharCount: newComposition count.
	myRun setMax: newComposition count.
	myRunView setComposition: newComposition! !

!FMRunDirector methodsFor: 'private: composing'!

{void} compose: chars {MuWordArray} with: attrs
{AttributeGroup unused} with: layout {AbstractLayout} 
	"This method is implemented in system specific subclasses
to 
	do the actual layout of characters. Note that this is a
run compose, 
	not a line compose. This must be changed later."

	| fugue {FMComposition} |
	fugue _ myComposer compose: chars with: layout.
	myRun setCharCount: fugue count.
	myRun setMax: fugue count.
	myRunView setComposition: fugue! !

!FMRunDirector methodsFor: 'protected: creation'!

create: onModel {FMTextRunModel} with: view {FMTextRunViewer}
	
	super create.
	[FMComposer] USES.
	myRun _ onModel.
	myRunView _ view.
	myLayout _ NULL.
	myComposer _ FMComposer fMComposer: onModel attributes!

{void} destruct
	
	myRun _ NULL.
	myRunView _ NULL.
	myLayout _ NULL.
	myComposer _ NULL.
	super destruct! !

!FMRunDirector methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myRun  << ')'! !

!FMRunDirector methodsFor: 'protected: setting'!

{void} viewer: newViewer {FMTextRunViewer}

	myRunView _ newViewer! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMRunDirector class
	instanceVariableNames: ''!

(FMRunDirector getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMRunDirector */
friend SPTR(FMRunDirector) fMRunDirector (FMTextRunModel * onRun, FMTextRunViewer * viewer);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMRunDirector class methodsFor: 'pseudo constructors'!

make: onRun {FMTextRunModel} with: viewer {FMTextRunViewer}
	^ self create: onRun with: viewer! !