#ifndef SIMPLECHAT_H
#define SIMPLECHAT_H
#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WEnvironment>
#include <Wt/WPushButton>
#include <Wt/WServer>
#include <Wt/WText>
#include <Wt/WTimer>

#include "SimpleChatServer.h"
#include "PopupChatWidget.h"

/* ************************************************************************* */
/**
 * @addtogroup chatexample
 */
/*@{*/
/*! \brief A chat demo application. */
class ChatApplication : public Wt::WApplication
{
    public:
        /*! \brief Create a new instance. */
        ChatApplication(const Wt::WEnvironment& env, SimpleChatServer& server);

    private:
        SimpleChatServer& server_;
        Wt::WText *javaScriptError_;
        const Wt::WEnvironment& env_;
        Wt::WTimer *timer_;

        /*! \brief Add another chat client. */
        void addChatWidget();
        void javaScriptTest();
        void emptyFunc();
};
/* ************************************************************************* */
/*! \brief A chat application widget.
 *
*/
class ChatWidget : public Wt::WApplication
{
    public:
        ChatWidget(const Wt::WEnvironment& env, SimpleChatServer& server);

    private:
        Wt::JSignal<Wt::WString> login_;
};
/* ************************************************************************* */
Wt::WApplication *createApplication(const Wt::WEnvironment& env, SimpleChatServer& server);
/* ************************************************************************* */
Wt::WApplication *createWidget(const Wt::WEnvironment& env, SimpleChatServer& server);
#endif // SIMPLECHAT_H
// --- End Of File ------------------------------------------------------------
