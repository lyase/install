/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 * Last Update: 22 May 2014
 * Version: 1.0.0
 *
 */

#include <Wt/WServer>
//#include <boost/filesystem.hpp>
#include <sys/stat.h>
#include "HomeFundation.h"
#include "SimpleChat.h"
#include <map>
#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"
//
#include "model/BlogSession.h"
#include "BlogRSSFeed.h"
#include <sys/stat.h>
/*
typedef std::map <std::string, boost::any> theConnectionPool;
theConnectionPool myConnectionPool;
typedef std::map <std::string, std::string> theRssFeed;
*/
/* ****************************************************************************
 * Global Variable
 * root Prefix: Used to set the URL Path: http:domain.tdl\prefix\root-path
 * See Wt Documenation on: --deploy-path=
 */
std::string rootPrefix="ww"; // this is used to fix path issues in Wt, must be in run and in path of all menu items and resources
/* ****************************************************************************
 * Global map
 * Connection Pool Map
 * Holds the Pointer to Wt::Dbo::SqlConnectionPool *
 */
std::map <std::string, boost::any> myConnectionPool;
/* ****************************************************************************
 * Global Variable
 * domainHost="wittywizard.org"
 */
std::map <std::string, std::string> myDomainHost;
/* ****************************************************************************
 * Global Variable
 * domainPath="/home/wittywizard/"
 * Full Path to Domain: /home/domain.tdl/
 * string *myDomainPath;
 */
std::map <std::string, std::string> myDomainPath;
/* ****************************************************************************
 * Global Variable
 * dbName="wittywizard"
 */
std::map <std::string, std::string> myDbName;
/* ****************************************************************************
 * Global Variable
 * dbUser="wittywizard"
 */
std::map <std::string, std::string> myDbUser;
/* ****************************************************************************
 * Global Variable
 * password="The1Wizard2Witty4Flesh"
 */
std::map <std::string, std::string> myDbPassword;
/* ****************************************************************************
 * Global Variable
 * dbPort="5432"
 */
std::map <std::string, std::string> myDbPort;
/* ****************************************************************************
 * Global Variable
 * gasAccount="pub-1083602596491715"
 *
 */
std::map <std::string, std::string> myGasAccount;
/* ****************************************************************************
 * Global Variable
 * gaAccount="UA-xxxxxxxx-x"
 * Google Analytic Account: See domain.xml
 * http://google.com/analytics/
 */
std::map <std::string, std::string> myGaAccount;
/* ****************************************************************************
 * Global Variable
 * myIncludes="home|chat|blog|about|contact|video"
 * myIncludes: Each Menu Item Included
 * See domain.xml:includes="home|chat|blog|about|contact|video"
 */
std::map <std::string, std::string> myIncludes;
/* ****************************************************************************
 * Global Variable
 * defaultTheme="blue"
 * See domain.xml:defaultTheme="blue"
 */
std::map <std::string, std::string> myDefaultTheme;
/* ****************************************************************************
 * Global Function
 * is File: Full Path to File: /home/domain.tdl/filename.ext
 */
inline bool isFile(const std::string& name)
{
  struct stat buffer;
  return (stat (name.c_str(), &buffer) == 0);
  // which is faster?
  // return boost::filesystem::exists(name);
}
/* ****************************************************************************
 * Global Function
 * is Path: Full Path: /home/domain.tdl/
 */
struct stat sb;
inline bool isPath(const std::string& pathName)
{
    if (stat(pathName.c_str(), &sb) == 0 && S_ISDIR(sb.st_mode))
    {
        return true;
    }
    return false;
}
/* ****************************************************************************
 * makeConnectionPool
 * FIXIT: Would it be faster to save this to a database?
 */
bool makeConnectionPool(QString filePath)
{
    if (isFile(filePath.toStdString()))
    {
        Wt::log("info") << "Starting XML Configuration File makeConnectionPool(" << filePath.toStdString() << ")";
    }
    else
    {
        Wt::log("error") << "-> Missing XML Configuration File makeConnectionPool(" << filePath.toStdString() << ")";
        return 1;
    }
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
        // domainHost
        x_item = domain_node->first_attribute("domainHost");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: domainHost = " << domain_node->name();
            return 1;
        }
        std::string domainHost(x_item->value(), x_item->value_size());
        myDomainHost[domainHost] = domainHost;
        // domainPath
        x_item = domain_node->first_attribute("domainPath");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: domainPath";
            return 1;
        }
        std::string domainPath(x_item->value(), x_item->value_size());
        myDomainPath[domainHost] = domainPath;
        if (!isPath(domainPath.c_str()))
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing Path for Domain: " << domainHost << " : path = " << domainPath;
        }
        // dbName
        x_item = domain_node->first_attribute("dbName");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: dbName";
            return 1;
        }
        std::string dbName(x_item->value(), x_item->value_size());
        myDbName[domainHost] = dbName;
        // dbUser
        x_item = domain_node->first_attribute("dbUser");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: dbUser";
            return 1;
        }
        std::string dbUser(x_item->value(), x_item->value_size());
        myDbUser[domainHost] = dbUser;
        // dbPassword
        x_item = domain_node->first_attribute("dbPassword");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: dbPassword";
            return 1;
        }
        std::string dbPassword(x_item->value(), x_item->value_size());
        myDbPassword[domainHost] = dbPassword;
        // dbPort
        x_item = domain_node->first_attribute("dbPort");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: dbPort";
            return 1;
        }
        std::string dbPort(x_item->value(), x_item->value_size());
        myDbPort[domainHost] = dbPort;
        // gaAccount
        x_item = domain_node->first_attribute("gaAccount");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: gaAccount";
            return 1;
        }
        std::string gaAccount(x_item->value(), x_item->value_size());
        myGaAccount[domainHost] = gaAccount;
        // gasAccount
        x_item = domain_node->first_attribute("gasAccount");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: gasAccount";
            return 1;
        }
        std::string gasAccount(x_item->value(), x_item->value_size());
        myGasAccount[domainHost] = gasAccount;
        // myIncludes
        x_item = domain_node->first_attribute("myIncludes");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: myIncludes";
            return 1;
        }
        std::string includes(x_item->value(), x_item->value_size());
        myIncludes[domainHost] = includes;
        // defaultTheme
        x_item = domain_node->first_attribute("defaultTheme");
        if (!x_item)
        {
            Wt::log("error") << "-> makeConnectionPool(" << filePath.toStdString() << ") Missing XML Element: defaultTheme";
            return 1;
        }
        std::string defaultTheme(x_item->value(), x_item->value_size());
        myDefaultTheme[domainHost] = defaultTheme;
    } // end for (rapidxml::xml_node<> * domain_node = root_node->first_node("domain"); domain_node; domain_node = domain_node->next_sibling("domain"))
    return true;
} // end bool makeConnectionPool
/* ****************************************************************************
 * main
 */
int main(int argc, char **argv)
{
    try
    {
        Wt::WServer server(argv[0]);

        //Wt::WMessageResourceBundle* bundle = new Wt::WMessageResourceBundle;
        //bundle->use(myDomainPath[domainName] + "./app_root/ww-home", false);
        //server.setLocalizedStrings(bundle);

        server.setServerConfiguration(argc, argv, WTHTTP_CONFIGURATION);

        BlogSession::configureAuth();

        // Note: this is in the root with executable
        // ./app_root/domains.xml
        if (!makeConnectionPool(server.appRoot().append("domains.xml").c_str()))
        {
            return 1; // Fix 404
        }

        server.addEntryPoint(Wt::Application, boost::bind(&createWWHomeApplication,  _1), "", "favicon.ico");
        // rss feed
        BlogRSSFeed rssFeed;
        server.addResource(&rssFeed, "/" + rootPrefix + "/blog/feed/");

        //SimpleChatServer chatServer(server);
        //server.addEntryPoint(Wt::Application, boost::bind(createApplication, _1, boost::ref(chatServer)), "/chat");
        //server.addEntryPoint(Wt::WidgetSet,   boost::bind(createWidget, _1,      boost::ref(chatServer)), "/chat.js");

        if (server.start())
        {
            Wt::WServer::waitForShutdown();
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
} // end int main
// --- End Of File ------------------------------------------------------------
