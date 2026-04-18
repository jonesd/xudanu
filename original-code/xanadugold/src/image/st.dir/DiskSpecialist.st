'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:10 pm'!

TransferSpecialist subclass: #DiskSpecialist
	instanceVariableNames: '
		myPacker {DiskManager}
		myInsideShepherd {BooleanVar}'
	classVariableNames: 'SomeSpecialists {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(DiskSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DiskSpecialist methodsFor: 'communication'!

{Heaper} receiveHeaper: cat {Category} from: rcvr {SpecialistRcvr}
 	"There's a lot of smalltalk only stuff in here.  Smalltalk stubs should move towards c++ stubs."

	| snarfID {SnarfID} index {Int32} hash {UInt32} result {Heaper} newCat {Category smalltalk} |
	(cat isEqualOrSubclassOf: Abraham) not ifTrue:
		[^rcvr basicReceive: (self getRecipe: cat)].
	myInsideShepherd not ifTrue: 
		[myInsideShepherd _ true.
		result _ rcvr basicReceive: (self getRecipe: cat).
		myInsideShepherd _ false.
		^result].
	hash _ rcvr receiveUInt32.
	[newCat _ rcvr receiveCategory] smalltalkOnly.
	snarfID _ rcvr receiveUInt32.
	index _ rcvr receiveUInt32.
	result _ myPacker fetchCanonical: hash with: snarfID with: index.
	result == NULL ifTrue: 
		[[result _ ShepherdStub create: hash with: newCat] smalltalkOnly.
		[result _ ((self getRecipe: cat) cast: StubRecipe) parseStub: rcvr with: hash] translateOnly.
		result ~~ NULL assert: 'Bad Stub'.
		myPacker registerStub: (result cast: Abraham) with: snarfID with: index].
	rcvr registerIbid: result.
	^result!

{void} receiveHeaper: cat {Category} into: memory {Heaper} from: rcvr {SpecialistRcvr} 
	"Return an object from the rcvr or NULL if cat is not a category that we 
	handle specially."
	(cat isEqualOrSubclassOf: Abraham)
		ifTrue: [((self getRecipe: cat) isKindOf: StubRecipe)
				ifTrue: [Heaper BLAST: #NotBecomable]
				ifFalse: [myInsideShepherd not
						ifTrue: 
							[myInsideShepherd _ true.
							rcvr basicReceive: (self getRecipe: cat) into: memory.
							myInsideShepherd _ false.
							^VOID]]].
	rcvr basicReceive: (self getRecipe: cat) into: memory!

{void} sendHeaper: hpr {Heaper} to: xmtr {SpecialistXmtr} 
	"Handle sending Shepherds specially."

	hpr cast: Abraham into: [:abe |
			myInsideShepherd
				ifTrue: 
					[abe getInfo.  "Test to verify that all persistently pointed-at sheps didi newShepherd."
					xmtr startInstance: abe with: abe getShepherdStubCategory.
					xmtr sendUInt32: abe hashForEqual.
					[xmtr sendCategory:
						(abe isStub
							ifTrue: [abe getCategoryFromStub]
							ifFalse: [abe getCategory])] smalltalkOnly.
					xmtr sendUInt32: abe getInfo snarfID.
					xmtr sendUInt32: abe getInfo index.
					xmtr endInstance]
				ifFalse: 
					[myInsideShepherd _ true.
					super sendHeaper: abe to: xmtr.
					myInsideShepherd _ false].
			^VOID]
		others: [super sendHeaper: hpr to: xmtr]! !

!DiskSpecialist methodsFor: 'create'!

create: cookbook {Cookbook} with: packer {DiskManager}
	super create: cookbook.
	myPacker _ packer.
	myInsideShepherd _ false!

{void} destroy
	(SomeSpecialists store: self) ifFalse: [super destroy]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DiskSpecialist class
	instanceVariableNames: ''!

(DiskSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DiskSpecialist class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSpecialists := InstanceCache make: 16!

linkTimeNonInherited
	SomeSpecialists := NULL! !

!DiskSpecialist class methodsFor: 'stream creation'!

{TransferSpecialist} make: book {Cookbook} with: packer {DiskManager}
	| result {Heaper} |
	result := SomeSpecialists fetch.
	result == NULL
		ifTrue: [^self create: book with: packer]
		ifFalse: [^(self new.Become: result) create: book with: packer]! !