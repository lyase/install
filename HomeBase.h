// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifndef HOME_H_
#define HOME_H_

#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/Dbo/Dbo>
#include <QString>
#include <vector>
#include "SimpleChatServer.h"
#include "WittyWizard.h"
/* ****************************************************************************
 * Lang
 * name:
 * code:
 * short Description:
 * long Description
 */
struct Lang
{
    Lang(const std::string& name, const std::string& code, const std::string& shortDescription, const std::string& longDescription) : name_(name), code_(code), shortDescription_(shortDescription), longDescription_(longDescription) { }
    std::string name_, code_, shortDescription_, longDescription_;
};
/* ****************************************************************************
 * Theme
 */
struct Theme
{
    Theme(const std::string& name) : name_(name) { }
    std::string name_;
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
class Home : public Wt::WApplication
{
    public:
        Home(const Wt::WEnvironment& env);

        virtual ~Home();

        void googleAnalyticsLogger();
        void SetBaseURL();

    protected:
        virtual std::string filePrefix() const = 0;

        void Init();
        // Add Language
        void addLanguage(const Lang& l) { languages.push_back(l); }
        // Add Theme
        void addTheme(const Theme& l) { themes.push_back(l); }

        std::string href(const std::string& url, const std::string& description);

        Wt::Dbo::SqlConnectionPool *dbConnection_;

    private:
        std::string appPath_;
        /* --------------------------------------------------------------------
         * homePage_ is the base page read from template
         */
        Wt::WWidget* homePage_;
        Wt::WTemplate* homeTemplate_;
        //
        //Wt::WStackedWidget* contents_;
        //
        std::string domainName;
        //
        std::string myHost;
        std::string myUrlScheme;
        std::string myBaseUrl;
        //
        void CreateHome();
        int IsPathLanguage(std::string langPath);

        Wt::WWidget* HomePage();
        Wt::WWidget* Contact();
        Wt::WWidget* About();
        Wt::WWidget* Blog();
        Wt::WWidget* Chat();
        Wt::WWidget* VideoMan();
        Wt::WWidget* HitCounter();
        Wt::WWidget* Admin();

        Wt::WMenu* mainMenu_;
        int language_ = 0;

        Wt::WWidget* WrapView(Wt::WWidget *(Home::*createFunction)());

        void UpdateTitle();
        void SetLanguage(int language, std::string langPath);
        void SetLanguageFromPath();
        void LogInternalPath(const std::string& path);
        void ChatSetUser(const Wt::WString& name);
        void HandleLanguagePopup(int data);
        void HandleThemePopup(int data);
        void SetWizardTheme(bool fromCookie, int index);
        // Language Vector Array
        std::vector<Lang> languages;
        // Theme Vector Array
        std::vector<Theme> themes;
        //
        std::string lastPath = "";
        std::string currentMenuItem = "";
        // Used to prevent internalPath changes
        bool isPathChanging = false;
};
#endif // HOME_H_
// --- End Of File ------------------------------------------------------------
