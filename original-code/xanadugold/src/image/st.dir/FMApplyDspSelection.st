'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:05 pm'!

SelectionObject subclass: #FMApplyDspSelection
	instanceVariableNames: '
		myDsp {Dsp}
		mySelection {SelectionObject}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!
FMApplyDspSelection comment:
'Instances wrap another selectionObject and transform all selection events going to it.  These are uses to allow a controller in a hierarchy of controllers to select within their local coodinate system and have it transformed to the global coordinate system for the model.'!

(FMApplyDspSelection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMApplyDspSelection methodsFor: 'selecting'!

{void} beginSelect: key {Position} 

	mySelection beginSelect: (myDsp of: key)!

{void} continueSelect: key {Position} 

	mySelection continueSelect: (myDsp of: key)!

{void} endSelect: key {Position} 
	
	mySelection endSelect: (myDsp of: key)!

{void} extendSelect: key {Position}
	mySelection extendSelect: (myDsp of: key)!

{void} multiSelect: key {Position}
	mySelection multiSelect: (myDsp of: key)! !

!FMApplyDspSelection methodsFor: 'accessing'!

{void} newDsp: dsp {Dsp}
	myDsp _ dsp!

{void} select: region {XnRegion}
	mySelection select: (myDsp ofAll: region)!

{XnRegion} selection
	^myDsp inverseOfAll: mySelection selection!

{Position} selectionPoint
	"the active point in the selection"
	^myDsp inverseOf: mySelection selectionPoint! !

!FMApplyDspSelection methodsFor: 'create'!

create: selection {SelectionObject}
	super create.
	mySelection _ selection.
	myDsp _ mySelection selection coordinateSpace identityDsp!

create: selection {SelectionObject} with: emptyDsp {Dsp}
	super create.
	mySelection _ selection.
	myDsp _ emptyDsp! !

!FMApplyDspSelection methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' << myDsp << ' on ' << mySelection << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMApplyDspSelection class
	instanceVariableNames: ''!

(FMApplyDspSelection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMApplyDspSelection class methodsFor: 'pseudo constructor'!

make: onSelection {SelectionObject}

	^ self create: onSelection! !