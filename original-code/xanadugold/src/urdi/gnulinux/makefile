#
# URDI makefile
#
# $Id: makefile,v 1.4 1992/12/19 00:50:49 ravi Exp $
#

XPPDIR=../..

EXTRASTUBBLEDEFS =
EXTRAINCLUDES = -I$(XPPDIR)/urdi

include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

include $(XPPDIR)/xpp/$(PLATFORM)/export.mk
include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk

####================
####================

####%r.tst : %o.txt
####	/usr/5bin/echo 'You really want to change the reference [ny]? \c'; line | grep -s '^y'
####	mv $*o.txt $*r.tst
####	rm $*d.txt

XPPLIB = $(XPPLIBX_O) $(XLATELIBX_O)

default: urdi.dif

tests: urdi.dif

all: tests
	beep

libs : urdix.o buildx.o

urdi5t.exe: urdi5t.o urdix.o $(XPPLIB)
	$(LINK.cxx) -o $@ urdi5t.o urdix.o $(XPPLIB) $(LDLIBSXX)

urdi4t.exe: urdi4t.o urdix.o $(XPPLIB)
	$(LINK.cxx) -o $@ urdi4t.o urdix.o $(XPPLIB) $(LDLIBSXX)

urdi3t.exe: urdi3t.o urdix.o $(XPPLIB)
	$(LINK.cxx) -o $@ urdi3t.o urdix.o $(XPPLIB) $(LDLIBSXX)

urdi2t.exe: urdi2t.o urdix.o $(XPPLIB)
	$(LINK.cxx) -o $@ urdi2t.o urdix.o $(XPPLIB) $(LDLIBSXX)

urdi.out: urdit.o urdix.o $(XPPLIB)
	$(LINK.cxx) -o urdit.exe urdit.o urdix.o $(XPPLIB) $(LDLIBSXX)
	csh -c './urdit.exe >& $@; true'
	#rm urdit.exe

#urdix.o : urdix.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) urdix.cxx

include depends.mk
