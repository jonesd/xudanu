'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:46 pm'!

FMTextDirector subclass: #FMParaDirector
	instanceVariableNames: '
		myTextModel {FMTextModel}
		mySplit {FMSplitTextModel}
		myLines {MuArray of: FMLineDirector}
		myLineViews {ListModel of: VIewer}
		myLayout {AbstractLayout}
		myControllerArray {IntegerTable of: FMController}
		myLineApplyDsp {FMApplyDspSelection}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMParaDirector getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMParaDirector */
friend SPTR(FMParaDirector) fMParaDirector (
		FMTextModel * tm, 
		ListModel * lm, 
		FMSplitTextModel * sm, 
		ScruTable * mc, 
		FMApplyDspSelection * applyDsp);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMParaDirector methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel unused} 
	
	(ur isKindOf: InsertionUR)
		ifTrue: [self updateInsertion: (ur basicCast: InsertionUR)]
	ifFalse: [(ur isKindOf: DeletionUR)
			ifTrue: [self updateDeletion: (ur basicCast: DeletionUR)]
	ifFalse: [(ur isKindOf: RegionUR)
			ifTrue: [self updateRegion: (ur basicCast: RegionUR)]
	ifFalse: [Heaper BLAST: #UNKNOWN.U.UPDATE]]]! !

!FMParaDirector methodsFor: 'private: updating'!

{void} updateDeletion: deletur {DeletionUR} 
	deletur region isEmpty not assert: 'deleting an empty region!!'.
	deletur region isSimple
		ifTrue: [self compose: (deletur region quickCast: IntegerRegion) start 
				with: deletur region count negated]
		ifFalse: [deletur region simpleRegions 
					forEach: [:simReg {IntegerRegion} | 
						self compose: simReg start with: simReg count negated]]!

{void} updateInsertion: insertur {InsertionUR} 

	self compose: insertur index with: insertur count!

{void} updateRegion: regur {RegionUR}
	self recompose: (regur region cast: IntegerRegion)! !

!FMParaDirector methodsFor: 'private: composing'!

{void} compose: startingAt {IntegerVar} with: delta {IntegerVar} 
	"This method rebuilds the composition starting at the specified 
	location. This is used after a change has occurred. The delta 
	parameter is the number of characters added or removed. This is 
	present to allow this algorithm to decide when the new composition 
	is completed. For example, if the update is an insert of 1 character, 
	the first line that balances the line count increases with the line count
	decreases plus the delta indicates complete composition."

	| dLine {FMSplitTextModel} lastLine {IntegerVar} reComp {BooleanVar}
	curDelta {IntegerVar} curLine {IntegerVar} composedTo {IntegerVar} 
	composeEnd {IntegerVar} startingCount {IntegerVar} yLimit {IntegerVar}
	paraHeight {IntegerVar} |
	
	curDelta _ delta.
	curLine _ mySplit splitFor: startingAt.
	lastLine _ myLines count - 1.
	((curLine > lastLine) and: [lastLine >= IntegerVar0]) ifTrue: [curLine _ lastLine].
	composedTo _ (mySplit dspAt: curLine) translation.
	composeEnd _ myTextModel charCount.
	yLimit _ myLayout extent y.
	paraHeight _ IntegerVar0.
	[curDelta ~~ IntegerVar0 and: [composedTo < composeEnd 
		and: [paraHeight < yLimit]]] whileTrue: [
		(curLine <= lastLine) 
			ifTrue: [dLine _ (mySplit get: curLine) cast: FMSplitTextModel.
				reComp _ true]
			ifFalse: [dLine _ FMSplitTextModel make: mySplit.
				mySplit append: dLine.
				reComp _ false].
		startingCount _ dLine charCount.
		reComp
			ifTrue: [self recomposeLine: curLine]
			ifFalse: [self composeLine: dLine with: curLine].
		composedTo _ composedTo + dLine charCount.
		curDelta _ curDelta + startingCount - dLine charCount.
		paraHeight _ paraHeight + ((myLines intFetch: curLine) cast: FMLineDirector) lineHeight.
		curLine _ curLine + 1].
	[curDelta < IntegerVar0 and: [curLine <= lastLine]] whileTrue: [
		curDelta _ curDelta + (mySplit get: lastLine) charCount.
		(myLines intGet: lastLine) destroy.
		myLines intWipe: lastLine.
		mySplit wipe: lastLine.
		lastLine _ lastLine - 1].
	"(curDelta == IntegerVar0 or: [paraHeight >= yLimit]) assert: 'Compose did not terminate correctly!!'."!

{void} composeLine: dLine {FMSplitTextModel} with: index {IntegerVar}
	| newDirector {FMLineDirector} newBuilding {FMDirectorBuilding} selDsp {FMSelectDsp}
	 lineBuild {FMLineBuilder} |
	 myLineApplyDsp == NULL
	 	ifTrue: [selDsp _ NULL]
	 	ifFalse: [selDsp _ FMSelectDsp make: dLine with: myLineApplyDsp].
	lineBuild _ FMLineBuilder make: selDsp.
	Scaffold fluidBind: (FMScaffold make: FMSplitTextModel with: lineBuild with: self scaffold)
		during: [newBuilding _ (Scaffold fluidGet build: dLine) cast: FMDirectorBuilding].
	newDirector _ newBuilding director cast: FMLineDirector.
	newDirector composeWith: myLayout.
	myControllerArray ~~ NULL ifTrue: [
		myControllerArray atInt: index store: newBuilding controller].
	myLines atInt: index store: newBuilding director.
	myLineViews replace: index with: newBuilding view.
	^ VOID!

{void} recompose: region {IntegerRegion} 
	"This method will recompose the text within the region specified (and 
	a bit more) and then ensure that the region outside the specified 
	region does not need recomposition as a result of the recomposition 
	of the text within the region."
 
	| startPos {IntegerVar} lastPos {IntegerVar} first {IntegerVar} last {IntegerVar}
	 delta {IntegerVar} changeReg {IntegerRegion} tmpWrd {MuWordArray} |
	region isEmpty ifTrue: [^ VOID].
	mySplit splitCount == IntegerVar0 
		ifTrue: [self compose: IntegerVar0 with: mySplit charLimit].
	tmpWrd _ mySplit chars.
	changeReg _ (tmpWrd domain) cast: IntegerRegion.
	changeReg _ ((region intersect: changeReg) asSimpleRegion) quickCast: IntegerRegion.
	(changeReg isEmpty not and: [changeReg isBoundedBelow]) 
		ifTrue: [startPos _ changeReg start] 
		ifFalse: [startPos _ IntegerVar0].
	(changeReg isEmpty not and: [changeReg isBoundedAbove])
		ifTrue: [lastPos _ changeReg stop]
		ifFalse: [lastPos _ mySplit splitCount].
	first _ mySplit splitFor: startPos.
	last _ mySplit splitFor: lastPos. "is this useful?"
	delta _ IntegerVar0.
	first to: last do: [:lineIdx {IntegerVar} | | dLine {FMTextModel} starting {IntegerVar} |
		dLine _ mySplit get: lineIdx.
		starting _ dLine charCount.
		self recomposeLine: lineIdx.
		delta _ delta + (starting - dLine charCount)].
	delta ~~ IntegerVar0 ifTrue: [self compose: lastPos with: delta]!

{void} recomposeLine: index {IntegerVar} 
	((myLines intGet: index) quickCast: FMTextDirector) composeWith: myLayout.! !

!FMParaDirector methodsFor: 'private: creation'!

create: tm {FMTextModel} with: list {ListModel} with: splitM {FMSplitTextModel} with: mc {ScruTable} with: applyDsp {FMApplyDspSelection}
	super create.
	myTextModel _ tm.
	myLineViews _ list.
	mySplit _ splitM.
	myLines _ MuArray array.
	myLayout _ NULL.
	applyDsp == NULL
		ifTrue: [myControllerArray _ NULL]
		ifFalse: [myControllerArray _ mc cast: IntegerTable].
	myLineApplyDsp _ applyDsp! !

!FMParaDirector methodsFor: 'composing'!

{void} composeWith: layout {AbstractLayout} 
	myLayout _ layout.
	"clear all line viewers"
	myLineViews wipe: myLineViews asTable domain.
	mySplit splitCount - 1 to: IntegerVar0 by: -1
		do: [:idx {IntegerVar} | mySplit wipe: idx].
	myLines stepper forEach: [:ld {FMLineDirector} | ld destroy].
	myLines _ MuArray array.
	myControllerArray ~~ NULL ifTrue: [
		(myControllerArray domain stepper: (IntegerSpace make getDescending))
			forEach: [:idx {IntegerPos} | myControllerArray wipe: idx]].
	self compose: IntegerVar0 with: myTextModel charCount! !

!FMParaDirector methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' on (' << myTextModel << ' splits: ' << mySplit << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMParaDirector class
	instanceVariableNames: ''!

(FMParaDirector getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMParaDirector */
friend SPTR(FMParaDirector) fMParaDirector (
		FMTextModel * tm, 
		ListModel * lm, 
		FMSplitTextModel * sm, 
		ScruTable * mc, 
		FMApplyDspSelection * applyDsp);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMParaDirector class methodsFor: 'pseudo constructors'!

make: tm {FMTextModel} with: lm {ListModel} with: sm {FMSplitTextModel} with: mc {ScruTable default: NULL} with: applyDsp {FMApplyDspSelection default: NULL} 
	^self
		create: tm
		with: lm
		with: sm
		with: mc
		with: applyDsp! !

!FMParaDirector class methodsFor: 'smalltalk: defaults'!

make: tm {FMTextModel} with: lm {ListModel} with: sm {FMSplitTextModel}
	^ self create: tm with: lm with: sm with: NULL with: NULL! !