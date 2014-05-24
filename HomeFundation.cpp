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
WwHome::WwHome(const WEnvironment& env) : Home(env)
{
    // add Language
    addLanguage(Lang("en", "/en/", "en",  "English"));
    addLanguage(Lang("cn", "/cn/", "汉语", "中文 (Chinese)"));
    addLanguage(Lang("ru", "/ru/", "ру",  "Русский (Russian)"));

    Init();
} // end WwHome::WwHome
/* ****************************************************************************
 * Wrap View
 */
WWidget *WwHome::WrapView(WWidget *(WwHome::*createWidget)())
{
    return makeStaticModel(boost::bind(createWidget, this));
} // end WWidget *WwHome::wrapView
/* ****************************************************************************
 * create WW Home Application
 */
WApplication *createWWHomeApplication(const WEnvironment& env)
{
    return new WwHome(env);
} // end WApplication *createWWHomeApplication
// --- End Of File ------------------------------------------------------------
