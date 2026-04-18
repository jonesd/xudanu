'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:21 pm'!

XnDependent subclass: #Filter2ReferencesSchnert
	instanceVariableNames: '
		myFilter {VariableModel of: ReferenceFilter}
		myDocument {DocumentModel}
		myReferences {SetModel of: Reference}
		myNewModel {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
Filter2ReferencesSchnert comment:
'Updates the reference list when the filter changes. Each time this happens, updates the NewModel so that the existing sensor knows to disappear.'!

(Filter2ReferencesSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Filter2ReferencesSchnert */
friend SPTR(Filter2ReferencesSchnert) filter2ReferencesSchnert (
											VariableModel OF1(ReferenceFilter) * filter,
											DocumentModel * document,
											SetModel OF1(Reference) * references);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Filter2ReferencesSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 
	(model == myFilter 
		or: [model == myDocument 
			and: [change isKindOf: NewContentsUpdate]])
		ifTrue: [self updateReferences]! !

!Filter2ReferencesSchnert methodsFor: 'private: creation'!

{void} destruct
	myFilter removeDependent: self.
	myDocument removeDependent: self.
	myFilter removeDependent: self.
	myDocument removeDependent: self.
	myNewModel destroy.
	myFilter _ NULL.
	myDocument _ NULL.
	myNewModel _ NULL.
	myReferences _ NULL.
	super destruct! !

!Filter2ReferencesSchnert methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo <<  self getCategory name << ' Filter' << myFilter << 'myDocument = ' << myDocument  
		<< ' MyReferences = ' << myReferences  
		<< 'myNewModel'  << myNewModel! !

!Filter2ReferencesSchnert methodsFor: 'private: private updating'!

{void} updateReferences
	myNewModel changed: NewContentsUpdate make.
	(myFilter getValue cast: TapestryFilter) watchReferences: myDocument
		with: myReferences
		with: myNewModel! !

!Filter2ReferencesSchnert methodsFor: 'smalltalk: passe'!

create: filter {VariableModel of: TapestryFilter} 
	with: document {DocumentModel} 
	with: references {SetModel of: Reference}
	
	super create.
	myFilter _ filter.
	myFilter addDependent: self.
	myDocument _ document.
	myDocument addDependent: self.
	myReferences _ references.
	"myNewModel _ XuModel connectorModel."
	self passe.

	myFilter addDependent: self.
	myDocument addDependent: self.
	self updateReferences! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Filter2ReferencesSchnert class
	instanceVariableNames: ''!

(Filter2ReferencesSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Filter2ReferencesSchnert */
friend SPTR(Filter2ReferencesSchnert) filter2ReferencesSchnert (
											VariableModel OF1(ReferenceFilter) * filter,
											DocumentModel * document,
											SetModel OF1(Reference) * references);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Filter2ReferencesSchnert class methodsFor: 'make'!

make: filter {VariableModel of: TapestryFilter} with: document {DocumentModel} with: references {SetModel of: Reference}
	^self create: filter with: document with: references! !