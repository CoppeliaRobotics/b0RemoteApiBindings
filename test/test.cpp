#include "test.h"
#include <stdio.h>

CTest::CTest()
{
    printf("In constructor\n");
}

CTest::~CTest()
{
    printf("In destructor\n");
}

void CTest::printSomething(const char* text)
{
    printf("%s\n",text);
}
