'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:02 pm'!

FeBundle subclass: #FePlaceHolderBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FePlaceHolderBundle comment:
'Describes a region of an Edition in which all indices in my region have a distinct PlaceHolder.'!

(FePlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FePlaceHolderBundle methodsFor: 'private: create'!

create: region {XnRegion}

	super create: region.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePlaceHolderBundle class
	instanceVariableNames: ''!

(FePlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FePlaceHolderBundle class methodsFor: 'create'!

make: region {XnRegion}

	^self create: region! !