'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:08 pm'!

CRFilter subclass: #CRClassFilter
	instanceVariableNames: 'myClassname {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRClassFilter methodsFor: 'accessing'!

{String} label
	^ myClassname asString!

{BooleanVar} passes: cr {ChangeRecord}
	^ (cr isKindOf: ClassRelatedCR) and: [cr className == myClassname]! !

!CRClassFilter methodsFor: 'create'!

create: onClass {Symbol}

	myClassname _ onClass asSymbol! !