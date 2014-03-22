/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */

#include <Wt/WServer>
#include "HomeFundation.h"
#include "SimpleChat.h"
#include <map>

#define RAPIDXML
#ifdef RAPIDXML
    #include "rapidxml/rapidxml.hpp"
    #include "rapidxml/rapidxml_utils.hpp"
#else
    #include <QXmlStreamReader>
    #include <QDebug>
    #include <QString>
    #include <QFile>
#endif
// Database
#include <Wt/Dbo/Session>
#include <Wt/Dbo/ptr>
#include <Wt/Dbo/Dbo>
#ifdef POSTGRES
    #include <Wt/Dbo/backend/Postgres>
#elif SQLITE3
    #include <Wt/Dbo/backend/Sqlite3>
#elif MYSQL
    #include <Wt/Dbo/backend/MySQL>
#elif FIREBIRD
    #include <Wt/Dbo/backend/Firebird>
#endif // FIREBIRD
#include <Wt/Dbo/FixedSqlConnectionPool>
//
#include "model/BlogSession.h"
#include "BlogRSSFeed.h"

/*
typedef std::map <std::string, boost::any> theConnectionPool;
theConnectionPool myConnectionPool;
typedef std::map <std::string, std::string> theRssFeed;
theRssFeed myRssFeed;
*/
/* ****************************************************************************
 * map
 */
std::map <std::string, boost::any> myConnectionPool;
std::map <std::string, std::string> myRssFeed;
/* ****************************************************************************
 * makeConnectionPool
 */
bool makeConnectionPool(QString filePath)
{
    filePath.append("domains.xml");
#ifdef RAPIDXML
    // Open XML File
    rapidxml::file<> xmlFile(filePath.toUtf8().constData());
    rapidxml::xml_document<> doc;
    doc.parse<0>(xmlFile.data());
    // Find our root node
    rapidxml::xml_node<> * root_node = doc.first_node("domains");
    // define xml item
    rapidxml::xml_attribute<> *x_item;
    for (rapidxml::xml_node<> * domain_node = root_node->first_node("domain"); domain_node; domain_node = domain_node->next_sibling("domain"))
    {
        // domainhost
        x_item = domain_node->first_attribute("domainhost");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: domainhost = " << domain_node->name() << ")";
            return 1;
        }
        std::string domainhost(x_item->value(), x_item->value_size());
        // path
        x_item = domain_node->first_attribute("path");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: path)";
            return 1;
        }
        std::string path(x_item->value(), x_item->value_size());
        // user
        x_item = domain_node->first_attribute("user");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: user)";
            return 1;
        }
        std::string user(x_item->value(), x_item->value_size());
        // password
        x_item = domain_node->first_attribute("password");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: password)";
            return 1;
        }
        std::string password(x_item->value(), x_item->value_size());
        // port
        x_item = domain_node->first_attribute("port");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: port)";
            return 1;
        }
        std::string port(x_item->value(), x_item->value_size());
        // dbname
        x_item = domain_node->first_attribute("dbname");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: dbname)";
            return 1;
        }
        std::string dbname(x_item->value(), x_item->value_size());
        // rssTitle
        x_item = domain_node->first_attribute("rssTitle");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: rssTitle)";
            return 1;
        }
        std::string rssTitle(x_item->value(), x_item->value_size());
        // rssURL
        x_item = domain_node->first_attribute("rssURL");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: rssURL)";
            return 1;
        }
        std::string rssURL(x_item->value(), x_item->value_size());
        // rssDescription
        x_item = domain_node->first_attribute("rssDescription");
        if (!x_item)
        {
            Wt::log("error") << "(makeConnectionPool: Missing XML Element: rssDescription)";
            return 1;
        }
        std::string rssDescription(x_item->value(), x_item->value_size());
        myRssFeed[domainhost.c_str()] = std::string(rssTitle.c_str()) + "\t" + std::string(rssURL.c_str()) + "\t" + std::string(rssDescription.c_str()) + "\t" + std::string(path.c_str());

        Wt::Dbo::SqlConnection *dbConnection;
        #ifdef POSTGRES
            dbConnection = new dbo::backend::Postgres("user=" + std::string(user.c_str()) + " password=" + std::string(password.c_str()) + " port=" + std::string(port.c_str()) + " dbname=" + std::string(dbname.c_str()));
        #elif SQLITE3
            dbo::backend::Sqlite3 *sqlite3 = new dbo::backend::Sqlite3(std::string(path.c_str()) + "app_root/" + std::string(dbname.c_str()));
            sqlite3->setDateTimeStorage(Wt::Dbo::SqlDateTime, Wt::Dbo::backend::Sqlite3::PseudoISO8601AsText);
            dbConnection = sqlite3;
        #elif MYSQL
            dbConnection = new dbo::backend::MySQL(dbname.c_str(), user.c_str(), password.c_str(), "localhost");
        #elif FIREBIRD
            #ifdef WIN32
                myFile = "C:\\opt\\db\\firebird\\" + dbname;
            #else
                myFile = "/opt/db/firebird/" + dbname;
            #endif
            dbConnection = new dbo::backend::Firebird("localhost", myFile.c_str(), myUser.c_str(), myPW.c_str(), "", "", ""); // Server:localhost, Path:File, user, password
        #endif // FIREBIRD
        dbConnection->setProperty("show-queries", "true");
        // We need to convert it FixedSqlConnectionPool to SqlConnectionPool, not sure if I should just refactor to use FixedSqlConnectionPool
        Wt::Dbo::SqlConnectionPool *dbConnection_ = new dbo::FixedSqlConnectionPool(dbConnection, 10);
        myConnectionPool[domainhost.c_str()] = dbConnection_;

        /*
        #ifdef POSTGRES
            myConnectionPool[domainhost.c_str()] = BlogSession::createConnectionPool("user=" + std::string(user.c_str()) + " password=" + std::string(password.c_str()) + " port=" + std::string(port.c_str()) + " dbname=" + std::string(dbname.c_str()));
        #elif SQLITE3
            myConnectionPool[domainhost.c_str()] = BlogSession::createConnectionPool(std::string(path.c_str()) + "app_root/" + std::string(dbname.c_str()));
        #elif MYSQL
            myConnectionPool[domainhost.c_str()] = BlogSession::createConnectionPool(dbname.data(), user.c_str(), password.c_str(), "localhost"); // , port.c_str()
        #elif FIREBIRD
            // Untested
            std::string myFile;
            std::string myUser = user;
            std::string myPW = password;
            #ifdef WIN32
                myFile = "C:\\opt\\db\\firebird\\" + dbname;
            #else
                myFile = "/opt/db/firebird/" + dbname;
            #endif
            myConnectionPool[domainhost.c_str()] = BlogSession::createConnectionPool("localhost" + "\t" + std::string(myFile.c_str()) + "\t" + std::string(myUser.c_str()) + "\t" + std::string(myPW.c_str())); // Pack Parameter
        #endif // FIREBIRD
        */
    }

    return true;
    //
#else
    QString domainhost;
    QString path;
    QString user;
    QString password;
    QString port;
    QString dbname;
    QString rssTitle;
    QString rssURL;
    QString rssDescription;
    QFile file(filePath);

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        Wt::log("warnning") << "(makeConnectionPool: File open error" << file.errorString().toStdString() << ")";
        return false;
    }
    QXmlStreamReader inputStream(&file);
    while (!inputStream.atEnd() && !inputStream.hasError())
    {
        inputStream.readNext();
        if (inputStream.isStartElement())
        {
            /* Let's get the attributes for domains */
            QXmlStreamAttributes attributes = inputStream.attributes();
            if(attributes.hasAttribute("domainhost"))
            {
                domainhost = attributes.value("domainhost").toString();
            }
            if(attributes.hasAttribute("path"))
            {
                path = attributes.value("path").toString();
            }
            if(attributes.hasAttribute("user"))
            {
                user = attributes.value("user").toString();
            }
            if(attributes.hasAttribute("password"))
            {
                password = attributes.value("password").toString();
            }
            if(attributes.hasAttribute("port"))
            {
                port = attributes.value("port").toString();
            }
            if(attributes.hasAttribute("dbname"))
            {
                dbname = attributes.value("dbname").toString();
            }
            if(attributes.hasAttribute("rssTitle"))
            {
                rssTitle = attributes.value("rssTitle").toString();
            }
            if(attributes.hasAttribute("rssURL"))
            {
                rssURL = attributes.value("rssURL").toString();
            }
            if(attributes.hasAttribute("rssDescription"))
            {
                rssDescription = attributes.value("rssDescription").toString();
            }
            myRssFeed[domainhost.toStdString()] = rssTitle.toStdString().append("\t").append(rssURL.toStdString()).append("\t").append(rssDescription.toStdString()).append("\t").append(path.toStdString()).c_str();
            #ifdef POSTGRES
                myConnectionPool[domainhost.toStdString()] = BlogSession::createConnectionPool("user=" + user.toStdString() + " password=" + password.toStdString() + " port=" + port.toStdString() + " dbname=" + dbname.toStdString());
            #elif SQLITE3
                myConnectionPool[domainhost.toStdString()] = BlogSession::createConnectionPool(path.toStdString().append("app_root/").append(dbname));
            #elif MYSQL
                myConnectionPool[domainhost.toStdString()] = BlogSession::createConnectionPool(dbname, user, password, "localhost", port);
            #elif FIREBIRD
                // Untested
                std::string myFile;
                std::string myUser = user;
                std::string myPW = password;
                #ifdef WIN32
                    myFile = "C:\\opt\\db\\firebird\\" + dbname;
                #else
                    myFile = "/opt/db/firebird/" + dbname;
                #endif
                myConnectionPool[domainhost.toStdString()] = BlogSession::createConnectionPool("localhost" + "\t" + myFile + "\t" + myUser + "\t" + myPW); // Pack Parameter
            #endif // FIREBIRD
        }
    }
    return true;
#endif
}
/* ****************************************************************************
 * main
 */
int main(int argc, char **argv)
{
    try
    {
        Wt::WServer server(argv[0]);

        server.setServerConfiguration(argc, argv, WTHTTP_CONFIGURATION);

        BlogSession::configureAuth();

        if (!makeConnectionPool(server.appRoot().c_str()))
        {
            return 1; // Fix 404
        }

        Wt::log("notice") << "(main: myRssFeed element " << myRssFeed["localhost"] << ")";

        server.addEntryPoint(Wt::Application, boost::bind(&createWtHomeApplication,  _1), "", "favicon.ico");
        // rss feed
        BlogRSSFeed rssFeed;
        server.addResource(&rssFeed, "/wt/blog/feed/"); // Fix wt

        //SimpleChatServer chatServer(server);
        //server.addEntryPoint(Wt::Application, boost::bind(createApplication, _1, boost::ref(chatServer)), "/chat");
        //server.addEntryPoint(Wt::WidgetSet,   boost::bind(createWidget, _1,      boost::ref(chatServer)), "/chat.js");

        if (server.start())
        {
            WServer::waitForShutdown();
            server.stop();
        }

    }
    catch (Wt::WServer::Exception& e)
    {
        std::cerr << e.what() << std::endl;
    }
    catch (std::exception &e)
    {
        std::cerr << "exception: " << e.what() << std::endl;
    }
}
// --- End Of File ------------------------------------------------------------
