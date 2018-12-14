# location of boost headers
#BOOST_INCLUDEPATH = "c:/local/boost_1_62_0"
#BOOST_INCLUDEPATH = "/usr/local/include"
#BOOST_INCLUDEPATH = "/usr/include"
#BOOST_INCLUDEPATH = "c:/msys64/mingw64/include"
BOOST_INCLUDEPATH = "d:/v_rep/programming/vcpkg/installed/x64-windows/include"    # (e.g. Windows)

# Boost libraries to link:
#BOOST_LIB_PATH = "c:/local/boost_1_62_0/lib64-msvc-14.0"
BOOST_LIB_PATH = "D:/v_rep/programming/vcpkg/installed/x64-windows/lib"

# location of lua headers
LUA_INCLUDEPATH = "d:/lua-5.1.5/src"
#LUA_INCLUDEPATH = "/usr/include/lua5.1"
#LUA_INCLUDEPATH = "/usr/local/include/lua5.1"

# lua libraries to link
LUA_LIBS = "d:/lua-5.1.5/src/lua51.lib"
#LUA_LIBS = "/usr/local/lib/liblua5.1.dylib"
#LUA_LIBS = -llua5.1

# jdk location
JDK_DIR = "C:/Program Files/Java/jdk1.7.0_40"
#JDK_DIR = "/usr/lib/jvm/java-7-openjdk-amd64"

# jdk header path
JDK_INCLUDEPATH = "$${JDK_DIR}/include" "$${JDK_DIR}/include/win32"
#JDK_INCLUDEPATH = "$${JDK_DIR}/include" "$${JDK_DIR}/include/linux"
#JDK_INCLUDEPATH = "/System/Library/Frameworks/JavaVM.framework/Headers"

# location of B0 headers:
B0_INCLUDEPATH = "d:/v_rep/programming/blueZero/include"    # (e.g. Windows)

# B0 libraries to link:
    B0_LIB = "d:/v_rep/programming/blueZero/build/Release/b0.lib"    # (e.g. Windows)
    B0_LIB_STATIC = "d:/v_rep/programming/blueZero/build/Release/b0-static.lib"    # (e.g. Windows)

#ZMQ:
    ZMQ_LIB = "D:\v_rep\programming\vcpkg\installed\x64-windows\lib\libzmq-mt-4_3_1.lib"    
    
# ZLIB:    
    ZLIB_LIB = "D:\v_rep\programming\vcpkg\installed\x64-windows\lib\zlib.lib"

exists(../config.pri) { include(../config.pri) }

