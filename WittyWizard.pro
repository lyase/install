#-------------------------------------------------
#
# Project created by QtCreator for Witty Wizard
#
# run --docroot . --http-address 0.0.0.0 --http-port 8088
# --docroot ./doc_root --approot "./app_root" --deploy-path=/wt --http-address 0.0.0.0 --http-port 8088
# sudo /usr/bin/qtcreator
#
#-------------------------------------------------
QT       += core
QT       -= gui
QT       += sql

TARGET = Witty-Wizard
CONFIG   += console
CONFIG   -= app_bundle
TEMPLATE = app

LIBS += -L/usr/lib -I/usr/local/include -lwt -lwthttp -lwtdbo -lcrypt -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time -lboost_thread


SOURCES += BlogRSSFeed.cpp FileItem.cpp main.cpp view/BlogLoginWidget.cpp view/BlogView.cpp \
            view/CommentView.cpp view/EditUsers.cpp view/PostView.cpp model/BlogSession.cpp model/BlogUserDatabase.cpp \
            model/Comment.cpp model/Post.cpp model/Tag.cpp model/Token.cpp model/User.cpp asciidoc/asciidoc.cpp SimpleChat.cpp \
            SimpleChatServer.cpp SimpleChatWidget.cpp HomeBase.cpp HomeFundation.cpp PopupChatWidget.cpp \
            view/BlogImpl.cpp view/VideoImpl.cpp \
    model/TheVideo.cpp \
    model/VideoSession.cpp \
    view/VideoView.cpp \
    WittyWizard.cpp \
    model/HitCounter.cpp \
    view/HitImpl.cpp \
    view/HitView.cpp \
    model/HitSession.cpp

HEADERS += FileItem.h model/BlogSession.h model/BlogUserDatabase.h model/Comment.h \
            model/Post.h model/Tag.h model/Token.h model/User.h \
            view/BlogLoginWidget.h view/BlogView.h view/CommentView.h \
            view/EditUsers.h view/PostView.h BlogRSSFeed.h asciidoc/asciidoc.h \
            SimpleChat.h SimpleChatServer.h SimpleChatWidget.h HomeBase.h HomeFundation.h PopupChatWidget.h \
            view/BlogImpl.h view/VideoImpl.h \
    model/TheVideo.h \
    model/VideoSession.h \
    view/VideoView.h \
    rapidxml/rapidxml.hpp \
    rapidxml/rapidxml_xhtml.hpp \
    rapidxml/rapidxml_utils.hpp \
    rapidxml/rapidxml_print.hpp \
    rapidxml/rapidxml_iterators.hpp \
    WittyWizard.h \
    model/HitCounter.h \
    view/HitImpl.h \
    view/HitView.h \
    model/HitSession.h
#

# PostgreSql
DEFINES += POSTGRES
LIBS += -lwtdbopostgres

# Sqlite3
#DEFINES += SQLITE3
#LIBS += -lwtdbosqlite3

# MySQL
# svn co https://wtdbomysql.svn.sourceforge.net/svnroot/wtdbomysql wtdbomysql
#DEFINES += MYSQL
#LIBS += -lwtdbomysql

# Firebird
#DEFINES += FIREBIRD
#LIBS += -lwtdbofirebird

# Debug mode
QMAKE_CXXFLAGS += -DNDEBUG
# C++11 compatable compile mode
QMAKE_CXXFLAGS += "-std=c++11"
CXXFLAGS="-std=c++0x"

# g++ -L/usr/lib -L/usr/local/lib -I/usr/local/include -lwtdbosqlite3 -lwthttp -lwt -lwtdbo -lcrypt -lpng -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time -lboost_thread main.cpp App.cpp AuthWidget.C RegistrationView.C model/Session.C model/User.C model/UserDetailsModel.C -o WittyWizard.wt
# -lboost_thread vs CentOS -lboost_thread-mt
#  -ltiff

# Use Navigation Bar if not defined
#DEFINES += NAV_MENU
# use QRegExp instead of string parser
#DEFINES += REGX
# Use rapidxml instead of QXmlStreamReader
DEFINES += RAPIDXML
# WVideo or WMediaPlayer
#DEFINES += WVIDEO
# Theme
DEFINES += THEME3
# Video Manager Module
DEFINES += VIDEOMAN
#DEFINES += USE_TEMPLATE
# ### End Of File #############################################################
