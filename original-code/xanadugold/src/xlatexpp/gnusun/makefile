#
#  xpp translated from smalltalk
#
#  $Id: makefile,v 1.21 1993/03/16 22:27:21 eric Exp $
#
#  For SGI:
#   - Replaced % rule with generic rule for making o.txt from .rc.
#     Added .rc to SUFFIXES in xpp.mk.
#      - michael Mar 27 1992
#

XPPDIR = ../..
EXTRADEFS = -DMANUAL_CRUTCH
#CXXOPTS = -CRUTCH
include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

include $(XPPDIR)/xpp/$(PLATFORM)/export.mk
include $(XPPDIR)/comm/$(PLATFORM)/export.mk
include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk

OTHER = cache gchooks hlogger primtab primval stepper thunk tokens
SET_PLUS = set tabtool
SPACE = cross edge filter hspace integer real sequenc space
TABLE = hashtab inttab tabent tables array
MORE_MISC = settab

NO_SPACES = $(OTHER) $(SET_PLUS)
SPACE_STUFF = $(SPACE) $(TABLE) $(MORE_MISC)

NO_SPACESX_O = $(NO_SPACES:=x.o)
SPACE_STUFFX_O = $(SPACE_STUFF:=x.o)

LIBST_O = $(XPPLIBX_O) $(COMMLIBX_O) xxpplibx.o spclibx.o testerx.o $(RCMAINX_O)

WORKING_TESTS = tester hlogger inttab hashtab integer become set tabent settab sequenc

TESTSD_TXT = $(WORKING_TESTS:=.dif) 

TESTS_O = $(WORKING_TESTS:=t.o) spacet.o

default : spclibx.o xxpplibx.o rcmainx.o

libs : default

all : spclibx.o xxpplibx.o tests

tests : $(TESTSD_TXT)

spclibx.o : $(SPACE_STUFFX_O)
	ld -r $(SPACE_STUFFX_O) -o spclibx.o

xxpplibx.o : $(NO_SPACESX_O)
	ld -r $(NO_SPACESX_O) -o xxpplibx.o

xlatestt.exe : $(TESTS_O) $(LIBST_O)
	$(LINK.cxx) -o $@ $(TESTS_O) $(LIBST_O) $(LDLIBSXX)

tester.out:  xlatestt.exe ../tester.rc
hlogger.out: xlatestt.exe ../hlogger.rc
inttab.out:  xlatestt.exe ../inttab.rc
hashtab.out: xlatestt.exe ../hashtab.rc
integer.out: xlatestt.exe ../integer.rc
become.out:  xlatestt.exe ../become.rc
set.out:     xlatestt.exe ../set.rc
tabent.out:  xlatestt.exe ../tabent.rc
settab.out:  xlatestt.exe ../settab.rc
sequenc.out: xlatestt.exe ../sequence.rc

%.out: ../%.rc
	csh -c './xlatestt.exe $< >& $@ && true'

#inttabx.o : inttabx.cxx
#	asynch ; $(COMPILE1.cxx) $(OUTPUT_OPTION) inttabx.cxx

#primtabx.o : primtabx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) primtabx.cxx

#tabentx.o : tabentx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) tabentx.cxx

#integerx.o : integerx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) integerx.cxx

#hashtabx.o : hashtabx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) hashtabx.cxx

#setx.o : setx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) setx.cxx

include depends.mk
