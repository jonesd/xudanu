'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:57 pm'!

BootPlan subclass: #ClearPlan
	instanceVariableNames: 'myCategory {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
ClearPlan comment:
'Remove a particular entry from the table of current BootPlans.'!

(ClearPlan getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!ClearPlan methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Connection} connection
	"Return the object representing the connection.  This gives the client a handle by which to terminate the connection."
	
	Heaper BLAST: #NoBootPlan.
	^NULL "fodder"! !

!ClearPlan methodsFor: 'operate'!

{void} execute
	"Use this hook to clear the element out of the bootPlan registration table."

	Connection clearPlan: myCategory! !

!ClearPlan methodsFor: 'creation'!

create: cat {Category}
	super create.
	myCategory _ cat! !

!ClearPlan methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.! !