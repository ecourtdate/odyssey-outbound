# ODYSSEY TO ECOURTDATE UPLOAD WEB SERVICE

This web service provides functionality to receive data from Odyssey's Configurable Integration Publisher and upload it to eCourtDate's API.

## Prerequisites
* Windows Server with IIS installed
* .NET Framework 4.8 or higher
* Write permissions to the configured file directory
* Valid API bearer token for the upload endpoint

## Installation
1. Create a new directory in your IIS web application folder 
   ```
   Example: C:\inetpub\wwwroot\eCourtDateUpload\
   ```

2. Copy these files to the directory:
   - `UploadeCourtDate.asmx`
   - `Web.config`

3. Configure the Web.config settings (see Configuration section)

4. Ensure the IIS application pool identity has write permissions to the configured file directory

## Configuration
The application uses Web.config for all configuration settings. 
Update the following settings in the appSettings section:

```xml
<appSettings>
  <add key="ApiRegion" value="staging" />
  <add key="AuthToken" value="your_bearer_token_here" />
  <add key="FileDirectory" value="C:\Temp\Publishing\" />
</appSettings>
```

### Required Settings:
* **ApiRegion**: The region of your eCourtDate API endpoint
* **AuthToken**: Your eCourtDate API Client Bearer token
* **FileDirectory**: Directory path where files will be temporarily stored

Get your eCourtDate credentials from https://console.ecourtdate.com/apis

### IIS Configuration:
1. Create a new application in IIS pointing to your deployment directory
2. Ensure the application pool is set to .NET 4.8 integrated pipeline mode
3. Enable ASP.NET Web Services in IIS features

## Odyssey Configuration
1. Create a new Configurable Integration Publisher action

2. Create a Publish Action user code in Odyssey that points to the URL for the web service
   ```
   Example: https://{your-server-name}/WebServices/eCourtDateUpload/UploadeCourtDate.asmx
   ```

3. Set the Publish Action name to "PublishDataWebService"

4. Trigger the action on the "Publish Data" event

## Usage
The web service exposes a single SOAP endpoint:
* Method: `PublishData`
* Input: XML string containing court date information
* Output: Boolean indicating success/failure

### SOAP Request Example:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <PublishData xmlns="http://www.tylertech.com">
      <dataXml>[Your XML data here]</dataXml>
    </PublishData>
  </soap:Body>
</soap:Envelope>
```

### Process Flow:
1. Service receives incoming SOAP requests
2. Saves the raw request to a timestamped file in the configured directory
3. Converts the file to base64
4. Uploads to the configured API endpoint with bearer token authentication
5. Returns success/failure status

## Error Handling
* Failed uploads are logged to the Debug output
* The service returns 'false' for any errors during processing
* Check Windows Event Viewer for additional IIS/ASP.NET related errors
* Configuration errors will be thrown if required settings are missing

## Security Considerations
* Store the bearer token securely
* Use HTTPS for the web service endpoint
* Regularly rotate the bearer token
* Implement appropriate authentication for the web service
* Monitor the temporary file directory and implement cleanup procedures
* Service is configured with a 100MB request size limit by default 