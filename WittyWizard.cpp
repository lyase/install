/* ****************************************************************************
 * Witty Wizard
 */
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include "WittyWizard.h"

//WittyWizard::WittyWizard() { }
/* ****************************************************************************
 * Set Cookie
 */
void SetCookie(std::string name, std::string myValue)
{
    Wt::WApplication *app = Wt::WApplication::instance();
    try
    {
        app->setCookie(name, myValue, 150000, "", "/", false);
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "WittyWizard::SetCookie: Failed writting cookie: " << name;
        Wt::log("error") << "WittyWizard::SetCookie()  Failed writting cookie: " << name;
    }
} // end void WittyWizard::SetCookie
/* ****************************************************************************
 * Get Cookie
 * std::string myCookie = GetCookie("videoman");
 */
std::string GetCookie(std::string name)
{
    std::string myCookie = "";
    try
    {
        myCookie = Wt::WApplication::instance()->environment().getCookie(name);
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "WittyWizard::GetCookie: Failed reading cookie: " << name;
        Wt::log("error") << "WittyWizard::GetCookie()  Failed reading cookie: " << name;
    }
    return myCookie;
} // end std::string WittyWizard::GetCookie
/* ****************************************************************************
 * String Replace
 * std::string myCookie = GetCookie("videoman");
 * std::string string(" $name");
 * StringReplace(string, "/en/", "/cn/");
 */
bool StringReplace(std::string& string2replace, const std::string& changefrom, const std::string& changeTo)
{
    size_t start_pos = string2replace.find(changefrom);
    if(start_pos == std::string::npos)
    {
        return false;
    }
    string2replace.replace(start_pos, changefrom.length(), changeTo);
    return true;
} // end StringReplace
// --- End Of File ------------------------------------------------------------
