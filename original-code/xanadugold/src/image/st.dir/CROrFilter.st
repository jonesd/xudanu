'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:10 pm'!

CRFilter subclass: #CROrFilter
	instanceVariableNames: '
		myAFilter {CRFilter}
		myBFilter {CRFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CROrFilter methodsFor: 'accessing'!

{String} label
	
	^ myAFilter label , ' or ' , myBFilter label!

{BooleanVar} passes: cr {ChangeRecord}
	
	^ (myAFilter passes: cr) or: [myBFilter passes: cr]! !

!CROrFilter methodsFor: 'create'!

create: a {CRFilter} with: b {CRFilter}

	super create.
	myAFilter _ a.
	myBFilter _ b! !