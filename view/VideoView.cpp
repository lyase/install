/* ****************************************************************************
 * Video View
 */
#ifdef VIDEOMAN
#include "VideoView.h"

/* ****************************************************************************
 * Video View
 */
VideoView::VideoView(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& db)
{
    impl_ = new VideoImpl(appPath, basePath, db);
    setImplementation(impl_);
} // end
/* ****************************************************************************
 * set Internal Base Path
 */
void VideoView::setInternalBasePath(const std::string& basePath)
{
    impl_->setInternalBasePath(basePath);
} // end
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
