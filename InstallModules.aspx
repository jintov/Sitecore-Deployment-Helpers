<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="Sitecore.Install" %>
<%@ Import Namespace="Sitecore.Install.Files" %>
<%@ Import Namespace="Sitecore.Install.Framework" %>
<%@ Import Namespace="Sitecore.Install.Items" %>
<%@ Import Namespace="Sitecore.Install.Utils" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>

<%@ Language=C# %>
<HTML>
    <script runat="server" language="C#">
    public void Page_Load(object sender, EventArgs e)
    {
        Sitecore.Context.SetActiveSite("shell");

        var log = LogManager.GetLogger("LogFileAppender");
        var packages = Directory.GetFiles(Settings.PackagePath, "*.zip", SearchOption.TopDirectoryOnly).OrderBy(p => p);

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
                        try
                        {
                            this.Install(package);
                            Response.Write("Installed Package: " + package + "<br>");
                        }
                        catch (Exception ex)
                        {
                            Response.Write("Could not install Package: " + package + "<br>");
                            log.Error(this, ex);
                        }
                    }
                
                    //Re-enable indexing
                    Settings.Indexing.Enabled = true;
                }
            }
        }
    }

    private void Install(string package)
    {
        IProcessingContext context = new SimpleProcessingContext();
        
        IItemInstallerEvents itemEvents = new DefaultItemInstallerEvents(new BehaviourOptions(InstallMode.Overwrite, MergeMode.Undefined));
        context.AddAspect(itemEvents);

        IFileInstallerEvents fileEvents = new DefaultFileInstallerEvents(true);
        context.AddAspect(fileEvents);

        Installer installer = new Installer();
        installer.InstallPackage(package, context);
    }

    protected String GetTime()
    {
        return DateTime.Now.ToString("t");
    }
    </script>

    <body>
        <form id="MyForm" runat="server">
            <div>This page installs packages from \Data\Packages folder.</div>
	        Current server time is <% =GetTime()%>
        </form>
    </body>
</HTML>