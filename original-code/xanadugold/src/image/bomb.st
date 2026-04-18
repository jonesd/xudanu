'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:39:55 pm'!

((CxxSystemOrganization tree childNamed: #bomb) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #bomb) destroyFiles]!

Object subclass: #Problem
	instanceVariableNames: '
		myProblemName {char star}
		myVal {int}
		myFileName {char star}
		myLineNumber {int}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-bomb'!



!Problem methodsFor: 'accessing'!

getFileName
	^myFileName!

getLineNumber
	^myLineNumber!

getProblemName
	^myProblemName!

getVal
	^myVal!

name
	^myProblemName! !

!Problem methodsFor: 'creation'!

create: name with: val with: file with: line
	myProblemName _ name.
	myVal _ val.
	myFileName _ file.
	myLineNumber _ line! !
(CxxSystemOrganization fileNamed: 'bomb')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'bomb')
	addClass: Problem
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #bomb value: #file) yourself))!