/* ****************************************************************************
 * Hit Implement
 */
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <Wt/WContainerWidget>
#include <Wt/WText>

#include "model/HitCounter.h"
#include "WittyWizard.h"
#include "HitImpl.h"
typedef Wt::Dbo::collection< Wt::Dbo::ptr<HitCounter> > HitCounters;
/* ****************************************************************************
 * Hit Implement
 */
HitImpl::HitImpl(Wt::Dbo::SqlConnectionPool& connectionPool, std::string myLocale) : session_(connectionPool)
{
    Wt::log("start") << " *** HitImpl::HitImpl() *** ";
    theLocale = myLocale;
    Set();
}
/* ****************************************************************************
 * ~Hit Implement
 */
HitImpl::~HitImpl()
{
    clear();
} // end VideoImpl::~VideoImpl
/* ****************************************************************************
 * Set
 */
void HitImpl::Set()
{
    // Create an instance of app to access Internal Paths
    Wt::WApplication* app = Wt::WApplication::instance();
    try
    {
        // Start a Transaction
        Wt::Dbo::Transaction t(session_);
        HitCounters myHitCounter = session_.find<HitCounter>();
        //
        hits = myHitCounter.size();
        //
        // Commit Transaction
        t.commit();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "HitImpl::Update: Failed reading from hitcounter database";
        Wt::log("error") << "HitImpl::Update()  Failed reading from hitcounter database";
    }

    try
    {
        // Start a Transaction
        Wt::Dbo::Transaction t(session_);
        //
        uniqueHits = session_.query<int>("select COUNT(distinct ipaddress) from hitcounter").where("page = ?").bind(app->internalPath());;
        // Commit Transaction
        t.commit();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "HitImpl::Update: Failed reading from hitcounter database";
        Wt::log("error") << "HitImpl::Update()  Failed reading from hitcounter database";
    }

} // end
/* ****************************************************************************
 * get Hits
 */
std::string HitImpl::getHits()
{
    try
    {
        Wt::WLocale myString = Wt::WLocale(theLocale.c_str());
        // Note: this only works if you set the Separator, use case to set it
        myString.setGroupSeparator(",");
        std::string myReturn = myString.toString(hits).toUTF8();
        return myReturn;
        /*
         * This requires locale to be installed and configured on server
        std::stringstream ss;
        ss.imbue(std::locale(theLocale.c_str()));
        ss << std::fixed << hits;
        return ss.str();
        */
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "HitImpl::getHits: Failed local not installed";
        Wt::log("error") << "HitImpl::getHits() Failed local not installed";
    }
    return std::to_string(hits);
} // end
/* ****************************************************************************
 * get UniqueHits
 */
std::string HitImpl::getUniqueHits()
{
    try
    {
        Wt::WLocale myString = Wt::WLocale(theLocale.c_str());
        // Note: this only works if you set the Separator, use case to set it
        myString.setGroupSeparator(",");
        std::string myReturn = myString.toString(uniqueHits).toUTF8();
        return myReturn;
        /*
         * This requires locale to be installed and configured on server
        std::stringstream ss;
        ss.imbue(std::locale(theLocale.c_str()));
        ss << std::fixed << hits;
        return ss.str();
        */
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "HitImpl::getUniqueHits: Failed local not installed";
        Wt::log("error") << "HitImpl::getUniqueHits() Failed local not installed";
    }
    return std::to_string(uniqueHits);
} // end
// --- End Of File ------------------------------------------------------------
