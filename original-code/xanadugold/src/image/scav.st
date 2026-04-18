'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:39:06 pm'!

((CxxSystemOrganization tree childNamed: #scav) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #scav) destroyFiles]!

Object subclass: #Heaplet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-scav'!

(Heaplet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #SMALLTALK.ONLY; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Heaplet class
	instanceVariableNames: ''!

(Heaplet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #SMALLTALK.ONLY; yourself)!

!Heaplet class methodsFor: 'collection'!

garbageCollect! !
(CxxSystemOrganization fileNamed: 'scav')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'scav')
	addClass: Heaplet
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #scav value: #file) yourself))!