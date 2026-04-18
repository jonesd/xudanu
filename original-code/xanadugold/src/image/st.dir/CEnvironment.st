'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:39 pm'!

Dictionary variableSubclass: #CEnvironment
	instanceVariableNames: ''
	classVariableNames: 'UserEnvironment Valid '
	poolDictionaries: ''
	category: 'OS-Support'!
CEnvironment comment:
'Class CEnvironment represents a Dictionary which can convert to and from the standard C  environment data structure (passed to the C entrypoint "main"), namely an array of strings which have the format "key=value".  The class is a dependent of the SystemDictionary, in order to obtain the current environment from the VM at return-from-snapshot time.  Instances are also useful in order to construct new C environments as dictionaries and then pass the standard format to forked ExternalProcess''s.

Class Variables:
	UserEnvironment	<CEnvironment> The environment of Smalltalk at startup
	Valid	<Boolean>'!


!CEnvironment methodsFor: 'converting'!

asStrings
	"Answer an array of strings in the external format."

	| sa i |
	sa _ Array new: self size.
	i _ 1.
	self
		associationsDo: 
			[:ass | 
			sa at: i put: ass key asString , '=' , ass value.
			i _ i + 1].
	^sa! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CEnvironment class
	instanceVariableNames: ''!


!CEnvironment class methodsFor: 'class initialization'!

checkEnvironment
	"Get the environment and cache it for later lookup by getenv:.
	Valid is set to false on system startup, and to true when the
	environment is loaded here"

	Valid
		ifFalse: 
			[UserEnvironment _ self fromStrings: self primEnvironment.
			Valid _ true]!

initialize
	"Add me as a dependent of the system dictionary (so I will be 
	informed when returning from snapshot) and cache the current 
	environment."
	"CEnvironment initialize"

	"Protect against multiple initialize's; but I sure wish that dependents 
	had set semantics."
	Smalltalk removeDependent: self.
	Smalltalk addDependent: self.
	self install!

install
	"Record that the environment is invalid.  On system startup,
	we just flush the cache--the current environment is not loaded
	until the first request"

	self release.
	Valid _ false!

release
	"Break the reference to the cached environment."

	UserEnvironment _ nil! !

!CEnvironment class methodsFor: 'class accessing'!

getenv: key 
	"Get the value of the named environment variable from the current 
	environment."

	self checkEnvironment.
	^UserEnvironment at: key ifAbsent: ['']!

userEnvironment
	"Return the current user environment, namely the one at system 
	startup."

	self checkEnvironment.
	^UserEnvironment! !

!CEnvironment class methodsFor: 'instance creation'!

fromStrings: aCollection 
	"Create an instance by converting from the external format."

	| ce |
	ce _ self new: aCollection size + (aCollection size // 3).
	aCollection do: 
		[:elem | 
		| lhs rhs eep es |
		es _ elem size.
		eep _ elem indexOf: $=.
		lhs _ eep = 0
					ifTrue: [elem copy]
					ifFalse: [elem copyFrom: 1 to: eep - 1].
		rhs _ eep = 0 | (eep = es)
					ifTrue: [String new]
					ifFalse: [elem copyFrom: eep + 1 to: es].
		ce at: lhs put: rhs].
	^ce! !

!CEnvironment class methodsFor: 'private: private'!

primEnvironment
	"Return the standard user environment as an Array of strings with the format 'key=value'."
	<primitive: 690>
	^Array with: 'INVALID'! !

CEnvironment initialize!
