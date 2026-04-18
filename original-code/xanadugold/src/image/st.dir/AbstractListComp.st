'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:00 pm'!

XnModel subclass: #AbstractListComp
	instanceVariableNames: ''
	classVariableNames: 'PointNotInComposedRegionSignal {Bomb smalltalk} '
	poolDictionaries: ''
	category: 'FM-Multi'!
AbstractListComp comment:
'This class is just a placeholder to point to all the layout classes and to describe the principles of their use.'!

(AbstractListComp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractListComp methodsFor: 'smalltalk: smalltalk only'!

displayString
	^self getCategory name! !

!AbstractListComp methodsFor: 'deferred: accessing'!

{XnRegion} compositionRegion
	"the region that everything is composed into"
	self subclassResponsibility!

{PointRegion} computeEnclosureFor: views {ScruTable of: Viewer} 
	self subclassResponsibility!

{XnRegion} regionAt: index {IntegerVar}
	self subclassResponsibility!

{IntegerVar} regionIndexFor: aPoint {PointPos}
self subclassResponsibility!

{ListStyle} style

	self subclassResponsibility!

{Dsp} translationAt: index {IntegerVar}
	self subclassResponsibility! !

!AbstractListComp methodsFor: 'deferred: composing'!

{void} compose: views {ScruTable of: Viewer} with: layout
{AbstractLayout unused}
	self subclassResponsibility!

{RegionLayout}layoutAt: index{IntegerVar} 
	self subclassResponsibility!

{void} recompose: views {ScruTable of: Viewer} with: start {IntegerVar} with: where {XnRegion} 
	self subclassResponsibility! !

!AbstractListComp methodsFor: 'composing'!

{PointRegion} uncomposedRegion
	"This method returns a layout for the part of the layout that has 
	not been composed into yet."

	^PointRegion make! !

!AbstractListComp methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AbstractListComp class
	instanceVariableNames: ''!

(AbstractListComp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractListComp class methodsFor: 'smalltalk: smalltalk init'!

initialize
	"NoSelectionIndex is used for communication between ListComps and ListViews. 
	 NoSelection is used for communication between ListViews and ListControllers."
	 "AbstractListComp initialize." 
	 
	Smalltalk at: #NoSelectionIndex put: -1! !

AbstractListComp initialize!
