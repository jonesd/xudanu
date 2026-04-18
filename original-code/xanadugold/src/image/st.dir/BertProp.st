'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:48 pm'!

Prop subclass: #BertProp
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

	self passe! !