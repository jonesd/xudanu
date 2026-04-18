'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:43 pm'!

Object subclass: #Executor
	instanceVariableNames: '
		familyMembers {UNKNOWN}
		familyWills {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Finalization-Example'!



!Executor methodsFor: 'finalization'!

readLastWillAndTestamentOfTheDeparted
	"Read the will of each family member that has died."

	familyMembers nilAllCorpsesAndDo: [:deadIndex | (familyWills at: deadIndex) 
value]! !

!Executor methodsFor: 'updating'!

update: anAspectSymbol with: aParameter from: aSender 
	"Finalize all finalizable entries of aSender"

	(aSender == familyMembers and: [anAspectSymbol = #ElementExpired])
		ifTrue: [self readLastWillAndTestamentOfTheDeparted]
		ifFalse: [^self]! !

!Executor methodsFor: 'accessing'!

familyMembers: aWeakArray 
	familyMembers removeDependent: self.
	familyMembers _ aWeakArray.
	familyMembers addDependent: self!

familyWills: anArray 
	familyWills _ anArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Executor class
	instanceVariableNames: ''!



!Executor class methodsFor: 'example'!

example
	"Executor example inspect"

	| family wills familyLawyer |
	family _ WeakArray
				with: 'cain' copy
				with: 'abel' copy
				with: 'eve' copy
				with: 'adam' copy.
	wills _ Array
				with: [Transcript show: 'Cain has died. Bequethes his assets to the 
church.'; cr]
				with: [Transcript show: 'Abel has died. Killed by Cain for his assets.'; 
cr]	
				with: [Transcript show: 'Eve has died. Bequethes her assets to Abel.'; cr]
				with: [Transcript show: 'Adam has died. Bequethes his assets to Eve.'; cr].
	familyLawyer _ Executor new.
	familyLawyer familyWills: wills.
	familyLawyer familyMembers: family.
	^familyLawyer! !