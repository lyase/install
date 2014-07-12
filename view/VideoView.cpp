/* ****************************************************************************
 * Video View
 */
#ifdef VIDEOMAN
#include "VideoView.h"
/* ****************************************************************************
 * Video View
 */
VideoView::VideoView(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& db, const std::string& lang)
{
    impl_ = new VideoImpl(appPath, basePath, db, lang);
    setImplementation(impl_);
} // end VideoView
/* ****************************************************************************
 * set Internal Base Path
 */
void VideoView::SetInternalBasePath(const std::string& basePath)
{
    impl_->SetInternalBasePath(basePath);
} // end SetInternalBasePath
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
