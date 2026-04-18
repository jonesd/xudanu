'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:59 pm'!

FeBundle subclass: #FeElementBundle
	instanceVariableNames: 'myElement {FeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeElementBundle comment:
'Describes a region of an Edition in which all indices in my region hold the same RangeElement.'!

(FeElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeElementBundle methodsFor: 'accessing'!

{FeRangeElement CLIENT} element
	"Essential. The RangeElement which is at every position in my region"
	
	^myElement! !

!FeElementBundle methodsFor: 'private: create'!

create: region {XnRegion} with: element {FeRangeElement}

	super create: region.
	myElement := element! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeElementBundle class
	instanceVariableNames: ''!

(FeElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeElementBundle class methodsFor: 'create'!

make: region {XnRegion} with: element {FeRangeElement}

	^self create: region with: element! !

!FeElementBundle class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeRangeElement CLIENT} element
"! !