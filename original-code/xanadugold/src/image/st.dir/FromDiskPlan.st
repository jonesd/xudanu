'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:59 pm'!

BootPlan subclass: #FromDiskPlan
	instanceVariableNames: '
		myCategory {Category}
		myFilename {Character star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
FromDiskPlan comment:
'Instances of this represent the plan for getting a particular kind of object from an urdi on a particular file.  They open the urdi, create a packer, retrieve the Turtle from the packer, and pull out the boot object.'!

(FromDiskPlan getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!FromDiskPlan methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Connection} connection
	"Return the object representing the connection.  This gives the client a handle by which to terminate the connection."
	
	DiskManager make: myFilename.
	^DiskConnection create: self bootCategory with: CurrentPacker fluidGet getInitialFlock bootHeaper! !

!FromDiskPlan methodsFor: 'creation'!

create: cat {Category} with: filename {Character star}
	super create.
	myCategory _ cat.
	myFilename _ filename! !

!FromDiskPlan methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.
	myFilename _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.
	xmtr sendString: myFilename.! !