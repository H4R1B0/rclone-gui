#ifndef LIBRCLONE_H
#define LIBRCLONE_H

struct RcloneRPCResult {
    char* Output;
    int Status;
};

extern void RcloneInitialize(void);
extern void RcloneFinalize(void);
extern struct RcloneRPCResult RcloneRPC(char* method, char* input);
extern void RcloneFreeString(char* str);

#endif /* LIBRCLONE_H */
