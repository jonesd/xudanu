'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:34 pm'!

TransferSpecialist subclass: #DiskCountSpecialist
	instanceVariableNames: 'myInsideShepherd {BooleanVar}'
	classVariableNames: '
		MaxFlocks {Int32} 
		MaxSnarfs {Int32} 
		SomeSpecialists {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(DiskCountSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DiskCountSpecialist methodsFor: 'creation'!

create: cookbook {Cookbook}
	super create: cookbook.
	myInsideShepherd _ false!

{void} destroy
	(SomeSpecialists store: self) ifFalse: [super destroy]! !

!DiskCountSpecialist methodsFor: 'communication'!

{Heaper} receiveHeaper: cat {Category unused} from: rcvr {SpecialistRcvr unused}
 	"DiskCountSpecialist are only for sending."

	Heaper BLAST: #IncompleteAbstraction.
	^NULL!

{void} receiveHeaper: cat {Category unused} into: memory {Heaper unused} from: rcvr {SpecialistRcvr unused} 
	"DiskCountSpecialist are only for sending."
	
	Heaper BLAST: #IncompleteAbstraction!

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
					xmtr sendUInt32: MaxSnarfs.
					xmtr sendUInt32: MaxFlocks.
					xmtr endInstance]
				ifFalse: 
					[myInsideShepherd _ true.
					super sendHeaper: abe to: xmtr.
					myInsideShepherd _ false].
			^VOID]
		others: [super sendHeaper: hpr to: xmtr]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DiskCountSpecialist class
	instanceVariableNames: ''!

(DiskCountSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DiskCountSpecialist class methodsFor: 'creation'!

{TransferSpecialist} make: aBook {Cookbook}
	| result {Heaper} |
	result := SomeSpecialists fetch.
	result == NULL
		ifTrue: [^self create: aBook]
		ifFalse: [^(self new.Become: result) create: aBook]! !

!DiskCountSpecialist class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	SomeSpecialists := InstanceCache make: 16!

linkTimeNonInherited
	MaxSnarfs _ 3000000.
	MaxFlocks _ 3000000.
	SomeSpecialists := NULL! !