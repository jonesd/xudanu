'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:20 pm'!

FeWrapperSpec subclass: #FeConcreteWrapperSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeConcreteWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeConcreteWrapperSpec methodsFor: 'protected:'!

{void} setup

	super setup.
	self fetchSuperSpec ~~ NULL ifTrue:
		[self fetchSuperSpec setupConcreteSubSpec: self].! !

!FeConcreteWrapperSpec methodsFor: 'accessing'!

{BooleanVar} certify: edition {FeEdition}

	self subclassResponsibility!

{BooleanVar} wraps: other {FeConcreteWrapperSpec}
	"Whether I can wrap the given type"
	self subclassResponsibility! !

!FeConcreteWrapperSpec methodsFor: 'create'!

create: def {FeWrapperDef}
	super create: def! !

!FeConcreteWrapperSpec methodsFor: 'for wrappers only'!

{void} endorse: edition {FeEdition}
	"Endorse an Edition as being of this type"
	
	[BeEdition] USES.
	edition beEdition endorse: self endorsements! !

!FeConcreteWrapperSpec methodsFor: 'vulnerable'!

{FeWrapper | NULL} fetchWrap: edition {FeEdition}

	self subclassResponsibility! !