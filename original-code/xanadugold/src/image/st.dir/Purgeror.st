'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:38 pm'!

SanitationEngineer subclass: #Purgeror
	instanceVariableNames: '
		myCount {IntegerVar}
		myPacker {DiskManager}
		myPurgePending {BooleanVar}'
	classVariableNames: 'PurgeRate {IntegerVar} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
Purgeror comment:
'We are about to garbage collect.  Every so often, purge the objects that are clean so their flocks can be garbage collected.'!

(Purgeror getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Purgeror methodsFor: 'accessing'!

{void INLINE} clearPurgePending
	myPurgePending := false.
	myCount := IntegerVar0!

{BooleanVar INLINE} purgePending
	^ myPurgePending! !

!Purgeror methodsFor: 'protected: creation'!

create: packer {DiskManager}
	super create.
	myPacker _ packer.
	myCount _ IntegerVar0.
	myPurgePending _ false! !

!Purgeror methodsFor: 'invoking'!

{void} recycle: required {BooleanVar}
	required ifTrue: [
		myPurgePending := true.
		^VOID].
	(myCount >= PurgeRate and: [PurgeRate > IntegerVarZero])
		ifTrue:
			[(InsideTransactionFlag fluidFetch or: [myPacker insideCommit])
				ifFalse:
					[myPacker purgeClean.
					myCount _ IntegerVarZero.
					myPurgePending _ false]
				ifTrue:
					[myPurgePending _ true]]
		ifFalse: [myCount _ myCount + 1]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Purgeror class
	instanceVariableNames: ''!

(Purgeror getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Purgeror class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	PurgeRate _ 40.
	[Abraham] USES! !

!Purgeror class methodsFor: 'creation'!

make: packer {DiskManager}
	^self create: packer! !

!Purgeror class methodsFor: 'setting'!

{void} setPurgeRate: count {IntegerVar}
	PurgeRate _ count! !