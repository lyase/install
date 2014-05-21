#-------------------------------------------------
#
# Project created by QtCreator for Wt
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
            model/hitCounter.cpp view/BlogImpl.cpp view/VideoImpl.cpp \
    model/TheVideo.cpp \
    model/VideoSession.cpp \
    view/VideoView.cpp

HEADERS += FileItem.h model/BlogSession.h model/BlogUserDatabase.h model/Comment.h \
            model/Post.h model/Tag.h model/Token.h model/User.h \
            view/BlogLoginWidget.h view/BlogView.h view/CommentView.h \
            view/EditUsers.h view/PostView.h BlogRSSFeed.h asciidoc/asciidoc.h \
            SimpleChat.h SimpleChatServer.h SimpleChatWidget.h HomeBase.h HomeFundation.h PopupChatWidget.h \
            model/hitCounter.h view/BlogImpl.h view/VideoImpl.h \
    model/TheVideo.h \
    model/VideoSession.h \
    view/VideoView.h \
    rapidxml/rapidxml.hpp \
    rapidxml/rapidxml_xhtml.hpp \
    rapidxml/rapidxml_utils.hpp \
    rapidxml/rapidxml_print.hpp \
    rapidxml/rapidxml_iterators.hpp
#
# Remove Other Files before posting to github
OTHER_FILES += wt-home.xml wt-home_cn.xml wt-home_ru.xml \
                css/reset.css css/home.css css/asciidoc.css css/blog.css css/blogexample.css css/chatwidget_ie6.css css/chatwidget.css \
                index.html model/update-sqlite3-3.1.12.sql blog.xml css/wt/wt.css css/wt/wt_ie.css simplechat.xml \
    ../wt-home-build-desktop-Debug/app_root/blog.xml \
    ../wt-home-build-desktop-Debug/app_root/simplechat.xml \
    ../wt-home-build-desktop-Debug/app_root/wt-home_cn.xml \
    ../wt-home-build-desktop-Debug/app_root/wt-home_ru.xml \
    ../wt-home-build-desktop-Debug/app_root/wt-home.xml \
    ../wt-home-build-desktop-Debug/doc_root/resources/css/chat/chatapp.css \
    ../wt-home-build-desktop-Debug/doc_root/resources/css/chat/chatwidget_ie6.css \
    ../wt-home-build-desktop-Debug/doc_root/resources/css/chat/chatwidget.css \
    ../wt-home-build-desktop-Debug/app_root/domains.xml \
    domains.xml \
    ../../../../../../../lightwizzard/app_root/blog.xml \
    ../../../../../../../lightwizzard/app_root/simplechat.xml \
    ../../../../../../../lightwizzard/app_root/wt-home_cn.xml \
    ../../../../../../../lightwizzard/app_root/wt-home_ru.xml \
    ../../../../../../../lightwizzard/app_root/wt-home.xml \
    ../../../../../../../vetshelpcenter/app_root/blog.xml \
    ../../../../../../../vetshelpcenter/app_root/simplechat.xml \
    ../../../../../../../vetshelpcenter/app_root/wt-home_cn.xml \
    ../../../../../../../vetshelpcenter/app_root/wt-home_ru.xml \
    ../../../../../../../vetshelpcenter/app_root/wt-home.xml \
    ../../../../../../../wittywizard/app_root/blog.xml \
    ../../../../../../../wittywizard/app_root/simplechat.xml \
    ../../../../../../../wittywizard/app_root/wt-home_cn.xml \
    ../../../../../../../wittywizard/app_root/wt-home_ru.xml \
    ../../../../../../../wittywizard/app_root/wt-home.xml \
    ../../../../../../../lightwizzard/app_root/video/video.xml \
    ../../../../../lightwizzard/app_root/blog.xml \
    ../../../../../lightwizzard/app_root/simplechat.xml \
    ../../../../../vetshelpcenter/app_root/blog.xml \
    ../../../../../vetshelpcenter/app_root/wt-home_ru.xml \
    ../../../../../vetshelpcenter/app_root/wt-home.xml \
    ../../../../../vetshelpcenter/app_root/simplechat.xml \
    ../../../../../wittywizard/app_root/blog.xml \
    ../../../../../wittywizard/app_root/simplechat.xml \
    ../../../../../wittywizard/app_root/wt-home.xml \
    Notes/git-update.sh \
    Notes/README.html \
    Notes/credentials.txt \
    Notes/More-Notes.txt \
    Notes/Notes.txt \
    Notes/README.md \
    Notes/vm-source-code.txt \
    Notes/Wt-Mail-list-1.txt \
    README.md \
    ../../../../../lightwizzard/app_root/video/video.xml \
    ../build-WittyWizard-Desktop-Debug/doc_root/resources/css/wittywizard.css \
    ../build-WittyWizard-Desktop-Debug/doc_root/resources/css/wittywizard_ie.css \
    ../build-WittyWizard-Desktop-Debug/app_root/wt-home.xml \
    ../build-WittyWizard-Desktop-Debug/app_root/wt-home_ru.xml \
    ../build-WittyWizard-Desktop-Debug/app_root/wt-home_cn.xml \
    ../build-WittyWizard-Desktop-Debug/app_root/blog.xml \
    ../../../../../vetshelpcenter/app_root/video/video.xml \
    ../../../../../wittywizard/app_root/video/video.xml \
    ../build-WittyWizard-Desktop-Debug/app_root/video/video.xml \
    app_root/simplechat.xml \
    app_root/domains.xml \
    app_root/blog.xml \
    app_root/video/video.xml \
    ../../../../../lightwizzard/app_root/ww-home.xml \
    ../../../../../lightwizzard/app_root/ww-home_ru.xml \
    ../../../../../lightwizzard/app_root/ww-home_cn.xml \
    app_root/ww-home.xml \
    app_root/ww-home_ru.xml \
    app_root/ww-home_cn.xml \
    ../../../../../wittywizard/app_root/ww-home_cn.xml \
    ../../../../../wittywizard/app_root/ww-home_ru.xml \
    ../../../../../vetshelpcenter/app_root/ww-home_cn.xml \
    ../../../../../vetshelpcenter/app_root/ww-home_ru.xml \
    ../../../../../vetshelpcenter/app_root/ww-home.xml \
    ../../../../../wittywizard/app_root/ww-home.xml \
    ../build-WittyWizard-Desktop-Debug/app_root/domains.xml \
    rapidxml/manual.html \
    rapidxml/license.txt

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
# ### End Of File #############################################################
