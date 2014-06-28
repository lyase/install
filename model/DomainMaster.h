#ifndef DOMAINMASTER_H
#define DOMAINMASTER_H

#include <Wt/Dbo/Dbo>
#include <Wt/Dbo/Types>
#include <Wt/Dbo/WtSqlTraits>

/* ****************************************************************************
 * DomainMaster
 */
class DomainMaster : public Wt::Dbo::Dbo<DomainMaster>
{
    public:
        DomainMaster();
        //
        std::string domainHost;         // domainHost: default, localhost, wittywizard.org
        std::string path;               // path: /home/domain.tdl
        std::string dbname;             // dbname: Database Name
        std::string user;               // user: Database User Name
        std::string password;           // password: Database Password
        std::string port;               // port: SQL Port Number: PostgreSQL=5432
        std::string gaAccount;          // gaAccount: Google Analyst Account
        std::string gasAccount;         // gasAccount: Google Adsense Account
        std::string includes;           // includes:
        //
        template<class Action>
        void persist(Action &a)
        {
            Wt::Dbo::field(a, domainHost,     "domainHost");
            Wt::Dbo::field(a, path,           "path");
            Wt::Dbo::field(a, dbname,         "dbname");
            Wt::Dbo::field(a, user,           "user");
            Wt::Dbo::field(a, password,       "password");
            Wt::Dbo::field(a, port,           "port");
            Wt::Dbo::field(a, gaAccount,      "gaAccount");
            Wt::Dbo::field(a, gasAccount,     "gasAccount");
            Wt::Dbo::field(a, includes,       "includes");
        }
};
#endif // DOMAINMASTER_H
// --- End Of File ------------------------------------------------------------



