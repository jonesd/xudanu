'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:40:21 pm'!

((CxxSystemOrganization tree childNamed: 'fmcrap') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'fmcrap') destroyFiles]!


(CxxSystemOrganization fileNamed: 'transform')
	comment: ''!

(CxxSystemOrganization fileNamed: 'runmdl')
	comment: ''!

(CxxSystemOrganization fileNamed: 'fmdirect')
	comment: ''!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'fmcrap' value: nil)
 addChild: ((CxxTreeAssociation key: 'transform' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'runmdl' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'fmdirect' value: #file) yourself); yourself))!