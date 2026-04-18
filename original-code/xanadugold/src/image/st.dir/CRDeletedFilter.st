'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:09 pm'!

CRFilter subclass: #CRDeletedFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRDeletedFilter methodsFor: 'accessing'!

{String} label
	^ 'huh?'!

{BooleanVar} passes: cr {ChangeRecord}
	^ cr deleted! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CRDeletedFilter class
	instanceVariableNames: ''!



!CRDeletedFilter class methodsFor: 'make'!

deleted

	^ self create!

notDeleted

	^ CRNotFilter make: (self create)! !