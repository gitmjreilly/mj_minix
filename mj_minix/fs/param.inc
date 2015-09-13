(* 
 * param.inc based on param.h AST1, 7900
 *
 * Fancy Jamet casting b/c my compiler does not have unions.
 * 
 * FS uses two messages in_msg, out_msg
 * We use pointers e.g. m3_in to messages to get the fields as AST wants them
 * So, for example, m3_in and m1_in both point to in_msg, but allow us to get fields
 *)
#ifndef PARAM_INC
#define PARAM_INC

#define ls_fd m2_in^.m2i1
#define name m3_in^.m3p1
#define mode m3_in^.m3i2
#define name_length m3_in^.m3i1
#define offset m2_in^.m2l1
#define pathname m3_in^.m3cal
#define whence m2_in^.m2i2

#define buffer m1_in^.m1p1
#define fd m1_in^.m1i1
#define nbytes m1_in^.m1i2

(* Output message stuff *)
#define reply_type m1_out^.m_type
#define reply_l1 m2_out^.m2l1


#endif 