#
#  server translated from smalltalk
#
#  $Id: makefile,v 1.21 1993/03/01 21:28:04 eric Exp $
#

XPPDIR = ../..

EXTRADEFS = -DMANUAL_CRUTCH
EXTRASTUBBLEDEFS = -FWITH_SERVER_HOOKS -J.
EXTRASTUBBLEDEPENDS = $(XPPDIR)/stubble/copy.hf \
	$(XPPDIR)/stubble/backend1.hf $(XPPDIR)/stubble/backend2.hf

EXTRAINCLUDES = -I$(XPPDIR)/disk -I$(XPPDIR)/client

include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

include $(XPPDIR)/xpp/$(PLATFORM)/export.mk
include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk
include $(XPPDIR)/disk/$(PLATFORM)/export.mk
#include $(XPPDIR)/client/$(PLATFORM)/export.mk

MAIN      = sheph tclude
ENT       = ent htree loaves oroot
TRACEDAG  = branch dagwood tracep
ENTCANOPY = canopy props
SERVERXPP = counter grantab
NFEBE     = brange1 brange2 brange3 crypto detect granmap id nadmin nkernel nlinks \
	    sysadm wrapper
FOR_FEBE  = worksrv

SERVER = $(MAIN) $(ENT) $(TRACEDAG) $(ENTCANOPY) $(SERVERXPP) $(NFEBE) \
	 $(FOR_FEBE)
SERVER_O = $(SERVER:=x.o)

#TESTSD_TXT = grantab.dif sheph.dif id.dif nkernel.dif
TESTSD_TXT = grantab.dif wend.dif

TESTS_O = grantabt.o shepht.o nkernelt.o # idt.o

default : libs

all: libs tests

libs: servlibx.o

tests: $(TESTSD_TXT)

servlibx.o : $(SERVER_O)
	ld -r $(SERVER_O) -o $@

ent : $(ENT:=x.o)

serverxpp : $(SERVERXPP:=x.o)

main : $(sheph tclude:=x.o)

entcanopy : $(ENTCANOPY:=x.o)

tracedag : $(TRACEDAG:=x.o)

nfebe : $(NFEBE:=x.o)

XPP_LIBS_O = $(XPPLIBX_O) $(XXPPLIBX_O)

TEST_LIBS_O = $(SERVER_O) $(XPPLIBT_O) \
		$(XLATELIBT_O) $(DISKLIBX_O) $(DISKTESTS_O) $(STACKX_O) \
		$(SETT_O) $(SPACET_O) $(RCMAINX_O) $(PROMISE_O) 
#../xpp/xmallocx.o

# this one is for linking without profiling
#febet.exe : $(TESTS_O) $(T_LIBS) mcount.o
#	$(LINK.np.cxx) -n -o $@ $(TESTS_O) $(T_LIBS) mcount.o $(LDLIBSXX)

# this one links in /tmp to take advantage of TMPFS mounted /tmp
#febet.exe : $(TESTS_O) $(TEST_LIBS_O)
#	($(LINK.cxx) -n -o /tmp/$$$$.exe $(TESTS_O) $(TEST_LIBS_O) $(LDLIBSXX) ; cp /tmp/$$$$.exe $@ ; rm /tmp/$$$$.exe) || rm /tmp/$$$$.exe

febet.exe : $(TESTS_O) $(TEST_LIBS_O)
	$(LINK.cxx) -n -o $@ $(TESTS_O) $(TEST_LIBS_O) $(LDLIBSXX);echo "beep";beep

febelink.o : $(TESTS_O) $(MAINLESS_T_LIBS)
	ld -r -o /tmp/$$$$.o $(TESTS_O) $(MAINLESS_T_LIBS) $(LDLIBSXX) ; cp /tmp/$$$$.o $@ ; rm /tmp/$$$$.o

# just the server without all of the tests
SERVER_LIBS = $(SERVER_O) $(XPPLIBX_O) $(XLATELIBX_O) \
	$(DISKLIBX_O) $(RCMAINX_O) $(PROMISE_O) $(STACKX_O)

xuserver.exe : $(SERVER_LIBS) mcount.o makefile
	$(LINK.np.cxx) -o $@ $(SERVER_LIBS) mcount.o $(LDLIBSXX)

grantab.out:	febet.exe ../grantab.rc
sheph.out:	febet.exe ../sheph.rc
wend.out:	febet.exe ../wend.rc
works.out:	febet.exe diskinit ../works.rc

%.out: ../%.rc
	csh -c './febet.exe ../$(@:.out=.rc) >& $@ ; true'

diskinit:	febet.exe ../init.rc
	csh -c './febet.exe ../init.rc >& $@ ; true'

#grantabx.o : grantabx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) grantabx.cxx

#canopyx.o : canopyx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) canopyx.cxx

#propx.o : propx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) propx.cxx

#brange2x.o : brange2x.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) brange2x.cxx


# still need to check that nothing has a zero hash!
# blasts.txt : FORCE
blasts.txt :  ../../xpp/sun/hashes.exe makefile
	perl -ne 'print if s/.*BLAST[A-Z_]*\(([A-Za-z0-9_]+)\).*/\1/' $(XPPDIR)/*/*[xrp].[chi]xx | sort -u | ../../xpp/sun/hashes.exe > blasts.txt
	test `wc -l < blasts.txt` -eq `sed -e 's/ .*//' < blasts.txt | uniq | wc -l`

blasts.h : blasts.txt ../../xpp/sun/hashes.exe
	perl -pe 's/(0x[0-9a-fA-F]+) (.*)/#define XU_\2_PROBLEM \1/' < blasts.txt > blasts.h

include depends.mk
