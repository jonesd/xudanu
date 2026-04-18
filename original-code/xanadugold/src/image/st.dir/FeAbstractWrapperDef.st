'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:19 pm'!

FeWrapperDef subclass: #FeAbstractWrapperDef
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeAbstractWrapperDef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!FeAbstractWrapperDef methodsFor: 'create'!

create: name {Sequence} with: superName {Sequence | NULL} with: holder {FeWrapperSpecHolder var | NULL}

	super create: name with: superName with: holder.! !

!FeAbstractWrapperDef methodsFor: 'accessing'!

{FeWrapperSpec} makeSpec
	
	^FeAbstractWrapperSpec make: self! !

!FeAbstractWrapperDef methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !