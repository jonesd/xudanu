'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:58 pm'!

Heaper subclass: #Connection
	instanceVariableNames: ''
	classVariableNames: 'TheBootPlans {PrimPtr2PtrTable of: Category with: BootPlan} '
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
Connection comment:
'Suclasses represent particular kinds of connections.  The connection object serves two purposes:  you can get the boot object from it, and you can destroy it to break the connection.  Note that destroying the bootObject does not break the connection because you might have gotten other objects from it.'!

(Connection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Connection methodsFor: 'accessing'!

{Category} bootCategory

	self subclassResponsibility!

{Heaper} bootHeaper

	self subclassResponsibility! !

!Connection methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Connection class
	instanceVariableNames: ''!

(Connection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Connection class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	TheBootPlans _ PrimPtr2PtrTable make: 8.!

linkTimeNonInherited
	TheBootPlans _ NULL! !

!Connection class methodsFor: 'registration'!

{void} clearPlan: cat {Category}
	"Throw out any plan associated with cat."
	
	TheBootPlans remove: cat!

{void} registerBootPlan: plan {BootPlan}
	"For the current run, return plan if anyone looks for a bootPlan that returns an instance of the category that plan returns."
	
	TheBootPlans at: plan bootCategory introduce: plan! !

!Connection class methodsFor: 'creation'!

make: category {Category}
	^((TheBootPlans get: category) cast: BootPlan) connection! !