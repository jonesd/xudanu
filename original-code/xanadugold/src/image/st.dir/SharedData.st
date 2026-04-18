'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:15 pm'!

Abraham subclass: #SharedData
	instanceVariableNames: '
		myArrangement {Arrangement}
		myData {PrimArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(SharedData getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SharedData methodsFor: 'accessing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myData contentsHash!

{Heaper | NULL} fetch: key {Position}
	^myData fetchValue: (myArrangement indexOf: key) DOTasLong!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimArray} with: dsp {Dsp} 
	"Transfer my data into the toArray mapping through my arrangement and his arrangement."
	
	keys isEmpty ifFalse:
		[toArrange
			copyElements: toArray
			with: dsp
			with: myData
			with: myArrangement
			with: (dsp inverseOfAll: keys)]!

{PrimSpec} spec
	"Return the primSpec for my data."
	
	^myData spec! !

!SharedData methodsFor: 'creation'!

create: data {PrimDataArray} with: arrange {Arrangement} 
	super create.
	myData _ data.
	myArrangement _ arrange.
	myData count = myArrangement region count DOTasLong assert: 'Invalid arrangement'.
	self newShepherd.
	self remember! !

!SharedData methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myArrangement _ receiver receiveHeaper.
	myData _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myArrangement.
	xmtr sendHeaper: myData.! !