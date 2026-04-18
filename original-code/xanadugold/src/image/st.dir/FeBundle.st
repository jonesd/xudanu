'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:56 pm'!

Heaper subclass: #FeBundle
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeBundle comment:
'Describes a single chunk of information from an Edition'!

(FeBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeBundle methodsFor: 'protected: create'!

create: region {XnRegion}

	super create.
	myRegion := region.! !

!FeBundle methodsFor: 'accessing'!

{XnRegion CLIENT} region
	"Essential. The positions in the Edition for which I describe the contents"
	
	^myRegion! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeBundle class
	instanceVariableNames: ''!

(FeBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeBundle class methodsFor: 'smalltalk: system'!

info.stProtocol
"{XnRegion CLIENT} region
"! !