'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:51 pm'!

Thunk subclass: #PrintCBlocksTracks
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(PrintCBlocksTracks getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!PrintCBlocksTracks methodsFor: 'operate'!

{void} execute
	""
	"PrintCBlocksTracks create execute"
	
	CBlockTracker printTrackersOn: cerr.
	[cerr endEntry] smalltalkOnly! !

!PrintCBlocksTracks methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !