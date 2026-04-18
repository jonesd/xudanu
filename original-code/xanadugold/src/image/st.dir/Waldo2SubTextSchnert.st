'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:29 pm'!

XnDependent subclass: #Waldo2SubTextSchnert
	instanceVariableNames: '
		myParent {WaldoModel}
		myKey {ID}
		myText {WaldoTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
Waldo2SubTextSchnert comment:
'Pulls a text waldo out of a DirectRecord (or wrapper of one)'!

(Waldo2SubTextSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubTextSchnert methodsFor: 'private: private updating'!

{void} updateText
	myText replaceWith: ((myParent waldo getChild: myKey) cast: XuText)! !

!Waldo2SubTextSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	(model == (myParent basicCast: XnModel) 
        	and: [change isKindOf: NewContentsUpdate]) ifTrue:
                [self updateText]! !

!Waldo2SubTextSchnert methodsFor: 'create'!

create: parent {WaldoModel} with: key {ID} with: text {WaldoTextModel}
	super create.
	myParent _ parent.
	myKey _ key.
	myText _ text.
	myParent addDependent: self.
	self updateText! !

!Waldo2SubTextSchnert methodsFor: 'protected: creation'!

{void} destruct
	myParent removeDependent: self.
	super destruct! !

!Waldo2SubTextSchnert methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo <<  self getCategory name<< 'myParent = ' << myParent 
		<< 'myKey = ' << myKey 
		<< 'myText = ' << myText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Waldo2SubTextSchnert class
	instanceVariableNames: ''!

(Waldo2SubTextSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubTextSchnert class methodsFor: 'make'!

make: parent {WaldoModel} with: key {ID} with: text {WaldoTextModel}
	^self create: parent with: key with: text! !