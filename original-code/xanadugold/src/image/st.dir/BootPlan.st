'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:56 pm'!

Thunk subclass: #BootPlan
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!

(BootPlan getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!BootPlan methodsFor: 'accessing'!

{Category} bootCategory
	self subclassResponsibility!

{Connection} connection
	"Return the object representing the connection.  This gives the client a handle by which to terminate the connection."
	
	self subclassResponsibility! !

!BootPlan methodsFor: 'operate'!

{void} execute
	"A comm hook couldn't register the bootPlan because it's working with a not-fully
	 constructed object, so we have to make bootPlans thunks and register them here."

	Connection registerBootPlan: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BootPlan class
	instanceVariableNames: ''!

(BootPlan getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!BootPlan class methodsFor: 'smalltalk: init'!

cleanupGarbage
	BootCuisine _ NULL!

initTimeNonInherited
	Cookbook declareCookbook: 'boot' with: BootPlan with: BootCuisine with: XppCuisine!

linkTimeNonInherited
	Recipe star defineGlobal: #BootCuisine with: NULL.! !