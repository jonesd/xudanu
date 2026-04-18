'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:17 pm'!

Position subclass: #FilterPosition
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filter'!
FilterPosition comment:
'Encapsulates a Region in the baseSpace into a Position so that it can be treated as one for polymorphism. See Filter.'!

(FilterPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!FilterPosition methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myRegion hashForEqual + 1!

{BooleanVar} isEqual: other {Heaper} 

	other 
		cast: FilterPosition into: [:rap |
			^rap baseRegion isEqual: myRegion]
		others: [^false].
	^false "fodder"! !

!FilterPosition methodsFor: 'accessing'!

{XnRegion} asRegion

	^(Filter subsetFilter: self coordinateSpace
			with: myRegion)
		intersect: (Filter supersetFilter: self coordinateSpace
			with: myRegion)!

{XnRegion CLIENT INLINE} baseRegion
	"Essential. The region in the base space which I represent."
	
	^myRegion!

{CoordinateSpace} coordinateSpace
	^FilterSpace make: myRegion coordinateSpace! !

!FilterPosition methodsFor: 'instance creation'!

create: region {XnRegion}
	super create.
	myRegion _ region.! !

!FilterPosition methodsFor: 'smalltalk: passe'!

{XnRegion} region

	self passe! !

!FilterPosition methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FilterPosition class
	instanceVariableNames: ''!

(FilterPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!FilterPosition class methodsFor: 'pseudo constructors'!

make: region {XnRegion}
	"A position containing the given region."
	
	^FilterPosition create: region! !

!FilterPosition class methodsFor: 'smalltalk: system'!

info.stProtocol
"{XnRegion CLIENT} baseRegion
"! !