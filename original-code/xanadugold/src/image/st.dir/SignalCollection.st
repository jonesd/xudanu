'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:28 pm'!

IdentitySet variableSubclass: #SignalCollection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Exception Handling'!
SignalCollection comment:
'Instances of class SignalCollection holds a collection of Signals to allow a handler to serve for many different Signals that are not related by inheritance.
'!


!SignalCollection methodsFor: 'testing'!

accepts: aSignal
	"Answer whether the receiver accepts the signal aSignal."

	self do: [:sig | (sig accepts: aSignal) ifTrue: [^true]].
	^false! !

!SignalCollection methodsFor: 'handling'!

{void} delayTry: aBlock catch: aHandler
	"ProbList delayTry: [foo] catch: [:broken {Promise} | bar]
	translates to
	DELAY_TRY_BEGIN(ProbList) {
		foo
	} DELAY_CATCH(broken) {
		bar
	} DELAY_TRY_END;"

	| collector {CollectionAgent} aPromise {Promise} |
	Promise newCollector: self.
	collector := Promise collector.
	[aBlock value] valueNowOrOnUnwindDo: [Promise popCollector].
	Promise force.
	aPromise _ collector firstPromise.
	[aPromise ~~ NULL] whileTrue: [
		aHandler value: aPromise.
		aPromise _ aPromise next].!

handle: handlerBlock do: doBlock
	"Execute the doBlock.  If an exception occurs
	whose Signal is included in the receiver,
	execute the handlerBlock."

	^doBlock value! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SignalCollection class
	instanceVariableNames: ''!


!SignalCollection class methodsFor: 'private: private'!

addSelector: selector withMethod: compiledMethod
	"Intercept this so we can mark the handler method"

	super addSelector: selector withMethod:
		(selector == #handle:do:
			ifTrue: [compiledMethod asHandlerMethod]
			ifFalse: [compiledMethod])! !