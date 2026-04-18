'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:11 pm'!

CRTypeFilter subclass: #CRUserFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRUserFilter methodsFor: 'accessing'!

{BooleanVar} passes: cr {ChangeRecord}
	^ self types includes: cr user! !