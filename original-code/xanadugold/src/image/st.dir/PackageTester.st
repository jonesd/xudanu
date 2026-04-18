'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:59 pm'!

Tester subclass: #PackageTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgmain'!

(PackageTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!PackageTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	| coreB {CoreB} coreC {CoreC} appE {AppE} |
	coreB := CoreB create: 3.
	coreB zip: oo with: 10.
	(coreB pack: StubB) zip: oo with: 11.
	(coreB pack: StubA) zip: oo with: 12.
	oo << 'coreB->zoom () = ' << (coreB zoom: oo) << '
'.
	oo << 'PACK(StubB,coreB)->zoom () = ' << ((coreB pack: StubB) zoom: oo) << '
'.
	
	coreC := CoreC create: 7.
	coreC zip: oo with: 110.
	(coreC pack: StubC) zip: oo with: 111.
	(coreC pack: StubA) zip: oo with: 112.
	coreC zap: oo with: 20 with: 21.
	(coreC pack: StubC) zap: oo with: 22 with: 23.

	((coreB pack: StubA) pack: AppA) zipTwice: oo with: 200.
	((coreC pack: StubA) pack: AppA) zipTwice: oo with: 201.
	
	appE := Package MAKE.U.HOOKED: #AppE.
	appE zipTwice: oo with: 300.
	(appE contents pack: AppA) zipTwice: oo with: 301.
	appE bang: oo with: 310.
	(appE contents pack: AppD) bang: oo with: 311.
	appE boom: oo with: 320 with: 321.
	(appE contents pack: AppE) boom: oo with: 322 with: 323.! !

!PackageTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !