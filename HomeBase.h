// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef HOME_H_
#define HOME_H_

#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/Dbo/Dbo>
#include <QString>
#include <vector>
#include "SimpleChatServer.h"
/* ****************************************************************************
 * WMenu
 * WStackedWidget
 * WTabWidget
 * WTreeNode
 * WTable
 */
namespace Wt
{
    class WMenu;
    class WStackedWidget;
    class WTabWidget;
    class WTreeNode;
    class WTable;
}
/* ****************************************************************************
 * Wt
 */
using namespace Wt;
/* ****************************************************************************
 * Lang
 */
struct Lang
{
    Lang(const std::string& code, const std::string& path, const std::string& shortDescription, const std::string& longDescription) : code_(code), path_(path), shortDescription_(shortDescription), longDescription_(longDescription) { }
    std::string code_, path_, shortDescription_, longDescription_;
};
/* ****************************************************************************
 * DeferredWidget
 * A utility container widget which defers creation of its single child widget
 * until the container is loaded (which is done on-demand by a WMenu).
 * The constructor takes the create function for the widget as a parameter.
 *
 * We use this to defer widget creation until needed.
 */
template <typename Function>
class DeferredWidget : public Wt::WContainerWidget
{
    public:
        DeferredWidget(Function f) : f_(f) { }

    private:
        void load()
        {
            Wt::WContainerWidget::load();
            if (count() == 0)
            {
                addWidget(f_());
            }
        }

        Function f_;
};
/* ****************************************************************************
 * deferCreate
 */
template <typename Function>
DeferredWidget<Function>* deferCreate(Function f)
{
    return new DeferredWidget<Function>(f);
}
/* ****************************************************************************
 * Home
 */
class Home : public WApplication
{
    public:
        Home(const Wt::WEnvironment& env);

        virtual ~Home();

        void googleAnalyticsLogger();

    protected:
        virtual std::string filePrefix() const = 0;

        void init();

        void addLanguage(const Lang& l) { languages.push_back(l); }

        Wt::WString tr(const char* key);
        std::string href(const std::string& url, const std::string& description);

        Wt::Dbo::SqlConnectionPool *dbConnection_;

    private:
        QString appPath;
        /* ******************************
         * homePage_ is the base page read from template
         */
        Wt::WWidget* homePage_;

        Wt::WStackedWidget* contents_;

        void createHome();

        Wt::WWidget* home();
        Wt::WWidget* contact();
        Wt::WWidget* about();
        Wt::WWidget* blog();
        Wt::WWidget* chat();
        Wt::WWidget* video();

        Wt::WMenu* mainMenu_;
        int language_;

        Wt::WWidget* wrapView(WWidget *(Home::*createFunction)());

        void updateTitle();
        void setLanguage(int language);
        void setLanguageFromPath();
        void setup();
        void logInternalPath(const std::string& path);
        void chatSetUser(const WString& name);
        void handlePopup(int data);
        std::vector<std::string> split(std::string str, std::string delim);
        
        std::vector<Lang> languages;

};

#endif // HOME_H_
// --- End Of File ------------------------------------------------------------
