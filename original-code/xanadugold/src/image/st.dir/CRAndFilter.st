'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:08 pm'!

CRFilter subclass: #CRAndFilter
	instanceVariableNames: '
		myAFilter {CRFilter}
		myBFilter {CRFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRAndFilter methodsFor: 'accessing'!

{String} label
	^myAFilter label , ' and ' , myBFilter label!

{BooleanVar} passes: cr {ChangeRecord}
	
	^ (myAFilter passes: cr) and: [myBFilter passes: cr]! !

!CRAndFilter methodsFor: 'create'!

create: a {CRFilter} with: b {CRFilter}

	super create.
	myAFilter _ a.
	myBFilter _ b! !