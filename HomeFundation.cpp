/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */

#include <Wt/WAnchor>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <Wt/WMenuItem>
#include <Wt/WStackedWidget>
#include <Wt/WTable>
#include <Wt/WTabWidget>
#include <Wt/WText>
#include <Wt/WTreeNode>
#include <Wt/WViewWidget>
#include <Wt/WWidget>

#include "HomeFundation.h"
/* ****************************************************************************
 * WwHome
 */
WwHome::WwHome(const Wt::WEnvironment& env) : Home(env)
{
    // add Language
    //              name,  code, shortDescription, longDescription
    addLanguage(Lang("en", "en_US", "en",  "English"));
    addLanguage(Lang("cn", "zh_CN", "汉语", "中文 (Chinese)"));
    addLanguage(Lang("ru", "ru_RU", "ру",  "Русский (Russian)"));
    // add Theme
    addTheme(Theme("red"));
    addTheme(Theme("white"));
    addTheme(Theme("blue"));
    addTheme(Theme("green"));
    addTheme(Theme("tan"));
    addTheme(Theme("default"));
    // Initialize Home
    Init();
} // end WwHome::WwHome
/* ****************************************************************************
 * Wrap View
 */
Wt::WWidget *WwHome::WrapView(Wt::WWidget *(WwHome::*createWidget)())
{
    return makeStaticModel(boost::bind(createWidget, this));
} // end WWidget *WwHome::wrapView
/* ****************************************************************************
 * create WW Home Application called from main.cpp
 */
Wt::WApplication *createWWHomeApplication(const Wt::WEnvironment& env)
{
    return new WwHome(env);
} // end Wt::WApplication *createWWHomeApplication
// --- End Of File ------------------------------------------------------------
