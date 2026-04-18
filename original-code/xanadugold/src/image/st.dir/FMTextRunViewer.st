'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:51 pm'!

LeafViewer subclass: #FMTextRunViewer
	instanceVariableNames: '
		myTextRun {FMTextRunModel}
		myComposition {FMComposition}
		myComposer {FMComposer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMTextRunViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextRunViewer */
friend SPTR(FMTextRunViewer) fMTextRunViewer (FMTextRunModel * onRun, FMComposer * composer);

';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextRunViewer methodsFor: 'accessing'!

{FMComposition} composition

	^ myComposition!

{XnRegion} regionAt: index {IntegerVar unused}
	"Return the displayRegion occupied by the model position."
	
	self unimplemented.
	^NULL!

{Position} selectionFor: aPoint {PointPos}
	"Find the model position corresponding to the display
position (a XuPoint)."

	"self halt."
	^ (myComposer charIndexFor: aPoint with: myTextRun chars
with: myComposition) integer! !

!FMTextRunViewer methodsFor: 'private: accessing'!

{AttributeGroup} attributes
	"This method returns the set of attributes that apply
	to the run being displayed"
	
	^ myTextRun attributes!

{MuWordArray} chars
	"This method returns an XuWordArray containing just the chars
	that this viewer should display"
	
	^ myTextRun chars! !

!FMTextRunViewer methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' on ' << myTextRun "<< ' into ' << self enclosure"! !

!FMTextRunViewer methodsFor: 'setting'!

{void} setComposition: newComp {FMComposition} 
	"This method is used to set a new composition for the text viewer. 
	The composition sets the display area as well as the number of 
	characters in the display run."

	| deltaX {IntegerVar} deltaY {IntegerVar} |
	myComposition == NULL
		ifTrue: [deltaX _ newComp displayWidth.
			deltaY _ newComp displayHeight]
		ifFalse: [deltaX _ newComp displayWidth - myComposition displayWidth.
			deltaY _ newComp displayHeight - myComposition displayHeight].
	myComposition _ newComp.
	self changedEnclosureBy: (PointPos make: deltaX with: deltaY)! !

!FMTextRunViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	"This is the fundamental display message for Viewers,
that 
	subclasses must implement."

	aWarp
		display: myTextRun composedChars
		from: IntegerVar0
		to: myTextRun charCount
		attributes: myTextRun attributes
		at: PointPos make.
	self validate! !

!FMTextRunViewer methodsFor: 'private: creation'!

create: onRun {FMTextRunModel} with: composer {FMComposer}
	super create.
	myTextRun _ onRun.
	myComposer _ composer.
	myComposition _ NULL!

{void} destruct

	myTextRun _ NULL.
	myComposer _ NULL.
	super destruct! !

!FMTextRunViewer methodsFor: 'protected: enclosure'!

{PointRegion} computeEnclosure
	myComposition ~~ NULL assert: 'Now, how did I have a NULL composition?'.
	^ PointRegion make.IntegerVar: myComposition displayWidth with: myComposition displayHeight! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMTextRunViewer class
	instanceVariableNames: ''!

(FMTextRunViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextRunViewer */
friend SPTR(FMTextRunViewer) fMTextRunViewer (FMTextRunModel * onRun, FMComposer * composer);

';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextRunViewer class methodsFor: 'pseudo constructor'!

make: onRun {FMTextRunModel} with: composer {FMComposer}

	^ self create: onRun with: composer! !