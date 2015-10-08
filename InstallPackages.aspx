<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.Data.Serialization" %>
<%@ Import Namespace="Sitecore.Security.Serialization" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Update" %>
<%@ Import Namespace="Sitecore.Update.Installer" %>
<%@ Import Namespace="Sitecore.Update.Installer.Exceptions" %>
<%@ Import Namespace="Sitecore.Update.Installer.Installer.Utils" %>
<%@ Import Namespace="Sitecore.Update.Installer.Utils" %>
<%@ Import Namespace="Sitecore.Update.Metadata" %>
<%@ Import Namespace="Sitecore.Update.Utils" %>

<%@ Language=C# %>
<HTML>
    <script runat="server" language="C#">
    public void Page_Load(object sender, EventArgs e)
    {
        Sitecore.Context.SetActiveSite("shell");

        var packages = Directory.GetFiles(Server.MapPath("/sitecore/admin/Packages"), "*.update", SearchOption.TopDirectoryOnly).OrderBy(p => p);

        using (new SecurityDisabler())
        {
            using (new ProxyDisabler())
            {
                using (new SyncOperationContext())
                {
                    //Temporarily disable indexing
                    Settings.Indexing.Enabled = false;

                    foreach (var package in packages)
                    {
                        this.Install(package);
                        Response.Write("Installed Package: " + package + "<br>");
                    }

                    //Install any Sitecore roles and users present in the package
                    InstallSecurityAccounts();

                    //Re-enable indexing
                    Settings.Indexing.Enabled = true;

                    //Cleanup temporary folders for Sitecore items that was created by Sitecore installer
                    Cleanup("core");
                    Cleanup("master");
                }
            }
        }
    }

    private void Install(string package)
    {
        string text = null;
        List<ContingencyEntry> entries = null;
        var log = LogManager.GetLogger("LogFileAppender");

        using (new ShutdownGuard())
        {
            var installationInfo = new PackageInstallationInfo
            {
                Action = UpgradeAction.Upgrade,
                Mode = InstallMode.Install,
                Path = package
            };

            //Install package
            try
            {
                entries = UpdateHelper.Install(installationInfo, log, out text);
            }
            catch (PostStepInstallerException ex)
            {
                Response.Write("Could not install Package: " + package + "<br>");
                entries = ex.Entries;
                text = ex.HistoryPath;
                
                throw;
            }

            //Run post installation steps
            try
            {
                ExecutePostInstallationSteps(package, text, log);
            }
            catch (PostStepInstallerException ex)
            {
                Response.Write("Could not execute post install steps: " + package + "<br>");

                throw;
            }
        }
    }

    private void ExecutePostInstallationSteps(string packagePath, string historyPath, ILog logger)
    {
        MetadataView metadata = UpdateHelper.LoadMetadata(packagePath);
        List<ContingencyEntry> entries = UpdateHelper.LoadEntries(historyPath);
        DiffInstaller diffInstaller = new DiffInstaller(UpgradeAction.Upgrade);
        diffInstaller.ExecutePostInstallationInstructions(packagePath, historyPath, InstallMode.Install, metadata, logger, ref entries);
    }
    
    protected void InstallSecurityAccounts()
    {
        string serverRootPath = Server.MapPath("/");
        string securityPath = Path.Combine(serverRootPath, "security");
        if (Directory.Exists(securityPath))
        {
            string serializationPath = Path.GetDirectoryName(SecuritySerializationUtils.PathToSerialization);
            if (!Directory.Exists(serializationPath))
            {
                Directory.CreateDirectory(serializationPath);
            }

            Directory.Move(securityPath, SecuritySerializationUtils.PathToSerialization);

            //First install roles
            List<string> loadedRoles = new List<string>((IEnumerable<string>)Directory.GetFiles(SecuritySerializationUtils.PathToSerialization, "*.role", SearchOption.AllDirectories));
            foreach (string path in loadedRoles)
            {
                Manager.LoadRole(path);
            }

            //Then install users
            List<string> loadedUsers = new List<string>((IEnumerable<string>)Directory.GetFiles(SecuritySerializationUtils.PathToSerialization, "*.user", SearchOption.AllDirectories));
            foreach (string path in loadedUsers)
            {
                Manager.LoadUser(path);
            }

            Directory.Delete(SecuritySerializationUtils.PathToSerialization, true);
        }
    }

    protected void Cleanup(string folderName)
    {
        string serverRootPath = Server.MapPath("/");

        string folderPath = Path.Combine(serverRootPath, folderName);
        if (Directory.Exists(folderPath))
        {
            Directory.Delete(folderPath);
        }
    }

    protected String GetTime()
    {
        return DateTime.Now.ToString("t");
    }
    </script>
   
    <body>
        <form id="MyForm" runat="server">
	        <div>This page installs packages from \sitecore\admin\Packages folder.</div>
	        Current server time is <% =GetTime()%>
        </form>
    </body>
</HTML>