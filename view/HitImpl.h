#ifndef HITIMPL_H
#define HITIMPL_H
#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WEnvironment>
#include "model/HitCounter.h"
#include "model/HitSession.h"
/* ****************************************************************************
 * Hit Implement
 */
class HitImpl : public Wt::WContainerWidget
{
    public:
        HitImpl(Wt::Dbo::SqlConnectionPool& connectionPool, std::string myLocale);
        virtual ~HitImpl();
        //
        HitSession session_;
        /* --------------------------------------------------------------------
         * session
         */
        HitSession& session()  { return session_;  }
        //
        Wt::WWidget* Update();
        std::string getHits();
        std::string getUniqueHits();
    private:
        void Set();
        long hits = 0;
        long uniqueHits = 0;
        std::string theLocale;
}; // end class HitImpl
#endif // HITIMPL_H
// --- End Of File ------------------------------------------------------------
