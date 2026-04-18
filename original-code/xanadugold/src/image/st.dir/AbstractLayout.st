'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:57 pm'!

Heaper subclass: #AbstractLayout
	instanceVariableNames: ''
	classVariableNames: '
		HSlice {XnRegion} 
		MaxLayoutRegion {PointRegion} 
		VSlice {XnRegion} '
	poolDictionaries: ''
	category: 'FM-Layout'!
AbstractLayout comment:
'This is a placeholder class for the objects that get passed in the composition operation.  Layou objects represent arbitrary constraints and properties on the layout of projected images.  Subclasses will know about rectangle, widths, indents distances, orientation axes, etc.

Layout should properly represent on which sides composition is bounded.'!

(AbstractLayout getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractLayout methodsFor: 'accessing'!

{PointPos} extent
	self subclassResponsibility!

{PointRegion} rectangle
	self subclassResponsibility!

{PointRegion} region
	self subclassResponsibility! !

!AbstractLayout methodsFor: 'transforming'!

{AbstractLayout} scaledBy: scale {PointPos} 
	self subclassResponsibility!

{AbstractLayout} translatedBy: xlate {PointPos} 
	self subclassResponsibility! !

!AbstractLayout methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name! !

!AbstractLayout methodsFor: 'testing'!

{UInt32} hashForEqual

	^ self getCategory hashForEqual bitXor: self region hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: AbstractLayout into: [:aLay |
			^aLay region isEqual: self region]
		others: [^false]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AbstractLayout class
	instanceVariableNames: ''!

(AbstractLayout getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractLayout class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: PointRegion.
	MaxLayoutRegion _ PointRegion make: -32768 with: -32768 with: 32768 with: 32768!

linkTimeNonInherited

	MaxLayoutRegion _ NULL! !

!AbstractLayout class methodsFor: 'protected: accessing'!

{PointRegion} maxLayoutRegion
	^ MaxLayoutRegion! !