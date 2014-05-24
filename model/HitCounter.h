#ifndef HITCOUNTER_H
#define HITCOUNTER_H
#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WDateTime>
#include <Wt/Dbo/Dbo>
#include <QString>
#include <vector>

/* ****************************************************************************
 * Hit Counter
 * ipaddress: ip4 or ip6, hash not acceptable for counting unique hits
 * hits: Perpage
 */
class HitCounter : public Wt::Dbo::Dbo<HitCounter>
{
    public:
        HitCounter();
        Wt::WString ipaddress;    // ipaddress
        Wt::WString page;         // page
        int hits;                 // hits
        Wt::WDateTime  date;

        //
        template<class Action>
        void persist(Action &a)
        {
            Wt::Dbo::field(a, ipaddress,       "ipaddress");
            Wt::Dbo::field(a, hits,            "hits");
            Wt::Dbo::field(a, page,            "page");
        }
};

#endif // HITCOUNTER_H
// --- End Of File ------------------------------------------------------------
