'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:15 pm'!

Dsp subclass: #IntegerMapping
	instanceVariableNames: 'myTranslation {IntegerVar}'
	classVariableNames: 'TheIdentityIntegerMapping {IntegerMapping star} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
IntegerMapping comment:
'Transforms integers by adding a (possibly negative) offset.  In addition to the Dsp protocol, an IntegerDsp will respond to "translation" with the offset that it is adding.  
	
	Old documentation indicated a possibility of a future upgrade of IntegerDsp which would also optionally reflect (or negate) its input in addition to offsetting.  This would however be a non-upwards compatable change in that current clients already assume that the answer to "translation" fully describes the IntegerDsp.  If such a possibility is introduced, it should be as a super-type of IntegerDsp, since it would have a weaker contract.  Then compatability problems can be caught by the type checker.'!

(IntegerMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class IntegerDsp */
friend class IntegerSpace;
';
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!IntegerMapping methodsFor: 'unprotected for init creation'!

create: translation {IntegerVar}
	"Initialize instance variables"
	super create.
	myTranslation _ translation.! !

!IntegerMapping methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << myTranslation << ')'! !

!IntegerMapping methodsFor: 'transforming'!

{Position} inverseOf: pos {Position} 

	(pos ~~ NULL) assert.
	"shouldn't be necessary, but the old code used to check for NULL 
	so I want to make sure I haven't broken anything"
	self == TheIdentityIntegerMapping
		ifTrue: [^pos]
		ifFalse: [^((pos cast: IntegerPos) asIntegerVar - myTranslation) integer]!

{XnRegion} inverseOfAll: reg {XnRegion} 

	| region {IntegerRegion} result {IntegerEdgeAccumulator} edges {IntegerEdgeStepper} resultReg {XnRegion} |
	self == TheIdentityIntegerMapping
		ifTrue: [^reg]
		ifFalse: 
			[region _ reg cast: IntegerRegion.
			"Transform an interval by transforming the endpoints"
			result _ IntegerEdgeAccumulator make: region isBoundedBelow not with: region transitionCount.
			edges _ region edgeStepper.
			[edges hasValue]
				whileTrue: [result edge: (self inverseOfInt: edges edge).
					edges step].
			edges destroy.
			resultReg _ result region.
			result destroy.
			^ resultReg]!

{IntegerVar} inverseOfInt: pos {IntegerVar}

	self == TheIdentityIntegerMapping ifTrue: [^pos].
	^pos - myTranslation!

{Position} of: pos {Position} 

	(pos ~~ NULL) assert.
	"shouldn't be necessary, but the old code used to check for NULL 
	so I want to make sure I haven't broken anything"
	
	self == TheIdentityIntegerMapping
		ifTrue: [^pos]
		ifFalse: [^(myTranslation + (pos cast: IntegerPos) asIntegerVar) integer]!

{XnRegion} ofAll: reg {XnRegion} 

	| region {IntegerRegion} 
	  result {IntegerEdgeAccumulator} 
	  edges {IntegerEdgeStepper}
	  resultReg {XnRegion} |
	  
	self == TheIdentityIntegerMapping
		ifTrue: [^reg]
		ifFalse: 
			[region _ reg cast: IntegerRegion.
			"Transform an interval by transforming the endpoints"
			result _ IntegerEdgeAccumulator 
						make: region isBoundedBelow not 
						with: region transitionCount.
			edges _ region edgeStepper.
			[edges hasValue]
				whileTrue: [result edge: (self ofInt: edges edge).
					edges step].
			edges destroy.
			resultReg _ result region.
			result destroy.
			^ resultReg]!

{IntegerVar} ofInt: pos {IntegerVar}

	self == TheIdentityIntegerMapping ifTrue: [^pos].
	^ myTranslation + pos! !

!IntegerMapping methodsFor: 'accessing'!

{CoordinateSpace INLINE} coordinateSpace

	^ IntegerSpace make!

{BooleanVar INLINE} isIdentity
	^ myTranslation = IntegerVar0!

{IntegerVar CLIENT INLINE} translation
	"The offset which I add to a position.  
	If my translation is 7, then this->of(4) is 11."
	
	^myTranslation! !

!IntegerMapping methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^ (myTranslation) DOTasLong + #cat.U.IntegerMapping hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	"Should have same offset and reversal"

	other
		cast: IntegerMapping into: [:iDsp |
			^iDsp translation = myTranslation]
		others: [^false].
	^ false "compiler fodder"! !

!IntegerMapping methodsFor: 'combining'!

{Dsp} compose: other {Dsp} 

	self == TheIdentityIntegerMapping
		ifTrue: [^ other]
		ifFalse: [other == TheIdentityIntegerMapping ifTrue: [^ self]].
	^IntegerMapping make: (myTranslation + (other quickCast: IntegerMapping) translation)!

{Mapping} inverse

	self == TheIdentityIntegerMapping ifTrue: [^self].
	^IntegerMapping make: myTranslation negated!

{Dsp} inverseCompose: other {Dsp}

	self == TheIdentityIntegerMapping
		ifTrue: [ ^ other ]
		ifFalse: [ ^ other minus: self ]!

{Dsp} minus: other {Dsp} 

	other == TheIdentityIntegerMapping
		ifTrue: [ ^self ]
		ifFalse: [ ^IntegerMapping make: (myTranslation - (other cast: IntegerMapping) translation)]! !

!IntegerMapping methodsFor: 'sender'!

{void SEND.HOOK} sendIntegerMapping: xmtr {Xmtr}
	xmtr sendIntegerVar: myTranslation.! !

!IntegerMapping methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}
	
	self sendIntegerMapping: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerMapping class
	instanceVariableNames: ''!

(IntegerMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class IntegerDsp */
friend class IntegerSpace;
';
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!IntegerMapping class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	TheIdentityIntegerMapping _ (IntegerMapping new.AllocType: #PERSISTENT) create: IntegerVar0!

linkTimeNonInherited
	TheIdentityIntegerMapping _ NULL! !

!IntegerMapping class methodsFor: 'pseudo constructors'!

make

	^IntegerSpace make identityDsp cast: IntegerMapping!

{Heaper} make.Rcvr: rcvr {Rcvr}
	| translate {IntegerVar} result {Heaper} |
	translate _ rcvr receiveIntegerVar.
	translate == IntegerVarZero
		ifTrue: [result _ TheIdentityIntegerMapping]
		ifFalse: [result _ self create: translate].
	(rcvr cast: SpecialistRcvr) registerIbid: result.
	^result!

make: translate {IntegerVar}

	translate == IntegerVar0
		ifTrue: [^self make]
		ifFalse: [^self create: translate]! !

!IntegerMapping class methodsFor: 'private: for create'!

{Dsp} identity

	^self create: IntegerVarZero! !

!IntegerMapping class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT} translation
"! !