#
#  non-translated xpp
#
#  $Id: makefile,v 1.31 1993/04/10 00:54:43 eric Exp $
#

XPPDIR = ../..

#CXXOPTS = -CRUTCH
#EXTRADEFS = -DMANUAL_CRUTCH
EXTRASTUBBLEDEPENDS = $(XPPDIR)/stubble/copy.hf
EXTRAINCLUDES = -I$(XPPDIR)/xpp -I$(XPPDIR)/platform/$(PLATFORM) -I$(XPPDIR)/disk
EXTRACLEANING = bstatic.c
# -I../disk above is for stubrcp

include xpp.mk

include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk
include $(XPPDIR)/platform/$(PLATFORM)/export.mk

#COMPILE.cxx = $(COMPILE4.cxx)

#	compat and things that depend only on compat
COMPAT_O   = ccompatc.o # tracerc.o
LOWLEVEL   = hsbox fhash bomb queues
XPP_LOWLEVEL_O = $(COMPAT_O) $(LOWLEVEL:=x.o)
LDLIBSXX = -lg++ -lm
#	memory management stuff
MEMORY  = alloc scav tomb xunew # bibop garbage
MEMORY_O = $(MEMORY:=x.o)

#	tofu and other things that don't depend on xlatexpp
TOFU	= tofu opaque intvar parray wparray fluid sema4 init \
		choose psrand diag logger

XPP_MIDLEVEL_O = $(XPP_LOWLEVEL_O) $(TOFU:=x.o)

#	things that depends on xlatexpp
XPP_XLATE = filetp

XPP_HILEVEL_O = $(XPP_MIDLEVEL_O) $(XPP_XLATE:=x.o)
RPC = copyrcp stubrcp sockptl
RPC_O = $(RPC:=x.o)

XPP_MIN_LIB_O = $(XPP_MIDLEVEL_O) $(RPC_O)
XPP_LIB_O = $(XPP_HILEVEL_O) $(RPC_O)

XPPLIBX_O = xpplibx.o filetpx.o $(XLATELIBX_O)
XPPLIBT_O = xpplibx.o filetpx.o $(XLATELIBT_O)

TEST_NAMES = ccompat xcompat crutch bomb fluid tofu init intvar parray \
		choose alloc fhash opaque cbomb scav # garbage bibop

TESTS = $(TEST_NAMES:=.dif)

# default:	inlinet.c
default :  xpplibx.o

all : libs tests

libs : xpplibx.o filetpx.o

tests : $(TESTS)

gclibx.o : $(MEMORY_O)
	ld -r $(MEMORY_O) -o $@

xpplibx.o : $(XPP_MIN_LIB_O) gclibx.o gmonx.o
	ld -r $(XPP_MIN_LIB_O) gclibx.o gmonx.o -o $@

bibop.out : bibopt.o $(XPPLIBX_O)
	$(LINK.cxx) -o bibopt.exe bibopt.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -cf './bibopt.exe >& $@ && true'
	#rm bibopt.exe

scav.out : scavt.o $(XPPLIBX_O)
	$(LINK.cxx) -o scavt.exe scavt.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -cf './scavt.exe >& $@ && true'
	#rm scavt.exe

ccompat.out : ccompatt.o $(COMPAT_O)
	$(LINK.c) -o ccompatt.exe ccompatt.o $(COMPAT_O) $(LDLIBS)
	csh -c './ccompatt.exe >& $@ && true'
	rm ccompatt.exe

xcompat.out : xcompatt.o $(COMPAT_O)
	$(LINK.cxx) -o xcompatt.exe xcompatt.o $(COMPAT_O) $(LDLIBSXX)
	csh -c './xcompatt.exe >& $@ && true'
	rm xcompatt.exe

crutch.out : crutcht.o $(COMPAT_O)
	$(LINK.cxx) -o crutcht.exe crutcht.o $(COMPAT_O) $(LDLIBSXX)
	csh -c './crutcht.exe >& $@ && true'
	rm crutcht.exe

alloc.out : alloct.o $(XPPLIBX_O)
	$(LINK.cxx) -o alloct.exe alloct.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './alloct.exe >& $@ && true'
	rm alloct.exe

fluid.out : fluidt.o $(XPPLIBX_O)
	$(LINK.cxx) -o fluidt.exe fluidt.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './fluidt.exe >& $@ && true'
	rm fluidt.exe


loggert.exe : loggert.o $(XPPLIBX_O)
	$(LINK.cxx) -o loggert.exe loggert.o $(XPPLIBX_O) $(LDLIBSXX)

logger1.out : loggert.exe
	csh -c './loggert.exe >& $@ && true'

logger2.out : loggert.exe
	VanillaLog=cerr csh -c './loggert.exe >& $@ && true'

vanilla.log : loggert.exe
	VanillaLog=file csh -c './loggert.exe && true'


fhash.out : fhasht.o fhashx.o hsboxx.o ccompatc.o
	$(LINK.cxx) -o fhasht.exe fhasht.o fhashx.o hsboxx.o ccompatc.o $(LDLIBSXX)
	csh -c './fhasht.exe >& $@ && true'
	rm fhasht.exe

tofu.out : tofut.o $(XPPLIBX_O)
	$(LINK.cxx) -o tofut.exe tofut.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './tofut.exe >& $@ && true'
	rm tofut.exe

opaque.out : opaquet.o $(XPPLIBX_O)
	$(LINK.cxx) -o opaquet.exe opaquet.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './opaquet.exe >& $@ && true'
	rm opaquet.exe

bombt.exe : bombt.o bombx.o $(COMPAT_O)
	$(LINK.cxx) -o bombt.exe bombt.o bombx.o $(COMPAT_O) $(LDLIBSXX)

bomb.out : bombt.exe
	csh -c './bombt.exe >& $@ && true'
	rm bombt.exe

# C bombs and their tests.

cbombt.exp : cbombt.o cbombx.o bombx.o dumstatc.o $(COMPAT_O)
#	$(LINK.c) -o cbombt.exp cbombt.o cbombx.o bombx.o dumstatc.o $(COMPAT_O) $(LDLIBSXX) -L/net/xanadu/files5/nat2.0/sun4 -lC2
	$(LINK.c) -o cbombt.exp cbombt.o cbombx.o bombx.o dumstatc.o $(COMPAT_O) $(LDLIBSXX)

cbombx.o:     ../cbombx.cxx

cbombt.exe : cbombt.o cbombx.o bombx.o bstatic.o $(COMPAT_O)
	$(LINK.c) -o cbombt.exe cbombt.o cbombx.o bombx.o bstatic.o $(COMPAT_O) $(LDLIBSXX)
#	$(LINK.c) -o cbombt.exe cbombt.o cbombx.o bombx.o bstatic.o $(COMPAT_O) $(LDLIBSXX) -L/net/xanadu/files5/nat2.0/sun4 -lC2

cbomb.out : cbombt.exe
	csh -c '(./cbombt.exe >& $@ && rm cbombt.exe) || (touch cbombt.exe; false)'


bstatic.c: bombx.o cbombx.o
	nm $(NM_FORMAT_ARG) bombx.o cbombx.o | awk -f ../init.awk > $@
	nm $(NM_FORMAT_ARG) bombx.o cbombx.o | awk -f ../term.awk >> $@

intvar.out : intvart.o $(XPPLIBX_O)
	$(LINK.cxx) -o intvart.exe intvart.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './intvart.exe >& $@ && true'
	rm intvart.exe

choose.out : chooset.o $(XPPLIBX_O)
	$(LINK.cxx) -o chooset.exe chooset.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './chooset.exe >& $@ && true'
	rm chooset.exe

garbage.out : garbaget.o $(XPPLIBX_O)
	$(LINK.cxx) -o garbaget.exe garbaget.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './garbaget.exe >& $@ && true'
	rm garbaget.exe

parrayt.exe : parrayt.o $(XPPLIBX_O)
	$(LINK.cxx) -o parrayt.exe parrayt.o $(XPPLIBX_O) $(LDLIBSXX)

parray.out : parrayt.exe
	csh -c './parrayt.exe >& $@ && true'
	rm parrayt.exe

wparrayt.exe : wparrayt.o $(XPPLIBX_O)
	$(LINK.cxx) -o wparrayt.exe wparrayt.o $(XPPLIBX_O) $(LDLIBSXX)

wparray.out : wparrayt.exe
	csh -c './wparrayt.exe >& $@ && true'
	rm wparrayt.exe

init.out : initt.o $(XPPLIBX_O)
	$(LINK.cxx) -o initt.exe initt.o $(XPPLIBX_O) $(LDLIBSXX)
	csh -c './initt.exe >& $@ && true'
	rm initt.exe

psrand.out : psrandt.o psrandx.o
	$(LINK.cxx) -o psrandt.exe psrandt.o psrandx.o $(LDLIBSXX)
	csh -c './psrandt.exe >& $@ && true'
	rm psrandt.exe

HASHES_O = fhashx.o hsboxx.o bombx.o

hashes.exe : hashes.o $(HASHES_O)
	$(LINK.cxx) -o $@ hashes.o $(HASHES_O) $(LDLIBSXX)

include depends.mk

