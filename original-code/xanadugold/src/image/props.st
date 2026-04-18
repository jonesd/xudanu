'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 15 March 1995 at 2:35:59 pm'!

((CxxSystemOrganization tree childNamed: 'props') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'props') destroyFiles]!

Heaper subclass: #Prop
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
Prop comment:
'A collection of properties which are to be found by navigating a Canopy.  PropJoints are the union/intersection style abstraction of the properties which provide for such navigation.'!

(Prop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Prop methodsFor: 'accessing'!

{UInt32} flags
	"The flags used in the Canopy to tag this prop"
	
	self subclassResponsibility!

{Prop} with: other {Prop}
	self subclassResponsibility! !

!Prop methodsFor: 'smalltalk: suspended'!

{PropJoint} joint

	"Returns the filtering information from this one prop as a PropJoint. "
	
	self subclassResponsibility! !Prop subclass: #BertProp
	instanceVariableNames: '
		myPermissions {XnRegion of: ID}
		myEndorsements {XnRegion of: ID}
		mySensorWaitingFlag {BooleanVar}
		myCannotPartializeFlag {BooleanVar}'
	classVariableNames: 'TheIdentityBertProp {BertProp} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
BertProp comment:
'The properties which are nevigable towards using the Bert Canopy.  All of these are properties of the Stamps at the leaves of the Bert Canopy.'!

(BertProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!BertProp methodsFor: 'accessing'!

{CrossRegion} endorsements
	^myEndorsements cast: CrossRegion!

{UInt32} flags

	^BertCrum flagsFor: (myPermissions cast: IDRegion)
		with: (myEndorsements cast: CrossRegion)
		with: myCannotPartializeFlag
		with: mySensorWaitingFlag!

{BooleanVar} isNotPartializable
	^myCannotPartializeFlag!

{BooleanVar} isSensorWaiting
	^mySensorWaitingFlag!

{XnRegion of: ID} permissions
	^myPermissions!

{Prop} with: other {Prop}
	| o {BertProp} |
	o _ other cast: BertProp.
	^BertProp make: (myPermissions unionWith: o permissions)
		with: (myEndorsements unionWith: o endorsements)
		with: (mySensorWaitingFlag or: [o isSensorWaiting])
		with: (myCannotPartializeFlag or: [o isNotPartializable])! !

!BertProp methodsFor: 'creation'!

create: permissions {XnRegion of: ID} 
	with: endorsements {XnRegion of: ID} 
	with: isSensorWaiting {BooleanVar} 
	with: isNotPartializable {BooleanVar}
	super create.
	myPermissions _ permissions.
	myEndorsements _ endorsements.
	mySensorWaitingFlag _ isSensorWaiting.
	myCannotPartializeFlag _ isNotPartializable.! !

!BertProp methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myPermissions hashForEqual bitXor: myEndorsements hashForEqual!

{BooleanVar} isEmpty
	"Does this do the right thing."
	
	self knownBug.
	^myEndorsements isEmpty and: [myPermissions isEmpty]!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: BertProp into: [:b |
			^(b endorsements isEqual: myEndorsements)
			 and: [(b permissions isEqual: myPermissions)
			 and: [b isSensorWaiting == mySensorWaitingFlag
			 and: [b isNotPartializable == myCannotPartializeFlag]]]]
		others: [^false].
	^ false "compiler fodder"! !

!BertProp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(P: ' << myPermissions << '; E: ' << myEndorsements.
	mySensorWaitingFlag ifTrue: [oo << '; sensor'].
	myCannotPartializeFlag ifTrue: [oo << '; cannot partialize'].
	oo << ')'! !

!BertProp methodsFor: 'smalltalk: suspended'!

{PropJoint} joint
	^BertPropJoint
		make: (Joint make: myPermissions)
		with: (Joint make: myEndorsements)
		with: mySensorWaitingFlag
		with: myCannotPartializeFlag! !

!BertProp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.
	mySensorWaitingFlag _ receiver receiveBooleanVar.
	myCannotPartializeFlag _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsements.
	xmtr sendBooleanVar: mySensorWaitingFlag.
	xmtr sendBooleanVar: myCannotPartializeFlag.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BertProp class
	instanceVariableNames: ''!

(BertProp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!BertProp class methodsFor: 'creation'!

{BertProp} cannotPartializeProp
	[BeGrandMap] USES.
	^BertProp make: IDSpace global emptyRegion
		with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
		with: false
		with: true!

{BertProp} detectorWaitingProp

	^BertProp make: CurrentGrandMap fluidGet globalIDSpace emptyRegion
			with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
			with: true
			with: false!

{BertProp} endorsementsProp: endorsements {XnRegion}

	^BertProp make: IDSpace global emptyRegion
		with: endorsements
		with: false
		with: false!

{BertProp} make

	TheIdentityBertProp == NULL ifTrue:
		[TheIdentityBertProp := BertProp make: IDSpace global emptyRegion
			with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
			with: false
			with: false].
	^TheIdentityBertProp!

make: permissions {XnRegion of: ID} 
	with: endorsements {XnRegion} 
	with: isSensorWaiting {BooleanVar} 
	with: isNotPartializable {BooleanVar} 
	^self
		create: permissions
		with: endorsements
		with: isSensorWaiting
		with: isNotPartializable!

{BertProp} permissionsProp: iDs {XnRegion of: ID}
	^BertProp make: iDs
		with: CurrentGrandMap fluidGet endorsementSpace emptyRegion
		with: false
		with: false! !

!BertProp class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	TheIdentityBertProp _ NULL.! !

!BertProp class methodsFor: 'smalltalk: passe'!

{BertProp} sensorWaitingProp

	self passe! !Prop subclass: #SensorProp
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
	ThePartialSensorProp _ NULL.! !Heaper subclass: #PropChange
	instanceVariableNames: ''
	classVariableNames: '
		TheBertPropChange {PropChange} 
		TheCannotPartializeChange {PropChange} 
		TheDetectorWaitingChange {PropChange} 
		TheEndorsementsChange {PropChange} 
		ThePermissionsChange {PropChange} 
		TheSensorPropChange {PropChange} '
	poolDictionaries: ''
	category: 'Xanadu-props'!
PropChange comment:
'Each concrete class has just one canonical instance and no state.  A PropChange is used to represent which property aspect changed (such as permission vs endorsement vs both).'!

(PropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	self subclassResponsibility!

{Prop} changed: old {Prop} with: a {Prop}
	"Return a Prop which is the same as 'old' for aspects which I don't represent as changing, and 'a' for aspects that I do represent as changing.
	
	 This is used to replace Props with minimum effort, given that the 'a' parameter has only new props which are of the aspect this change replaces, while the 'old' parameter starts as the original set of Props, perhaps including other aspects.
	 
	 See also: with:with:, which unions rather than replacing."
	
	self subclassResponsibility!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	"return a finder looking for this change from before to after, in addition to whatever oldFinder is looking for (assumes this changes is a subset of oldFinder's change)"
	
	self subclassResponsibility!

{BooleanVar} isFull
	"whether this is a complete change of props"
	self subclassResponsibility!

{Prop} with: old {Prop} with: a {Prop}
	"Return a Prop which is the same as 'old' for aspects which I don't represent as changing, and the union of 'old' and 'a' for aspects that I do represent as changing.
	
	 This is used to accumulate changes to Props with minimum effort, given that the 'a' parameter has only new props which are of the aspect this change changes, while the 'old' parameter starts as the original set of Props, perhaps including other aspects.
	 
	 See also changed:with:, which replaces rather than unioning."
	
	self subclassResponsibility! !

!PropChange methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self takeOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!PropChange methodsFor: 'smalltalk: passe'!

{PropFinder} fetchFinder: before {Prop} with: after {Prop}

	self passe "extra args"!

{PropFinder} finderPartFrom: finder {PropFinder}

	self passe! !

!PropChange methodsFor: 'smalltalk: defaults'!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	
	^self fetchFinder: before with: after with: element with: NULL! !

!PropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	
	self subclassResponsibility!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	"Return a PropJoint which is the same as 'old' for aspects which I don't represent as changing, and 'a' for aspects that I do represent as changing.
	
	 This is used to replace PropJoints with minimum effort, given that the 'a' parameter has only new PropJoints which are of the aspect this change replaces, while the 'old' parameter starts as the original set of PropJoints, perhaps including other aspects.
	 
	 See also: change:with:, which does this for Props rather than PropJoints."
	
	self subclassResponsibility!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	self subclassResponsibility!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	self subclassResponsibility!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropChange class
	instanceVariableNames: ''!

(PropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropChange class methodsFor: 'pseudo constructors'!

{PropChange} bertPropChange
	^TheBertPropChange!

{PropChange} cannotPartializeChange
	^TheCannotPartializeChange!

{PropChange} detectorWaitingChange
	^TheDetectorWaitingChange!

{PropChange} endorsementsChange
	^TheEndorsementsChange!

{PropChange} permissionsChange
	^ThePermissionsChange!

{PropChange} sensorPropChange
	"Returns the canonical PropChange object for propagating the properties that result from installing a recorder (permissions and endorsement filters).  A better name would be recorderPropChange"
	
	^TheSensorPropChange! !

!PropChange class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	TheCannotPartializeChange _ CannotPartializeChange create.
	TheDetectorWaitingChange _ DetectorWaitingChange create.
	TheEndorsementsChange _ EndorsementsChange create.
	TheBertPropChange _ BertPropChange create.
	TheSensorPropChange _ SensorPropChange create.
	ThePermissionsChange _ PermissionsChange create.!

linkTimeNonInherited
	TheCannotPartializeChange _ NULL.
	TheDetectorWaitingChange _ NULL.
	TheEndorsementsChange _ NULL.
	TheBertPropChange _ NULL.
	TheSensorPropChange _ NULL.
	ThePermissionsChange _ NULL! !PropChange subclass: #CannotPartializeChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
CannotPartializeChange comment:
'The "Cannot Partialize" property is a Bert Canopy property to remember that a Stamp is actively being viewed (by a session level Orgl) and therefore cannot be poured-out (made more partial).  Should probably not be a Prop(erty), by rather a NOCOPY session level bit in the BertCrums.'!

(CannotPartializeChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CannotPartializeChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) isNotPartializable == (b cast: BertProp) isNotPartializable!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	bp isNotPartializable == abp isNotPartializable ifTrue: [^old].
	^BertProp make: bp permissions
		with: bp endorsements
		with: bp isSensorWaiting
		with: abp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	(bp isNotPartializable or: [abp isNotPartializable not])
		ifTrue: [^old]
		ifFalse: [^BertProp make: bp permissions
			with: bp endorsements
			with: bp isSensorWaiting
			with: abp isNotPartializable]! !

!CannotPartializeChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) isNotPartializable == (b cast: BertPropJoint) isNotPartializable!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	bpj isNotPartializable == one isNotPartializable
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) isNotPartializable == (b cast: BertProp) isNotPartializable!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	bpj isNotPartializable == (one isNotPartializable
			or: [two isNotPartializable])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} p {BertProp wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	p _ prop cast: BertProp.
	bpj isNotPartializable == (one isNotPartializable
			or: [two isNotPartializable
			or: [p isNotPartializable]])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]! !

!CannotPartializeChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #DetectorWaitingChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
DetectorWaitingChange comment:
'The "Detector Waiting" property is a Bert Canopy property to remember that an Edition has a Detector waiting for PlaceHolders to be filled in.'!

(DetectorWaitingChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!DetectorWaitingChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) isSensorWaiting == (b cast: BertProp) isSensorWaiting!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	bp isSensorWaiting == abp isSensorWaiting ifTrue: [^old].
	^BertProp make: bp permissions
		with: bp endorsements
		with: abp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL!

{BooleanVar} isFull

	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	(bp isSensorWaiting or: [abp isSensorWaiting not])
		ifTrue: [^old]
		ifFalse: [^BertProp make: bp permissions
			with: bp endorsements
			with: abp isSensorWaiting
			with: bp isNotPartializable]! !

!DetectorWaitingChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) isSensorWaiting == (b cast: BertPropJoint) isSensorWaiting!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	bpj isSensorWaiting == one isSensorWaiting
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: one isSensorWaiting
				with: bpj isNotPartializable]!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}

	^(a cast: BertPropJoint) isSensorWaiting == (b cast: BertProp) isSensorWaiting!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}

	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	bpj isSensorWaiting == (one isSensorWaiting
			or: [two isSensorWaiting])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting not
				with: bpj isNotPartializable]!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}

	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} p {BertProp wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	p _ prop cast: BertProp.
	bpj isSensorWaiting == (one isSensorWaiting
			or: [two isSensorWaiting
			or: [p isSensorWaiting]])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting not
				with: bpj isNotPartializable]! !

!DetectorWaitingChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #EndorsementsChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
EndorsementsChange comment:
'Used when the Endorsement part of a BertProp changed'!

(EndorsementsChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!EndorsementsChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) endorsements isEqual: (b cast: BertProp) endorsements!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: bp permissions
		with: (a cast: BertProp) endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	before cast: BertProp into: [ :b |
	after cast: BertProp into: [ :a |
		| result {PropFinder} delta {RegionDelta}
		  any {PropFinder} anys {ImmuSet}
		  simple {PropFinder} simples {ImmuSet} |
		delta := RegionDelta make: b endorsements with: a endorsements.
		delta isSame ifTrue:
			[^NULL].
		any := AnyRecorderEFinder make: (a permissions cast: IDRegion) with: delta.
		any isEmpty
			ifTrue: [anys := ImmuSet make]
			ifFalse: [anys := ImmuSet newWith: any].
		simple := OriginalResultRecorderEFinder make: element
			with: (a permissions cast: IDRegion)
			with: delta.
		simple isEmpty
			ifTrue: [simples := ImmuSet make]
			ifFalse: [simples := ImmuSet newWith: simple].
		oldFinder == NULL ifTrue:
			[result := CumulativeRecorderFinder
				make: anys
				with: simples
				with: ImmuSet make]
		ifFalse:
			[oldFinder cast: CumulativeRecorderFinder into: [ :crf |
				result := CumulativeRecorderFinder
					make: anys
					with: simples
					with: (crf current unionWith: crf others)]].
		result isEmpty
			ifTrue: [^NULL]
			ifFalse: [^result]]].
	^NULL "fodder"!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: bp permissions
		with: ((a cast: BertProp) endorsements unionWith: bp endorsements)
		with: bp isSensorWaiting
		with: bp isNotPartializable! !

!EndorsementsChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) endorsementsJoint isEqual: (b cast: BertPropJoint) endorsementsJoint!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bertprop {BertPropJoint wimpy} |
	bertprop _ old cast: BertPropJoint.
	^BertPropJoint make: bertprop  permissionsJoint
		with: (a cast: BertPropJoint) endorsementsJoint
		with: bertprop isSensorWaiting
		with: bertprop isNotPartializable!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) endorsementsJoint unioned isEqual: (b cast: BertProp) endorsements!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bertprop {BertPropJoint wimpy} |
	bertprop _ old cast: BertPropJoint.
	^BertPropJoint make: bertprop  permissionsJoint
		with: ((a cast: BertPropJoint) endorsementsJoint join: (b cast: BertPropJoint) endorsementsJoint)
		with: bertprop isSensorWaiting
		with: bertprop isNotPartializable!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	^BertPropJoint make: bpj  permissionsJoint
		with: (((a cast: BertPropJoint) endorsementsJoint
			join: (b cast: BertPropJoint) endorsementsJoint)
			with: (prop cast: BertProp) endorsements)
		with: bpj isSensorWaiting
		with: bpj isNotPartializable! !

!EndorsementsChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #FullPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
FullPropChange comment:
'Use this to indicate that all aspects of the Prop may have changed.'!

(FullPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!FullPropChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^a isEqual: b!

{Prop} changed: old {Prop unused} with: a {Prop}

	^a!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	self subclassResponsibility!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^true!

{Prop} with: old {Prop} with: a {Prop}

	^old with: a! !

!FullPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^a isEqual: b!

{PropJoint} changedJoint: old {PropJoint unused} with: a {PropJoint}
	
	^a!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	self subclassResponsibility!

{PropJoint} join: old {PropJoint unused} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	^a join: b!

{PropJoint} joinProp: old {PropJoint unused} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	^(a join: b) with: prop! !FullPropChange subclass: #BertPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
BertPropChange comment:
'Use when it is fine to consider that all aspects of the BertProp may have changed'!

(BertPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BertPropChange methodsFor: 'accessing'!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	| p {PropFinder} e {PropFinder} |
	p := PropChange permissionsChange
			fetchFinder: before with: after with: element with: oldFinder.
	e := PropChange endorsementsChange
			fetchFinder: before with: after with: element with: oldFinder.
	p == NULL ifTrue: [^e].
	e == NULL ifTrue: [^p].
	p cast: CumulativeRecorderFinder into: [ :pcrf |
	e cast: CumulativeRecorderFinder into: [ :ecrf |
		^CumulativeRecorderFinder
			make: (pcrf generators unionWith: ecrf generators)
			with: (pcrf current unionWith: ecrf current)
			with: (pcrf others unionWith: ecrf others)]].
	^NULL "fodder"! !

!BertPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	| bpj {BertPropJoint wimpy} bp {BertProp wimpy} |
	bpj _ a cast: BertPropJoint.
	bp _ b cast: BertProp.
	^(bpj endorsementsJoint unioned isEqual: bp endorsements)
		and: [(bpj permissionsJoint unioned isEqual: bp permissions)
		and: [bpj isSensorWaiting == bp isSensorWaiting
		and: [bpj isNotPartializable == bp isNotPartializable]]]! !

!BertPropChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !FullPropChange subclass: #SensorPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
SensorPropChange comment:
'Use when it is fine to consider that all aspects of the SensorProp may have changed'!

(SensorPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SensorPropChange methodsFor: 'accessing'!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL! !

!SensorPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	
	a cast: SensorPropJoint into: [ :spj |
	b cast: SensorProp into: [ :sp |
		^(spj relevantEndorsements isEqual: sp relevantEndorsements)
			and: [(spj relevantPermissions isEqual: sp relevantPermissions)
			and: [spj isPartial == sp isPartial]]]].
	^false "fodder"! !

!SensorPropChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropChange subclass: #PermissionsChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
PermissionsChange comment:
'Used when the Permissions part of a BertProp changed'!

(PermissionsChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!PermissionsChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) permissions isEqual: (b cast: BertProp) permissions!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: (a cast: BertProp) permissions
		with: bp endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	before cast: BertProp into: [ :b |
	after cast: BertProp into: [ :a |
		| result {PropFinder} delta {RegionDelta}
		  any {PropFinder} anys {ImmuSet}
		  simple {PropFinder} simples {ImmuSet} |
		delta := RegionDelta make: b permissions with: a permissions.
		delta isSame ifTrue:
			[^NULL].
		any := AnyRecorderPFinder make: delta.
		any isEmpty
			ifTrue: [anys := ImmuSet make]
			ifFalse: [anys := ImmuSet newWith: any].
		simple :=ResultRecorderPFinder make: element
			with: delta
			with: a endorsements.
		simple isEmpty
			ifTrue: [simples := ImmuSet make]
			ifFalse: [simples := ImmuSet newWith: simple].
		oldFinder == NULL ifTrue:
			[result := CumulativeRecorderFinder
				make: anys
				with: simples
				with: ImmuSet make]
		ifFalse:
			[oldFinder cast: CumulativeRecorderFinder into: [ :crf |
				result := CumulativeRecorderFinder
					make: anys
					with: simples
					with: (crf current unionWith: crf others)]].
		result isEmpty
			ifTrue: [^NULL]
			ifFalse: [^result]]].
	^NULL "fodder"!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: ((a cast: BertProp) permissions unionWith: bp permissions)
		with: bp endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable! !

!PermissionsChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) permissionsJoint isEqual: (b cast: BertPropJoint) permissionsJoint!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bp {BertPropJoint wimpy} |
	bp _ old cast: BertPropJoint.
	^BertPropJoint make: (a cast: BertPropJoint) permissionsJoint
		with: bp endorsementsJoint
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) permissionsJoint unioned isEqual: (b cast: BertProp) permissions!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bp {BertPropJoint wimpy} |
	bp _ old cast: BertPropJoint.
	^BertPropJoint make: ((a cast: BertPropJoint) permissionsJoint join: (b cast: BertPropJoint) permissionsJoint)
		with: bp endorsementsJoint
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	^BertPropJoint make: (((a cast: BertPropJoint) permissionsJoint
			join: (b cast: BertPropJoint) permissionsJoint)
			with: (prop cast: BertProp) permissions)
		with: bpj endorsementsJoint
		with: bpj isSensorWaiting
		with: bpj isNotPartializable! !

!PermissionsChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !Heaper subclass: #PropFinder
	instanceVariableNames: 'myFlags {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PropFinder comment:
'For filtering by canopies.  Matches against Props and CanopyCrum flags'!

(PropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create.
	myFlags := flags.! !

!PropFinder methodsFor: 'accessing'!

{BooleanVar} doesPass: parent {CanopyCrum}
	"return whether the propJoint passes the finder"

	^(myFlags bitOr: parent flags) ~= UInt32Zero!

{PropFinder} findPast: stamp {BeEdition}
	"During a southwards walk of a multi-Edition (aka multi-Stamp), normally we simplify the finder by using PropFinder>>pass:.  However, when we cross an internal Edition boundary and are about to walk into the O-plane of that contained edition we call this method (findPast:) to get the new PropFinder."
	
	self subclassResponsibility!

{UInt32} flags

	^myFlags!

{BooleanVar} isEmpty
	"Overridden only in ClosedPropFinder"
	^false!

{BooleanVar} isFull
	"Overridden only in OpenPropFinder"
	^false!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility!

{PropFinder} pass: parent {CanopyCrum}
	"return a simple enough finder for looking at the children"

	(self doesPass: parent)
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropFinder class
	instanceVariableNames: ''!

(PropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropFinder class methodsFor: 'creation'!

{PropFinder} backfollowFinder: permissionsFilter {Filter of: (XnRegion of: ID)}
	permissionsFilter isEmpty
		ifTrue: [^PropFinder closedPropFinder]
		ifFalse: [^BackfollowPFinder 
			create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: NULL
				with: false
				with: false)
			with: permissionsFilter]!

{PropFinder} backfollowFinder: permissionsFilter {Filter of: (XnRegion of: ID)} 
	with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	(permissionsFilter isEmpty or: [endorsementsFilter isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	endorsementsFilter isFull ifTrue:
		[^BackfollowPFinder create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: NULL
				with: false
				with: false)
			with: permissionsFilter].
	^BackfollowFinder create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: (endorsementsFilter relevantRegion cast: CrossRegion)
				with: false
				with: false)
			with: permissionsFilter
			with: endorsementsFilter!

{PropFinder} cannotPartializeFinder
	^CannotPartializeFinder create!

{PropFinder} closedPropFinder
	^ClosedPropFinder create!

{PropFinder} openPropFinder
	^OpenPropFinder create!

{PropFinder} sensorFinder
	^SensorFinder create! !

!PropFinder class methodsFor: 'smalltalk: passe'!

{PropFinder} partialityFinder

	self passe!

{PropFinder} recorderFinder.RegionDelta: permissionsDelta {RegionDelta of: (XuRegion of: ID)} 
	with.RegionDelta: endorsementsDelta {RegionDelta of: (XuRegion of: ID)} 

	self passe.!

{PropFinder} recorderFinder.RegionDelta: permissionsDelta {RegionDelta of: (XuRegion of: ID)} 
	with.XuRegion: endorsements {XuRegion of: ID} 

	self passe.!

{PropFinder} recorderFinder.XuRegion: permissions {XuRegion of: ID} 
	with.RegionDelta: endorsementsDelta {RegionDelta of: (XuRegion of: ID)} 

	self passe.!

{PropFinder} recorderPFinder: element {BeRangeElement}
	with: permissionsDelta {RegionDelta of: IDRegion}
	with: endorsements {CrossRegion of: IDRegion and: IDRegion}
	
	self passe! !PropFinder subclass: #BertPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BertPropFinder comment:
'Used to filter by the bert canopy'!

(BertPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!BertPropFinder methodsFor: 'create'!

create
	super create "for comm"!

create: flags {UInt32}

	super create: flags! !

!BertPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!BertPropFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	self subclassResponsibility! !BertPropFinder subclass: #BackfollowFinder
	instanceVariableNames: '
		myPermissionsFilter {Filter of: (XnRegion of: ID)}
		myEndorsementsFilter {Filter of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BackfollowFinder comment:
'Finder used to filter the htree walk by the bert canopy when doing a backFollow which uses both permissions and endorsement filters'!

(BackfollowFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowFinder methodsFor: 'creation'!

create: flags {UInt32}
	with: permissionsFilter {Filter of: (XnRegion of: ID)} 
	with: endorsementsFilter {Filter of: (CrossRegion of: ID)}
	
	super create: flags.
	myPermissionsFilter _ permissionsFilter.
	myEndorsementsFilter _ endorsementsFilter! !

!BackfollowFinder methodsFor: 'accessing'!

{Filter of: (XnRegion of: ID)} endorsementsFilter
	^myEndorsementsFilter!

{PropFinder} findPast: edition {BeEdition}

	| canSee {BooleanVar} endorsements {XnRegion} |
	Ravi thingToDo. "use regions in finder so that we don't need to create intermediate objects"
	canSee := false.
	endorsements := edition endorsements.
	edition currentWorks stepper forEach: [ :work {BeWork} |
		((work fetchReadClub ~~ NULL
			and: [myPermissionsFilter match: work fetchReadClub asRegion])
		or:
			[work fetchEditClub ~~ NULL
				and: [myPermissionsFilter match: work fetchEditClub asRegion]])
			ifTrue:
				[canSee := true.
				endorsements := endorsements unionWith: work endorsements]].
	(myEndorsementsFilter match: endorsements) ifTrue:
		[canSee ifTrue:
			[^PropFinder openPropFinder]
		ifFalse:
			[^PropFinder backfollowFinder: myPermissionsFilter]].
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	| p {BertProp wimpy} |
	p _ prop cast: BertProp.
	^(myPermissionsFilter match: p permissions) and: [myEndorsementsFilter match: p endorsements]!

{Filter of: (XnRegion of: ID)} permissionsFilter
	^myPermissionsFilter! !

!BackfollowFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(self getCategory hashForEqual bitXor: myPermissionsFilter hashForEqual)
	  bitXor: myEndorsementsFilter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: BackfollowFinder into: [:o |
			^(myPermissionsFilter isEqual: o permissionsFilter) 
			 and: [myEndorsementsFilter isEqual: o endorsementsFilter]]
		others:
			[^false].
	^false "fodder"! !

!BackfollowFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint} 
	"return a simple enough finder for looking at the children"

	| p {BertPropJoint wimpy} |
	p _ parent cast: BertPropJoint.
	^PropFinder  
		backfollowFinder: (myPermissionsFilter pass: p permissionsJoint)
		with: (myEndorsementsFilter pass: p endorsementsJoint)! !

!BackfollowFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.
	myEndorsementsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.
	xmtr sendHeaper: myEndorsementsFilter.! !BertPropFinder subclass: #BackfollowPFinder
	instanceVariableNames: 'myPermissionsFilter {Filter of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BackfollowPFinder comment:
'Finder used to filter the htree walk by the bert canopy when doing a backFollow which uses just permissions filters'!

(BackfollowPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowPFinder methodsFor: 'creation'!

create: flags {UInt32}
	with: permissionsFilter {Filter of: (XnRegion of: ID)}
	super create: flags.
	myPermissionsFilter _ permissionsFilter! !

!BackfollowPFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition}

	Ravi thingToDo. "use regions in finder so that we don't need to create intermediate objects"
	edition currentWorks stepper forEach: [ :work {BeWork} |
		((work fetchReadClub ~~ NULL
			and: [myPermissionsFilter match: work fetchReadClub asRegion])
		or:
			[work fetchEditClub ~~ NULL
				and: [myPermissionsFilter match: work fetchEditClub asRegion]])
			ifTrue: [^PropFinder openPropFinder]].
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^myPermissionsFilter match: (prop cast: BertProp) permissions!

{Filter of: (XnRegion of: ID)} permissionsFilter
	^myPermissionsFilter! !

!BackfollowPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual bitXor: myPermissionsFilter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: BackfollowPFinder into: [:o |
			^myPermissionsFilter isEqual: o permissionsFilter]
		others:
			[^false].
	^false "fodder"! !

!BackfollowPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint} 
	"return a simple enough finder for looking at the children"
	^PropFinder backfollowFinder: (myPermissionsFilter pass: (parent cast: BertPropJoint) permissionsJoint)! !

!BackfollowPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.! !BertPropFinder subclass: #CannotPartializeFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CannotPartializeFinder comment:
'Used to figure out which Stamps have Orgls on them so that the archiver can knw that they cannot be partialized.  Will go away because the state described is session level state and therefore should be store in NOCOPY variables instead of in the Canopy''s Props.'!

(CannotPartializeFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CannotPartializeFinder methodsFor: 'create'!

create

	super create: BertCrum isNotPartializableFlag! !

!CannotPartializeFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^self "inability to partialize is transitive"!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: BertProp) isNotPartializable! !

!CannotPartializeFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: CannotPartializeFinder! !

!CannotPartializeFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: BertPropJoint) isNotPartializable
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!CannotPartializeFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !BertPropFinder subclass: #SensorFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorFinder comment:
'Currently unused but will be re-instated.  Used to find which containing Editions have WaitForCompletionDetectors installed on them so that they can be rung when placegholders get filled in.'!

(SensorFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SensorFinder methodsFor: 'create'!

create

	super create: BertCrum isSensorWaitingFlag! !

!SensorFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^PropFinder closedPropFinder "Dont look for Detectors past an Edition boundary"!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: BertProp) isSensorWaiting! !

!SensorFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: SensorFinder! !

!SensorFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: BertPropJoint) isSensorWaiting
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!SensorFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropFinder subclass: #ClosedPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ClosedPropFinder comment:
'The finder which matches nothing.  Used to indicate that this subtree is known to be useless (no matches possible below here).'!

(ClosedPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ClosedPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} isEmpty
	"Overridden only here"
	^true!

{BooleanVar} match: prop {Prop unused}
	"tell whether a prop matches this filter"
	^false!

{PropFinder} pass: crum {CanopyCrum unused}

	^self! !

!ClosedPropFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: ClosedPropFinder! !

!ClosedPropFinder methodsFor: 'create'!

create

	super create: UInt32Zero! !

!ClosedPropFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropFinder subclass: #OpenPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
OpenPropFinder comment:
'The finder which matches everything.  Used to indicate that everything below here necessarily matches.'!

(OpenPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OpenPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} isFull
	
	^true!

{BooleanVar} match: prop {Prop unused}
	"tell whether a prop matches this filter"
	^true!

{PropFinder} pass: crum {CanopyCrum unused}

	^self! !

!OpenPropFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: OpenPropFinder! !

!OpenPropFinder methodsFor: 'create'!

create

	super create: UInt32Zero bitInvert! !

!OpenPropFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !PropFinder subclass: #SensorPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorPropFinder comment:
'Used to filter by the sensor canopy'!

(SensorPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!SensorPropFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!SensorPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!SensorPropFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: crum {CanopyCrum}

	self subclassResponsibility! !SensorPropFinder subclass: #AbstractRecorderFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AbstractRecorderFinder comment:
'The finders used to find recorders in the sensor canopy in response to some change in props of a Stamp.'!

(AbstractRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!AbstractRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!AbstractRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}
	"While doing one step of a southward walk in the O-tree,
	 filtered by the sensor canopy,
	 looking for recorders that represent queries that are newly passed by the change of properties,
	 where the object that changed properties and the change itself are represented by my state,
	 record my object into the recorder if it newly passes the recorder's filtering criteria.
	 
	 See class comments of the various subclasses for details on the purpose of each kindOf AbstractRecorderFinder."
	
	self subclassResponsibility! !

!AbstractRecorderFinder methodsFor: 'smalltalk: passe'!

{void} checkStamp: stamp {BeEdition} with: recorder {TransclusionRecorder}
	"record the stamp into the recorder if I pass this recorder's filters"
	
	self passe!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {RecorderFossil}
	"While doing one step of a southward walk in the O-tree,
	 filtered by the sensor canopy,
	 looking for recorders that represent queries that are newly passed by the change of properties in the Stamp
	 (said change in properties being represented by my state),
	 record the stamp into the recorder if the stamp newly passes the fossil's filtering criteria.
	 
	 See class comments of the various subclasses for details on the purpose of each kindOf AbstractRecorderFinder."
	
	self passe! !

!AbstractRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: crum {CanopyCrum}

	self subclassResponsibility! !AbstractRecorderFinder subclass: #AnyRecorderFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderFinder comment:
'NOT.A.TYPE A general superclass for finders that looks for all recorders, and all elements they might find, resulting from a given change.'!

(AnyRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AnyRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!AnyRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	"do nothing"! !

!AnyRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}

	self subclassResponsibility!

{PropFinder} nextFinder: edition {BeEdition}
	"An additional finder to use below the given Edition"
	
	self subclassResponsibility! !

!AnyRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	self subclassResponsibility! !AnyRecorderFinder subclass: #AnyRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderEFinder comment:
'Generates finders for recorders triggered by an increase in endorsements. Also remembers the (approximate) permissions on the object whose endorsements changed'!

(AnyRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissions)
			and: [p relevantEndorsements intersects: myNewEndorsements]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{PropFinder} nextFinder: edition {BeEdition}

	^ContainedEditionRecorderEFinder make: edition
		with: myPermissions
		with: myEndorsementsDelta
		with: myNewEndorsements!

{IDRegion} permissions

	^myPermissions! !

!AnyRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!AnyRecorderEFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myPermissions hashForEqual
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: AnyRecorderEFinder into: [ :other |
		^(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]
	others:
		[^false].
	^false "fodder"! !

!AnyRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^AnyRecorderEFinder make: ((p relevantPermissions intersect: myPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((p relevantEndorsements intersect: myNewEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!AnyRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AnyRecorderEFinder class
	instanceVariableNames: ''!

(AnyRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	^self make: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum flagsFor: permissions
			with: newEndorsements
			with: false)
		with: permissions with: endorsementsDelta with: newEndorsements! !AnyRecorderFinder subclass: #AnyRecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta of: IDRegion}
		myPermissions {IDRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderPFinder comment:
'Generates finders for recorders triggered by an increase in permissions'!

(AnyRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderPFinder methodsFor: 'accessing'!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^p relevantPermissions intersects: myPermissions].
	^false "fodder"!

{PropFinder} nextFinder: edition {BeEdition}

	^ResultRecorderPFinder make: edition
		with: myPermissionsDelta
		with: myPermissions
		with: edition totalEndorsements!

{IDRegion} permissions 
	
	^myPermissions!

{RegionDelta of: IDRegion} permissionsDelta
	
	^myPermissionsDelta! !

!AnyRecorderPFinder methodsFor: 'create'!

create: flags {UInt32}
	with: permissionsDelta {RegionDelta of: IDRegion}
	with: permissions {IDRegion}
	
	super create: flags.
	myPermissionsDelta := permissionsDelta.
	myPermissions := permissions.! !

!AnyRecorderPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myPermissionsDelta hashForEqual
		bitXor: myPermissions hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: AnyRecorderPFinder into: [ :other |
		^(myPermissionsDelta isEqual: other permissionsDelta)
			and: [myPermissions isEqual: other permissions]]
	others:
		[^false].
	^false "fodder"! !

!AnyRecorderPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^AnyRecorderPFinder make: myPermissionsDelta
			with: ((p relevantPermissions intersect: myPermissions) cast: IDRegion)].
	^NULL "fodder"! !

!AnyRecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myPermissions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myPermissions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AnyRecorderPFinder class
	instanceVariableNames: ''!

(AnyRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderPFinder class methodsFor: 'create'!

{PropFinder} make: permissionsDelta {RegionDelta of: IDRegion}
	
	^self make: permissionsDelta
		with: ((permissionsDelta after minus: permissionsDelta before) cast: IDRegion)!

{PropFinder} make: permissionsDelta {RegionDelta of: IDRegion}
	with: newPermissions {IDRegion}
	
	newPermissions isEmpty ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum flagsFor: newPermissions with: NULL with: false)
		with: permissionsDelta with: newPermissions.! !AbstractRecorderFinder subclass: #CumulativeRecorderFinder
	instanceVariableNames: '
		myGenerators {ImmuSet of: AnyRecorderFinder}
		myCurrent {ImmuSet of: SimpleRecorderFinder}
		myOthers {ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CumulativeRecorderFinder comment:
'Propagates a change to all recorders which might be interested in it, and picking up all elements which might newly be made visible by it. The generators make new finders as we pass by additional Edition boundaries. Also holds onto a collection of simple finders looking for recorders triggered by specific Works or Editions. The current set contains those which might record the current edition, and are passed to all Recorders. The others are only passed to Recorders with the directContainersOnly flag off.'!

(CumulativeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CumulativeRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	myCurrent stepper forEach: [ :current {SimpleRecorderFinder} |
		current checkRecorder: recorder with: fossil].
	recorder isDirectOnly ifFalse:
		[myOthers stepper forEach: [ :other {SimpleRecorderFinder} |
			other checkRecorder: recorder with: fossil]]! !

!CumulativeRecorderFinder methodsFor: 'create'!

create: flags {UInt32}
	with: generators {ImmuSet of: AnyRecorderFinder}
	with: current {ImmuSet of: SimpleRecorderFinder}
	with: others {ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder}
	
	super create: flags.
	myGenerators := generators.
	myCurrent := current.
	myOthers := others.! !

!CumulativeRecorderFinder methodsFor: 'accessing'!

{ImmuSet of: AnyRecorderFinder} current

	^myCurrent!

{PropFinder} findPast: edition {BeEdition}
	
	| newCurrent {SetAccumulator} |
	newCurrent := SetAccumulator make.
	myGenerators stepper forEach: [ :gen {AnyRecorderFinder} |
		| next {PropFinder} |
		next := gen nextFinder: edition.
		next isEmpty ifFalse:
			[newCurrent step: (next cast: SimpleRecorderFinder) "cast will catch algorithm bugs in a place from which they are easier to fix" ]].
	^CumulativeRecorderFinder
		make: myGenerators
		with: (newCurrent value cast: ImmuSet)
		with: (myOthers unionWith: myCurrent)!

{ImmuSet of: AnyRecorderFinder} generators

	^myGenerators!

{BooleanVar} match: prop {Prop}

	myGenerators stepper forEach: [ :gen {PropFinder} |
		(gen match: prop) ifTrue: [^true]].
	^false!

{ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder} others

	^myOthers!

{PropFinder} pass: parent {CanopyCrum}

	parent cast: SensorCrum into: [ :p |
		| newGenerators {SetAccumulator} newCurrent {SetAccumulator}
		  newOthers {SetAccumulator} past {PropFinder} |
		newGenerators := SetAccumulator make.
		myGenerators stepper forEach: [ :gen {PropFinder} |
			past := gen pass: p.
			past isEmpty ifFalse:
				[newGenerators step: past]].
		(newGenerators value cast: ImmuSet) isEmpty ifTrue:
			[^PropFinder closedPropFinder].
		newCurrent := SetAccumulator make.
		myCurrent stepper forEach: [ :current {PropFinder} |
			past := current pass: p.
			past isEmpty ifFalse:
				[newCurrent step: past]].
		newOthers := SetAccumulator make.
		myOthers stepper forEach: [ :other {PropFinder} |
			past := other pass: p.
			past isEmpty ifFalse:
				[newOthers step: past]].
		^CumulativeRecorderFinder
			make: (newGenerators value cast: ImmuSet)
			with: (newCurrent value cast: ImmuSet)
			with: (newOthers value cast: ImmuSet)].
	^NULL "fodder"! !

!CumulativeRecorderFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myGenerators hashForEqual
		bitXor: myCurrent hashForEqual)
		bitXor: myOthers hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: CumulativeRecorderFinder into: [ :other |
		^(myGenerators isEqual: other generators)
			and: [(myCurrent isEqual: other current)
			and: [myOthers isEqual: other others]]]
	others:
		[^false].
	^false "fodder"! !

!CumulativeRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myGenerators _ receiver receiveHeaper.
	myCurrent _ receiver receiveHeaper.
	myOthers _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myGenerators.
	xmtr sendHeaper: myCurrent.
	xmtr sendHeaper: myOthers.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CumulativeRecorderFinder class
	instanceVariableNames: ''!

(CumulativeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CumulativeRecorderFinder class methodsFor: 'create'!

{PropFinder} make: generators {ImmuSet of: SimpleRecorderFinder}
	with: current {ImmuSet of: SimpleRecorderFinder}
	with: others {ImmuSet of: SimpleRecorderFinder}
	
	| f {UInt32} |
	generators isEmpty ifTrue:
		[^PropFinder closedPropFinder].
	Ravi thingToDo. "since current & generators can have at most two elements, represent them explicitly as two OR(NULL) pointers? or make special SmallImmuSet class?"
	f := UInt32Zero.
	generators stepper forEach: [ :g {AnyRecorderFinder} |
		f := f bitOr: g flags].
	current stepper forEach: [ :c {SimpleRecorderFinder} |
		f := f bitOr: c flags].
	others stepper forEach: [ :o {AbstractRecorderFinder} |
		f := f bitOr: o flags].
	^self create: f
		with: generators
		with: current
		with: others! !AbstractRecorderFinder subclass: #SimpleRecorderFinder
	instanceVariableNames: 'myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SimpleRecorderFinder comment:
'A finder which holds onto a RangeElement and looks for ResultRecorders which might want to record it NOT.A.TYPE '!

(SimpleRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!SimpleRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}

	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	((recorder accepts: self rangeElement) and: [self shouldTrigger: recorder with: fossil]) ifTrue:
		[(RecorderTrigger make: fossil with: myRangeElement) schedule]!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}
	"Whether the recorder should be triggered with my RangeElement"
	
	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}
	with: element {BeRangeElement}

	super create: flags.
	myRangeElement := element.! !

!SimpleRecorderFinder methodsFor: 'protected:'!

{BeEdition} edition

	^myRangeElement cast: BeEdition!

{BeRangeElement} rangeElement

	^myRangeElement!

{BeWork} work

	^myRangeElement cast: BeWork! !

!SimpleRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRangeElement _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRangeElement.! !SimpleRecorderFinder subclass: #ContainedEditionRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ContainedEditionRecorderEFinder comment:
'Looks for recorders which might be triggered by an increase in endorsements in something containing my edition. Keep the total endorsements on my edition for quick reject?'!

(ContainedEditionRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ContainedEditionRecorderEFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	recorder cast: EditionRecorder into: [ :er |
		[FeServer] USES.
		CurrentKeyMaster fluidBind: er keyMaster during:
			[^(er indirectFilter isSwitchedOnBy: myEndorsementsDelta)
				and: [(er directFilter match: self edition visibleEndorsements)
				and: [self edition anyPasses: (PropFinder
					backfollowFinder: er permissionsFilter)]]]].
	^false "fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissions)
			and: [p relevantEndorsements intersects: myNewEndorsements]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{IDRegion} permissions 
	
	^myPermissions! !

!ContainedEditionRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags with: element.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!ContainedEditionRecorderEFinder methodsFor: 'testing'!

{UInt32	} actualHashForEqual

	^((self rangeElement hashForEqual
		bitXor: myPermissions hashForEqual)
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: ContainedEditionRecorderEFinder into: [ :other |
		^(self rangeElement isEqual: other rangeElement)
			and: [(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^ContainedEditionRecorderEFinder
			make: self edition
			with: ((myPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((myNewEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ContainedEditionRecorderEFinder class
	instanceVariableNames: ''!

(ContainedEditionRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ContainedEditionRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	Ravi thingToDo. "Separate out relevant endorsements from new endorsements; relevant is those on contained edition - so you can exclude paths which would never care to record that Edition. At the moment all spawned Contained...Finders will vanish at the same time, i.e. when noone cares about the new endorsements any more. Putting in the relevant endorsements as well allows them to vanish earlier. This could also be done by testing self edition totalEndorsements in match and pass."
	
	^self make: element
		with: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: permissions
			with: newEndorsements
			with: false)
		with: element
		with: permissions
		with: endorsementsDelta
		with: newEndorsements.! !SimpleRecorderFinder subclass: #OriginalResultRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
OriginalResultRecorderEFinder comment:
'Looks for recorders which might be triggered by an increase in endorsements on my RangeElement itself'!

(OriginalResultRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OriginalResultRecorderEFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	 recorder cast: EditionRecorder into: [ :er |
	 	^(er directFilter isSwitchedOnBy: myEndorsementsDelta)
	 		and: [self edition anyPasses: (PropFinder
	 			backfollowFinder: er permissionsFilter
	 			with: er indirectFilter)]]
	 cast: WorkRecorder into: [ :wr |
	 	^(wr endorsementsFilter isSwitchedOnBy: myEndorsementsDelta)
	 		and: [self work canBeReadBy: wr keyMaster]].
	^false "fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantEndorsements intersects: myNewEndorsements)
			and: [p relevantPermissions intersects: myPermissions]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{IDRegion} permissions 
	
	^myPermissions! !

!OriginalResultRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags with: element.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!OriginalResultRecorderEFinder methodsFor: 'testing'!

{UInt32	} actualHashForEqual

	^((self rangeElement hashForEqual
		bitXor: myPermissions hashForEqual)
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: OriginalResultRecorderEFinder into: [ :other |
		^(self rangeElement isEqual: other rangeElement)
			and: [(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^OriginalResultRecorderEFinder
			make: self rangeElement
			with: ((myPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((myNewEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OriginalResultRecorderEFinder class
	instanceVariableNames: ''!

(OriginalResultRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OriginalResultRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	^self make: element
		with: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: permissions
			with: newEndorsements
			with: false)
		with: element
		with: permissions
		with: endorsementsDelta
		with: newEndorsements.! !SimpleRecorderFinder subclass: #ResultRecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta}
		myNewPermissions {IDRegion}
		myEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ResultRecorderPFinder comment:
'Looks for records which might be triggered by in increase in visibility of my RangeElement'!

(ResultRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ResultRecorderPFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: newPermissions {IDRegion}
	with: endorsements {CrossRegion}

	super create: flags with: element.
	myPermissionsDelta := permissionsDelta.
	myNewPermissions := newPermissions.
	myEndorsements := endorsements.! !

!ResultRecorderPFinder methodsFor: 'accessing'!

{CrossRegion} endorsements

	^myEndorsements!

{BooleanVar} match: prop {Prop} 

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissionsDelta after)
			and: [p relevantEndorsements intersects: myEndorsements]].
	^false "fodder"!

{IDRegion} newPermissions 
	
	^myNewPermissions!

{RegionDelta of: IDRegion} permissionsDelta
	
	^myPermissionsDelta! !

!ResultRecorderPFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	(recorder permissionsFilter isSwitchedOnBy: myPermissionsDelta) ifTrue:
		[recorder cast: EditionRecorder into: [ :er |
			CurrentKeyMaster fluidBind: er keyMaster during:
				[^er directFilter match: self edition visibleEndorsements]]
		cast: WorkRecorder into: [ :wr |
			^wr endorsementsFilter match: self work endorsements]]
	ifFalse:
		[^false].
	^false "fodder"! !

!ResultRecorderPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myPermissionsDelta hashForEqual
		bitXor: myNewPermissions hashForEqual)
		bitXor: myEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: ResultRecorderPFinder into: [ :other |
		^(myPermissionsDelta isEqual: other permissionsDelta)
			and: [(myNewPermissions isEqual: other newPermissions)
			and: [myEndorsements isEqual: other endorsements]]]
	others:
		[^false].
	^false "fodder"! !

!ResultRecorderPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^ResultRecorderPFinder make: self rangeElement
			with: myPermissionsDelta
			with: ((myNewPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: ((myEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!ResultRecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myNewPermissions _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myNewPermissions.
	xmtr sendHeaper: myEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ResultRecorderPFinder class
	instanceVariableNames: ''!

(ResultRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ResultRecorderPFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: endorsements {CrossRegion}

	^self make: element
		with: permissionsDelta
		with: ((permissionsDelta after minus: permissionsDelta before) cast: IDRegion)
		with: endorsements.!

{PropFinder} make: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: newPermissions {IDRegion}
	with: endorsements {CrossRegion}

	(newPermissions isEmpty or: [endorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: newPermissions
			with: endorsements
			with: false)
		with: element with: permissionsDelta with: newPermissions with: endorsements.! !SensorPropFinder subclass: #PartialityFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PartialityFinder comment:
'When walking the o-plane to separate out the "partial" part of an Edition, this finder is used to filter the walk according to the sensor canopy.'!

(PartialityFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SMALLTALK.ONLY; add: #OBSOLETE; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!PartialityFinder methodsFor: 'create'!

create

	super create: SensorCrum isPartialFlag! !

!PartialityFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: SensorProp) isPartial! !

!PartialityFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: PartialityFinder! !

!PartialityFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: SensorPropJoint) isPartial
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!PartialityFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
(CxxSystemOrganization fileNamed: 'props')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'props')
	addClass: PropFinder
getOrMakeCxxClassDescription in: #public;
	addClass: Prop
getOrMakeCxxClassDescription in: #public;
	addClass: BertProp
getOrMakeCxxClassDescription in: #public;
	addClass: SensorProp
getOrMakeCxxClassDescription in: #public;
	addClass: PropChange
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'props')
	addClass: CannotPartializeChange
getOrMakeCxxClassDescription in: #private;
	addClass: DetectorWaitingChange
getOrMakeCxxClassDescription in: #private;
	addClass: FullPropChange
getOrMakeCxxClassDescription in: #private;
	addClass: SensorPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: OpenPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: BertPropChange
getOrMakeCxxClassDescription in: #private;
	addClass: EndorsementsChange
getOrMakeCxxClassDescription in: #private;
	addClass: AbstractRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: ClosedPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: PermissionsChange
getOrMakeCxxClassDescription in: #private;
	addClass: BertPropFinder
getOrMakeCxxClassDescription in: #private;
	addClass: SimpleRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: AnyRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: ContainedEditionRecorderEFinder
getOrMakeCxxClassDescription in: #private;
	addClass: ResultRecorderPFinder
getOrMakeCxxClassDescription in: #private;
	addClass: PartialityFinder
getOrMakeCxxClassDescription in: #private;
	addClass: BackfollowFinder
getOrMakeCxxClassDescription in: #private;
	addClass: AnyRecorderEFinder
getOrMakeCxxClassDescription in: #private;
	addClass: CannotPartializeFinder
getOrMakeCxxClassDescription in: #private;
	addClass: SensorPropChange
getOrMakeCxxClassDescription in: #private;
	addClass: SensorFinder
getOrMakeCxxClassDescription in: #private;
	addClass: CumulativeRecorderFinder
getOrMakeCxxClassDescription in: #private;
	addClass: BackfollowPFinder
getOrMakeCxxClassDescription in: #private;
	addClass: AnyRecorderPFinder
getOrMakeCxxClassDescription in: #private;
	addClass: OriginalResultRecorderEFinder
getOrMakeCxxClassDescription in: #private!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'props' value: #file) yourself))!