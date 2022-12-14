#include <stdlib.h>
#include <string.h>

#include <ncurses.h>

int main() {
  char *path = getenv("PATH");
  if (path == NULL) {
    printf("Failed to get the environment variable: 'PATH'\n");
    exit(EXIT_FAILURE);
  }

  char *saveptr = NULL;
  for (char *str = path;; str = NULL) {
    char *tok = strtok_r(str, ":", &saveptr);
    if (tok == NULL) {
      break;
    }
    printf("tok = %s\n", tok);
  }

  exit(EXIT_SUCCESS);
}
