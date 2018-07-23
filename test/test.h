#ifdef BUILD_DLL
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT __declspec(dllimport)
#endif

class EXPORT CTest
{
public:
    CTest();
    virtual ~CTest();

    void printSomething(const char* text);
};
