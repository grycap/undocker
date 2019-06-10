#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  char **params = (char**)malloc((argc+1)*sizeof(char*));
  for (int i=0;i<argc;i++) params[i]=argv[i];
  params[argc]=0;
  char app[]="/usr/bin/undocker-rt";
  params[0]=app;
  if (setuid(0)) {
    printf("failed to get root permissions\n");
    return 1;
  }
  if (execv(app, params)) {
    printf("failed to run '%s'\n", app);
    return 1;
  }
  return 0;
}