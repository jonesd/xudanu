'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:48 pm'!

SelectionObject subclass: #FMSelectDsp
	instanceVariableNames: '
		myModel {FMSplitTextModel}
		mySelection {FMApplyDspSelection}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMSelectDsp comment:
'Instances are used with a FMApplyDspSelection selectionObject.  These map from a selection in a higher level object to the dsp used to transform selections in the lower level objects.'!

(FMSelectDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMSelectDsp methodsFor: 'accessing'!

{void} select: region {XnRegion unused}
	self unimplemented!

{XnRegion} selection
	self unimplemented.
	^NULL!

{Position} selectionPoint
	"the active point in the selection"
	self unimplemented.
	^NULL! !

!FMSelectDsp methodsFor: 'selecting'!

{void} beginSelect: key {Position}
	"This is the basic start selection operation. 
	 Clear the old selection and start a new one."

	self continueSelect: key!

{void} continueSelect: key {Position} 
	"For the supplied model key, find the dsp to use to 
	transform sub-pieces of the piece of model represented by key into 
	the coordinate system of model."

	mySelection newDsp: (myModel dspAt: (key cast: IntegerPos) asIntegerVar)! !

!FMSelectDsp methodsFor: 'create'!

create: model {FMSplitTextModel} with: selection {FMApplyDspSelection}
	super create.
	myModel _ model.
	mySelection _ selection! !

!FMSelectDsp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' onto ' << mySelection! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMSelectDsp class
	instanceVariableNames: ''!

(FMSelectDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMSelectDsp class methodsFor: 'pseudo constructor'!

make: onSplit {FMSplitTextModel} with: selection {FMApplyDspSelection}

	^ self create: onSplit with: selection! !