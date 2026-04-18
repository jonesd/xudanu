'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:28 pm'!

Heaper subclass: #ProtocolBroker
	instanceVariableNames: ''
	classVariableNames: '
		CommProtocols {ProtocolItem} 
		DiskProtocols {ProtocolItem} 
		TheCommProtocol {XcvrMaker} 
		TheDiskProtocol {XcvrMaker} '
	poolDictionaries: ''
	category: 'Xanadu-negoti8'!

(ProtocolBroker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ProtocolBroker methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProtocolBroker class
	instanceVariableNames: ''!

(ProtocolBroker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ProtocolBroker class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	DiskProtocols _ NULL.
	CommProtocols _ NULL.
	TheCommProtocol _ NULL.
	TheDiskProtocol _ NULL! !

!ProtocolBroker class methodsFor: 'configuration'!

{XcvrMaker} commProtocol
	"return whichever is the best current protocol."
	TheCommProtocol == NULL ifTrue: [TheCommProtocol _ (CommProtocols get: 'binary1') cast: XcvrMaker].
	^TheCommProtocol!

{XcvrMaker} commProtocol: id {char star}
	^(CommProtocols get: id) cast: XcvrMaker!

{XcvrMaker} diskProtocol
	"return whichever is the best current protocol."
	TheDiskProtocol == NULL ifTrue: [TheDiskProtocol _ (DiskProtocols get: 'binary1') cast: XcvrMaker].
	^TheDiskProtocol!

{XcvrMaker} diskProtocol: id {char star}
	^(DiskProtocols get: id) cast: XcvrMaker!

{void} registerXcvrProtocol: maker {XcvrMaker}
	CommProtocols _ ProtocolItem create: maker id with: maker with: CommProtocols.
	DiskProtocols _ ProtocolItem create: maker id with: maker with: DiskProtocols.!

{void} setCommProtocol: maker {XcvrMaker}
	"Set the protocol."
	
	TheCommProtocol _ maker!

{void} setDiskProtocol: maker {XcvrMaker}
	"Set the protocol."
	
	TheDiskProtocol _ maker! !