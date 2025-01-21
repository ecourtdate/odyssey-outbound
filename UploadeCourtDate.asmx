<%@ WebService Language="C#" Class="ConfigurablePublishing.PublishActionWebService" %>

using System.Web.Services;
using System.ComponentModel;
using System.Web.Services.Protocols;
using System;
using System.Xml;
using System.Net;
using System.IO;
using System.Text;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Text.Json;
using System.Configuration;

namespace ConfigurablePublishing
{
  #region web service

  [WebService(Namespace = "http://www.tylertech.com")]
  [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
  [ToolboxItem(false)]
  public class PublishActionWebService : WebService
  {
    // Configuration properties loaded from Web.config
    private string ApiRegion => ConfigurationManager.AppSettings["ApiRegion"];
    private string AuthToken => ConfigurationManager.AppSettings["AuthToken"];
    private string FileDirectory => ConfigurationManager.AppSettings["FileDirectory"];

    // ****************
    // *** "PublishData" is the service method on the Odyssey publish action configuration
    // ****************
    [WebMethod]
    public bool PublishData(string dataXml)
    {
      try
      {
        // Validate configuration
        if (string.IsNullOrEmpty(ApiEndpoint) || string.IsNullOrEmpty(AuthToken) || string.IsNullOrEmpty(FileDirectory))
        {
          throw new ConfigurationErrorsException("Missing required configuration settings. Please check Web.config.");
        }

        // Ensure directory exists
        if (!Directory.Exists(FileDirectory))
        {
          Directory.CreateDirectory(FileDirectory);
        }

        Stream receiveStream = System.Web.HttpContext.Current.Request.InputStream;
        string rawHTTPText = string.Empty;

        // Move to beginning of input stream and read
        receiveStream.Position = 0;
        using (StreamReader readStream = new StreamReader(receiveStream, System.Text.Encoding.UTF8))
        {
          rawHTTPText = readStream.ReadToEnd();
        }

        string fileName = DateTime.Now.ToString("yyyyMMdd-HHmmss-fff") + ".txt";
        string filePath = Path.Combine(FileDirectory, fileName);

        // Save file locally
        File.WriteAllText(filePath, rawHTTPText);

        // Upload to API
        return UploadFileToApi(filePath, fileName).GetAwaiter().GetResult();
      }
      catch (Exception ex)
      {
        // Log error appropriately
        System.Diagnostics.Debug.WriteLine($"Error in PublishData: {ex.Message}");
        return false;
      }
    }

    private async Task<bool> UploadFileToApi(string filePath, string fileName)
    {
      using (var httpClient = new HttpClient())
      {
        // Set up authentication
        httpClient.DefaultRequestHeaders.Authorization = 
          new AuthenticationHeaderValue("Bearer", AuthToken);

        // Read file and convert to base64
        byte[] fileBytes = File.ReadAllBytes(filePath);
        string base64Data = Convert.ToBase64String(fileBytes);

        // Create upload payload
        var payload = new
        {
          name = fileName,
          type = "text/plain",
          size = fileBytes.Length,
          file_data = base64Data
        };

        // Serialize to JSON
        string jsonContent = JsonSerializer.Serialize(payload);
        var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

        // Send request
        var response = await httpClient.PostAsync($"https://{ApiRegion}.api.ecourtdate.com/v1/uploads", content);

        // log failed response
        if (!response.IsSuccessStatusCode)
        {
          System.Diagnostics.Debug.WriteLine($"Upload failed with status code: {response.StatusCode}");
        }
        
        // Return true if successful
        return response.IsSuccessStatusCode;
      }
    }
  }

  #endregion
}
