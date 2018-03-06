 #
include $(ORACLE_HOME)/precomp/lib/env_precomp.mk


EXE = parse_bank_file
OBJS = parse_bank_file.o

.SUFFIXES: .pc .c .o

parse_bank_file:   $(OBJS)
	$(CC) -o $(EXE) $(OBJS) -L$(LIBHOME) $(PROLDLIBS)

.pc.c:
	$(PROC) SQLCHECK=SEMANTICS $(PROCFLAGS) USERID=$(DB_USER)/$(DB_PASS)@$(DB_NAME) iname=$*

.pc.o:
	$(PROC) SQLCHECK=SEMANTICS $(PROCFLAGS) USERID=$(DB_USER)/$(DB_PASS)@$(DB_NAME) iname=$*
	$(CC) $(CFLAGS) -c $*.c

.c.o:
	$(CC) -g3 -O0 $(CFLAGS) -c $*.c

