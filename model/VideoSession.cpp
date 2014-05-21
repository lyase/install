/* ****************************************************************************
 * The Video
 */
#ifdef VIDEOMAN
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <Wt/Dbo/Dbo>
#include <Wt/Dbo/ptr>
#include <Wt/Dbo/Session>
#include <Wt/Dbo/Impl>
#include <Wt/Dbo/Types>
#include <Wt/Dbo/QueryModel>
#include <Wt/WComboBox>
//
#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"
//
#include "TheVideo.h"
#include "VideoSession.h"
/* ****************************************************************************
 * Video Session
 */
VideoSession::VideoSession(const std::string& appPath, Wt::Dbo::SqlConnectionPool& connectionPool) : appPath_(appPath), connectionPool_(connectionPool)
{
    Wt::log("start") << " *** VideoSession::VideoSession() *** ";
    setConnectionPool(connectionPool_);
    mapClass<TheVideo>("video");
    try
    {
        Wt::Dbo::Transaction t(*this);
        // Note: you must drop tables to do update, FIXIT make it a url in the backend with credentials
        //dropTables();
        createTables();
        std::cerr << "Created database: video " << std::endl;
        t.commit();
        Update();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "Using existing video database";
    }
    Wt::log("end") << " *** VideoSession::VideoSession() *** ";
} // end VideoSession::VideoSession
/* ****************************************************************************
 * Video Session
 * Check Database for existing records and delete them
 * Read in XML file and populate Database
 */
void VideoSession::Update()
{
    Wt::log("start") << " *** VideoSession::Update()  *** ";
    try
    {
        // Open XML File
        std::string fullFilePath = appPath_.c_str() + std::string("video.xml");
        const char *filePath = fullFilePath.c_str();
        rapidxml::file<> xmlFile(filePath);
        rapidxml::xml_document<> doc;
        doc.parse<0>(xmlFile.data());
        // Find our root node
        /*
         *
<?xml version="1.0" encoding="ISO-8859-1" ?>
<videos>
    <!-- 3 Comboboxes -->
    <category name="Make|Model|Year" scheme="make|model|year">
        <video name="66 Dodge Cuda"        categories="Dodge|Cudu|1966"        title="426 Hemi" path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
        <video name="77 Dodge Power Wagon" categories="Dodge|Power Wagon|1977" title="318"      path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
        <video name="69 Plymoth Firebird"  categories="Plymoth|Firebird|1969"  title="350"      path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
    </category>
    <!-- 1 Comboboxes -->
    <category name="Color" scheme="color">
        <video name="Blue"  categories="Blue"  title="The Color Blue"  path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
        <video name="Red"   categories="Red"   title="The Color Red"   path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
        <video name="White" categories="White" title="The Color White" path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
    </category>
    <!-- 0 Comboboxes -->
    <category name="" scheme="">
        <video name="Video 1" categories="" title="First Video"  path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
        <video name="Video 2" categories="" title="Second Video" path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
        <video name="Video 3" categories="" title="Third Video"  path="http://domain.tdl/path/filename" ism4v="1" isogv="0" isutube="0" poster="http://domain.tdl/path/fileName.png" width="640" height="360" isautoplay="0" sizes="1080,720" quality="hd,lq" pages=""></video>
    </category>
</videos>
        */
        rapidxml::xml_node<> * root_node = doc.first_node("videos");
        rapidxml::xml_attribute<> *nodeAttrib;
        rapidxml::xml_node<> * domain_node = root_node->first_node("category");
        rapidxml::xml_node<> * category_node = root_node->first_node("category");
        // scheme
        nodeAttrib = domain_node->first_attribute("scheme");
        if (!nodeAttrib)
        {
            Wt::log("error") << "(Update: Missing XML Element: scheme = " << domain_node->name() << ")";
            return;
        }
        std::string mySchema(nodeAttrib->value(), nodeAttrib->value_size());
        // scheme name
        nodeAttrib = domain_node->first_attribute("name");
        if (!nodeAttrib)
        {
            Wt::log("error") << "(Update: Missing XML Element scheme: name = " << domain_node->name() << ")";
            return;
        }
        std::string mySchemeNames(nodeAttrib->value(), nodeAttrib->value_size());
        Wt::log("progress") << "(Update: scheme name)";
        for (rapidxml::xml_node<> * domain_node = category_node->first_node("video"); domain_node; domain_node = domain_node->next_sibling("video"))
        {
            Wt::log("progress") << "(Update: Start Loop = " << domain_node->name() << ")";
            // Start a Transaction
            Wt::Dbo::Transaction t(*this);
            // Create a new Video Instance
            Wt::Dbo::ptr<TheVideo> thisVideo = add(new TheVideo());
            // Set object to Modify
            TheVideo *videoDb = thisVideo.modify();
            // Read in Schema that was read in before this loop
            videoDb->schema = mySchema;
            videoDb->schema_names = mySchemeNames;
            // name of combo box
            nodeAttrib = domain_node->first_attribute("name");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: name = " << domain_node->name() << ")";
                return;
            }
            std::string myname(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->name = myname;
            Wt::log("progress") << "(Update: name)";
            // categories
            nodeAttrib = domain_node->first_attribute("categories");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: categories = " << domain_node->name() << ")";
                return;
            }
            std::string mycategories(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->categories = mycategories;
            Wt::log("progress") << "(Update: categories)";
            // title
            nodeAttrib = domain_node->first_attribute("title");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: title = " << domain_node->name() << ")";
                return;
            }
            std::string mytitle(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->title = mytitle;
            Wt::log("progress") << "(Update: title)";
            // path
            nodeAttrib = domain_node->first_attribute("path");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: path = " << domain_node->name() << ")";
                return;
            }
            std::string mypath(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->path = mypath;
            Wt::log("progress") << "(Update: path)";
            // ism4v
            nodeAttrib = domain_node->first_attribute("ism4v");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: ism4v = " << domain_node->name() << ")";
                return;
            }
            std::string myism4v(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->ism4v = atoi(myism4v.c_str());
            Wt::log("progress") << "(Update: ism4v)";
            // isogv
            nodeAttrib = domain_node->first_attribute("isogv");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: isogv = " << domain_node->name() << ")";
                return;
            }
            std::string myisogv(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->isogv = atoi(myisogv.c_str());
            Wt::log("progress") << "(Update: isogv)";
            // isutube
            nodeAttrib = domain_node->first_attribute("isutube");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: isutube = " << domain_node->name() << ")";
                return;
            }
            std::string myisutube(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->isutube = atoi(myisutube.c_str());
            Wt::log("progress") << "(Update: isutube)";
            // poster
            nodeAttrib = domain_node->first_attribute("poster");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: poster = " << domain_node->name() << ")";
                return;
            }
            std::string myposter(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->poster = myposter;
            Wt::log("progress") << "(Update: poster)";
            // width
            nodeAttrib = domain_node->first_attribute("width");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: width = " << domain_node->name() << ")";
                return;
            }
            std::string mywidth(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->width = atoi(mywidth.c_str());
            Wt::log("progress") << "(Update: width)";
            // height
            nodeAttrib = domain_node->first_attribute("height");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: height = " << domain_node->name() << ")";
                return;
            }
            std::string myheight(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->height = atoi(myheight.c_str());
            Wt::log("progress") << "(Update: height)";
            // isautoplay stored as a 1=true, 0=false
            nodeAttrib = domain_node->first_attribute("isautoplay");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: isautoplay = " << domain_node->name() << ")";
                return;
            }
            std::string myisautoplay(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->isautoplay = atoi(myisautoplay.c_str());
            Wt::log("progress") << "(Update: isautoplay)";
            // sizes
            nodeAttrib = domain_node->first_attribute("sizes");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: sizes = " << domain_node->name() << ")";
                return;
            }
            std::string mysizes(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->sizes = mysizes;
            Wt::log("progress") << "(Update: sizes)";
            // quality
            nodeAttrib = domain_node->first_attribute("quality");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: quality = " << domain_node->name() << ")";
                return;
            }
            std::string myquality(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->quality = myquality;
            Wt::log("progress") << "(Update: quality)";
            // pagetop
            nodeAttrib = domain_node->first_attribute("pagetop");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: pagetop = " << domain_node->name() << ")";
                return;
            }
            std::string mypagetop(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->pagetop = mypagetop;
            Wt::log("progress") << "(Update: pagetop)";
            // pagetopwidth
            nodeAttrib = domain_node->first_attribute("pagetopwidth");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: pagetopwidth = " << domain_node->name() << ")";
                return;
            }
            std::string mypagetopwidth(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->pagetopwidth = mypagetopwidth;
            Wt::log("progress") << "(Update: pagetopwidth)";
            // pagetopheight
            nodeAttrib = domain_node->first_attribute("pagetopheight");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: pagetopheight = " << domain_node->name() << ")";
                return;
            }
            std::string mypagetopheight(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->pagetopheight = mypagetopheight;
            Wt::log("progress") << "(Update: pagetopheight)";
            // pagebottom
            nodeAttrib = domain_node->first_attribute("pagebottom");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: pagebottom = " << domain_node->name() << ")";
                return;
            }
            std::string mypagebottom(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->pagebottom = mypagebottom;
            Wt::log("progress") << "(Update: pagebottom)";
            // pagebottomwidth
            nodeAttrib = domain_node->first_attribute("pagebottomwidth");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: pagebottomwidth = " << domain_node->name() << ")";
                return;
            }
            std::string mypagebottomwidth(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->pagebottomwidth = mypagebottomwidth;
            Wt::log("progress") << "(Update: pagebottomwidth)";
            // pagebottomheight
            nodeAttrib = domain_node->first_attribute("pagebottomheight");
            if (!nodeAttrib)
            {
                Wt::log("error") << "(Update: Missing XML Element: pagebottomheight = " << domain_node->name() << ")";
                return;
            }
            std::string mypagebottomheight(nodeAttrib->value(), nodeAttrib->value_size());
            videoDb->pagebottomheight = mypagebottomheight;
            Wt::log("progress") << "(Update: pagebottomheight)";
            // Commit Transaction
            t.commit();
        } // end for
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "Update: Failed writting to video database";
        Wt::log("error") << "-> VideoSession::Update()  Failed writting to video database)";
    }
    Wt::log("end") << "VideoSession::Update()";
} // end void VideoSession::Update
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
