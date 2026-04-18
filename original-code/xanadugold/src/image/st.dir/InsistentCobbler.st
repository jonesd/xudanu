'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:00 pm'!

Cobbler subclass: #InsistentCobbler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!

(InsistentCobbler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!InsistentCobbler methodsFor: 'accessing'!

{Connection} acceptConnection: tport {Transporter}

	| reader {Rcvr} makerID {char star} maker {XcvrMaker}
	  book {Cookbook} bookID {char star} station {Station} |
	reader _ TextyXcvrMaker makeReader: tport readStream.
"The initiator insists."
	makerID _ reader receiveString.
	bookID _ reader receiveString.
	maker _ ProtocolBroker commProtocol: makerID.
	book _ Cookbook make.String: bookID.
	makerID delete.
	bookID delete.
	reader destroy.
	station _ Station make: tport with: maker.
	"^ServerConnection make: tport with: book bootCategory with: (RPCSpecialist make: station with: book)"
	WJR shouldImplement. "RPC -> promise"
	^NULL!

{Connection} initiateConnection: tport {Transporter} with: cat {Category}

	| maker {XcvrMaker} writer {Xmtr} book {Cookbook} station {Station} |
	maker _ ProtocolBroker commProtocol.
	writer _ TextyXcvrMaker makeWriter: tport writeStream.
"Insist on the stream protocol."
	writer sendString: maker id.
	book _ Cookbook make.Category: cat.
"Insist on the cookbook ID."
	writer sendString: book id.
	writer destroy.
	station _ Station make: tport with: maker.
	"^ClientConnection make: tport with: cat with: (RPCSpecialist make: station with: book)"
	WJR shouldImplement. "RPC -> promise"
	^NULL! !