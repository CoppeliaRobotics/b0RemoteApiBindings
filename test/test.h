#ifdef BUILD_DLL
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT __declspec(dllimport)
#endif

class CTest
{
public:
    EXPORT CTest();
    EXPORT virtual ~CTest();

    EXPORT void printSomething(const char* text);
};
