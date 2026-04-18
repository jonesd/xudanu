'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:53 pm'!

PropJoint subclass: #BertPropJoint
	instanceVariableNames: '
		myPermissionsJoint {Joint of: (XnRegion of: ID)}
		myEndorsementsJoint {Joint of: (XnRegion of: ID)}
		mySensorWaitingFlag {BooleanVar}
		myCannotPartializeFlag {BooleanVar}'
	classVariableNames: '
		CannotPartializePropJoint {BertPropJoint} 
		IdentityBertPropJoint {BertPropJoint} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!

(BertPropJoint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!BertPropJoint methodsFor: 'testing'!

{UInt32} hashForEqual
	| result {UInt32} |
	result _ UInt32Zero.
	mySensorWaitingFlag ifTrue: [result _ result bitXor: 1].
	myCannotPartializeFlag ifTrue: [result _ result bitXor: 2].
	^(myPermissionsJoint hashForEqual bitXor: myEndorsementsJoint hashForEqual) bitXor: result!

{BooleanVar} isEqual: other {Heaper}
	other cast: BertPropJoint into: [:o |
			^(myPermissionsJoint isEqual: o permissionsJoint)
				and: [(myEndorsementsJoint isEqual: o endorsementsJoint)
				and: [mySensorWaitingFlag = o isSensorWaiting
				and: [myCannotPartializeFlag = o isNotPartializable]]]]
		others: [^false].
	^ false "compiler fodder"! !

!BertPropJoint methodsFor: 'accessing'!

{Joint of: (XnRegion of: ID)} endorsementsJoint
	^myEndorsementsJoint!

{BooleanVar} isNotPartializable
	^myCannotPartializeFlag!

{BooleanVar} isSensorWaiting
	^mySensorWaitingFlag!

{PropJoint} join: other {PropJoint}
	| o {BertPropJoint wimpy} |
	o _ other cast: BertPropJoint.
	^BertPropJoint make: (myPermissionsJoint join: o permissionsJoint)
		with: (myEndorsementsJoint join: o endorsementsJoint)
		with: (mySensorWaitingFlag or: [o isSensorWaiting])
		with: (myCannotPartializeFlag or: [o isNotPartializable])!

{Joint of: (XnRegion of: ID)} permissionsJoint
	^myPermissionsJoint!

{PropJoint} with: prop {Prop}
	| p {BertProp wimpy} |
	p _ prop cast: BertProp.
	^BertPropJoint make: (myPermissionsJoint with: p permissions)
		with: (myEndorsementsJoint with: p endorsements)
		with: (mySensorWaitingFlag or: [p isSensorWaiting])
		with: (myCannotPartializeFlag or: [p isNotPartializable])! !

!BertPropJoint methodsFor: 'creation'!

create: permissionsJoint {Joint of: (XnRegion of: ID)} 
	with: endorsementsJoint {Joint of: (XnRegion of: ID)} 
	with: isSensorWaiting {BooleanVar} 
	with: isNotPartializable {BooleanVar}
	super create.
	myPermissionsJoint _ permissionsJoint.
	myEndorsementsJoint _ endorsementsJoint.
	mySensorWaitingFlag _ isSensorWaiting.
	myCannotPartializeFlag _ isNotPartializable.! !

!BertPropJoint methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name
		<< '(perm: ' << myPermissionsJoint
		<< '; end: ' << myEndorsementsJoint.
	mySensorWaitingFlag ifTrue: [oo << '; sensor'].
	myCannotPartializeFlag ifTrue: [oo << '; cannot partialize'].
	oo << ')'! !

!BertPropJoint methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsJoint _ receiver receiveHeaper.
	myEndorsementsJoint _ receiver receiveHeaper.
	mySensorWaitingFlag _ receiver receiveBooleanVar.
	myCannotPartializeFlag _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsJoint.
	xmtr sendHeaper: myEndorsementsJoint.
	xmtr sendBooleanVar: mySensorWaitingFlag.
	xmtr sendBooleanVar: myCannotPartializeFlag.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BertPropJoint class
	instanceVariableNames: ''!

(BertPropJoint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!BertPropJoint class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	IdentityBertPropJoint _ NULL! !

!BertPropJoint class methodsFor: 'creation'!

make

	IdentityBertPropJoint == NULL ifTrue:
		[IdentityBertPropJoint := self
			make: (Joint make.CoordinateSpace: IDSpace global)
			with: (Joint make.CoordinateSpace: CurrentGrandMap fluidGet endorsementSpace)
			with: false
			with: false].
	^IdentityBertPropJoint!

make: permissionsJoint {Joint of: (XnRegion of: ID)} 
	with: endorsementsJoint {Joint of: (XnRegion of: ID)} 
	with: isSensorWaiting {BooleanVar} 
	with: isNotPartializable {BooleanVar} 
	^self
		create: permissionsJoint
		with: endorsementsJoint
		with: isSensorWaiting
		with: isNotPartializable! !