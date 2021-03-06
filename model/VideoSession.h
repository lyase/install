#ifdef VIDEOMAN
#ifndef VIDEOSESSION_H
#define VIDEOSESSION_H
#include <Wt/Dbo/Dbo>
//#include <Wt/WComboBox>
/* ****************************************************************************
 * The VideoSession
 */
class VideoSession : public Wt::Dbo::Session
{
    public:
        VideoSession(const std::string& appPath, Wt::Dbo::SqlConnectionPool& connectionPool);
    private:
        bool ImportXML();
        //
        std::string appPath_;
        Wt::Dbo::SqlConnectionPool& connectionPool_;
};
#endif // VIDEOSESSION_H
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
