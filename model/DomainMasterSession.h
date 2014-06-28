/* ****************************************************************************
 * The DomainMasterSession
 */
#ifndef DOMAINMASTERSESSION_H
#define DOMAINMASTERSESSION_H
#include <Wt/Dbo/Dbo>
/* ****************************************************************************
 * The DomainMasterSession
 */
class DomainMasterSession : public Wt::Dbo::Session
{
    public:
        DomainMasterSession(const std::string& appPath, Wt::Dbo::SqlConnectionPool& connectionPool);
    private:
        void Update();
        //
        std::string appPath_;
        Wt::Dbo::SqlConnectionPool& connectionPool_;
};
#endif // DOMAINMASTERSESSION_H
// --- End Of File ------------------------------------------------------------
