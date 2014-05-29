/* ****************************************************************************
 * Hit Counter
 */
#ifndef HITCOUNTER_H
#define HITCOUNTER_H
//
#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WDateTime>
#include <Wt/Dbo/Dbo>
#include <Wt/Dbo/Types>
#include <Wt/Dbo/WtSqlTraits>
/* ****************************************************************************
 * Hit Counter
 * ipaddress: ip4 or ip6, hash not acceptable for counting unique hits
 * page: Internal Path: /en/about
 * date: Date of hit
 */
class HitCounter : public Wt::Dbo::Dbo<HitCounter>
{
    public:
        HitCounter();
        Wt::WString ipaddress;    // ipaddress: Hash will not work, you have to track IP Address for Unique Hits
        Wt::WString page;         // page: Internal Path: /en/about
        Wt::WDateTime date;       // date: Date of hit
        //
        template<class Action>
        void persist(Action &a)
        {
            Wt::Dbo::field(a, ipaddress, "ipaddress");
            Wt::Dbo::field(a, page,      "page");
            Wt::Dbo::field(a, date,      "date");
        }
}; // end class HitCounter
#endif // HITCOUNTER_H
// --- End Of File ------------------------------------------------------------
