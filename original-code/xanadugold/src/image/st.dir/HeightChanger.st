'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:50 pm'!

PropChanger subclass: #HeightChanger
	instanceVariableNames: 'myChange {PropChange}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
HeightChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(HeightChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!HeightChanger methodsFor: 'creation'!

create: crum {CanopyCrum}

	super create: crum.
	self newShepherd.!

create: crum {CanopyCrum | NULL} with: hash {UInt32} with: info {FlockInfo}
	"Special constructor for becoming this class"

	super create: crum with: hash.
	self flockInfo: info.
	self diskUpdate.! !

!HeightChanger methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of height recalculation.
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"
	
	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[self fetchCrum changeHeight
			ifTrue: [self setCrum: self fetchCrum fetchParent]
			ifFalse: [self setCrum: NULL]].
	^self fetchCrum ~~ NULL! !

!HeightChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myChange _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myChange.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeightChanger class
	instanceVariableNames: ''!

(HeightChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!HeightChanger class methodsFor: 'creation'!

make: crum {CanopyCrum} with: change {PropChange unused}
	
	self knownBug.	"BOGUS"
	DiskManager consistent: 3 with:
		[^self create: crum]! !