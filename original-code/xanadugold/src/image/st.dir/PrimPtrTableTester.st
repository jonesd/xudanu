'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:26 pm'!

Tester subclass: #PrimPtrTableTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!

(PrimPtrTableTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!PrimPtrTableTester methodsFor: 'tests'!

{void} accessTestOn: oo {ostream reference}
	| tab {PrimPtrTable} |
	"For this tests, I use as keys category pointers from the minimal xpp set"
	tab := PrimPtrTable make: 7.
	"first test a few introduces"
	tab at: 1 introduce: Heaper.
	tab at: 2 introduce: Category.
	tab at: 3 introduce: PrimIndexTable.
	(tab get: 1) ~~ Heaper ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 2) ~~ Category ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 3) ~~ PrimIndexTable ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	"now do some more to cause a grow."
	tab at: 4 introduce: Tester.
	tab at: 5 introduce: PrimIndexTableTester.
	tab at: 7 introduce: Recipe.
	tab at: 8 introduce: BootMaker.
	(tab get: 1) ~~ Heaper ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 2) ~~ Category ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 3) ~~ PrimIndexTable ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 4) ~~ Tester ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 5) ~~ PrimIndexTableTester ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 7) ~~ Recipe ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	(tab get: 8) ~~ BootMaker ifTrue: [ Heaper BLAST: #IntroduceFailed ].
	"Now remove some stuff."
	tab remove: 7.
	(tab get: 1) ~~ Heaper ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: 2) ~~ Category ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: 3) ~~ PrimIndexTable ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: 4) ~~ Tester ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: 5) ~~ PrimIndexTableTester ifTrue: [ Heaper BLAST: #RemoveFouled ].
	(tab get: 8) ~~ BootMaker ifTrue: [ Heaper BLAST: #RemoveFouled ].! !

!PrimPtrTableTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 

	self accessTestOn: oo! !

!PrimPtrTableTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !