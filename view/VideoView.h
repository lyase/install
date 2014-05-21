/* ****************************************************************************
 * Video View
 */
#ifdef VIDEOMAN
#ifndef VIDEOVIEW_H
#define VIDEOVIEW_H

#include <Wt/WCompositeWidget>
#include "VideoImpl.h"
/* ****************************************************************************
 * Prototype VideoImpl
 */
class VideoImpl;
/* ****************************************************************************
 * Video View
 */
class VideoView : public Wt::WCompositeWidget
{
    public:
        VideoView(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& db);
        void setInternalBasePath(const std::string& basePath);
    private:
        VideoImpl *impl_;
};
#endif // VIDEOVIEW_H
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
