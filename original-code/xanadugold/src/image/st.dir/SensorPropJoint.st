'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:02 pm'!

PropJoint subclass: #SensorPropJoint
	instanceVariableNames: '
		myRelevantPermissions {IDRegion}
		myRelevantEndorsements {CrossRegion of: IDRegion and: IDRegion}
		myPartialFlag {BooleanVar}'
	classVariableNames: 'IdentitySensorPropJoint {SensorPropJoint} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!

(SensorPropJoint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SensorPropJoint methodsFor: 'accessing'!

{BooleanVar} isPartial
	^myPartialFlag!

{PropJoint} join: other {PropJoint}
	
	Ravi thingToDo. "implement proper simpleRegions so we can use simpleUnion"
	other cast: SensorPropJoint into: [ :o |
		^SensorPropJoint make: ((myRelevantPermissions
				unionWith: o relevantPermissions) cast: IDRegion)
			with: ((myRelevantEndorsements
				unionWith: o relevantEndorsements) cast: CrossRegion)
			with: (myPartialFlag or: [o isPartial])].
	^NULL "fodder"!

{CrossRegion} relevantEndorsements

	^myRelevantEndorsements!

{IDRegion} relevantPermissions

	^myRelevantPermissions!

{PropJoint} with: prop {Prop}
	
	Ravi thingToDo. "implement proper simpleRegions so we can use simpleUnion"
	prop cast: SensorProp into: [ :s |
		^SensorPropJoint make: ((myRelevantPermissions
				unionWith: s relevantPermissions) cast: IDRegion)
			with: ((myRelevantEndorsements
				unionWith: s relevantEndorsements) cast: CrossRegion)
			with: (myPartialFlag or: [s isPartial])].
	^NULL "fodder"! !

!SensorPropJoint methodsFor: 'creation'!

create: relevantPermissions {IDRegion} 
	with: relevantEndorsements {CrossRegion of: IDRegion and: IDRegion} 
	with: isPartial {BooleanVar}
	
	super create.
	myRelevantPermissions _ relevantPermissions.
	myRelevantEndorsements _ relevantEndorsements.
	myPartialFlag _ isPartial.! !

!SensorPropJoint methodsFor: 'testing'!

{UInt32} hashForEqual
	|result {UInt32} |
	myPartialFlag ifTrue: [result _ 1] ifFalse: [result _ UInt32Zero].
	^(myRelevantPermissions hashForEqual bitXor: myRelevantEndorsements hashForEqual) 
		bitXor: result!

{BooleanVar} isEqual: other {Heaper}
	
	other cast: SensorPropJoint into: [:o |
			^(myRelevantPermissions isEqual: o relevantPermissions)
				and: [(myRelevantEndorsements isEqual: o relevantEndorsements)
				and: [myPartialFlag = o isPartial]]]
		others: [^false].
	^false "fodder"! !

!SensorPropJoint methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(P: ' << myRelevantPermissions
		<< '; E: ' << myRelevantEndorsements << ')'! !

!SensorPropJoint methodsFor: 'smalltalk: passe'!

{Filter of: (XuRegion of: ID)} endorsementsFilter

	self passe!

{Filter of: IDRegion} permissionsFilter

	self passe! !

!SensorPropJoint methodsFor: 'generated:'!

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

SensorPropJoint class
	instanceVariableNames: ''!

(SensorPropJoint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SensorPropJoint class methodsFor: 'creation'!

make
	IdentitySensorPropJoint == NULL ifTrue:
		[IdentitySensorPropJoint _ self
			create: (CurrentGrandMap fluidGet globalIDSpace emptyRegion cast: IDRegion)
			with: (CurrentGrandMap fluidGet endorsementSpace emptyRegion cast: CrossRegion)
			with: false].
	^IdentitySensorPropJoint!

make: relevantPermissions {IDRegion} 
	with: relevantEndorsements {CrossRegion} 
	with: isPartial {BooleanVar}

	^self create: relevantPermissions with: relevantEndorsements with: isPartial! !

!SensorPropJoint class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited

	IdentitySensorPropJoint _ NULL! !