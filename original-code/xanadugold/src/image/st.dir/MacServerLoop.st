'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:46 pm'!

ServerLoop subclass: #MacServerLoop
	instanceVariableNames: ''
	classVariableNames: '
		GenericData {#Ptr var} 
		MyEmptyRegion {#RgnHandle var} 
		ServerLoopDispatchHook {#DispatchProc var} '
	poolDictionaries: ''
	category: 'Xanadu-macsrv'!

(MacServerLoop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!MacServerLoop methodsFor: 'protected: registration'!

{void} deregisterListener: aListener {Listener}!

{void} registerListener: aListen {Listener}

	"Listener, we don't need no stinkin listeners!!"! !

!MacServerLoop methodsFor: 'execution'!

{void} mainLoop: exitTester {ExitTest}
	[Stepper, MuSet] USES.
	
	[exitTester shouldExit] whileFalse: [ | activity {BooleanVar} |
		activity _ false.
		self listeners stepper forEach: [:ml {MacListener} |
			ml hasTraffic
				ifTrue: [ml processInput.
					activity _ true]].
		activity not ifTrue: [
			activity _ false.
			"cxx:
			EventRecord ev;
			Boolean got;
			got = WaitNextEvent (everyEvent, &ev, SLEEP_TIME, MyEmptyRegion);
			if (got) {
				if (ServerLoopDispatchHook !!= NULL) {
					(*ServerLoopDispatchHook)(&ev, GenericData);
				}
			}"
		]
	].! !

!MacServerLoop methodsFor: 'creation'!

create
	super create! !

!MacServerLoop methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacServerLoop class
	instanceVariableNames: ''!

(MacServerLoop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!MacServerLoop class methodsFor: 'smalltalk: initialization'!

{void} initTimeNonInherited

	MyEmptyRegion.
	"cxx:
	MacServerLoop::MyEmptyRegion = NewRgn();
	MacServerLoop::ServerLoopDispatchHook = (DispatchProc) &_DoDebugEvent;
	AWho.data = NewPtr (256);
	MacServerLoop::GenericData = (Ptr) &AWho;
	"!

{void} linkTimeNonInherited

	MyEmptyRegion _ NULL.
	ServerLoopDispatchHook _ NULL.
	GenericData _ NULL.! !