'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:24 pm'!

Tester subclass: #PrimIndexTableTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!

(PrimIndexTableTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!PrimIndexTableTester methodsFor: 'tests'!

{void} accessTestOn: oo {ostream reference}
	| tab {PrimIndexTable} |
	"For this tests, I use as keys category pointers from the minimal xpp set"
	tab := PrimIndexTable make: 7.
	"first test a few introduces"
	tab at: Heaper introduce: 1.
	tab at: Category introduce: 2.
	tab at: PrimIndexTable introduce: 3.
	(tab get: Heaper) ~~ 1 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: Category) ~~ 2 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: PrimIndexTable) ~~ 3 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	"now do some more to cause a grow."
	tab at: Tester introduce: 4.
	tab at: PrimIndexTableTester introduce: 5.
	tab at: Recipe introduce: 7.
	tab at: BootMaker introduce: 8.
	(tab get: Heaper) ~~ 1 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: Category) ~~ 2 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: PrimIndexTable) ~~ 3 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: Tester) ~~ 4 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: PrimIndexTableTester) ~~ 5 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: Recipe) ~~ 7 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: BootMaker) ~~ 8 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	"Now remove some stuff."
	tab remove: Recipe.
	(tab get: Heaper) ~~ 1 ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: Category) ~~ 2 ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: PrimIndexTable) ~~ 3 ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: Tester) ~~ 4 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: PrimIndexTableTester) ~~ 5 ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: BootMaker) ~~ 8 ifTrue: [ Heaper BLAST: #IntroduceFailed ].! !

!PrimIndexTableTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 

	self accessTestOn: oo! !

!PrimIndexTableTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !