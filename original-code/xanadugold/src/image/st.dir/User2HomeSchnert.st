'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:54 pm'!

XnModel subclass: #User2HomeSchnert
	instanceVariableNames: '
		myUser {UserModel}
		myHome {WaldoModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
User2HomeSchnert comment:
'Retrives the user''s home document'!

(User2HomeSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2HomeSchnert methodsFor: 'create'!

create: who {UserModel} with: home {HomeDocumentModel}
	super create.
	myUser _ who.
	myHome _ home.
	myUser addDependent: self.
	self updateHome! !

!User2HomeSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	"change the home document"

	model == (myUser basicCast: XnModel) ifTrue: [self updateHome]! !

!User2HomeSchnert methodsFor: 'private: private updating'!

{void} updateHome
	myHome setWaldo: myUser keyMaster getHomeDocID
		with: (Sequence string: 'IndexedWaldo')
		with: true
		with: myUser keyMaster! !

!User2HomeSchnert methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' (myUser = ' << myUser << '
	myHome =  ' << myUser << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

User2HomeSchnert class
	instanceVariableNames: ''!

(User2HomeSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2HomeSchnert class methodsFor: 'make'!

make: who {UserModel} with: home {HomeDocumentModel}
	^self create: who with: home! !