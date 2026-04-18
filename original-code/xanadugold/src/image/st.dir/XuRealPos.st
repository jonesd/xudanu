'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:58 pm'!

XuPosition subclass: #XuRealPos
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuRealPos comment:
'Represents some real number exactly.  Not all real numbers can be exactly represented.  See class comment in RealSpace.'!

(XuRealPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!