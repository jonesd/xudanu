'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:07 pm'!

Abraham subclass: #HRoot
	instanceVariableNames: '
		myHCrum {HUpperCrum}
		mySensorCrum {SensorCrum}
		myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(HRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!HRoot methodsFor: 'creation'!

create.ID: iD {ID}
	super create.
	myContents _ iD.
	myHCrum _ HUpperCrum make.
	mySensorCrum _ SensorCrum make.
	self newShepherd!

create.IObject: iobj {IObject}
	super create.
	myContents _ iobj.
	myHCrum _ HUpperCrum make.BertCrum: iobj orglRoot hCrum bertCrum.
	mySensorCrum _ iobj orglRoot sensorCrum.
	self newShepherd!

create.PackOBits: pob {PackOBits}
	super create.
	myContents _ pob.
	myHCrum _ HUpperCrum make.
	mySensorCrum _ SensorCrum make.
	self newShepherd! !

!HRoot methodsFor: 'accessing'!

{Heaper} contents
	^myRangeElement!

{HistoryCrum} hCrum
	^myHCrum!

{Mapping} mappingTo: trace {TracePosition} with: mapping {Mapping}
	"return a mapping from my data to corresponding stuff in the given trace"
	^self hCrum mappingTo: trace with: mapping!

{SensorCrum} sensorCrum
	^mySensorCrum!

{void} wait: sensor {XnSensor}
	"ring the sensor when partiality gets filled in"
	
	myContents 
		cast: Stamp into: [:stamp |
			stamp orglRoot
				wait: (BackfollowSensor 
					make: stamp 
					with: sensor 
					with: self)]
		others: []! !

!HRoot methodsFor: 'back reference'!

{void} addOParent: oparent {Loaf} 
	"add oparent to the set of upward pointers and update the bertCrums my child."

	| bCrum {BertCrum} newBCrum {BertCrum} |
	bCrum _ myHCrum bertCrum.
	myHCrum addOParent: oparent.
	myHCrum isEmpty not ifTrue: [self remember].
	newBCrum _ myHCrum bertCrum.
	(bCrum isLE: newBCrum) ifTrue: [myContents 
		cast: IObject into: [:iObj |
			iObj orglRoot updateBCrumTo: newBCrum]
		others: []].
	self diskUpdate!

{BooleanVar} anyPasses: finder {PropFinder}
	^myHCrum anyPasses: finder!

{BertCrum} bertCrum
	^ myHCrum bertCrum!

{void} checkRecorders: stamp {Stamp} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	
	myRangeElement 
		cast: IObject into: [:iObj |
			iObj checkRecorders: stamp with: finder with: scrum]
		others: []!

{void} delayedStoreBackfollow: finder {PropFinder} 
	with: recorder {Fossil of: BackfollowRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	myHCrum delayedStoreBackfollow: finder with: recorder with: hCrumCache!

{BooleanVar} inTrace: trace {TracePosition}
	"Return true if the receiver can backfollow to trace."

	^myHCrum inTrace: trace!

{void} removeOParent: oparent {OPart}
	"remove oparent from the set of upward pointers."

	myHCrum removeOParent: oparent.
	self diskUpdate.
	myHCrum isEmpty 
		ifTrue: 
			["Now we get into the risky part of deletion.  myHCrum
			 canForget iff all the downward pointers are gone."
			self destroy]"
		ifFalse: []"!

{void} updateBCrumTo: newBCrum {BertCrum} 
	"My bertCrum must not be leafward of newBCrum. 
	Thus it must be LE to newCrum. Otherwise correct it and recur."

	(myHCrum propagateBCrum: newBCrum) ifTrue: 
		[self diskUpdate.
		myContents 
			cast: IObject into: [:iObj |
				iObj orglRoot updateBCrumTo: newBCrum]
			others: []]! !

!HRoot methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myHCrum << ', ' << myContents << ')'! !

!HRoot methodsFor: 'protected: delete'!

{void} dismantle
	DiskManager consistent: 12 with:
		[(mySensorCrum ~~ NULL and: [mySensorCrum isKindOf: SensorCrum])
			ifTrue: [mySensorCrum removePointer: self].
		(self hCrum ~~ NULL and: [(self hCrum isKindOf: HistoryCrum)
				and: [self hCrum bertCrum isKindOf: BertCrum]])
			ifTrue: [self hCrum bertCrum removePointer: self hCrum].
		myHCrum _ NULL.
		self hack.
		myContents
			cast: ID into: [:iD |
				CurrentGrandMap fluidGet removeIDHRoot: iD]
			cast: IObject into: [:iObj |
				iObj removeHRoot].
		super dismantle]! !

!HRoot methodsFor: 'testing'!

{UInt32} contentsHash

	^((super contentsHash
		bitXor: myHCrum hashForEqual)
		bitXor: mySensorCrum hashForEqual)
		bitXor: myRangeElement hashForEqual! !

!HRoot methodsFor: 'smalltalk: passe'!

{void} storeBackfollow: finder {PropFinder} 
	with: table {MuTable of: ID and: Stamp} 
	with: hCrumCache {HashSetCache of: HistoryCrum}
	self passe! !

!HRoot methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHCrum _ receiver receiveHeaper.
	mySensorCrum _ receiver receiveHeaper.
	myRangeElement _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myHCrum.
	xmtr sendHeaper: mySensorCrum.
	xmtr sendHeaper: myRangeElement.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HRoot class
	instanceVariableNames: ''!

(HRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!HRoot class methodsFor: 'pseudo constructors'!

make.ID: iD {ID}
	^self create.ID: iD!

make.IObject: iobj {IObject}
	^self create.IObject: iobj!

make.PackOBits: pob {PackOBits}
	^self create.PackOBits: pob! !

!HRoot class methodsFor: 'smalltalk: smalltalk creation'!

create.ID: iD {ID}
	^self new create.ID: iD!

create.IObject: iobj {IObject}
	^self new create.IObject: iobj!

create.PackOBits: pob {PackOBits}
	^self new create.PackOBits: pob! !