'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:07 pm'!

Object subclass: #ChangeRecordRep
	instanceVariableNames: 'myRecord myEmphasis '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log'!


!ChangeRecordRep methodsFor: 'ops'!

= another {Object}
	^(another isKindOf: self class) and: [myRecord = another record]!

printOn: oo {ostream reference}
	oo emphasis: myEmphasis;
		nextPutAll: myRecord printString;
		emphasis: 1!

record
	^ myRecord! !

!ChangeRecordRep methodsFor: 'create'!

create: record {ChangeRecord} with: emphasis {Integer}

	myRecord _ record.
	myEmphasis _ emphasis.! !