/* ****************************************************************************
 * DomainMasterSession
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
//#include <Wt/WComboBox>
//
#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"
//
#include "DomainMaster.h"
#include "DomainMasterSession.h"
/* ****************************************************************************
 * DomainMasterSession
 */
DomainMasterSession::DomainMasterSession(const std::string& appPath, Wt::Dbo::SqlConnectionPool& connectionPool) : appPath_(appPath), connectionPool_(connectionPool)
{
    Wt::log("start") << " *** DomainMasterSession::DomainMasterSession() *** ";
    setConnectionPool(connectionPool_);
    mapClass<DomainMaster>("domains");
    try
    {
        Wt::Dbo::Transaction t(*this);
        // Note: you must drop tables to do update, FIXIT make it a url in the backend with credentials
        //dropTables();
        createTables();
        std::cerr << "Created database: domains " << std::endl;
        t.commit();
        Update();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "Using existing domains database";
    }
    Wt::log("end") << " *** DomainMasterSession::DomainMasterSession() *** ";
}
/* ****************************************************************************
 * DomainMasterSession
 */
void DomainMasterSession::Update()
{

}
// --- End Of File ------------------------------------------------------------
