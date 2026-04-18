'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:35 pm'!

Tester subclass: #FMTextTester
	instanceVariableNames: '
		window {FMTestWindow NOCOPY}
		building {FMBuilding NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(FMTextTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!FMTextTester methodsFor: 'smalltalk: windowing'!

{void} createSmalltalkWindow: newBuild {FMBuilding}

	building _ newBuild.
	window _ STTestWindow make: newBuild!

{void} openSmalltalkWindow

	window open.! !

!FMTextTester methodsFor: 'buildings'!

{ScruTable of: FMBuilder} builders

	| table {MuTable of: FMBuilder} |  
	table _ MuTable make: (HeaperSpace make).
	table at: (HeaperAsPosition make: AttributedTextModel)
introduce: STMBuilder make.
	table at: (HeaperAsPosition make: SelectedTextModel)
introduce: FMTextEditBuilder make.
	^ table! !

!FMTextTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
 
	"FMTextTester runTest"
	
	| chars {MuWordArray} aBuilding {FMBuilding} |
	chars _ MuWordArray make.charVector: 'This was an old
man. Not an incredibly old man; obsolete, spavined; not as
worn as the sway-backed stone steps ascending the Pyramid
of the Sun to an ancient temple; not yet a relic. But even
so, a very old man, this old man perched on an antique
shooting stick, its handles open to form a seat, its spike
thrust at an angle into the soft ground and trimmed grass
of the cemetery.  This was an old man. Not an incredibly
old man; obsolete, spavined; not as worn as the
sway-backed stone steps ascending the Pyramid of the Sun
to an ancient temple; not yet a relic. But even so, a very
old man, this old man perched on an antique shooting
stick, its handles open to form a seat, its spike thrust
at an angle into the soft ground and trimmed grass of the
cemetery.'.
	Scaffold fluidBind: (FMScaffold make: self builders with: Scaffold fluidGet)
		during: [aBuilding _ Scaffold fluidGet build: (chars convert: SelectedTextModel)].
	[self createSmalltalkWindow: aBuilding.
	self openSmalltalkWindow] smalltalkOnly! !

!FMTextTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !