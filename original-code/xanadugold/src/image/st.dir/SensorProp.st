'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:49 pm'!

Prop subclass: #SensorProp
	instanceVariableNames: '
		myRelevantPermissions {IDRegion}
		myRelevantEndorsements {CrossRegion of: IDRegion and: IDRegion}
		myPartialFlag {BooleanVar}'
	classVariableNames: '
		TheIdentitySensorProp {SensorProp} 
		ThePartialSensorProp {SensorProp} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
SensorProp comment:
'The properties which are nevigable towards using the Sensor Canopy.  The permissions and endorsements are those whose changes may affect the triggering of the recorders that decorate the canopy.  myPartialFlag is a property of the o-leaf-stuff which are at the leaves of the Sensor Canopy.'!

(SensorProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SensorProp methodsFor: 'creation'!

create: relevantPermissions {IDRegion} 
	with: relevantEndorsements {CrossRegion of: IDRegion and: IDRegion} 
	with: isPartial {BooleanVar}
	
	super create.
	myRelevantPermissions _ relevantPermissions.
	myRelevantEndorsements _ relevantEndorsements.
	myPartialFlag _ isPartial.! !

!SensorProp methodsFor: 'accessing'!

{UInt32} flags

	^SensorCrum flagsFor: myRelevantPermissions
		with: myRelevantEndorsements
		with: myPartialFlag!

{BooleanVar} isPartial
	^myPartialFlag!

{CrossRegion} relevantEndorsements

	^myRelevantEndorsements!

{IDRegion} relevantPermissions

	^myRelevantPermissions!

{Prop} with: other {Prop}
	
	other cast: SensorProp into: [ :o |
		^SensorProp make: ((myRelevantPermissions
				unionWith: o relevantPermissions) cast: IDRegion)
			with: ((myRelevantEndorsements
				unionWith: o relevantEndorsements) cast: CrossRegion)
			with: (myPartialFlag or: [o isPartial])].
	^ NULL "compiler fodder"! !

!SensorProp methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myRelevantPermissions hashForEqual
		bitXor: myRelevantEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper
		cast: SensorProp into: [ :prop |
			^(myRelevantEndorsements isEqual: prop relevantEndorsements)
				and: [(myRelevantPermissions isEqual: prop relevantPermissions)
				and: [myPartialFlag == prop isPartial]]]
		others:
			[^false].
	^ false "compiler fodder"! !

!SensorProp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'SensorProp(P: ' << myRelevantPermissions
		<< '; E: ' << myRelevantEndorsements.
	myPartialFlag ifTrue: [oo << '; partial'].
	oo << ')'! !

!SensorProp methodsFor: 'smalltalk: passe'!

{Filter of: (XuRegion of: ID)} endorsementsFilter

	self passe!

{Filter of: (XuRegion of: ID)} permissionsFilter

	self passe! !

!SensorProp methodsFor: 'smalltalk: suspended'!

{PropJoint} joint

	Ravi thingToDo. "implement proper simpleRegions so we can use simpleUnion"
	^SensorPropJoint make: (myRelevantPermissions "asSimpleRegion" cast: IDRegion)
		with: (myRelevantEndorsements "asSimpleRegion" cast: CrossRegion)
		with: myPartialFlag! !

!SensorProp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRelevantPermissions _ receiver receiveHeaper.
	myRelevantEndorsements _ receiver receiveHeaper.
	myPartialFlag _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRelevantPermissions.
	xmtr sendHeaper: myRelevantEndorsements.
	xmtr sendBooleanVar: myPartialFlag.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SensorProp class
	instanceVariableNames: ''!

(SensorProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SensorProp class methodsFor: 'creation'!

make
	"returns an empty SensorProp"
	
	TheIdentitySensorProp == NULL ifTrue:
		[TheIdentitySensorProp := self
			create: (CurrentGrandMap fluidGet globalIDSpace emptyRegion cast: IDRegion)
			with: (CurrentGrandMap fluidGet endorsementSpace emptyRegion cast: CrossRegion)
			with: false].
	^TheIdentitySensorProp!

make: relevantPermissions {IDRegion} 
	with: relevantEndorsements {CrossRegion} 
	with: isPartial {BooleanVar}

	^self create: relevantPermissions with: relevantEndorsements with: isPartial!

{SensorProp} partial

	"returns an empty SensorProp with the partial flag on"
	ThePartialSensorProp == NULL ifTrue:
		[ThePartialSensorProp := self
			create: (CurrentGrandMap fluidGet globalIDSpace emptyRegion cast: IDRegion)
			with: (CurrentGrandMap fluidGet endorsementSpace emptyRegion cast: CrossRegion)
			with: true].
	^ThePartialSensorProp! !

!SensorProp class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	TheIdentitySensorProp _ NULL.
	ThePartialSensorProp _ NULL.! !