'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:26 pm'!

XnSensor subclass: #BackfollowSensor
	instanceVariableNames: '
		myStamp {Stamp}
		mySensor {XnSensor}
		myHRoot {HRoot}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-orgl'!

(BackfollowSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #COPY; yourself)!

!BackfollowSensor methodsFor: 'create'!

create: stamp {Stamp} with: sensor {XnSensor}
	super create.
	myStamp _ stamp.
	mySensor _ sensor.
	myHRoot _ NULL!

create: stamp {Stamp} with: sensor {XnSensor} with: hroot {HRoot}
	super create.
	myStamp _ stamp.
	mySensor _ sensor.
	myHRoot _ hroot! !

!BackfollowSensor methodsFor: 'ringing'!

{void} ring: value {Heaper}
	"ring with a loaf that has just replaced partiality
	figures out the region in myStamp, and rings mySensor"
	| region {XnRegion} |
	value
		cast: OExpandingLoaf into: [:loaf |
			region _ loaf
				getRegionIn: myStamp
				with: myStamp orglRoot hCut
				with: NULL]
		cast: Pair into: [:pair |
			region _ (pair left cast: HRoot)
				getRegionIn: myStamp
				with: myStamp orglRoot hCut
				with: (pair right cast: XnRegion)].
	myHRoot ~~ NULL
		ifTrue: [mySensor ring: (Pair make: myHRoot with: region)]
		ifFalse: [mySensor ring: region]! !

!BackfollowSensor methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myStamp _ receiver receiveHeaper.
	mySensor _ receiver receiveHeaper.
	myHRoot _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myStamp.
	xmtr sendHeaper: mySensor.
	xmtr sendHeaper: myHRoot.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BackfollowSensor class
	instanceVariableNames: ''!

(BackfollowSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #COPY; yourself)!

!BackfollowSensor class methodsFor: 'create'!

make: stamp {Stamp} with: sensor {XnSensor}
	^BackfollowSensor create: stamp with: sensor!

make: stamp {Stamp} with: sensor {XnSensor} with: hroot {HRoot}
	^BackfollowSensor create: stamp with: sensor with: hroot! !