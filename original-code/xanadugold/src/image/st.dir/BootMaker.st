'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:56 pm'!

BootPlan subclass: #BootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!

(BootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!BootMaker methodsFor: 'accessing'!

{Category} bootCategory
	self subclassResponsibility!

{Connection} connection
	"Return the object representing the connection.  This gives the client a handle by which to terminate the connection."
	
	^DirectConnection create: self bootCategory with: self bootHeaper! !

!BootMaker methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name.! !

!BootMaker methodsFor: 'protected:'!

{Heaper} bootHeaper
	"Subclasses of maker only need to define the routine that makes the boot heaper."
	
	self subclassResponsibility! !