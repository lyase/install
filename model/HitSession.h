#ifndef HITSESSION_H
#define HITSESSION_H
#include <Wt/Dbo/Dbo>
/* ****************************************************************************
 * Hit Session
 */
class HitSession : public Wt::Dbo::Session
{
    public:
        HitSession(Wt::Dbo::SqlConnectionPool& connectionPool);
        //
        Wt::Dbo::SqlConnectionPool& connectionPool_;
        void Update();
};
#endif // HITSESSION_H
// --- End Of File ------------------------------------------------------------
