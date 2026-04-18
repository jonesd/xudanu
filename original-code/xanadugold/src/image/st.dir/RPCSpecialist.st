'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:13 pm'!

TransferSpecialist subclass: #RPCSpecialist
	instanceVariableNames: '
		myXmtr {SpecialistXmtr}
		myRcvr {SpecialistRcvr}
		mySent {PrimPtrTable}
		myReceived {PrimPtrTable}
		mySightings {PrimPtr2PtrTable}
		myNextSighting {IntegerVar}
		myPendingProxyReleases {MuSet of: RPCIntegerThing}
		myUnknownProxies {PrimPtrTable of: Proxy}
		myOutstandingProxies {MuSet of: RPCIntegerThing}
		myRequestDepth {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!
RPCSpecialist comment:
'mySent maps integer->strong ptr, myReceived maps integer->wimpy ptr, mySightings maps wimpy ptr->sighting'!

(RPCSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #CONCRETE; yourself)!

!RPCSpecialist methodsFor: 'communication'!

{Heaper} receiveHeaper: cat {Category} from: rcvr {SpecialistRcvr}
	"Return an object from the rcvr or NULL if cat is not a category that we handle specially.
	Note the trouble we need to go through to register everything properly before it gets used!!"
	
	| result {Heaper} |
	(cat isEqual: ProxySighting) ifTrue:  
		[| num {IntegerVar} proxyCat {Category} |
		num _ rcvr receiveIntegerVar.
		proxyCat _ rcvr receiveCategory.
		result _ myReceived fetch: num.
		result == NULL ifTrue:  "We threw away the proxy.  Create a stub and get it later."
			[result _ myUnknownProxies fetch: num.
			result == NULL ifTrue:
				['HeaperConstructor_Bomb ctorBomb;
				result = (Heaper *)Heaper::operator new (0, &ctorBomb, proxyCat);' translateOnly.
				[result _ DeletedHeaper create] smalltalkOnly.
				myUnknownProxies at: num introduce: result]].
		rcvr registerIbid: result.
		^result].
	(cat isEqual: ActualSighting) ifTrue: 
		[result _ mySent get: rcvr receiveIntegerVar.
		rcvr registerIbid: result.
		^result].
	(self getRecipe: cat)
		cast: ProxyRecipe into: [:recipe |
			| num {IntegerVar} |
			num _ rcvr receiveIntegerVar.
			result _ myUnknownProxies fetch: num.
			result == NULL
				ifTrue:
					['HeaperConstructor_Bomb ctorBomb;
					result = (Heaper *)Heaper::operator new (0, &ctorBomb, cat);' translateOnly.
					[result _ DeletedHeaper create] smalltalkOnly]
				ifFalse: [myUnknownProxies remove: num].
			rcvr registerIbid: result.
			myReceived at: num introduce: result.
			mySightings at: result introduce: (ActualSighting make: num).
			recipe parseProxy: rcvr with: self into: result.
			^result]
		cast: Recipe into: [:recipe | ^rcvr basicReceive: recipe]!

{void} receiveHeaper: cat {Category} into: memory {Heaper} from: rcvr {SpecialistRcvr}
	"Return an object from the rcvr or NULL if cat is not a category that we handle specially."
	
	((cat isEqual: ProxySighting) 
			or: [(cat isEqual: ActualSighting)
			or: [(self getRecipe: cat) isKindOf: ProxyRecipe]])
		ifTrue: [RPCSpecialist BLAST: #NotBecomable].

	rcvr basicReceive: (self getRecipe: cat) into: memory!

{void} sendHeaper: hpr {Heaper} to: xmtr {SpecialistXmtr}
	"The special case here is if heaper isByProxy, then intern it in the entry table."
	
	hpr isByProxy
		ifTrue: 
			[| sighting {Sighting} |
			sighting _ (mySightings fetch: hpr) cast: Sighting.
			sighting ~~ NULL
				ifTrue:
					[xmtr startInstance: hpr with: sighting getCategory.
					xmtr sendIntegerVar: sighting number.
					sighting isProxy ifTrue: 
						[myOutstandingProxies store: (RPCIntegerThing make: sighting number).
						xmtr sendCategory: hpr getProxyCategory].
					xmtr endInstance]
				ifFalse: 
					["Register the sighting of this object."
					mySent at: myNextSighting introduce: hpr.
					mySightings at: hpr introduce: (ProxySighting make: myNextSighting).
					xmtr startInstance: hpr with: hpr getProxyCategory.
					xmtr sendIntegerVar: myNextSighting.
					myNextSighting _ myNextSighting + 1.
					hpr sendProxyTo: xmtr.
					xmtr endInstance]]
		ifFalse: [super sendHeaper: hpr to: xmtr]! !

!RPCSpecialist methodsFor: 'accessing'!

{Heaper} receiveBootHeaper

	^myRcvr receiveHeaper!

{void} sendBootHeaper: object {Heaper}
	"send an initial object to start up the other end"
	myXmtr sendHeaper: object! !

!RPCSpecialist methodsFor: 'proxy release'!

{void} releaseProxy: proxy {Heaper}
	"Called by FooProxy::destruct, this informs the server
	 of the release, then removes the object from the local tables."

	| sighting {Sighting} |
	sighting _ (mySightings get: proxy) cast: Sighting.
	mySightings remove: proxy.
	myReceived remove: sighting number.
	myPendingProxyReleases == NULL ifTrue: [myPendingProxyReleases _ MuSet make].
	myPendingProxyReleases store: (RPCIntegerThing make: sighting number)! !

!RPCSpecialist methodsFor: 'vulnerable proxy release'!

{NOWAIT PROXY} releaseActuals: set {ScruSet of: RPCIntegerThing}
	"Called by the specialist at the far end of the connection because it got rid of some proxies."

	set stepper forEach: 
		[:id {RPCIntegerThing} |
		(myOutstandingProxies hasMember: id) ifFalse:    "Don't delete if we just sent them this proxy reference."
			[| num {Int32}  actual {Heaper} |
			num _ id asIntegerVar DOTasLong.
			actual _ mySent get: num.
			mySightings remove: actual.
			mySent remove: num]]!

{NOWAIT PROXY} resendProxies: proxies {ScruSet of: RPCIntegerThing}
	"Send across the wire all the proxy objects (not just sightings)
	 indicated by numbers in proxies.  Don't put anything in any of the tables."

	myXmtr sendHeaper: (Response integerVarResponse: proxies count).
	proxies stepper forEach: [:id {RPCIntegerThing} |
		| num {IntegerVar} hpr {Heaper} |
		num _ id asIntegerVar.
		hpr _ mySent get: num.
		hpr isByProxy ifFalse: [Heaper BLAST: #BadProxy].
		myXmtr startInstance: hpr with: hpr getProxyCategory.
		myXmtr sendIntegerVar: num.
		hpr sendProxyTo: myXmtr.
		myXmtr endInstance]! !

!RPCSpecialist methodsFor: 'private: private'!

{void} evaluateRequest: request {Request}

	| result {Response} |
	RPCSpecialist problems.EVERY.U.PROXY 
		handle: [:ex | 
				[myXmtr sendHeaper: (Phaser make: ex)] smalltalkOnly.
				'myXmtr->sendHeaper (Phaser::make (&PROBLEM(ex)));' translateOnly.
				^VOID]
		do: 	[result _ request evaluate].
	
	(result isKindOf: NOWAITResponse) ifFalse: 
		[myXmtr sendHeaper: result.
		"The other side will now request all proxies that
		 it needs to handle all outstanding messages from 
		 me, so we shouldn't keep around the outstanding 
		 proxy list anymore."
		myOutstandingProxies isEmpty ifFalse:
			[myOutstandingProxies destroy.
			myOutstandingProxies _ MuSet make]]!

{void} releaseProxiesNow
	"The garbage collector may have destructed some Proxies recently. If 
	so, tell the specialist on the other side."

	(myPendingProxyReleases ~~ NULL and: [myRequestDepth <= Int32Zero])
		ifTrue: 
			[myRequestDepth _ 1.
			myPendingProxyReleases stepper forEach:
				[:id {RPCIntegerThing} |
					(myReceived fetch: id asIntegerVar) ~~ NULL ifTrue: [myPendingProxyReleases remove: id]].
			myPendingProxyReleases isEmpty ifFalse: 
				[[self requestNOWAIT: self
						with: 'releaseActuals:'
						withHeaper: myPendingProxyReleases] smalltalkOnly.
				 [self requestNOWAIT: self
					   with: 'releaseActuals'
					   withHeaper: myPendingProxyReleases] translateOnly	].
			myPendingProxyReleases destroy.
			myPendingProxyReleases _ NULL.
			myRequestDepth _ IntegerVar0]!

{void} requestUnknownProxies
	"We've accumulated unknown proxies.  Ask the other side to send them."
	
	"NOTE:  The server must never do this because it waits for a client!!!!!!!!"

	myUnknownProxies count ~~ Int32Zero ifTrue:
		[| set {MuSet} response {Response} |
		set _ MuSet make: myUnknownProxies count.
		[self requestNOWAIT: self with: 'resendProxies:' with.Heaper: set] smalltalkOnly.
		[self requestNOWAIT: self with: 'resendProxies' withHeaper: set] translateOnly.
		response _ self waitForResponse.
		response cast: IntegerVarResponse into: [:resp | resp value == set count ifFalse: [Heaper BLAST: #ProxiesConfused]].
		myUnknownProxies count timesRepeat: [myRcvr receiveHeaper].
		set destroy.
		myUnknownProxies count ~~ Int32Zero ifTrue: [Heaper BLAST: #UnknownProxies]]!

{void} sendRequest: request {Request}
	"This lets us add to the behavior of sending requests from proxies without modifying the stubble script all the time."

	self releaseProxiesNow.   "Inform the other side about any proxies that were recently destructed."
	myXmtr sendHeaper: request!

{Response} waitForResponse

	| pendingRequests {PrimPtrTable | NULL} |
	pendingRequests _ NULL.    "Queue async requests till after the response to the current one."
	myRequestDepth _ myRequestDepth + 1.
	[true] whileTrue:
		[myRcvr receiveHeaper
			cast: Response into: 
				[:resp |
				"get any unknown proxies resent from the other side."
				self requestUnknownProxies.
				"Handle any requests that came in while waiting for a response.  They'd better be NOWAIT."
				pendingRequests ~~ NULL ifTrue:
					[Int32Zero almostTo: pendingRequests count do: 
						[:i {Int32} | self evaluateRequest: ((pendingRequests get: i) cast: Request)]].
				myRequestDepth _ myRequestDepth - 1.
				self releaseProxiesNow.
				^resp]
			cast: Phaser into: 
				[:phas | 
				"get any unknown proxies resent from the other side."
				self requestUnknownProxies.
				myRequestDepth _ myRequestDepth - 1.
				phas explode]
			cast: Request into: 
				[:req | 
				pendingRequests == NULL ifTrue: [pendingRequests _ PrimPtrTable make: 4].
				pendingRequests at: pendingRequests count introduce: req]
			others: [RPCSpecialist BLAST: #CommunicationsBreakdown]]! !

!RPCSpecialist methodsFor: 'protected: bogus creation'!

create
	super create: NULL.
	Heaper BLAST: #NoninstanciableAsProxy! !

!RPCSpecialist methodsFor: 'protected: destruct'!

{void} destruct

	"Probably should destroy my internal tables as well as all the Proxy 
	objects stored in myReceived"
	self thingToDo.

	super destruct.! !

!RPCSpecialist methodsFor: 'evaluating'!

{void} waitForAndProcessMessage

	self evaluateRequest: (myRcvr receiveHeaper cast: Request)! !

!RPCSpecialist methodsFor: 'creation'!

create: station {Station} with: aBook {Cookbook}

	super create: aBook.
	myRcvr _ station makeRcvr: self.
	myXmtr _ station makeXmtr: self.
	mySent _ PrimPtrTable make: 256.
	myReceived _ PrimPtrTable weak: 256.
	mySightings _ PrimPtr2PtrTable make: 256.
	myNextSighting _ 1.
	mySent at: IntegerVar0 introduce: self.
	mySightings at: self introduce: (ActualSighting make: IntegerVar0).
	myRequestDepth _ IntegerVar0.
	myOutstandingProxies _ MuSet make.
	myPendingProxyReleases _ NULL.
	myUnknownProxies _ PrimPtrTable make: 128! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RPCSpecialist class
	instanceVariableNames: ''!

(RPCSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #CONCRETE; yourself)!

!RPCSpecialist class methodsFor: 'pseudo constructors'!

make
	"Parameterized by command line arguments or something"
	
	self unimplemented.
	^NULL!

make: station {Station} with: aBook {Cookbook}

	^self create: station with: aBook! !

!RPCSpecialist class methodsFor: 'smalltalk: obsolete p-constructors'!

