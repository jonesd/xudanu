'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:54 pm'!

XnDependent subclass: #BoolM2ImageSchnert
	instanceVariableNames: '
		myImageModel {VariableModel of: Image}
		myBooleanModel {BooleanModel}
		myImages {Pair of: Image}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-imagevu'!

(BoolM2ImageSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoolM2ImageSchnert methodsFor: 'creation'!

create: boolM {BooleanModel} with: imageM {VariableModel of: Image} with: imagePair {Pair of: Image}

	super create.
	myBooleanModel _ boolM.
	myImageModel _ imageM.
	myImages _ imagePair.
	myBooleanModel addDependent: self.
	self setModel!

{void} destruct

	myBooleanModel getCategory ~= Heaper ifTrue:
		[myBooleanModel removeDependent: self].
	myBooleanModel _ NULL.
	myImageModel _ NULL.
	myImages _ NULL.
	super destruct! !

!BoolM2ImageSchnert methodsFor: 'updating'!

{void} setModel
	| myNew {Heaper} |
	myBooleanModel getValue
		ifTrue: [myNew _ myImages left]
		ifFalse: [myNew _ myImages right].
	myImageModel setValue: myNew!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	self setModel! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BoolM2ImageSchnert class
	instanceVariableNames: ''!

(BoolM2ImageSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoolM2ImageSchnert class methodsFor: 'make'!

make: boolM {BooleanModel} with: imageM {VariableModel of: Image} with: images {Pair of: Image and: Image}

	^ self create: boolM with: imageM with: images! !