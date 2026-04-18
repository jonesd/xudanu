'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:10 pm'!

CRFilter subclass: #CRIdentifierFilter
	instanceVariableNames: 'myIdent {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRIdentifierFilter methodsFor: 'accessing'!

{String} label
	^ myIdent!

{BooleanVar} passes: cr {ChangeRecord}
	
	^ myIdent == cr identifier! !

!CRIdentifierFilter methodsFor: 'create'!

create: onIdent {Symbol}
	super create.
	myIdent _ onIdent! !