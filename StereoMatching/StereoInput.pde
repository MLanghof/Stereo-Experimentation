// This class encapsulates input data for the stereo matching process.
// The various input methods (static image, video stream) should subclass this class.


abstract class StereoInput
{
  float xOffset = 77.0; // mm
  public float xOffset() { return xOffset; }
  
  float delta = 0;
  float zF;
  
  float openX;
  public float openX() { return openX; }
  
  float openY;
  public float openY() { return openY; }
  
  // Enforcing these variables to be final is impractical/impossible if you want to use subclasses.
  // You could make the getters abstract. Nobody really cares though; if you wanna mess things up,
  // there are better ways than creating and using a bogus subclass of this.
  int resX;
  public int resX() { return resX; }
  
  int resY;
  public int resY() { return resY; }
  
  float ratio;
  public float ratio() { return ratio; }
  
  boolean newDataAvailable = false;
  //volatile boolean dataMutex = false;
  PImage currentData;

  
  StereoInput(String zipPath)
  {
    InputStream input = createInput(zipPath);
    ZipInputStream zis = new ZipInputStream(input);
    JSONObject j = parametersJSONFromZip(zis);
    
    String[] requiredKeys = { "openX", "openY", "xOffset", "delta", "resX", "resY" };
    for (int i = 0; i < requiredKeys.length; i++)
      if (!j.hasKey(requiredKeys[i]))
        println("WARNING: Input file didn't define stereo parameter " + requiredKeys[i] + "!");
    
    constructorBusiness(j.getFloat("openX"), j.getFloat("openY"), j.getFloat("xOffset"), j.getFloat("delta"), j.getInt("resX"), j.getInt("resY"));
    
    furtherZipConstruction(zis);
  }
  
  // Override in subclass if you want to read out more stuff from the zip stream.
  void furtherZipConstruction(ZipInputStream zis)
  {
    // Implement in subclass!
  }
  
  
  StereoInput(float openX, float openY, float xOffset, float delta, int resX, int resY)
  {
    constructorBusiness(openX, openY, xOffset, delta, resX, resY);
  }
    
  StereoInput(float ccdWidth, float ccdHeight, float ccdF, float xOffset, float delta, int resX, int resY)
  {
    constructorBusiness(2.0 * atan(ccdWidth / ccdF / 2.0), 2.0 * atan(ccdHeight / ccdF / 2.0),
         xOffset, delta, resX, resY);
  }
  
  void constructorBusiness(float openX, float openY, float xOffset, float delta, int resX, int resY)
  {
    this.openX = openX;
    this.openY = openY;
    
    this.xOffset = xOffset;
    this.delta = delta;
    if (delta != 0) zF = xOffset / atan(delta);
    
    this.resX = resX;
    this.resY = resY;
    this.ratio = resY / resX;
    
    if (abs(ratio - tan(openY)/tan(openX)) > 0.001)
      println("WARNING: The aspect ratios of camera and image for a stereo input didn't match!");
  }
  
  
  public void zipParameters(ZipOutputStream zos)
  {
    try {
      ZipEntry entry = new ZipEntry("stereoParameters");
      zos.putNextEntry(entry);
      JSONObject json = parametersToJSON();
      zos.write(json.toString().getBytes());
      zos.closeEntry();
    } catch (IOException e) { e.printStackTrace(); }
  }
  
  JSONObject parametersToJSON()
  {
    JSONObject json = new JSONObject();
    json.setFloat("openX", openX);
    json.setFloat("openY", openY);
    json.setFloat("xOffset", xOffset);
    json.setFloat("delta", delta);
    json.setInt("resX", resX);
    json.setInt("resY", resY);
    println(json.toString());
    return json;
  }
  
  public JSONObject parametersJSONFromZip(ZipInputStream zis)
  {
    ZipEntry entry;
    String jsonString = "";
    try {
      zis.reset();
      while ((entry = zis.getNextEntry()) != null)
      {
        if (entry.getName() == "stereoParameters")
        {
          BufferedReader in = new BufferedReader(new InputStreamReader(zis));
          String line;
          while ((line=in.readLine()) != null)
            jsonString += line;
        }
      }
    } catch (IOException e) { e.printStackTrace(); }
    
    return JSONObject.parse(jsonString);
  }

  void JSONToParameters(JSONObject json)
  {
    
    
  }
  
  public boolean isNewDataAvailable()
  { return newDataAvailable; }
  
  public PImage getData()
  {
    newDataAvailable = false;
    return currentData;
  }
  
}

class StaticImageInput extends StereoInput
{
  
  public StaticImageInput(float ccdWidth, float ccdHeight, float ccdF, float xOffset, float delta, PImage img)
  {
    // Image size will be updated later on
    super(ccdWidth, ccdHeight, ccdF, xOffset, delta, img.width, img.height);
    this.currentData = img;
    newDataAvailable = true;
    
  }
  
  
  public void saveToFile(String name)
  {
    
  }
  
}  

float zFToDelta(float xOffset, float zF)
{
  return atan(xOffset/zF);
}
