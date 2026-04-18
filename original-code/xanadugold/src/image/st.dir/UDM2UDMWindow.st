'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:03 pm'!

Converter subclass: #UDM2UDMWindow
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UDM2UDMWindow getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UDM2UDMWindow methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	"perform the conversion.  This is defined by those who define a new converter, but not directly called
	 by clients.  Clients invoke conversion purely by using the CONVERT macro"
	
	^ UDMWindowModel make: (value cast: UserDirectoryModel)! !

!UDM2UDMWindow methodsFor: 'creation'!

create
	super create: UserDirectoryModel with: WindowModel! !