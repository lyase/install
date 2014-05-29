/* ****************************************************************************
 * Hit Session
 */
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <Wt/Dbo/Dbo>
#include <Wt/Dbo/ptr>
#include <Wt/Dbo/Session>
#include <Wt/Dbo/Impl>
#include <Wt/Dbo/Types>
#include <Wt/Dbo/QueryModel>
#include "HitSession.h"
#include "HitCounter.h"
/* ****************************************************************************
 * Hit Session
 */
HitSession::HitSession(Wt::Dbo::SqlConnectionPool& connectionPool) : connectionPool_(connectionPool)
{
    Wt::log("start") << " *** HitSession::HitSession() *** ";
    setConnectionPool(connectionPool_);
    mapClass<HitCounter>("hitcounter"); // table name hitcounter
    try
    {
        Wt::Dbo::Transaction t(*this);
        // Note: you must drop tables to do update
        //dropTables();
        createTables();
        std::cerr << "Created database: hitcounter " << std::endl;
        t.commit();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "Using existing hitcounter database";
    }
    Update();
    Wt::log("end") << " *** HitSession::HitSession() *** ";
} // end HitSession::HitSession
/* ****************************************************************************
 * Update
 */
void HitSession::Update()
{
    Wt::log("start") << " *** HitSession::Update()  *** ";
    // Create an instance of app to access Internal Paths
    Wt::WApplication* app = Wt::WApplication::instance();
    try
    {
        // Start a Transaction
        Wt::Dbo::Transaction t(*this);
        // Create a new Video Instance
        Wt::Dbo::ptr<HitCounter> thisCounter = add(new HitCounter());
        // Set object to Modify
        HitCounter *counterDb = thisCounter.modify();
        // IP Address
        counterDb->ipaddress = app->environment().clientAddress();
        // page
        counterDb->page = app->internalPath();
        // date
        counterDb->date = Wt::WDateTime::currentDateTime();;
        // Commit Transaction
        t.commit();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "HitImpl::Update: Failed writting to hitcounter database";
        Wt::log("error") << "-> HitSession::Update()  Failed writting to hitcounter database)";
    }
    Wt::log("end") << "HitSession::Update() app->environment().clientAddress()=" << app->environment().clientAddress();
} // end
// --- End Of File ------------------------------------------------------------
