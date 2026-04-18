'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:03 pm'!

UnOrdered subclass: #CompositePosition
	instanceVariableNames: '
		myCS {CoordinateSpace}
		myKey {Position}
		myPosition {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositePosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!CompositePosition methodsFor: 'comparing'!

{UInt32} hashForEqual

	^myCS hashForEqual bitXor: (myKey hashForEqual bitXor: myPosition hashForEqual)!

{BooleanVar} isEqual: other {Heaper} 
	^(other isKindOf: CompositePosition)
		and: [((other basicCast: CompositePosition) coordinateSpace isEqual: myCS)
		and: [((other basicCast: CompositePosition) key isEqual: myKey)
		and: [(other basicCast: CompositePosition) position isEqual: myPosition]]]! !

!CompositePosition methodsFor: 'accessing'!

{XnRegion} asRegion

	^CompositeRegion compositeSliceRegion: self coordinateSpace
		with: self key
		with: self position asRegion!

{CoordinateSpace} coordinateSpace
	^myCS!

{Position} key
	^myKey!

{Position} position
	^myPosition! !

!CompositePosition methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.
	myKey _ receiver receiveHeaper.
	myPosition _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.
	xmtr sendHeaper: myKey.
	xmtr sendHeaper: myPosition.! !