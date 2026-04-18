dir ../../xpp
dir ../../xlatexpp
dir ../../comm
dir ../../server
dir ../../disk
dir ../../platform/sun
dir ../../urdi
dir ../../xpp/sxx
dir ../../xlatexpp/sxx
dir ../../comm/sxx
dir ../../server/sxx
dir ../../disk/sxx
dir ../../platform/sun
dir ../../urdi/sxx
define bboom
b blast__FP7Problem
end
define pboom
print *__0argProblemInstanceP
end
handle 28 nostop noprint
set print demangle off
define nogc
set DisableGC=1
end
define pthis
print *__0this
end
break unprotect__14HeapletManagerSFP7Heapler
break  protect__14HeapletManagerSFP7Heaplet


