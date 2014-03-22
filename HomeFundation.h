// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef WT_HOME_H_
#define WT_HOME_H_

#include <Wt/WApplication>

#include "HomeBase.h"

/* ****************************************************************************
 *
 */
using namespace Wt;
/* ****************************************************************************
 * WtHome
 */
class WtHome : public Home
{
    public:
        WtHome(const WEnvironment& env);

    protected:
        virtual std::string filePrefix() const { return "wt-"; }

    private:
        WWidget *wrapView(WWidget *(WtHome::*createFunction)());

};
/* ****************************************************************************
 * createWtHomeApplication
 */
WApplication *createWtHomeApplication(const WEnvironment& env);

#endif // WT_HOME_H_
// --- End Of File ------------------------------------------------------------
