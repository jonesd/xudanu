'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:27 pm'!

Thunk subclass: #FollowThunk
	instanceVariableNames: 'myWindow {DocumentWindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!
FollowThunk comment:
'Follows a reference and opens a window on the other end when invoked, selecting the appropriate contents

		myReferences {ListModel of: Reference}
			The references which might be followed
		mySelection {SelectionObject}
			Uses the selection point to determine which of the references to follow'!

(FollowThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FollowThunk methodsFor: 'create'!

create: window {DocumentWindowModel}
	super create.
	myWindow _ window! !

!FollowThunk methodsFor: 'operate'!

{void} execute
	"open a new window on the other end of the link"
	|  result {Pair of: ID and: Reference} doc {DocumentModel} |
	[Cursor wait showWhile: [
		result _ self follow]] smalltalkOnly.
	[result _ self follow] translateOnly.
	doc _ Application fluidGet getDocument: (result left cast: ID).
	Application fluidGet openWindowAt: doc
		with: ((result right cast: Reference) regionIn: doc)! !

!FollowThunk methodsFor: 'private: private'!

{Pair of: ID and: Reference} follow
	"choose a reference and follow it"
	self thingToDo. "menu for multiple endsets and ends"
	^((myWindow references
		get: (myWindow referencesSelection selectionPoint
			cast: IntegerPos) asIntegerVar)
	cast: Reference) follow: myWindow document! !

!FollowThunk methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<<  'myWindow = ' <<  myWindow! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FollowThunk class
	instanceVariableNames: ''!

(FollowThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FollowThunk class methodsFor: 'pseudo constructors'!

make: window {DocumentWindowModel}
	^self create: window! !