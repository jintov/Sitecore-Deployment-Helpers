Sitecore-Deployment-Helpers
========================

First things first - this has been forked from Alexander Doroshenko's repository (https://github.com/adoprog/Sitecore-Deployment-Helpers)

The changes I have done to the original helper pages are:

 **InstallPackages.aspx** - will install all Sitecore update packages (*.update) present in /sitecore/admin/packages folder

 - Support for running post installation steps that may be present in
   the package
 - Installing Sitecore security accounts in the package
   (roles and users)
 - Disabling indexing during installation to speed up
   the installation
 - Clean up of temporary folders created in the web
   root for the Sitecore items present in the package

**InstallModules.aspx** - will install all modules (*.zip) from %datafolder%/packages folder

 - Disabling indexing during installation to speed up
   the installation

**Publish.aspx** - will publish content from master to the web database

 - Takes a query string parameter (mode) indicating the type of publish to be performed (mode=full -> Republish, mode=smart -> Smart Publish, Incremental for everything else)
