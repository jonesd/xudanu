'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:57 pm'!

Heaper subclass: #Cobbler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
Cobbler comment:
'Subclasses implement particular negotiation strategies for deciding the representation protocol and cookbook to be used in a given comm connection.   The middleman for these takes a transporter in which it can engage in the fixed and simple meta-protocol for deciding on a negotiation protocol.'!

(Cobbler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Cobbler methodsFor: 'accessing'!

{Connection} acceptConnection: tport {Transporter}
	"Someone is trying to establish a connection the current executable.  Accept
	 that connection and try to negotiate about cookbookc and the like."
	 
	self subclassResponsibility!

{Connection} initiateConnection: tport {Transporter} with: cat {Category}
	"Initiate negotiations for a high level connection over the wire.  cat is the bootCategory."

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

!Cobbler methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' <<  ')'.! !

!Cobbler methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Cobbler class
	instanceVariableNames: ''!

(Cobbler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Cobbler class methodsFor: 'creation'!

{Cobbler} make: tport {Transporter}
	"This should actually look up the meta-protocol's name and use that."
	
	| in {Rcvr} |
	in _ TextyXcvrMaker makeReader: tport readStream.
	in receiveString delete.    self hack. "This should at least require that the meta-protocol be insistence."
	in destroy.
	^InsistentCobbler create!

{Cobbler} make: tport {Transporter} with: meta {char star}
	"This should actually look up the meta-protocol's name and use that."
	
	| out {Xmtr} |
	out _ TextyXcvrMaker makeWriter: tport writeStream.
	out sendString: meta.
	out destroy.
	^InsistentCobbler create! !