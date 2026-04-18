'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:27 pm'!

FebeTester subclass: #TapestryTester
	instanceVariableNames: 'myPublic {KeyMaster NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(TapestryTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!TapestryTester methodsFor: 'create'!

create
	super create.
	myPublic _ NULL! !

!TapestryTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"TapestryTester runTest"
	
	myPublic _ self keyMaster.
	[Transcript nextPutAll: 'building Application'; cr; endEntry] smalltalkOnly.
	Application fluidSet: (TapestryAppModel make: myPublic).
	[Transcript nextPutAll: 'Logging in'; cr; endEntry] smalltalkOnly.
	Application fluidGet login.
	"[STWindowModel windowsGone wait] smalltalkOnly"! !

!TapestryTester methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' (myPublic = ' << myPublic << ')'! !

!TapestryTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartTapestryTester: rcvr {Rcvr unused default: NULL}
	myPublic _ NULL! !

!TapestryTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartTapestryTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !