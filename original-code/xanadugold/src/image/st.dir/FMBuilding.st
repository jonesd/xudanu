'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:36 pm'!

Heaper subclass: #FMBuilding
	instanceVariableNames: '
		myView {Viewer}
		myController {FMController}'
	classVariableNames: 'GlobalRegistrationBook {MuSet} '
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMBuilding getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMBuilding methodsFor: 'accessing'!

{FMController} controller
	^myController!

{void} testView
	[^FMVCView open: self] smalltalkOnly.
	[self unimplemented] translateOnly!

{Viewer} view
	^myView! !

!FMBuilding methodsFor: 'create'!

create: view {Viewer} with: controller {FMController}
	super create.
	view ~~ NULL assert: 'NULL view in FMBuilding'.
	myView _ view.
	myController _ controller! !

!FMBuilding methodsFor: 'testing'!

{UInt32} hashForEqual
	myController ~~ NULL
		ifTrue: [^myController hashForEqual + myView hashForEqual]
		ifFalse: [^myView hashForEqual]!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: FMBuilding into: [:fmb |
			^(fmb controller isEqual: myController)
			 and: [fmb view isEqual: myView]]
		others: [^false]! !

!FMBuilding methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
oo << 'FmBuilding ' 
<< 'myView = ' << myView  
	<<  ' myControler =' << 	myController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMBuilding class
	instanceVariableNames: ''!

(FMBuilding getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMBuilding class methodsFor: 'pcreate'!

make: v {Viewer} with: c {FMController}
	^self create: v with: c! !

!FMBuilding class methodsFor: 'smalltalk: smalltalk initialization'!

cleanupGarbage
	self linkTimeNonInherited!

initTimeNonInherited
	self REQUIRES: MuSet.
	GlobalRegistrationBook _ MuSet make.!

linkTimeNonInherited
GlobalRegistrationBook _ NULL! !

!FMBuilding class methodsFor: 'extern: smalltalk: smalltalk externalDeRegistration'!

{void}externalDeRegisterAsStrongPointer: building{void star} 
"	FMBuildingRegisterationBook remove: (building cast:FMBuilding)"
	 FMBuilding unRegisterAsStrongPointer: (building basicCast:FMBuilding)! !

!FMBuilding class methodsFor: 'registration'!

{void} registerAsStrongPointer: registrant{Heaper} 
	GlobalRegistrationBook introduce: registrant!

{void} unRegisterAsStrongPointer: registrant{Heaper}  
	" this code with Set assumes each building is put in
	only once, thus when it is removed it is time to delete it"
	[Transcript show: 'unregister a strong pointer to '; print: registrant; cr; endEntry] smalltalkOnly.
	(registrant  = NULL) ifFalse:[
	GlobalRegistrationBook remove: registrant.
	registrant destroy.
	]! !