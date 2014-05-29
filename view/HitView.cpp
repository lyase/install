/* ****************************************************************************
 * Hit View
 */
#include <Wt/WText>
#include "HitView.h"
/* ****************************************************************************
 * Hit View
 */
HitView::HitView(Wt::Dbo::SqlConnectionPool& db, std::string myLocale)
{
    Wt::log("start") << " *** HitView::HitView() myLocale = " << myLocale << " *** ";
    theLocale_ = myLocale;
    impl_ = new HitImpl(db, myLocale);
    setImplementation(impl_);
} // end
/* ****************************************************************************
 * Update
 */
Wt::WWidget* HitView::Update()
{
    Wt::log("start") << " *** HitView::Update() theLocale_ = " << theLocale_ << " *** ";

    Wt::WContainerWidget *container = new Wt::WContainerWidget();

    Wt::WText *text1 =  new Wt::WText(Wt::WString::tr("hits") + ": " + impl_->getHits() + "<br />", container);
    text1->setStyleClass("hits");

    Wt::WText *text2 =  new Wt::WText(Wt::WString::tr("unique-hits") + ": " + impl_->getUniqueHits(),  container);
    text2->setStyleClass("unique-hits");

    return container;
} // end
// --- End Of File ------------------------------------------------------------
