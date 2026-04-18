'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:23 pm'!

XnDependent subclass: #LoginSchnert
	instanceVariableNames: '
		myApp {TapestryAppModel}
		myKM {VariableModel of: KeyMaster}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(LoginSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginSchnert methodsFor: 'create'!

create: kmVar {VariableModel of: KeyMaster} with: app {TapestryAppModel}

	super create.
	myApp _ app.
	myKM _ kmVar.
	myKM addDependent: self!

{void} destruct

	myApp _ NULL.
	myKM removeDependent: self.
	myKM _ NULL.
	super destruct.! !

!LoginSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	myKM fetchValue == NULL ifTrue: [^ VOID].
	myApp setKeyMaster: (myKM fetchValue cast: KeyMaster)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LoginSchnert class
	instanceVariableNames: ''!

(LoginSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginSchnert class methodsFor: 'make'!

make: kmVar {VariableModel of: KeyMaster} with: app {TapestryAppModel}

	^ self create: kmVar with: app! !