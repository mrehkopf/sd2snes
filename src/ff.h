/*--------------------------------------------------------------------------/
/  FatFs - FAT file system module include file  R0.06        (C)ChaN, 2008
/---------------------------------------------------------------------------/
/ FatFs module is an experimenal project to implement FAT file system to
/ cheap microcontrollers. This is a free software and is opened for education,
/ research and development under license policy of following trems.
/
/  Copyright (C) 2008, ChaN, all right reserved.
/
/ * The FatFs module is a free software and there is no warranty.
/ * You can use, modify and/or redistribute it for personal, non-profit or
/ * commercial use without any restriction under your responsibility.
/ * Redistributions of source code must retain the above copyright notice.
/
/---------------------------------------------------------------------------*/

#ifndef _FATFS

#define _MCU_ENDIAN     1
/* The _MCU_ENDIAN defines which access method is used to the FAT structure.
/  1: Enable word access.
/  2: Disable word access and use byte-by-byte access instead.
/  When the architectural byte order of the MCU is big-endian and/or address
/  miss-aligned access results incorrect behavior, the _MCU_ENDIAN must be set
/  to 2. If it is not the case, it can be set to 1 for good code efficiency. */

#define _FS_READONLY    0
/* Setting _FS_READONLY to 1 defines read only configuration. This removes
/  writing functions, f_write, f_sync, f_unlink, f_mkdir, f_chmod, f_rename,
/  f_truncate and useless f_getfree. */

#define _FS_MINIMIZE    0
/* The _FS_MINIMIZE option defines minimization level to remove some functions.
/  0: Full function.
/  1: f_stat, f_getfree, f_unlink, f_mkdir, f_chmod, f_truncate and f_rename are removed.
/  2: f_opendir and f_readdir are removed in addition to level 1.
/  3: f_lseek is removed in addition to level 2. */

#define _USE_STRFUNC    0
/* To enable string functions, set _USE_STRFUNC to 1 or 2. */

#define _DRIVES     1 
/*MAX_DRIVES*/
/* Number of physical drives to be used. This affects the size of internal
 * table. (when using _USE_DRIVE_PREFIX */

#define _USE_MKFS   0
/* When _USE_MKFS is set to 1 and _FS_READONLY is set to 0, f_mkfs function is
/  enabled. */

#define _MULTI_PARTITION    0
/* When _MULTI_PARTITION is set to 0, each logical drive is bound to the same
/  physical drive number and can mount only 1st primary partition.
/
/  When it is set to 1, the low _PARTITION_MASK bits of each partition represent
/  the partition and the high (8-_PARTITION_MASK) bits represent the physical
/  drive */

#define _PARTITION_MASK     4

#define _USE_FSINFO 1
/* To enable FSInfo support on FAT32 volume, set _USE_FSINFO to 1. */

#define _USE_SJIS   0
/* When _USE_SJIS is set to 1, Shift-JIS code transparency is enabled, otherwise
/  only US-ASCII(7bit) code can be accepted as file/directory name. */

#define _USE_NTFLAG 0
/* When _USE_NTFLAG is set to 1, upper/lower case of the file name is preserved.
/  Note that the files are always accessed in case insensitive. */

#define _USE_CHDIR 0

#define _USE_CURR_DIR 1

#define _USE_LFN 1

/* Maximum number of characters to return for a LFN */
/* The buffer used for FILINFO.lfn must be at least */
/* _MAX_LFN_LENGTH+1 characters long!               */
/* Note that if _USE_LFN_DBCS is set, this value    */
/* represents the characters needed, not bytes      */
#define _MAX_LFN_LENGTH 255

/* When _USE_LFN_DBCS is set to 1, FILINFO.lfn will contain a DBCS string, not
/  a simple ASCII string  */
#define _USE_LFN_DBCS 0

/* When set to 1, All FIL objects will use the buffer.  This reduces memory
/  requirements as open files will only require space for a FIL object, but
/  operate slower. When set, ff.c will behave like tff.c, but will allow
/  multiple filesystems.  */
#define _USE_FS_BUF 1

/* When set to 1, All objects will use a static  buffer.  This reduces memory
/  requirements to the absolute minimum ~512 bytes for the buffer, but will
/  operate slower.  This option can only be set if _USE_FS_BUF is set.  */
#define _USE_1_BUF 1

/* If set to 1, FatFs will manage the FATFS structures after mounting.  If
/  set to 0, the caller must send the correct drive FATFS structure for each
/  call.  Normally, this should be set to 1, but if the caller wants to use
/  low level l_* functions or skip sending the drive number in the path string,
/  this must be turned off.  */
#define _USE_DRIVE_PREFIX 1

/* If set to 1, FatFS will delay mounting the drive until first use.  Normally,
/  this should be turned on.  However, it cannot be used with
/  _USE_DRIVE_PREFIX = 0  */
#define _USE_DEFERRED_MOUNT 0

/* New features in 0.05a, not required yet */
#define _USE_TRUNCATE 0
#define _USE_UTIME   0

#include "integer.h"

#if _USE_LFN_DBCS != 0
#define S_LFN_OFFSET 26
#define S_LFN_INCREMENT 2
#else
#define S_LFN_OFFSET 13
#define S_LFN_INCREMENT 1
#endif

/* Definitions corresponds to multiple sector size (not tested) */
#define S_MAX_SIZ   512U            /* Do not change */
#if S_MAX_SIZ > 512U
#define SS(fs)  ((fs)->s_size)
#else
#define SS(fs)  512U
#endif

#if _USE_1_BUF == 1 && _USE_FS_BUF == 0
#error You can only use 1_BUF with _USE_FS_BUF at present
#define _USE_1_BUF 0
#endif

typedef struct _BUF {
  DWORD sect;
  BYTE  dirty;              /* dirty flag (1:must be written back) */
//BYTE  pad1;
#if _USE_1_BUF != 0
  struct _FATFS *fs;
#endif
  BYTE  data[S_MAX_SIZ];    /* Disk access window for Directory/FAT */
} BUF;

/* File system object structure */
typedef struct _FATFS {
  //WORD    id;             /* File system mount ID */
    WORD    n_rootdir;      /* Number of root directory entries */
    DWORD   sects_fat;      /* Sectors per fat */
    DWORD   max_clust;      /* Maximum cluster# + 1 */
    DWORD   fatbase;        /* FAT start sector */
    DWORD   dirbase;        /* Root directory start sector (cluster# for FAT32) */
    DWORD   database;       /* Data start sector */
#if _USE_CHDIR != 0 || _USE_CURR_DIR != 0
    DWORD curr_dir;
#endif
#if !_FS_READONLY
    DWORD   last_clust;     /* Last allocated cluster */
    DWORD   free_clust;     /* Number of free clusters */
#if _USE_FSINFO
    DWORD   fsi_sector;     /* fsinfo sector */
    BYTE    fsi_flag;       /* fsinfo dirty flag (1:must be written back) */
  //BYTE    pad2;
#endif
#endif
    BYTE    fs_type;        /* FAT sub type */
    BYTE    csize;          /* Number of sectors per cluster */
#if S_MAX_SIZ > 512U
    WORD    s_size;         /* Sector size */
#endif
    BYTE    n_fats;         /* Number of FAT copies */
    BYTE    drive;          /* Physical drive number */
#if _USE_1_BUF == 0
    BUF   buf;
#endif
} FATFS;

/* Directory object structure */
typedef struct _DIR {
  //WORD    id;         /* Owner file system mount ID */
    WORD    index;      /* Current index */
    FATFS*  fs;         /* Pointer to the owner file system object */
    DWORD   sclust;     /* Start cluster */
    DWORD   clust;      /* Current cluster */
    DWORD   sect;       /* Current sector */
} DIR;


/* File object structure */
typedef struct _FIL {
  //WORD    id;             /* Owner file system mount ID */
    BYTE    flag;           /* File status flags */
    BYTE    csect;          /* Sector address in the cluster */
    FATFS*  fs;             /* Pointer to the owner file system object */
    DWORD   fptr;           /* File R/W pointer */
    DWORD   fsize;          /* File size */
    DWORD   org_clust;      /* File start cluster */
    DWORD   curr_clust;     /* Current cluster */
    DWORD   curr_sect;      /* Current sector */
#if _FS_READONLY == 0
    DWORD   dir_sect;       /* Sector containing the directory entry */
    BYTE*   dir_ptr;        /* Ponter to the directory entry in the window */
#endif
#if _USE_LESS_BUF == 0 && _USE_1_BUF == 0
    BUF   buf;              /* File R/W buffer */
#endif
} FIL;


/* File status structure */
typedef struct _FILINFO {
    DWORD fsize;            /* Size */
    WORD fdate;             /* Date */
    WORD ftime;             /* Time */
    BYTE fattrib;           /* Attribute */
    DWORD clust;            /* Start cluster */
    UCHAR fname[8+1+3+1];   /* Name (8.3 format) */
#if _USE_LFN != 0
    UCHAR* lfn;
#endif
} FILINFO;



/* Definitions corresponds to multi partition */

#if _MULTI_PARTITION != 0   /* Multiple partition cfg */

#define LD2PD(drv) (drv >> (8-_PARTITION_MASK))       /* Get physical drive# */
#define LD2PT(drv) (drv & ((1<<_PARTITION_MASK)-1))   /* Get partition# */
#define _LOGICAL_DRIVES (_DRIVES * (1<<_PARTITION_MASK))

#else                               /* Single partition cfg */

#define LD2PD(drv) (drv)            /* Physical drive# is equal to logical drive# */
#define LD2PT(drv) 0                /* Always mounts the 1st partition */
#define _LOGICAL_DRIVES _DRIVES

#endif


/* File function return code (FRESULT) */

typedef enum {
    FR_OK = 0,          /* 0 */
    FR_NOT_READY,       /* 1 */
    FR_NO_FILE,         /* 2 */
    FR_NO_PATH,         /* 3 */
    FR_INVALID_NAME,    /* 4 */
    FR_INVALID_DRIVE,   /* 5 */
    FR_DENIED,          /* 6 */
    FR_EXIST,           /* 7 */
    FR_RW_ERROR,        /* 8 */
    FR_WRITE_PROTECTED, /* 9 */
    FR_NOT_ENABLED,     /* 10 */
    FR_NO_FILESYSTEM,   /* 11 */
    FR_INVALID_OBJECT,  /* 12 */
    FR_MKFS_ABORTED,    /* 13 */
    FR_IS_DIRECTORY,    /* 13 */
    FR_IS_READONLY,     /* 14 */
    FR_DIR_NOT_EMPTY,   /* 15 */
    FR_NOT_DIRECTORY    /* 16 */
} FRESULT;



/*-----------------------------------------------------*/
/* FatFs module application interface                  */

#if _USE_DRIVE_PREFIX == 0
FRESULT f_mount (BYTE, FATFS*);                             /* Mount/Unmount a logical drive */
FRESULT f_open (FATFS*, FIL*, const UCHAR*, BYTE);          /* Open or create a file */
FRESULT f_read (FIL*, void*, UINT, UINT*);                  /* Read data from a file */
FRESULT f_write (FIL*, const void*, UINT, UINT*);           /* Write data to a file */
FRESULT f_lseek (FIL*, DWORD);                              /* Move file pointer of a file object */
FRESULT f_close (FIL*);                                     /* Close an open file object */
FRESULT f_opendir (FATFS*, DIR*, const UCHAR*);             /* Open an existing directory */
FRESULT f_readdir (DIR*, FILINFO*);                         /* Read a directory item */
FRESULT f_stat (FATFS*, const UCHAR*, FILINFO*);            /* Get file status */
FRESULT f_getfree (FATFS*, const UCHAR*, DWORD*);           /* Get number of free clusters on the drive */
FRESULT f_sync (FIL*);                                      /* Flush cached data of a writing file */
FRESULT f_unlink (FATFS*, const UCHAR*);                    /* Delete an existing file or directory */
FRESULT f_mkdir (FATFS*, const UCHAR*);                     /* Create a new directory */
FRESULT f_chmod (FATFS*, const UCHAR*, BYTE, BYTE);         /* Change file/dir attriburte */
FRESULT f_rename (FATFS*, const UCHAR*, const UCHAR*);      /* Rename/Move a file or directory */
FRESULT f_mkfs (BYTE, BYTE, WORD);                          /* Create a file system on the drive */
FRESULT f_chdir (FATFS*, const UCHAR*);                     /* Change current directory */

#else

FRESULT f_mount (BYTE, FATFS*);                             /* Mount/Unmount a logical drive */
FRESULT f_open (FIL*, const UCHAR*, BYTE);                  /* Open or create a file */
FRESULT f_read (FIL*, void*, UINT, UINT*);                  /* Read data from a file */
FRESULT f_write (FIL*, const void*, UINT, UINT*);           /* Write data to a file */
FRESULT f_lseek (FIL*, DWORD);                              /* Move file pointer of a file object */
FRESULT f_close (FIL*);                                     /* Close an open file object */
FRESULT f_opendir (DIR*, const UCHAR*);                     /* Open an existing directory */
FRESULT f_readdir (DIR*, FILINFO*);                         /* Read a directory item */
FRESULT f_stat (const UCHAR*, FILINFO*);                    /* Get file status */
FRESULT f_getfree (const UCHAR*, DWORD*, FATFS**);          /* Get number of free clusters on the drive */
FRESULT f_sync (FIL*);                                      /* Flush cached data of a writing file */
FRESULT f_unlink (const UCHAR*);                            /* Delete an existing file or directory */
FRESULT f_mkdir (const UCHAR*);                             /* Create a new directory */
FRESULT f_chmod (const UCHAR*, BYTE, BYTE);                 /* Change file/dir attriburte */
FRESULT f_rename (const UCHAR*, const UCHAR*);              /* Rename/Move a file or directory */
FRESULT f_mkfs (BYTE, BYTE, WORD);                          /* Create a file system on the drive */
FRESULT f_chdir (const UCHAR*);                             /* Change current directory */

#endif

/* Low Level functions */
FRESULT l_opendir(FATFS* fs, DWORD cluster, DIR *dirobj);   /* Open an existing directory by its start cluster */
FRESULT l_opencluster(FATFS *fs, FIL *fp, DWORD clust);     /* Open a cluster by number as a read-only file */
FRESULT l_getfree (FATFS*, const UCHAR*, DWORD*, DWORD);    /* Get number of free clusters on the drive, limited */

#if _USE_STRFUNC
#define feof(fp) ((fp)->fptr == (fp)->fsize)
#define EOF -1
int fputc (int, FIL*);                              /* Put a character to the file */
int fputs (const char*, FIL*);                      /* Put a string to the file */
int fprintf (FIL*, const char*, ...);               /* Put a formatted string to the file */
char* fgets (char*, int, FIL*);                     /* Get a string from the file */
#endif

/* User defined function to give a current time to fatfs module */

#if CONFIG_RTC_VARIANT > 0
DWORD get_fattime (void); /* 31-25: Year(0-127 org.1980), 24-21: Month(1-12), 20-16: Day(1-31) */
                            /* 15-11: Hour(0-23), 10-5: Minute(0-59), 4-0: Second(0-29 *2) */
#else
/* Fixed time: 1982-08-31 0:00:00, same month as the introduction of the C64 */
#  define get_fattime() 0x51f0000
#endif

/* File access control and file status flags (FIL.flag) */

#define FA_READ             0x01
#define FA_OPEN_EXISTING    0x00
#if _FS_READONLY == 0
#define FA_WRITE            0x02
#define FA_CREATE_NEW       0x04
#define FA_CREATE_ALWAYS    0x08
#define FA_OPEN_ALWAYS      0x10
#define FA__WRITTEN         0x20
#define FA__DIRTY           0x40
#endif
#define FA__ERROR           0x80


/* FAT sub type (FATFS.fs_type) */

#define FS_FAT12    1
#define FS_FAT16    2
#define FS_FAT32    3


/* File attribute bits for directory entry */

#define AM_RDO  0x01    /* Read only */
#define AM_HID  0x02    /* Hidden */
#define AM_SYS  0x04    /* System */
#define AM_VOL  0x08    /* Volume label */
#define AM_LFN  0x0F    /* LFN entry */
#define AM_DIR  0x10    /* Directory */
#define AM_ARC  0x20    /* Archive */



/* Offset of FAT structure members */

#define BS_jmpBoot          0
#define BS_OEMName          3
#define BPB_BytsPerSec      11
#define BPB_SecPerClus      13
#define BPB_RsvdSecCnt      14
#define BPB_NumFATs         16
#define BPB_RootEntCnt      17
#define BPB_TotSec16        19
#define BPB_Media           21
#define BPB_FATSz16         22
#define BPB_SecPerTrk       24
#define BPB_NumHeads        26
#define BPB_HiddSec         28
#define BPB_TotSec32        32
#define BS_55AA             510

#define BS_DrvNum           36
#define BS_BootSig          38
#define BS_VolID            39
#define BS_VolLab           43
#define BS_FilSysType       54

#define BPB_FATSz32         36
#define BPB_ExtFlags        40
#define BPB_FSVer           42
#define BPB_RootClus        44
#define BPB_FSInfo          48
#define BPB_BkBootSec       50
#define BS_DrvNum32         64
#define BS_BootSig32        66
#define BS_VolID32          67
#define BS_VolLab32         71
#define BS_FilSysType32     82

#define FSI_LeadSig         0
#define FSI_StrucSig        484
#define FSI_Free_Count      488
#define FSI_Nxt_Free        492

#define MBR_Table           446

#define DIR_Name            0
#define DIR_Attr            11
#define DIR_NTres           12
#define DIR_Chksum          13
#define DIR_CrtTime         14
#define DIR_CrtDate         16
#define DIR_FstClusHI       20
#define DIR_WrtTime         22
#define DIR_WrtDate         24
#define DIR_FstClusLO       26
#define DIR_FileSize        28



/* Multi-byte word access macros  */

#if _MCU_ENDIAN == 1    /* Use word access */
#define LD_WORD(ptr)        (WORD)(*(WORD*)(BYTE*)(ptr))
#define LD_DWORD(ptr)       (DWORD)(*(DWORD*)(BYTE*)(ptr))
#define ST_WORD(ptr,val)    *(WORD*)(BYTE*)(ptr)=(WORD)(val)
#define ST_DWORD(ptr,val)   *(DWORD*)(BYTE*)(ptr)=(DWORD)(val)
#elif _MCU_ENDIAN == 2  /* Use byte-by-byte access */
#define LD_WORD(ptr)        (WORD)(((WORD)*(volatile BYTE*)((ptr)+1)<<8)|(WORD)*(volatile BYTE*)(ptr))
#define LD_DWORD(ptr)       (DWORD)(((DWORD)*(volatile BYTE*)((ptr)+3)<<24)|((DWORD)*(volatile BYTE*)((ptr)+2)<<16)|((WORD)*(volatile BYTE*)((ptr)+1)<<8)|*(volatile BYTE*)(ptr))
#define ST_WORD(ptr,val)    *(volatile BYTE*)(ptr)=(BYTE)(val); *(volatile BYTE*)((ptr)+1)=(BYTE)((WORD)(val)>>8)
#define ST_DWORD(ptr,val)   *(volatile BYTE*)(ptr)=(BYTE)(val); *(volatile BYTE*)((ptr)+1)=(BYTE)((WORD)(val)>>8); *(volatile BYTE*)((ptr)+2)=(BYTE)((DWORD)(val)>>16); *(volatile BYTE*)((ptr)+3)=(BYTE)((DWORD)(val)>>24)
#else
#error Do not forget to set _MCU_ENDIAN properly!
#endif

#define _FATFS
#endif /* _FATFS */
