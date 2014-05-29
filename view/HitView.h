#ifndef HITVIEW_H
#define HITVIEW_H
#include <Wt/WCompositeWidget>
#include "HitImpl.h"
/* ****************************************************************************
 * Prototype HitImpl
 */
class HitImpl;
/* ****************************************************************************
 * class Hit Implement
 */
class HitView : public Wt::WCompositeWidget
{
    public:
        HitView(Wt::Dbo::SqlConnectionPool& db, std::string myLocale);
        Wt::WWidget* Update();
    private:
        HitImpl *impl_;
        std::string theLocale_;
};
#endif // HITVIEW_H
// --- End Of File ------------------------------------------------------------
