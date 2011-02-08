#ifndef MSU1_H
#define MSU1_H

#ifdef DEBUG_MSU1
#define DBG_MSU1
#else
#define DBG_MSU1 while(0)
#endif

#define MSU_DAC_BUFSIZE	(2048)

int msu1_entrycheck_and_loop(void);

#endif
