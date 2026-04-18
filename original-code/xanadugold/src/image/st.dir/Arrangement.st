'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:03 pm'!

Heaper subclass: #Arrangement
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-arrange'!
Arrangement comment:
'Generally represents a pair of an OrderSpec and a Region.  Arrangements map between regions and primArrays.'!

(Arrangement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!Arrangement methodsFor: 'accessing'!

{void} copyElements: toArray {PrimArray} with: toDsp {Dsp}
	with: fromArray {PrimArray} with: fromArrange {Arrangement} with: fromRegion {XnRegion}
	
	"Copy elements into toArray arranged according to the receiver. 
	 Copy them from fromArray arranged according to fromArrange.  
	 The source region is fromRegion.  It gets tranformed by toDsp
	 into the toArray."
	
	fromRegion stepper forEach: 
		[:key {Position} |
		toArray at: (self indexOf: (toDsp of: key)) DOTasLong
			storeValue: (fromArray fetchValue: (fromArrange indexOf: key) DOTasLong)]!

{IntegerVar} indexOf: position {Position unused}
	"Return the index of position into my Region according to my OrderSpec."

	self subclassResponsibility!

{IntegerRegion} indicesOf: region {XnRegion}
	"Return the region of all the indices corresponding to positions in region."

	self subclassResponsibility!

{XnRegion} keysOf: start {Int32} with: stop {Int32}
	"Return the region that corresponds to a range of indices."

	self subclassResponsibility!

{XnRegion} region
	"The region of positions in the arrangement"
	
	self subclassResponsibility! !

!Arrangement methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !