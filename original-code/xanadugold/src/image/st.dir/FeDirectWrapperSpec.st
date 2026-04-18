'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:21 pm'!

FeConcreteWrapperSpec subclass: #FeDirectWrapperSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeDirectWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeDirectWrapperSpec methodsFor: 'accessing'!

{BooleanVar} wraps: other {FeConcreteWrapperSpec}

	^self == other! !

!FeDirectWrapperSpec methodsFor: 'private:'!

{BooleanVar} certify: edition {FeEdition}
	"Try to certify as this type. If successful, return TRUE and endorse it; if not, return FALSE."
	((self def cast: FeDirectWrapperDef) check: edition) ifTrue:
		[self endorse: edition.
		^true]
	ifFalse:
		[^false]! !

!FeDirectWrapperSpec methodsFor: 'create'!

create: def {FeDirectWrapperDef}
	super create: def! !

!FeDirectWrapperSpec methodsFor: 'vulnerable'!

{FeWrapper} fetchWrap: edition {FeEdition}

	((self isCertified: edition) or: [self certify: edition]) ifTrue:
		[^(self def cast: FeDirectWrapperDef) makeWrapper: edition]
	ifFalse:
		[^NULL]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeDirectWrapperSpec class
	instanceVariableNames: ''!

(FeDirectWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeDirectWrapperSpec class methodsFor: 'pseudo constructors'!

make: def {FeDirectWrapperDef}

	^self create: def! !