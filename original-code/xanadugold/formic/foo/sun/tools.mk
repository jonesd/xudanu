
SUFFIXES = .cxx .o .c .s .S .ln .f .F .l .mod .sym .def .p .r .y .h .sh .cps \
	   .test .diffs t.exe d.txt

.SUFFIXES: $(SUFFIXES)                     

#ALTFLAG = -g
ALTFLAG = -O4
#PROFILE_FLAG = -pg

# Directories that everything wants to reference...

GMON_DIR=$(PARSERTOP)/gmon
GMON_O_DIR=$(PARSERTOP)/gmon/$(PLATFORM)
XPP_DIR=$(PARSERTOP)/xpp
XPP_O_DIR=$(PARSERTOP)/xpp/$(PLATFORM)
STRING_DIR=$(PARSERTOP)/string
STRING_O_DIR=$(PARSERTOP)/string/$(PLATFORM)
PARSER_DIR=$(PARSERTOP)/parser
PARSER_O_DIR=$(PARSERTOP)/parser/$(PLATFORM)
PARAMS_DIR=$(PARSERTOP)/params
PARAMS_O_DIR=$(PARSERTOP)/params/$(PLATFORM)

# INCLUDE can be overridden in the individual makefiles...

COMMONINC=-I.. -I$(GMON_DIR) -I$(XPP_DIR) -I$(STRING_DIR) -I$(PARSER_DIR) -I$(PARAMS_DIR)
INCLUDES=$(COMMONINC)

# ====== C language section ======== 

COMPILE.c=$(CC) -c $(ALTFLAG) $(PROFILE_FLAG) $(INCLUDES)
LINK.c=$(CC) $(PROFILE_FLAG)

CPP = $(BUILDROOT)/usr/lib/cpp
#CPP_INCL = -I$(BUILDROOT)/usr/include/CC-2.0
CPP_INCL = -I/usr/lang/SC1.0/include/CC

.c:  
	$(LINK.c) -o $@ $<

%.o: ../%.c
	$(COMPILE.c) $<

.c.o:     
	$(COMPILE.c) $<

# ===== C++ language section =======

#CXX  = CC-2.0
CXX  = CC
CXXFLAGS = $(ALTFLAG) $(PROFILE_FLAG)

COMPILE.cxx=$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(INCLUDES) -c
LINK.cxx=$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(GLDFLAGS) $(TARGET_ARCH) $(INCLUDES)

SPECIAL_MALLOC = 
LDLIBSXX = $(LDLIBS)

.cxx:  
	$(LINK.cxx) -o $@ $< $(LDLIBSXX)
%.o: ../%.cxx
	$(COMPILE.cxx) $(OUTPUT_OPTION) $<               
.cxx.o:     
	$(COMPILE.cxx) $(OUTPUT_OPTION) $<               

# === Regression testing section ===

.exe.out:
	./$*.exe > $*.out 2>&1
