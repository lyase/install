/* ****************************************************************************
 * Witty Wizard
 */
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
#include "WittyWizard.h"
/* ****************************************************************************
 * Connection Pool Map
 * Holds the Pointer to Wt::Dbo::SqlConnectionPool *
 */
extern std::map <std::string, boost::any> myConnectionPool;
/* ****************************************************************************
 * Global Variable
 * domainHost="wittywizard.org"
 */
extern std::map <std::string, std::string> myDomainHost;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * Full Path to Domain: /home/domain.tdl/
 */
extern std::map <std::string, std::string> myDomainPath;
/* ****************************************************************************
 * Global Variable
 * dbName="wittywizard"
 */
extern std::map <std::string, std::string> myDbName;
/* ****************************************************************************
 * Global Variable
 * dbUser="wittywizard"
 */
extern std::map <std::string, std::string> myDbUser;
/* ****************************************************************************
 * Global Variable
 * password="The1Wizard2Witty4Flesh"
 */
extern std::map <std::string, std::string> myDbPassword;
/* ****************************************************************************
 * Global Variable
 * port="5432"
 */
extern std::map <std::string, std::string> myDbPort;
/* ****************************************************************************
 * Set Cookie
 */
void SetCookie(std::string name, std::string myValue)
{
    Wt::WApplication *app = Wt::WApplication::instance();
    try
    {
        app->setCookie(name, myValue, 150000, "", "/", false);
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "WittyWizard::SetCookie: Failed writting cookie: " << name;
        Wt::log("error") << "WittyWizard::SetCookie()  Failed writting cookie: " << name;
    }
} // end void WittyWizard::SetCookie
/* ****************************************************************************
 * Get Cookie
 * std::string myCookie = GetCookie("videoman");
 */
std::string GetCookie(std::string name)
{
    std::string myCookie = "";
    try
    {
        myCookie = Wt::WApplication::instance()->environment().getCookie(name);
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "WittyWizard::GetCookie: Failed reading cookie: " << name;
        Wt::log("error") << "WittyWizard::GetCookie()  Failed reading cookie: " << name;
    }
    return myCookie;
} // end std::string WittyWizard::GetCookie
/* ****************************************************************************
 * String Replace
 * std::string myCookie = GetCookie("videoman");
 * std::string string(" $name");
 * StringReplace(string, "/en/", "/cn/");
 */
bool StringReplace(std::string& string2replace, const std::string& changefrom, const std::string& changeTo)
{
    size_t start_pos = string2replace.find(changefrom);
    if(start_pos == std::string::npos)
    {
        return false;
    }
    string2replace.replace(start_pos, changefrom.length(), changeTo);
    return true;
} // end StringReplace
/* ****************************************************************************
 * FormatWithCommas
 */
//template<class T>
std::string FormatWithCommas(long value, std::string myLocale) // T value
{
    std::stringstream ss;
    ss.imbue(std::locale(myLocale.c_str()));
    ss << std::fixed << value;
    return ss.str();
} // end FormatWithCommas
/* ****************************************************************************
 * Global Function
 * SQL Database Connection
 */
bool SetSqlConnectionPool(std::string domainName)
{
    if (myConnectionPool.find(domainName) == myConnectionPool.end() && myDomainHost.find(domainName) != myDomainHost.end())
    {
        Wt::log("start") << " *** SetSqlConnectionPool(" << domainName << ")  myDbUser = " << myDbUser[domainName] << " | myDbPort = " << myDbPort[domainName] << " |  myDbName = "  <<  myDbName[domainName];
        try
        {
            Wt::Dbo::SqlConnection *dbConnection;
            #ifdef POSTGRES
                dbConnection = new Wt::Dbo::backend::Postgres("user=" + myDbUser[domainName] + " password=" + myDbPassword[domainName] + " port=" + myDbPort[domainName] + " dbname=" + myDbName[domainName]);
            #elif SQLITE3
                Wt::Dbo::backend::Sqlite3 *sqlite3 = new Wt::Dbo::backend::Sqlite3(std::string(path.c_str()) + "app_root/" + std::string(myDbName[domainName]));
                sqlite3->setDateTimeStorage(Wt::Dbo::SqlDateTime, Wt::Dbo::backend::Sqlite3::PseudoISO8601AsText);
                dbConnection = sqlite3;
            #elif MYSQL
                dbConnection = new Wt::Dbo::backend::MySQL(myDbName[domainName], myDbUser[domainName], myDbPassword[domainName], "localhost");
            #elif FIREBIRD
                #ifdef WIN32
                    myFile = "C:\\opt\\db\\firebird\\" + myDbName[domainName];
                #else
                    myFile = "/opt/db/firebird/" + myDbName[domainName];
                #endif
                dbConnection = new Wt::Dbo::backend::Firebird("localhost", myFile.c_str(), myDbUser[domainName], myDbPassword[domainName], "", "", ""); // Server:localhost, Path:File, user, password
            #endif // FIREBIRD
            dbConnection->setProperty("show-queries", "true");
            // We need to convert it FixedSqlConnectionPool to SqlConnectionPool, not sure if I should just refactor to use FixedSqlConnectionPool
            Wt::Dbo::SqlConnectionPool *dbConnection_ = new Wt::Dbo::FixedSqlConnectionPool(dbConnection, 10);
            myConnectionPool[domainName] = dbConnection_;
        }
        catch (std::exception& e)
        {
            std::cerr << e.what() << std::endl;
            std::cerr << "Error Connecting to domains database: " << domainName;
            Wt::log("error") << "WittyWizard::SetSqlConnectionPool()  Failed reading cookie: " << domainName;
            return false;
        }
    }
    else
    {
        Wt::log("start") << " *** SetSqlConnectionPool(" << domainName << ") reuse Connection";
    }
    return true;
}
// --- End Of File ------------------------------------------------------------
