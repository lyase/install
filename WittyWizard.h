#ifndef WITTYWIZARD_H
#define WITTYWIZARD_H
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <iomanip>
#include <locale>
/* ****************************************************************************
 *  Set Cookie
 */
void SetCookie(std::string name, std::string myValue);
/* ****************************************************************************
 *  Get Cookie
 */
std::string GetCookie(std::string name);
/* ****************************************************************************
 *  String Replace
 */
bool StringReplace(std::string& string2replace, const std::string& changefrom, const std::string& changeTo);
/* ****************************************************************************
 * FormatWithCommas
 */
std::string FormatWithCommas(long value, std::string myLocale);
/* ****************************************************************************
 * Set Sql Connection Pool
 */
bool SetSqlConnectionPool(std::string domainName);
/* ****************************************************************************
 * isFile
 */
bool isFile(const std::string& name);
/* ****************************************************************************
 * isPath
 */
bool isPath(const std::string& pathName);
//
#endif // WITTYWIZARD_H
// --- End Of File ------------------------------------------------------------
