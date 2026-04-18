'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:10 pm'!

CRFilter subclass: #CRNotFilter
	instanceVariableNames: 'myFilter {CRFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRNotFilter methodsFor: 'accessing'!

{String} label
	
	^ 'Not ' , myFilter label!

{BooleanVar} passes: cr {ChangeRecord}
	
	^ (myFilter passes: cr) not! !

!CRNotFilter methodsFor: 'create'!

create: filter {CRFilter}

	super create.
	myFilter _ filter! !