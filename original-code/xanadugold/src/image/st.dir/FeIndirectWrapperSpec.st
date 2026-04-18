'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:22 pm'!

FeConcreteWrapperSpec subclass: #FeIndirectWrapperSpec
	instanceVariableNames: 'myInner {FeConcreteWrapperSpec}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeIndirectWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeIndirectWrapperSpec methodsFor: 'accessing'!

{BooleanVar} wraps: other {FeConcreteWrapperSpec}

	^self == other or: [myInner wraps: other]! !

!FeIndirectWrapperSpec methodsFor: 'private:'!

{BooleanVar} certify: inner {FeEdition}
	"Try to certify as this type. If successful, return TRUE and endorse it; if not, return FALSE."
	(self indirectDef check: inner) ifTrue:
		[self endorse: inner.
		^true]
	ifFalse:
		[^false]!

{FeIndirectWrapperDef} indirectDef
	^self def cast: FeIndirectWrapperDef! !

!FeIndirectWrapperSpec methodsFor: 'protected:'!

{void} setup

	super setup.
	myInner := (FeWrapperSpec get: self indirectDef innerDefName) cast: FeConcreteWrapperSpec! !

!FeIndirectWrapperSpec methodsFor: 'create'!

create: def {FeIndirectWrapperDef}
	super create: def.
	myInner := NULL.! !

!FeIndirectWrapperSpec methodsFor: 'vulnerable'!

{FeWrapper | NULL} fetchWrap: edition {FeEdition}

	| inner {FeWrapper} |
	inner := myInner wrap: edition.
	((self isCertified: edition) or: [self certify: edition]) ifTrue:
		[^self indirectDef makeWrapper: edition with: inner].
	^NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeIndirectWrapperSpec class
	instanceVariableNames: ''!

(FeIndirectWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeIndirectWrapperSpec class methodsFor: 'pseudo constructors'!

make: def {FeIndirectWrapperDef}

	^self create: def! !