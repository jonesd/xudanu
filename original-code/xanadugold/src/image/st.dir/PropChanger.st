'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:52 pm'!

AgendaItem subclass: #PropChanger
	instanceVariableNames: 'myCrum {CanopyCrum | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
PropChanger comment:
'Used to propagate some prop(erty) change rootwards in some canopy.  Each step propagates it one step parentwards, until it gets to a local root or no further propagation in necessary.'!

(PropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!PropChanger methodsFor: 'protected: accessing'!

{CanopyCrum | NULL} fetchCrum

	^myCrum!

{void} setCrum: aCrum {CanopyCrum | NULL}
	"Move our placeholding finger to a new crum, updating refcounts accordingly"
	
	| |
	
	"atomically (though we've probably already gone nuclear)
		If there is a new crum
			bump its refcount.
		If there is an old crum
			unbump its refcount.
		Remember the new crum."
		
	DiskManager consistent: 3 with:
		[aCrum ~~ NULL ifTrue:
			[aCrum addPointer: self].
		myCrum ~~ NULL ifTrue:
			[myCrum removePointer: self].
		myCrum := aCrum.
		self diskUpdate].! !

!PropChanger methodsFor: 'accessing'!

{BooleanVar} step
	"propagate some prop(erty) change one step parentwards, until it gets to a local root or no further propagation in necessary."
	
	self subclassResponsibility! !

!PropChanger methodsFor: 'creation'!

create: crum {CanopyCrum | NULL}

	super create.
	myCrum _ crum.
	myCrum == NULL ifTrue:
		[myCrum addPointer: self].!

create: crum {CanopyCrum | NULL} with: hash {UInt32}
	"Special constructor for becoming this class"

	super create: hash.
	myCrum _ crum.
	"I don't 'myCrum addPointer: self' because, in becoming, my old self is presumed to already have pointed at the crum"!

{void} dismantle

	DiskManager consistent: 2 with:
		[myCrum ~~ NULL
			ifTrue:
				[myCrum removePointer: self.
				myCrum _ NULL].
		super dismantle]! !

!PropChanger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropChanger class
	instanceVariableNames: ''!

(PropChanger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!PropChanger class methodsFor: 'creation'!

{PropChanger} height: crum {CanopyCrum | NULL}
	
	DiskManager consistent: 3 with:
		[^HeightChanger create: crum]!

make: crum {CanopyCrum | NULL}
	
	DiskManager consistent: 2 with:
		[^ActualPropChanger create: crum]! !

!PropChanger class methodsFor: 'smalltalk: suspended'!

make: crum {CanopyCrum | NULL} with: change {PropChange}

	self suspended.
	self thingToDo. " Separate out different things to be propagatated into different PropChanger-like classes."
	
	DiskManager consistent: 3 with:
		[^ActualPropChanger create: crum with: change]! !