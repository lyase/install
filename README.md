Witty Wizard

Witty Wizard is C++ Content Management System (CMS) Wizard written in C++, using Wt or Witty, 
a C++ HTTP Library, which makes it easy to write Web Based applications.

The main Goal in this project is to provide an Installation Script written in Bash, 
and Called the WittyWizard-install.sh Script,
and CMS written in C++ using Witty, so its know as Witty Wizard,
as well as a Video Tutorial Series called The Witty Wizard, with a You-Tube Chanel. 

The Tutorial Video Series, is targeted for none Programmers, as well as seasoned vets
like myself who started Programming back in the 70's.

The Installation Script is called WittyWizard-install.sh,
this is also a Wizard Script, it uses Wizards to install Development Tools, 
Required Applications and Witty, on to a Platform like Linux, 
which has many Distributions, including Red Hat, with other code bases, 
like CentOS, Fedora and others, then you have Debian, which has code based off them,
like Ubuntu, Linux Mint Debian Edition or LMDE, and others,
each having their own installation methods,
not to mention Repositories, with different names for the same file, or files...
so lets face it, this script goes out of its way to make it work with every Distribution,
this is how it works, I will run the Witty Wizard CMS on a Public Web Server using CentOS, 
I chose this OS because at my current Hosting Provider, I have to chose one, 
I tried other options, and ran into installation problems, I work on them for a while,
then move on to one that works, and CentOS, worked great,
now this is Open Source, 
so if you can give detailed instructions, or patch, that work on an OS you want 
this script to work on, I will add it, it has to agree with Open Source Licenses, 
so people can use it, the script is Bash, easy to read, has a help file,
built in support for Multiple Languages, based on Computer Translation,
so its not perfect, but it allows for Manual or Human Translations also.

The WittyWizard-install.sh script is designed to install applications needed by Witty Wizard,
but it has a Configuration file that allows you to add an unlimited number of servers with
with different roles; so you can install Wt on one server if you want or
it can be used to install haproxy as a stand alone web, email or Database Server,
making it very flexible, the idea is to allow you to use haproxy for Witty Wizard,
so you can load balance your application, and using monit to monitor the processes,
so that the application is scalable and fault resilient.

Currently the Installation Script is in Alpha mode, its being tested in CentOS, Archlinux, and LMDE,
once I get these working, I will start on Other Debian based Distributions.

You can download, extract and move files to root of folder with this command:
wget https://github.com/WittyWizard/install/archive/master.zip; unzip master.zip; cd install-master; mv -v * ..; cd ..; rm -rf install-master; rm -f master.zip;
or this command will leave everything in the install-master folder.
wget https://github.com/WittyWizard/install/archive/master.zip; unzip master.zip; rm -f master.zip;
Once downloaded, cd install-wizard, and run:
./WittyWizard-install.sh -l
This will localize the script,
then run:
./WittyWizard-install.sh -h
this will build the help file help.html
Normally you only have to run -l and -h if you make changes to the scrips.
now you can run: 
./WittyWizard-install.sh
and Follow the Instructions; the video will cover most common questions on how to use it.

The CMS systems itself will be an on going Project based on Feedback from the Video Series,
but the end goal of this CMS is to be able to run this CMS from your Desktop,
and Control the OS you are on, this make more sense if you are running it on a Server,
and do not want cPanel or other panels to control the Server,
so this CMS will allow you to Create User Accounts and manage Email for users, 
it will have a File Browser, Database Browser, and other tools built in,
it will also give you access to features you normally ssh into and do by the command line,
so the security system is very important for this reason alone.

The Witty Wizard Video Series teaches users how I am creating this CMS, 
so it also teaches users how to use C++ and Wt to create the CMS,
as such its a great Resource of information on how to do things,
but the goal is to create a System that will allow for Blogs, Forums, Calenders, Email, Shopping Carts,
and other features that would be nice to have for this Series,
as well as being able to post Multimedia to the Web Site, manage Videos and other media.

The Series runs it Steps, each Step may have multiple updates and revisions, a General Outline:
Step 0 - This is the Installation Script to Install Wt and Witty Wizard.
Step 1 - Log in, multiple types of authentication will be available.
Step 2 - The Back-end, this is where we add new accounts.
Step 3 - The Front end, this is where we view the content created in Step 2.
Other Steps will cover topics like Blogs, Forums, Calenders, Email, Shopping Carts and more.

When Completed this CMS can be used to run small to large business, and up to Governments,
so it scales up very easy, its security has to be the best, and be easy to use.

Style Guild:
Braces are all vertically lined up with 4 spaces of indention
function()
{
    if () // If statements always have braces
    {
    }
    else
    {
    }
}
