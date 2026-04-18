'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:45 pm'!

Heaper subclass: #ApplicationModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Never Never Land'!



!ApplicationModel methodsFor: 'operations'!

{PassageModel} createPassage: permissions {ID unused}
	"create a new, empty passage"
	self hack. "ignoring permissions"
	^(self getDocument: (self user keyMaster
		makeEmptyWaldo: (Sequence string: 'XuText'))
			editionID) cast: PassageModel! !

!ApplicationModel methodsFor: 'clubs'!

{PermissionsModel} makeUserClub: km {KeyMaster}

	| nuClub {ClubManager} nuDir {XuDirectory}
	  nuHome {Waldo} nuID {ID} |
	nuClub _ km makeClub.
	nuClub lockSmith: (LockSmith booLockSmith: km).
	nuDir _ XuDirectory newDirectory: km with: nuClub getID.
	nuDir destroy.
	nuHome _ km makePersistentWaldo: (Sequence string: 'DirectRecord').
	nuClub homeDocID: nuHome getID.
	nuHome destroy.
	nuID _ nuClub getID.
	nuClub destroy.
	^PermissionsModel fetchPermissionsModel: km with: nuID! !

!ApplicationModel methodsFor: 'private: private'!

{DocumentModel} createDocModel: ofType {ID} with: editors {ScruSet default: NULL} with: readers {ScruSet default: NULL}
	
	"Create a new document model of the type specified and enter it into my list of documents.  This is done to keep a waldo on the document in case there is no bert on the document (and therefore making it inaccessible, except through the original waldo)."
	
	| newWaldo {Waldo} docModel {DocumentModel} |
	newWaldo _ self user keyMaster makePersistentWaldo: ofType.
	docModel _ newWaldo convert: DocumentModel.
	(editors ~~ NULL and: [editors isEmpty not]) 
		ifTrue: [docModel getEditPermissions addAll: editors].
	(readers ~~ NULL and: [readers isEmpty not])
		ifTrue: [docModel getReadPermissions addAll: readers].
	self documents at: docModel iD introduce: docModel.
	^ docModel! !