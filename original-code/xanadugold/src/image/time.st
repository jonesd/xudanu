'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:40:29 pm'!

((CxxSystemOrganization tree childNamed: 'time') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'time') destroyFiles]!

Object subclass: #TimeVar
	instanceVariableNames: 'aTime {UInt4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-time'!



!TimeVar methodsFor: 'creation'! !

!TimeVar methodsFor: 'testing'! !

!TimeVar methodsFor: 'math'!

{TimeVar} difference: from {TimeVar}! !
(CxxSystemOrganization fileNamed: 'time')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'time')
	addClass: TimeVar
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'time' value: #file) yourself))!