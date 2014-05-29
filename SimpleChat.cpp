/*
 * Modified for Witty Wizard
 *
 */
#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WEnvironment>
#include <Wt/WPushButton>
#include <Wt/WServer>
#include <Wt/WText>
#include <Wt/WTimer>

#include "SimpleChat.h"
#include "SimpleChatServer.h"
#include "PopupChatWidget.h"

using namespace Wt;
/* ************************************************************************* */
/*
 * ChatApplication
 */
ChatApplication::ChatApplication(const Wt::WEnvironment& env, SimpleChatServer& server) : Wt::WApplication(env), server_(server), env_(env)
{
    setTitle("Wt Chat");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/chat/chatapp.css");

    messageResourceBundle().use(appRoot() + "simplechat");

    javaScriptTest();

    root()->addWidget(new Wt::WText(WString::tr("chatter")));

    SimpleChatWidget *chatWidget = new SimpleChatWidget(server_, root());
    chatWidget->setStyleClass("chat");

    root()->addWidget(new Wt::WText(WString::tr("details")));

    Wt::WPushButton *b = new Wt::WPushButton("I'm schizophrenic ...", root());
    b->clicked().connect(b, &Wt::WPushButton::hide);
    b->clicked().connect(this, &ChatApplication::addChatWidget);
}
/* ************************************************************************* */
/*
 * javaScriptTest
 */
void ChatApplication::javaScriptTest()
{
    if(!env_.javaScript())
    {
        javaScriptError_ = new Wt::WText(WString::tr("serverpushwarning"), root());

        // The 5 second timer is a fallback for real server push.
        // The updated server state will piggy back on the response to this timeout.
        timer_ = new Wt::WTimer(root());
        timer_->setInterval(5000);
        timer_->timeout().connect(this, &ChatApplication::emptyFunc);
        timer_->start();
    }
}
/* ************************************************************************* */
/*
 * emptyFunc
 */
void ChatApplication::emptyFunc()
{

}
/* ************************************************************************* */
/*
 * addChatWidget
 */
void ChatApplication::addChatWidget()
{
    SimpleChatWidget *chatWidget2 = new SimpleChatWidget(server_, root());
    chatWidget2->setStyleClass("chat");
}
/* ************************************************************************* */
/*
 * ChatWidget
 */
ChatWidget::ChatWidget(const Wt::WEnvironment& env, SimpleChatServer& server) : Wt::WApplication(env), login_(this, "login")
{
    setCssTheme("");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/chat/chatwidget.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/chat/chatwidget_ie6.css", "lt IE 7");

    const std::string *div = env.getParameter("div");
    std::string defaultDiv = "div";
    if (!div)
    {
        div = &defaultDiv;
    }
    if (div)
    {
        setJavaScriptClass(*div);
        PopupChatWidget *chatWidget = new PopupChatWidget(server, *div);
        bindWidget(chatWidget, *div);

        login_.connect(chatWidget, &PopupChatWidget::setName);

        std::string chat = javaScriptClass();
        doJavaScript("if (window." + chat + "User) " + chat + ".emit(" + chat + ", 'login', " + chat + "User);" + "document.body.appendChild(" + chatWidget->jsRef() + ");");
    }
    else
    {
        std::cerr << "Missing: parameter: 'div'" << std::endl;
        quit();
    }
}
/* ************************************************************************* */
/*
 * createApplication
 */
Wt::WApplication *createApplication(const Wt::WEnvironment& env, SimpleChatServer& server)
{
    return new ChatApplication(env, server);
}
/* ************************************************************************* */
/*
 * createWidget
 */
Wt::WApplication *createWidget(const Wt::WEnvironment& env, SimpleChatServer& server)
{
    return new ChatWidget(env, server);
}
// --- End Of File ------------------------------------------------------------
