#ifndef STA_INC
#define STA_INC




type
	t_stat = record
		st_dev : integer;
		st_ino : integer;
		st_mode : integer;
		st_nlink : integer;
		st_uid : integer;
		st_gid : integer;
		st_rdev : integer;
		st_size : array[2] of integer;
		st_atime : array[2] of integer;
		st_mtime : array[2] of integer;
		st_ctime : array[2] of integer
	end;


#endif