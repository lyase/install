// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifndef WT_HOME_H_
#define WT_HOME_H_

#include <Wt/WApplication>

#include "HomeBase.h"
/* ****************************************************************************
 * Ww Home
 */
class WwHome : public Home
{
    public:
        WwHome(const Wt::WEnvironment& env);

    protected:
        virtual std::string filePrefix() const { return "ww-"; }

    private:
        Wt::WWidget *WrapView(Wt::WWidget *(WwHome::*createFunction)());

}; // end class WwHome
/* ****************************************************************************
 * createWtHomeApplication
 */
Wt::WApplication *createWWHomeApplication(const Wt::WEnvironment& env);

#endif // WT_HOME_H_
// --- End Of File ------------------------------------------------------------
