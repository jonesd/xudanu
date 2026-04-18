# 1 "../ccompatc.c"
 


















static char ccompatc_c_rcsid[] = "$Id: ccompatc.c,v 2.2 1992/08/14 22:06:59 shap Exp $";

# 1 "../ccompatc.h" 1
 














 
 
 
 














































 

 

 





 





 




# 98 "../ccompatc.h"






 





 





typedef long  		Int4;



typedef unsigned long  	UInt4;

typedef char			Int1;

typedef unsigned char		UInt1;


typedef long		Int32;




typedef unsigned long	UInt32;




typedef char		Int8;




typedef unsigned char	UInt8;




 

typedef int BooleanVar; 
















 


typedef double IEEEDoubleVar;  
typedef struct { unsigned char bytes [8]; } IEEE128;
typedef double IEEE64;
typedef float  IEEE32;
typedef struct {
	unsigned int sign :	 1 ;
	unsigned int exponent :  8 ;
	unsigned int mantissa : 23 ;
} IEEE32_fields;

typedef struct {
	unsigned int sign :	  1 ;
	unsigned int exponent :  11 ;
	unsigned int mantissaH : 20 ;
	unsigned int mantissaL : 32 ;
} IEEE64_fields;














 

 













 
 





 
# 233 "../ccompatc.h"

# 243 "../ccompatc.h"

# 253 "../ccompatc.h"


# 1 "/usr/local/lib/gcc-lib/sparc-sun-sunos4.1.3/2.5.8/include/string.h" 1 3
 














# 1 "/usr/local/lib/gcc-lib/sparc-sun-sunos4.1.3/2.5.8/include/sys/stdtypes.h" 1 3
 

 










typedef	int		sigset_t;	 

typedef	unsigned int	speed_t;	 
typedef	unsigned long	tcflag_t;	 
typedef	unsigned char	cc_t;		 
typedef	int		pid_t;		 

typedef	unsigned short	mode_t;		 
typedef	short		nlink_t;	 

typedef	long		clock_t;	 
typedef	long		time_t;		 



typedef long unsigned int size_t;		 



typedef int		ptrdiff_t;	 




typedef	unsigned short	wchar_t;	 



# 16 "/usr/local/lib/gcc-lib/sparc-sun-sunos4.1.3/2.5.8/include/string.h" 2 3







extern char *	strcat  (char *, const char *)  ;
extern char *	strchr  (const char *, int)  ;
extern int	strcmp  (const char *, const char *)  ;
extern char *	strcpy  (char *, const char *)  ;
extern size_t	strcspn  (const char *, const char *)  ;

extern char *	strdup( );

extern size_t	strlen  (const char *)  ;
extern char *	strncat  (char *, const char *, long unsigned int )  ;
extern int	strncmp  (const char *, const char *, long unsigned int )  ;
extern char *	strncpy  (char *, const char *, long unsigned int )  ;
extern char *	strpbrk  (const char *, const char *)  ;
extern char *	strrchr  (const char *, int)  ;
extern size_t	strspn  (const char *, const char *)  ;
extern char *	strstr  (const char *, const char *)  ;
extern char *	strtok  (char *, const char *)  ;

# 51 "/usr/local/lib/gcc-lib/sparc-sun-sunos4.1.3/2.5.8/include/string.h" 3





# 255 "../ccompatc.h" 2

 







# 273 "../ccompatc.h"









 




extern unsigned long alignUp  (unsigned long offset)  ;
   
   


 
 
 
 
 









 


































extern void doNothingWith  (void * ptr)  ;
















 




# 22 "../ccompatc.c" 2




 




	unsigned long alignUp (unsigned long offset)




{
    return ((offset + (sizeof (long))  -1) / (sizeof (long)) ) 
      * (sizeof (long)) ;
}


	void doNothingWith (void * ptr)




{
}

