'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:46 pm'!

FMTextDirector subclass: #FMLineDirector
	instanceVariableNames: '
		myLine {FMSplitTextModel}
		myRunDirectors {MuArray of: FMRunDirector}
		myRunViews {ListModel of: Viewer}
		myLayout {AbstractLayout}
		myControllerArray {MuArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMLineDirector getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMLineDirector */
friend class FMLineBuilder;
friend SPTR(FMLineDirector) fMLineDirector (FMSplitTextModel * onSplit, ListModel OF1(Viewer) * viewL, XuArray OF1(FMController) * contA);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMLineDirector methodsFor: 'schnerting'!

{XnRegion} displayRegionFor: modelRegion {XnRegion unused}

	"This method returns a region that represents the portion
of the display
	that represents the specified model region"
	self unimplemented.
	^NULL!

{XnRegion} modelRegionFor: displayRegion {XnRegion unused}

	"This method returns a region that represents the portion
of the model
	contained by the specified displayRegion."
	self unimplemented.
	^NULL! !

!FMLineDirector methodsFor: 'accessing'!

{IntegerVar} count
	"This method returns the number of characters that are correctly
	(according to my algorithm) composed into my layout"

	myLayout == NULL ifTrue: [Heaper BLAST: #NOT.U.LAYED.U.OUT].
	^ myLine charCount!

{IntegerVar} lineHeight

	| hite {IntegerVar} |
	hite _ IntegerVar0.
	myRunDirectors stepper forEach: [:rd {FMRunDirector} |
		hite < (rd composition displayHeight)
			ifTrue: [hite _ rd composition displayHeight]].
	^ hite! !

!FMLineDirector methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myLine  << ')'! !

!FMLineDirector methodsFor: 'private: composing'!

{void} cleanup: firstUnusedRun {IntegerVar} 
	| oldCount {IntegerVar} | 
	oldCount _ myRunDirectors count.
	(oldCount - 1) downTo: firstUnusedRun do: 
		[:idx {IntegerVar} | 
		(myRunDirectors intGet: idx) destroy.
		myRunDirectors intWipe: idx.
		myControllerArray ~~ NULL ifTrue: [
			(myControllerArray intGet: idx) destroy.
			myControllerArray intWipe: idx].
		myLine wipe: idx].
	firstUnusedRun < oldCount
		ifTrue: [myRunViews wipe: (IntegerRegion make: firstUnusedRun with: oldCount)]!

{void} composeFrom: startOffset {IntegerVar} 
	"This method composes the line starting at the specified offset within 
	the line. It is responsible for setting the maximum composed width 
	and the normal break width. It may have to create new runs and 
	run directors in order to compose the line "
	
	| composeMax {IntegerVar} curRun {IntegerVar} composedWidth {IntegerVar}
	 composeStop {CompositorEnum} lastRun {IntegerVar} charLimit {IntegerVar} charsComposed {IntegerVar} |
	composeMax _ myLayout extent x.
	curRun _ myLine splitFor: startOffset.
	lastRun _ myLine splitCount - 1.
	composedWidth _ IntegerVar0.
	composeStop _ #endOfRun.
	charLimit _ myLine charLimit.
	charsComposed _ IntegerVar0.
	[composeStop == #endOfRun and: 
		[composedWidth < composeMax and: 
		[charsComposed < charLimit]]] whileTrue: [
		| dView {FMTextRunViewer} dRun {FMTextRunModel} reComp {BooleanVar} |
		(curRun <= lastRun)
			ifTrue: [dRun _ (myLine get: curRun) cast: FMTextRunModel.
				reComp _ true]
			ifFalse: [dRun _ FMTextRunModel make: myLine.
				myLine append: dRun.
				reComp _ false].
		reComp 
			ifTrue: [self recomposeRun: dRun with: curRun with: composedWidth]
			ifFalse: [self composeRun: dRun with: curRun with: composedWidth].
		dView _ (myRunViews get: curRun) cast: FMTextRunViewer.
		composedWidth _ composedWidth + dView composition displayWidth.
		composeStop _ dView composition reason.
		charsComposed _ charsComposed + dRun charCount.
		curRun _ curRun + 1].
	myLine setMax: myLine charCount.
	composeStop == #lineOverflow 
		ifTrue: [self composeLineBreak: curRun - 1]
		ifFalse: [self cleanup: curRun]!

{void} composeLineBreak: lastUsefulRun {IntegerVar}
	"This method is used to backup the composition to a
reasonable line break."
	
	| curRun {IntegerVar} foundBreak {BooleanVar} |
	curRun _ lastUsefulRun.
	foundBreak _ false.
	[foundBreak or: [curRun < IntegerVar0]] whileFalse: [|
runDir {FMRunDirector} dCompos {FMComposition} |
		runDir _ (myRunDirectors intGet: curRun) cast:
FMRunDirector.
		dCompos _ runDir breakPosition.
		dCompos reason == #endOfRun 
			ifTrue: [runDir setComposition: dCompos.
				foundBreak _ true]
			ifFalse: [curRun _ curRun - 1]].
	foundBreak ifFalse: [curRun _ lastUsefulRun].
	self cleanup: curRun + 1!

{FMDirectorBuilding} composeRun: aRunModel {FMTextRunModel} with: runIndex {IntegerVar} with: leftEdge {IntegerVar}

	"First use brute strength, but by checking the charCount for the runModel,
	it can be determined if it has been composed before.  If so, then a recompose
	is in order, rather than a full build"
	
	| newBuild {FMDirectorBuilding} newDirector {FMRunDirector} |
	newBuild _ (self scaffold build: aRunModel) cast: FMDirectorBuilding.
	newDirector _ newBuild director cast: FMRunDirector.
	myRunViews insert: runIndex with: newBuild view.
	newDirector composeWith: (self runLayout: leftEdge).
	myControllerArray ~~ NULL ifTrue: [
		myControllerArray atInt: runIndex store: newBuild controller].
	myRunDirectors atInt: runIndex store: newDirector.
	^ newBuild!

{void} recomposeRun: aRunModel {FMTextRunModel unused}
with: runIndex {IntegerVar} with: leftEdge {IntegerVar}
	
	((myRunDirectors intGet: runIndex) cast:
FMTextDirector) composeWith: (self runLayout: leftEdge).!

{AbstractLayout} runLayout: newLeft {IntegerVar}

	| width {IntegerVar} height {IntegerVar} |
	newLeft == IntegerVar0
		ifTrue: [^ myLayout].
	width _ myLayout extent x - newLeft.
	height _ myLayout extent y.
	^ RegionLayout make.XuPoint: (PointPos make: width with: height)! !

!FMLineDirector methodsFor: 'composing'!

{void} composeWith: layout {AbstractLayout} 
	"This method is used to compose the model into the layout. Internal 
	state is set during the layout process to allow later display or 
	recompose."
	
	myLayout _ layout.
	self composeFrom: IntegerVar0! !

!FMLineDirector methodsFor: 'private: creation'!

create: onModel {FMSplitTextModel} with: viewers {ListModel of: Viewer} with: controllers {MuArray of: FMController}
	super create.
	myLine _ onModel.
	myRunViews _ viewers.
	myControllerArray _ controllers.
	myLayout _ NULL.
	myRunDirectors _ MuArray array.!

{void} destruct
	myRunViews _ NULL.
	myLayout _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMLineDirector class
	instanceVariableNames: ''!

(FMLineDirector getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMLineDirector */
friend class FMLineBuilder;
friend SPTR(FMLineDirector) fMLineDirector (FMSplitTextModel * onSplit, ListModel OF1(Viewer) * viewL, XuArray OF1(FMController) * contA);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMLineDirector class methodsFor: 'pseudo constructors'!

make: onSplit {FMSplitTextModel} with: viewL {ListModel of: Viewer} with: contA {MuArray of: FMController}
	^ self create: onSplit with: viewL with: contA! !