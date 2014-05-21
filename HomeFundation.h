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
class WwHome : public Home
{
    public:
        WwHome(const WEnvironment& env);

    protected:
        virtual std::string filePrefix() const { return "wt-"; }

    private:
        WWidget *WrapView(WWidget *(WwHome::*createFunction)());

};
/* ****************************************************************************
 * createWtHomeApplication
 */
WApplication *createWWHomeApplication(const WEnvironment& env);

#endif // WT_HOME_H_
// --- End Of File ------------------------------------------------------------
