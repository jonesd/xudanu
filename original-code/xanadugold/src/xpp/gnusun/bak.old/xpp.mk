#
# $Id: xpp.mk,v 1.22 1993/03/16 22:31:20 eric Exp $
#
# clients can pass in extra compile options with
#  EXTRAINCLUDES = -Ifoo -Ibar
#  EXTRADEFS = -Dbaz
#  EXTRASTUBBLEDEFS = -Fblort
#  EXTRACLEANING = file1 1zfile2		- extra things for make clean
#  CXXOPTS = -CRUTCH
#
include $(MAKELIB)/xu-$(PLATFORM).mk
#
# magic default rule to prevent default execution of below and export.mk rules
#
zizimaedzhikdefaltrul : default

# sun4 case(s)
CXX = gcc

CXXSYSINCLUDES = -I/usr/local/lib/g++-include  -I/usr/local/lib/g++-include/sys -I/usr/local/lib/gcc-lib/sparc-sun-sunos4.1.4/2.6.3/include  -I/usr/local/lib/gcc-lib/sparc-sun-sunos4.1.4/2.6.3/include/sys 

PROFILING_SWITCH = -pg
#COMPILER_SYS_DEFINES =  -DUSE_INLINE -DGNUSUN -DGNU  -Dsparc -Dunix  -Wall   -Wtraditional -Wparentheses 
COMPILER_SYS_DEFINES =  -DUSE_INLINE -DGNUSUN -DGNU  -Dsparc -Dunix   -w
#COMPILER_SYS_DEFINES =   -DGNUSUN -DGNU  -Dsparc -Dunix  -Wall
NM_FORMAT_ARG =

EXTRADEFS =
CXXEXTRAINCLUDES = $(CXXSYSINCLUDES)
CXXINCLUDES = -I. -I.. -I$(XPPDIR)/xpp -I$(XPPDIR)/xlatexpp -I$(XPPDIR)/disk -I$(XPPDIR)/comm -I$(XPPDIR)/server -I$(XPPDIR)/disk -I$(XPPDIR)/urdi -I../sxx $(CXXEXTRAINCLUDES)
DEFINES = $(EXTRADEFS)
CXXDEFINES = $(DEFINES)

#CXXOPTS =  -Winline -save-temps
CXXOPTS =  -Winline  -DMANUAL_CRUTCH=1
#CXXDEFINES = $(DEFINES) 
#CXXDEFINES = -DUSE_INLINE -DMANUAL_CRUTCH=1 $(DEFINES) 
#CXXDEFINES = -DUSE_INLINE -DUNSAFE_CASTING $(DEFINES) 

#
# This should turn off the .?~ rules that are the default
#
#
SUFFIXES = .cxx .o .c .s .S .ln .f .F .l .mod .sym .def .p .r .y .h .sh \
           .dif .out e.txt n.txt .ppout .hxx .rc .ref \
	   .cps .test .diffs .exp .err .cex .cer .sxx .includes \
	   .nit
.SUFFIXES: $(SUFFIXES)                     


#
#       C language section
#
CC        = gcc
CFLAGS    = -g3  $(PROFILING_SWITCH) $(INCLUDES)  $(COMPILER_SYS_DEFINES)

COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

%.o: ../%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

%.o: %.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

#
#	C++ language section
#
# local cfront doesn't generate code for multiple inheritance support...eric
# optimization higher that O1 suppresses tail recursion optimization since
# that technique presently doesn't know about unknown_control_flow, so it
# breaks on setjmp.
#
# see above for definition of CXX

CXX0FLAGS = -g3 -O0 $(PROFILING_SWITCH) $(CXXOPTS) $(CXXINCLUDES) \
	    $(COMPILER_SYS_DEFINES) $(CXXDEFINES)
CXX1FLAGS = -O1 $(PROFILING_SWITCH) $(CXXOPTS) $(CXXINCLUDES) \
	    $(COMPILER_SYS_DEFINES) $(CXXDEFINES)
CXX2FLAGS = -O2 $(PROFILING_SWITCH) $(CXXOPTS) $(CXXINCLUDES) \
	    $(COMPILER_SYS_DEFINES) $(CXXDEFINES)
CXX3FLAGS = -O3 $(PROFILING_SWITCH) $(CXXOPTS) $(CXXINCLUDES) \
	    $(COMPILER_SYS_DEFINES) $(CXXDEFINES)
CXX4FLAGS = -O4 $(PROFILING_SWITCH) $(CXXOPTS) $(CXXINCLUDES) \
	    $(COMPILER_SYS_DEFINES) $(CXXDEFINES)
CXXtcovFLAGS = -a -DTCOV $(PROFILING_SWITCH) $(CXXOPTS) $(CXXINCLUDES) \
	    $(COMPILER_SYS_DEFINES) $(CXXDEFINES)
CXXFLAGS = $(CXX0FLAGS)

COMPILE.cxx = $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE0.cxx = $(CXX) $(CXX0FLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE1.cxx = $(CXX) $(CXX1FLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE2.cxx = $(CXX) $(CXX2FLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE3.cxx = $(CXX) $(CXX3FLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE4.cxx = $(CXX) $(CXX4FLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILEtcov.cxx = $(CXX) $(CXXtcovFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c


EXPAND.cxx  = $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

LINK.cxx    = $(CXX) $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH)
LINKtcov.cxx = $(CXX) $(CXXtcovFLAGS) $(LDFLAGS) $(TARGET_ARCH)

#LINK.np.cxx    = $(CXX) -g $(INCLUDES) $(CXXDEFINES) $(LDFLAGS) $(TARGET_ARCH)
LINK.np.cxx    = $(CXX) -g3 $(CXXDEFINES) $(LDFLAGS) $(TARGET_ARCH)

LDLIBSXX = -lm $(LDLIBS) $(CXXPLATFORMLIBS)

%.o: ../%.cxx
	($(COMPILE.cxx) $(OUTPUT_OPTION) $< && (ld -r $@ ; rm -f $@ ; mv a.out $@ ; touch $@; true)) || (rm -f $@; false)

%.o: %.cxx
	($(COMPILE.cxx) $(OUTPUT_OPTION) $< && (ld -r $@ ; rm -f $@ ; mv a.out $@ ; touch $@; true)) || (rm -f $@; false)

#
# assembly language section
#

%.o: ../%.s
	as -o $@ $<

%.o: %.s
	as -o $@ $<

#
#	Produce stubble generated code
#
#	EXTRASTUBBLEDEPENDS can be set by client makefile to indicate foo.hf
#	or other files that .sxx's depend on.
#

STUBBLEDIR = $(XPPDIR)/stubble

STUBBLE = $(STUBBLEDIR)/$(PLATFORM)/stubble

#%.sxx : ../%.hxx $(EXTRASTUBBLEDEPENDS)
#	$(STUBBLE) $(EXTRASTUBBLEDEFS) $(INCLUDES) $(CXXDEFINES) $< -o../sxx/$@

../sxx/%.sxx : ../%.hxx $(STUBBLEDIR)/stubblef.f $(EXTRASTUBBLEDEPENDS)
	$(STUBBLE) $(EXTRASTUBBLEDEFS) $(CXXINCLUDES) $(CXXDEFINES) $< -o$@

%.ppo : ../%.hxx $(STUBBLEDIR)/stubblef.f $(EXTRASTUBBLEDEPENDS)
	$(STUBBLE) -p $(EXTRASTUBBLEDEFS) $(CXXINCLUDES) $(CXXDEFINES) $<


%.sxx : %.hxx $(STUBBLEDIR)/stubblef.f $(EXTRASTUBBLEDEPENDS)
	asynch ; $(STUBBLE) $(EXTRASTUBBLEDEFS) $(CXXINCLUDES) $(CXXDEFINES) $< -o../sxx/$@

%.ppo : %.hxx $(STUBBLEDIR)/stubblef.f $(EXTRASTUBBLEDEPENDS)
	asynch ; $(STUBBLE) -p $(EXTRASTUBBLEDEFS) $(CXXINCLUDES) $(CXXDEFINES) $<


#
#	Regression testing section
#		client makefiles must make appropriate %o.txt files
#

.out.dif :
	(diff ../$*.ref $< > $@) || (sleep 1; touch $<; false)
	touch $@

#
#	To see macro expansion errors, "make source.errors"
#

%.exp: ../%.cxx
	$(EXPAND.cxx) -E $(OUTPUT_OPTION) $< > $@

%.exp: %.cxx
	$(EXPAND.cxx) -E $(OUTPUT_OPTION) $< > $@

.exp.err: 
	fgrep -v "#" $< > foo.cxx
	$(COMPILE.cxx) $(OUTPUT_OPTION) foo.cxx 

#
#	To see c expansion errors, "make source.cerrors"
#

%.cex: ../%.cxx
	$(COMPILE.cxx) -Fc $(OUTPUT_OPTION) $< > $@

%.cex: %.cxx
	$(COMPILE.cxx) -Fc $(OUTPUT_OPTION) $< > $@

.cex.cer:
	fgrep -v "#line" $< > foo.c
	#	indent foo.c -bap -bacc -bad -bbb -ce -cli0.5
	#	c++filt2 < foo.c > foo.demangle
	$(COMPILE.c) $(OUTPUT_OPTION) foo.c

#
# in the unlikely case that assembly must be viewed, "make source.s"
#

%.s: ../%.cxx
	$(COMPILE.cxx) -S $(OUTPUT_OPTION) $<

%.s: ../%.c
	$(COMPILE.c) -S $(OUTPUT_OPTION) $<

%.s: %.cxx
	$(COMPILE.cxx) -S $(OUTPUT_OPTION) $<

%.s: %.c
	$(COMPILE.c) -S $(OUTPUT_OPTION) $<

#
#	To see timing results, "make source.timing"
#
#.exe.timing:
#	/usr/5bin/time csh -c './$< >& /dev/null ; true' && \
#	gprof -b $< | c++filt2 > $@

#
#	xlint section
#

%.nit: ../%.cxx
	$(XPPDIR)/stubble/$(PLATFORM)/xlint $(INCLUDESXX) $(CXXDEFINES) $<

%.inc: ../%.cxx
	/home/xanadu/ravi/bin/includes $(INCLUDESXX) $<


%.nit: %.cxx
	$(XPPDIR)/stubble/$(PLATFORM)/xlint $(CXXINCLUDES) $(CXXDEFINES) $<

%.inc: %.cxx
	/home/xanadu/ravi/bin/includes $(CXXINCLUDES) $<

#
# Clean dependable virgins that you can count on and other random rules
#

clean :
	rm -f *.ppout *-cX*.cxx *~ ../*~ core *.cexpand *.expand foo*
	rm -f memdump.txt zz* #* *.bak *.BAK $(EXTRACLEANING)
	find .. -name "*.save" -exec rm "-i" "{}" ";"

virgin : clean
	rm -f *.o *.exe ../sxx/*.sxx *.dif *.out gmon.out

newborn : virgin
	rm -f ../*xx
	rm depends.mk
	touch depends.mk

wc :
	cd .. ; wc *c.h *c.c *t.c *p.hxx *x.hxx *x.cxx *t.cxx *u.cxx

#
#	each client make file should include 'depends.mk,' usualy at the end
#

depends :
	-xmakedep -o - -R.hxx.sxx $(CXXDEFINES) $(CXXINCLUDES) \
		'-DCOPY:="copy.hf"' '-DPSEUDO_COPY:="copy.hf"' \
		-I$(XPPDIR)/stubble $(SYSINCLUDES) -W `ls *.cxx ../*.cxx` \
		| sed -e 's|^.*/\([a-z0-9]*\)\.sxx|        ../sxx/\1.sxx|' > depends.mk
	-xmakedep -o - $(CXXINCLUDES)  $(SYSZZZINCLUDES) \
		-W `ls *.c ../*.c` \
		| sed -e 's|^.*/\([a-z0-9]*\)\.sxx|        ../sxx/\1.sxx|' >> depends.mk
	-xmakedep -o - -e sxx $(CXXDEFINES) -DSTUBBLE $(CXXINCLUDES) \
		$(SYSZZINCLUDES) -W `ls *.hxx ../*.hxx` \
		| sed -e 's|^\([a-z0-9]*\)\.sxx:|../sxx/\1.sxx:|' >> depends.mk
	-(echo -n sxx: ; grep ../sxx depends.mk | grep -v : \
		| sed -e 's/ \\//' -e "s/$$/ \\\\/") >> depends.mk

#
#	magic rule used as comment/hint-to-make to cause rule evaluation
#

FORCE :

