'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:04 pm'!

Heaper subclass: #CacheManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cache'!

(CacheManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CacheManager methodsFor: 'accessing'!

{Heaper | NULL} fetch: key {Heaper}
	"Return the value associated with the key, if any."
	
	self subclassResponsibility!

{BooleanVar} hasMember: key {Heaper}
	"Does te cach contain something at the given key?"
	
	"Should the key be a Heaper or a Position?"
	
	self subclassResponsibility!

{BooleanVar} wipe: key {Heaper}
	"Remove the cached association with key.  Return true if the cache contained something at that key."
	
	self subclassResponsibility! !