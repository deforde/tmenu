#include "test_entry.h"

#include <unity.h>

void setUp(void) {
}

void tearDown(void) {
}

int main(void) {
  UNITY_BEGIN();

  RUN_TEST(testEntryBasic);

  return UNITY_END();
}
