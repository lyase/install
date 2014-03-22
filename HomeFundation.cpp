/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
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
 * WtHome
 */
WtHome::WtHome(const WEnvironment& env) : Home(env)
{
    // add Language
    addLanguage(Lang("en", "/", "en", "English"));
    addLanguage(Lang("cn", "/cn/", "汉语", "中文 (Chinese)"));
    addLanguage(Lang("ru", "/ru/", "ру", "Русский (Russian)"));

    init();
}
/* ****************************************************************************
 * wrapView
 */
WWidget *WtHome::wrapView(WWidget *(WtHome::*createWidget)())
{
    return makeStaticModel(boost::bind(createWidget, this));
}
/* ****************************************************************************
 * createWtHomeApplication
 */
WApplication *createWtHomeApplication(const WEnvironment& env)
{
    return new WtHome(env);
}
// --- End Of File ------------------------------------------------------------
