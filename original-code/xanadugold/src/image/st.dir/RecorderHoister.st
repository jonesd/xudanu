'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:52 pm'!

PropChanger subclass: #RecorderHoister
	instanceVariableNames: 'myCargo {MuSet of: TransclusionFossil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
RecorderHoister comment:
' NOT.A.TYPE I exist to hoist myCargo (a set of recorder fossils) up the Sensor canopy as far as it needs to go, as well as to propogate the props resulting from the planting of these recorders.  When I no longer have any cargo to hoist, I devolve into an ActualPropChanger

I assume that RecorderCheckers do their southward walk in a single step, so I can hoist recorders by an algorithm that would occasionally cause a recorder to be missed if RecorderCheckers were incremental.'!

(RecorderHoister getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #(MAY.BECOME ActualPropChanger ); add: #CONCRETE; yourself)!

!RecorderHoister methodsFor: 'creation'!

create: crum {CanopyCrum} with: aSetOfRecorders {MuSet of: RecorderFossil}

	super create: crum.
	myCargo _ aSetOfRecorders.
	self newShepherd.! !

!RecorderHoister methodsFor: 'accessing'!

{BooleanVar} step
	| |
	"See class comment for a constraint I impose on another class.
	
	If I'm done
		Stop me before I step again!!.
	atomically
		Do one step of property changing (and/or height recalculation until that's moved to HeightChanger). 
			If more needs to be done, step rootward.  (myCrum is set to NULL if I am the root.)
			else I'm done.  Remember it by setting myCrum to NULL
	return a flag saying whether I'm done"

	self thingToDo.	"update comment after we move height calculation to HeightChanger>>step"	
	self fetchCrum == NULL
		ifTrue: [^false].
	DiskManager consistent: 3 with:
		[ | crum {CanopyCrum | NULL} propsChangedFlag {BooleanVar} |
		crum := self fetchCrum fetchParent.
		propsChangedFlag := self fetchCrum changeCanopy.
		"All the updating of myPropJoint that's needed even though I hoist recorders into my parent below, since hoisting cannot change what myPropJoint needs to be."
		self setCrum: crum.
		crum == NULL ifTrue:
			[^false].
		myCargo restrictTo: (crum fetchChild1 cast: SensorCrum) recorders;
			       restrictTo: (crum fetchChild2 cast: SensorCrum) recorders.
		self diskUpdate.
		myCargo isEmpty ifTrue:
			[| hash {UInt32} 
			   info {FlockInfo} |
			propsChangedFlag ifFalse:
				[self setCrum: NULL.
				^false].
			myCargo destroy.
			"Normally done by destruct, but here we do it directly because we're about to become something"
			hash _ self hashForEqual.
			info _ self fetchInfo.
			(ActualPropChanger new.Become: self)
				create: crum
				with: hash
				with: info.
			"the special purpose constructor will not do a 'crum->addPointer(this)' so we don't have to undo it"
			^true].
		"If we reach this point, we have cargo to hoist."
		(crum fetchChild1 cast: SensorCrum) removeRecorders: myCargo asImmuSet.
		(crum fetchChild2 cast: SensorCrum) removeRecorders: myCargo asImmuSet.
		myCargo wipeAll: (crum cast: SensorCrum) recorders.
		myCargo isEmpty ifTrue:
			[propsChangedFlag ifFalse:
				[self setCrum: NULL].
			^propsChangedFlag]
		ifFalse:
			[(crum cast: SensorCrum) installRecorders: myCargo asImmuSet.
			crum diskUpdate]].
	^true! !

!RecorderHoister methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCargo _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCargo.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RecorderHoister class
	instanceVariableNames: ''!

(RecorderHoister getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #(MAY.BECOME ActualPropChanger ); add: #CONCRETE; yourself)!

!RecorderHoister class methodsFor: 'creation'!

{AgendaItem} make: crum {CanopyCrum} with:  aSetOfRecorders {ScruSet of: RecorderFossil}
	"Create a RecorderHoister."
	
	aSetOfRecorders isEmpty ifTrue:
		[^Agenda make].
	DiskManager consistent: 1 with:
		[^self create: crum with: aSetOfRecorders asMuSet]! !