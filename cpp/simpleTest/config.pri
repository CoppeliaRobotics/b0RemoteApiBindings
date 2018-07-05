# location of boost headers:
    BOOST_INCLUDEPATH = "c:/local/boost_1_62_0"    # (e.g. Windows)
    #BOOST_INCLUDEPATH = "/usr/local/include"    # (e.g. MacOS)

# location of B0 headers:
    B0_INCLUDEPATH = "../../blueZero/include"    # (e.g. Windows)

# B0 libraries to link:
    B0_LIBS = "../../blueZero/build/Release/b0.lib"    # (e.g. Windows)

# Boost thread libraries to link:
    BOOST_LIB_PATH = "c:/local/boost_1_62_0/lib64-msvc-14.0"

# Make sure if a config.pri is found one level above, that it will be used instead of this one:
    exists(../config.pri) { include(../config.pri) }
