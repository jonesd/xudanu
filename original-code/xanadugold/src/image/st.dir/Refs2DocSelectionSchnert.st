'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:00 pm'!

XnDependent subclass: #Refs2DocSelectionSchnert
	instanceVariableNames: 'myWindow {DocumentWindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
Refs2DocSelectionSchnert comment:
'When the referencesSelection changes, changes the documentSelection to the referenced material'!

(Refs2DocSelectionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Refs2DocSelectionSchnert methodsFor: 'create'!

create: window {DocumentWindowModel}
	super create.
	myWindow _ window.
	myWindow referencesSelection addDependent: self!

{void} destruct

	myWindow referencesSelection removeDependent: self.
	super destruct! !

!Refs2DocSelectionSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model
{XnModel} 
	(myWindow referencesSelection basicCast: XnModel) ==
model 
		ifTrue: [self updateSelection]! !

!Refs2DocSelectionSchnert methodsFor: 'private: private'!

{void} updateSelection
	| result {XnRegion} |
	result _ myWindow documentSelection selection coordinateSpace emptyRegion.
	myWindow referencesSelection selection stepper forEach: [ :i {IntegerPos} |
		result _ result unionWith: (((myWindow references get: i asIntegerVar) cast: Reference)
			regionIn: myWindow document)].
	myWindow documentSelection select: result! !

!Refs2DocSelectionSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	<< 'myWindow = '  << myWindow  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Refs2DocSelectionSchnert class
	instanceVariableNames: ''!

(Refs2DocSelectionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Refs2DocSelectionSchnert class methodsFor: 'pseudo constructors'!

make: window {DocumentWindowModel}
	^self create: window! !