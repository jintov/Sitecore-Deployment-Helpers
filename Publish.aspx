<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Update" %>
<%@ Import Namespace="Sitecore.Update.Installer" %>
<%@ Import Namespace="Sitecore.Update.Installer.Exceptions" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Publishing" %>

<%@ Language=C# %>
<HTML>
    <script runat="server" language="C#">
    public void Page_Load(object sender, EventArgs e)
    {
        Sitecore.Context.SetActiveSite("shell");

        using (new SecurityDisabler())
        {
            var log = LogManager.GetLogger("LogFileAppender");

            try
            {
                DateTime publishDate = DateTime.Now;
                Sitecore.Data.Database master = Sitecore.Configuration.Factory.GetDatabase("master");
                Sitecore.Data.Database web = Sitecore.Configuration.Factory.GetDatabase("web");
                
                if (Request["mode"] != null)
                {
                    if (Request["mode"].ToLowerInvariant().Equals("full"))
                    {
                        PublishManager.Republish(Sitecore.Client.ContentDatabase, new Database[] { web }, LanguageManager.GetLanguages(master).ToArray(), Sitecore.Context.Language);
                    }
                    else if (Request["mode"].ToLowerInvariant().Equals("smart"))
                    {
                        PublishManager.PublishSmart(Sitecore.Client.ContentDatabase, new Database[] { web }, LanguageManager.GetLanguages(master).ToArray(), Sitecore.Context.Language);
                    }
                    else
                    {
                        PublishManager.PublishIncremental(Sitecore.Client.ContentDatabase, new Database[] { web }, LanguageManager.GetLanguages(master).ToArray(), Sitecore.Context.Language);
                    }
                }
            }
            catch (Exception ex)
            {
                log.Error(this, ex);
                throw;
            }
        }
    }

    protected String GetTime()
    {
        return DateTime.Now.ToString("t");
    }
    </script>
   
    <body>
        <form id="MyForm" runat="server">
	        <div>This page publishes Master database.</div>
	        Current server time is <% =GetTime()%>
        </form>
    </body>
</HTML>