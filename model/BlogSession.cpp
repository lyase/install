/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#include <Wt/Auth/AuthService>
#include <Wt/Auth/HashFunction>
#include <Wt/Auth/Identity>
#include <Wt/Auth/PasswordService>
#include <Wt/Auth/PasswordStrengthValidator>
#include <Wt/Auth/PasswordVerifier>
#include <Wt/Auth/GoogleService>
// Database
#include <Wt/Dbo/Session>
#include <Wt/Dbo/ptr>
#include <Wt/Dbo/Dbo>
#ifdef POSTGRES
    #include <Wt/Dbo/backend/Postgres>
#elif SQLITE3
    #include <Wt/Dbo/backend/Sqlite3>
#elif MYSQL
    #include <Wt/Dbo/backend/MySQL>
#elif FIREBIRD
    #include <Wt/Dbo/backend/Firebird>
#endif // FIREBIRD
#include <Wt/Dbo/FixedSqlConnectionPool>

#ifndef WIN32
    #include <unistd.h>
#endif

#if !defined(WIN32) && !defined(__CYGWIN__) && !defined(ANDROID)
    #define HAVE_CRYPT
#endif
//
#include "BlogSession.h"
#include "Comment.h"
#include "Post.h"
#include "Tag.h"
#include "Token.h"
#include "User.h"
#include "asciidoc/asciidoc.h"
/* ****************************************************************************
 * Unix Crypt Hash Function
 * BlogOAuth
 */
namespace
{
    const std::string ADMIN_USERNAME = "admin";
    const std::string ADMIN_PASSWORD = "admin";

    #ifdef HAVE_CRYPT
    /* ************************************************************************
     * UnixCryptHashFunction
     */
    class UnixCryptHashFunction : public Wt::Auth::HashFunction
    {
        public:
            virtual std::string compute(const std::string& msg, const std::string& salt) const
            {
                std::string md5Salt = "$1$" + salt;
                return crypt(msg.c_str(), md5Salt.c_str());
            }

            virtual bool verify(const std::string& msg, const std::string& salt, const std::string& hash) const
            {
                (void)salt; // Eat Salt warning
                return crypt(msg.c_str(), hash.c_str()) == hash;
            }

            virtual std::string name () const
            {
                return "crypt";
            }
    }; // end
    #endif // HAVE_CRYPT
    /* ************************************************************************
     * BlogOAuth
     */
    class BlogOAuth : public std::vector<const Wt::Auth::OAuthService *>
    {
        public:
            ~BlogOAuth()
            {
                for (unsigned i = 0; i < size(); ++i)
                {
                    delete (*this)[i];
                }
            }
    };

    Wt::Auth::AuthService blogAuth;
    Wt::Auth::PasswordService blogPasswords(blogAuth);
    BlogOAuth blogOAuth;
} // end
/* ****************************************************************************
 * Blog Session
 */
BlogSession::BlogSession(Wt::Dbo::SqlConnectionPool &connectionPool) : connectionPool_(connectionPool), users_(*this)
{
    setConnectionPool(connectionPool_);

    mapClass<Comment>("comment");
    mapClass<Post>("post");
    mapClass<Tag>("tag");
    mapClass<Token>("token");
    mapClass<User>("user");

    try
    {
        Wt::Dbo::Transaction t(*this);
        createTables();

        Wt::Dbo::ptr<User> admin = add(new User());
        User *a = admin.modify();
        a->name = ADMIN_USERNAME;
        a->role = User::Admin;

        Wt::Auth::User authAdmin = users_.findWithIdentity(Wt::Auth::Identity::LoginName, a->name);
        blogPasswords.updatePassword(authAdmin, ADMIN_PASSWORD);

        Wt::Dbo::ptr<Post> post = add(new Post());
        Post *p = post.modify();

        p->state = Post::Published;
        p->author = admin;
        p->title = "Welcome!";
        p->briefSrc = "Welcome to your own blog.";
        // Fix Security
        p->bodySrc = "We have created for you an " + ADMIN_USERNAME + " user with password " + ADMIN_PASSWORD;
        p->briefHtml = asciidoc(p->briefSrc);
        p->bodyHtml = asciidoc(p->bodySrc);
        p->date = Wt::WDateTime::currentDateTime();

        Wt::Dbo::ptr<Comment> rootComment = add(new Comment());
        rootComment.modify()->post = post;

        t.commit();

        std::cerr << "Created database, and user " << ADMIN_USERNAME << " / " << ADMIN_PASSWORD << std::endl;
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "Using existing database";
    }
} // end
/* ****************************************************************************
 * configure Auth
 */
void BlogSession::configureAuth()
{
    blogAuth.setAuthTokensEnabled(true, "bloglogin");

    Wt::Auth::PasswordVerifier *verifier = new Wt::Auth::PasswordVerifier();
    verifier->addHashFunction(new Wt::Auth::BCryptHashFunction(7));
    #ifdef WT_WITH_SSL
        verifier->addHashFunction(new Wt::Auth::SHA1HashFunction());
    #endif
    #ifdef HAVE_CRYPT
        verifier->addHashFunction(new UnixCryptHashFunction());
    #endif
    blogPasswords.setVerifier(verifier);
    blogPasswords.setAttemptThrottlingEnabled(true);
    blogPasswords.setStrengthValidator(new Wt::Auth::PasswordStrengthValidator());

    if (Wt::Auth::GoogleService::configured())
    {
        blogOAuth.push_back(new Wt::Auth::GoogleService(blogAuth));
    }
} // end
/* ****************************************************************************
 * create Connection Pool
 */
Wt::Dbo::SqlConnectionPool *BlogSession::createConnectionPool(const std::string &dbParm)
{
    /* ------------------------------------------------------------------------
     * SqlConnection dbConnection
     */
    Wt::Dbo::SqlConnection *dbConnection;
    #ifdef POSTGRES
        dbConnection = new Wt::Dbo::backend::Postgres(dbParm);
    #elif SQLITE3
        Wt::Dbo::backend::Sqlite3 *sqlite3 = new Wt::Dbo::backend::Sqlite3(dbParm);
        sqlite3->setDateTimeStorage(Wt::Dbo::SqlDateTime, Wt::Dbo::backend::Sqlite3::PseudoISO8601AsText);
        dbConnection = sqlite3;
    #elif MYSQL
        dbConnection = new Wt::Dbo::backend::MySQL(dbParm);
    #elif FIREBIRD
        // Complety untested
        #ifdef REGX
            QRegExp rx("(\\t)"); // RegEx for ' ' or ',' or '.' or ':' or '\t'
            QStringList query = dbParm.split(rx);
            dbConnection = new Wt::Dbo::backend::Firebird(query[0], query[1], query[2], query[3], "", "", ""); // Server:localhost, Path:File, user, password
        #else
            std::vector <std::string> query;
            boost::split( query, dbParm, boost::is_any_of( "\t" ) );
            dbConnection = new Wt::Dbo::backend::Firebird(query[0], query[1], query[2], query[3], "", "", ""); // Server:localhost, Path:File, user, password
        #endif
    #endif // FIREBIRD
    dbConnection->setProperty("show-queries", "true");
    return new Wt::Dbo::FixedSqlConnectionPool(dbConnection, 10);
} // end
/* ****************************************************************************
 * user
 */
Wt::Dbo::ptr<User> BlogSession::user() const
{
    if (login_.loggedIn())
    {
        return users_.find(login_.user());
    }
    else
    {
        return Wt::Dbo::ptr<User>();
    }
} // end
/* ****************************************************************************
 * password Auth
 */
Wt::Auth::PasswordService *BlogSession::passwordAuth() const
{
    return &blogPasswords;
} // end
/* ****************************************************************************
 * oAuth
 */
const std::vector<const Wt::Auth::OAuthService *> &BlogSession::oAuth() const
{
    return blogOAuth;
} // end
// --- End Of File ------------------------------------------------------------
