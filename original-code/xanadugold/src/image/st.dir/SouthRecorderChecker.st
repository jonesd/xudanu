'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:53 pm'!

AgendaItem subclass: #SouthRecorderChecker
	instanceVariableNames: '
		myORoot {OrglRoot | NULL}
		myFinder {PropFinder}
		mySCrum {SensorCrum | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
SouthRecorderChecker comment:
'This is a one-shot agenda item.

When changing the prop(ertie)s of a Stamp, we need to first take care of the future backFollow requests (by updating the Bert Canopy so the filtered HTree walk will find this Stamp) before taking care of the past (the Recorders that were looking for this Stamp in their future).  This AgendaItem is to remember to take care of the past (by doing a southwards o-walk filtered by the Sensor Canopy) after the future is properly dealt with.

The RecorderHoister assumes that this southward walk is done in a single-step, so it is free to make changes in a way that, if it were interleaved with an incremental southward walk by a RecorderChecker looking for the recorder(s) being hoisted, might cause the hoisted recorder to be missed.

This is also used recursively by this very o-walk to schedule a further o-walk on appropriate sub-Stamps.

Keeping track of whether persistent objects are garbage-on-disk during AgendaItem processing only remains open for Stamps, except here where it also arises for an OrglRoot.  The OrglRoot is itself held by a persistent Stamp, from which it can be easily obtained, so we should probably just hold onto two Stamps instead of a Stamp and an OrglRoot (so I only have to solve the "how to keep it around" problem for Stamps).'!

(SouthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SouthRecorderChecker methodsFor: 'creation'!

create: oroot {OrglRoot}  
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	
	super create.
	myORoot _ oroot.
	myFinder _ finder.
	self knownBug. "make sure these objects stick around.  mySCrum has add/removePointer already.  myStamp and myORoot need something similar.  myFinder is one of my sheep and is already OK."
	mySCrum _ scrum.
	mySCrum ~~ NULL
		ifTrue: [mySCrum addPointer: self].
	self newShepherd.!

{void} dismantle
	
	DiskManager consistent: 3 with:
		[mySCrum ~~ NULL
			ifTrue: 
				[mySCrum removePointer: self.
				mySCrum _ NULL].
		self thingToDo. "stop making sure these objects stick around"
		super dismantle]! !

!SouthRecorderChecker methodsFor: 'accessing'!

{BooleanVar} step
	| |
	
	"See class comment for a constraint on this method.
	
	If empty ORoot
		We've already shot once.  Do nothing.
	Check for any recorders in the sensor canopy that need to be rung.
		Remember that we're done."
	myORoot == NULL
		ifTrue: [^false].
	myORoot checkRecorders: myFinder with: mySCrum.
	DiskManager consistent: 1 with:
		[myORoot _ NULL.
		self thingToDo. "stop making sure these objects stick around"
		self diskUpdate.
		^false]! !

!SouthRecorderChecker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myORoot _ receiver receiveHeaper.
	myFinder _ receiver receiveHeaper.
	mySCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myORoot.
	xmtr sendHeaper: myFinder.
	xmtr sendHeaper: mySCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SouthRecorderChecker class
	instanceVariableNames: ''!

(SouthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SouthRecorderChecker class methodsFor: 'creation'!

make: oroot {OrglRoot} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	DiskManager consistent: 2 with: 
		[^self
			create: oroot
			with: finder
			with: scrum]! !

!SouthRecorderChecker class methodsFor: 'smalltalk: passe'!

make: oroot {OrglRoot} 
	with: stamp {BeEdition} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	self passe "fewer args"! !