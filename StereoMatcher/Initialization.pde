
int defaultAppWidth = 1000;
int defaultAppHeight = 700;
String defaultImagePathL = "../images/default_left.png";
String defaultImagePathR = "../images/default_right.png";
String defaultBackgroundPath = "../images/default_background.jpg";

int loadupWidth, loadupHeight;
String imagePathL, imagePathR;
String backgroundPath;

boolean BackgroundSetupFunction()
{
  StringDict settingsDict = parseSettingsFile();
  println(time() + "Settings file parsed.");
  
  loadupWidth = retreiveSettingInt(settingsDict, "appSizeX", defaultAppWidth);
  loadupHeight = retreiveSettingInt(settingsDict, "appSizeY", defaultAppHeight);
  
  imagePathL = retreiveSettingString(settingsDict, "imagePathL", defaultImagePathL);
  imagePathR = retreiveSettingString(settingsDict, "imagePathR", defaultImagePathR);
  rawImageLeft = loadImage(imagePathL);
  rawImageRight = loadImage(imagePathR);
  if ((rawImageLeft == null) || (rawImageRight == null))
  {
    println("Fatal error: Couldn't load all input images.");
    println("Please check your localPreferences.txt to ensure you are pointing at a valid pair of images.");
    rawImageLeft = createImage(0, 0, RGB);
    rawImageRight = createImage(0, 0, RGB);
  }
  camXRes = rawImageLeft.width;
  camYRes = rawImageLeft.height;
  if ((rawImageLeft.width != rawImageRight.width) || (rawImageLeft.height != rawImageRight.height))
    println("Warning: Image dimensions of input images do not match! Using left image dimensions.");
  /*if (settingsDict.containsKey("camResolution"))
  {
    String[] camResolutionArgs = settingsDict.get("camResolution");
    if (camResolutionArgs.length == 2)
    {
      camXRes = int(camResolutionArgs[0]);
      camYRes = int(camResolutionArgs[1]);
    }
    else
      println("Error parsing settings file: Wrong number of arguments for camResolution");
  }*/
  // Note: This might get added later (support for loading different images at run time). For now,
  // I'm primarily concerned with getting this in a working form for git.
  if (float(camYRes)/camXRes - ratio > 0.01)
    println("Warning: Ratio of input images doesn't mach the ccd ratio! Unexpected things might happen.");
  camF = camYRes / tan(openY / 2.0) / 2.0;
  // Note that using camXRes would result in a different camF if ccd and cam have different ratios.
  
  backgroundPath = retreiveSettingString(settingsDict, "backgroundPath", defaultBackgroundPath);
  bg = loadImage(backgroundPath);
  if (bg == null)
  {
    println("Warning: Couldn't load background image.");
    bg = createImage(0, 0, RGB);
  }
  
  //createBackground();
  bg.loadPixels();
  
  println(time() + "Images loaded.");
  
  camLMat = new processing.core.PMatrix3D();
  camRMat = new processing.core.PMatrix3D(); // Calibration matrices can be inserted here! (Ok, currently nothing uses them...)
  
  imageLeft  = createImage(camXRes, camYRes, ARGB);
  imageRight = createImage(camXRes, camYRes, ARGB);
  rawDiffLeft  = createImage(camXRes, camYRes, ARGB);
  rawDiffRight = createImage(camXRes, camYRes, ARGB);
  
  // Projection screens
  pScreenL = new ProjectionScreen(camXRes, camYRes, openY);
  pScreenL.setProjection(-xC, 0, 0, -delta);
  pScreenR = new ProjectionScreen(camXRes, camYRes, openY);
  pScreenR.setProjection( xC, 0, 0,  delta);
  // Rected screens
  int scale = 2;
  rScreenL = new RectedScreen(pScreenL, camXRes/scale, camYRes/scale);
  rScreenR = new RectedScreen(pScreenR, camXRes/scale, camYRes/scale);
  
  // Temporary solution to have the pixel values available without the constant need for loadPixels()
  dataL = new color[camXRes/scale * camYRes/scale];
  dataR = new color[camXRes/scale * camYRes/scale];
  
  // Some graphics setups
  textureMode(NORMAL);
  textAlign(CENTER);
  //smooth(2);
  ((PGraphicsOpenGL)g).textureSampling(3); // Don't let the renderer smear all the pixels together...
  
  println(time() + "Created graphics.");
  
  /*roomA = new float[camXRes/tableStep][camYRes/tableStep][lambdaCount];
  roomB = new float[camXRes/tableStep][camYRes/tableStep][lambdaCount];
  // Multiply with lambda to get x, y and z
  lFactX = new float[camXRes/tableStep]; // Depends only on a1
  lFactY = new float[camYRes/tableStep]; // Depends only on b1
  lFactZ = new float[camXRes/tableStep]; // Depends only on a1*/
  
  /*diffLeft = new int[camXRes * camYRes][luminanceOnly ? 2 : 6];
  diffRight = new int[camXRes * camYRes][luminanceOnly ? 2 : 6];*/
  //int m1 = millis();
  //print(time() + "Creating room table... ");
  //CreateRoomTable();
  //println("Done after " + str(millis() - m1) + " ms");
  
  int m1 = millis();
  print(time() + "Calculating first differences... ");
  firstDifferences(rawImageLeft, rawDiffLeft, ConvolutionKernel.Scharr55);
  firstDifferences(rawImageRight, rawDiffRight, ConvolutionKernel.Scharr55);
  println("Done after " + str(millis() - m1) + " ms");
  println(time() + "Setup done!"); 
  
  
  float phi1 = -openX / 2.0 + delta;
  float l = zF / cos(phi1);
  float cz = l * cos(openX / 2.0);  
  px = sin(phi1) * l - xC;
  py = float(-camYRes/2) / camF * cz;
  pz = -l * cos(phi1);
  
  /*println(rScreenX1);
  println(rScreenX2);
  println(rScreenY1);
  println(rScreenY2);
  println(rScreenX1S);
  println(rectWidth/2);*/
  
  
  createControlWindow();
  
  convolutionPoints = createShape();
  coveredParallaxes = new boolean[rScreenL.xRes];
  
  
  backgroundSetupDone = true;
  closeSplashScreen = true;
  return true;
}

String retreiveSettingString(StringDict settingsDict, String settingsKey, String defaultValue)
{
  String returnVal = defaultValue;
  
  if (settingsDict.hasKey(settingsKey))
    returnVal = settingsDict.get(settingsKey);
  return returnVal;
}
int retreiveSettingInt(StringDict settingsDict, String settingsKey, int defaultValue)
{
  int returnVal = defaultValue;
  
  if (settingsDict.hasKey(settingsKey))
  {
    returnVal = int(settingsDict.get(settingsKey));
  }
  return returnVal;
}

StringDict parseSettingsFile()
{
  StringDict settingsDict = new StringDict();
  
  String[] localPreferences = loadStrings("localPreferences.txt");
  if (localPreferences == null)
  {
    saveStrings("localPreferences.txt", emptySettingsFile);
    println("Created a localPreferences.txt, customize your settings there!");
    return settingsDict;
  }
  
  for (int i = 0; i < localPreferences.length; i++)
  {
    if (localPreferences[i].length() < 1) continue;
    if (localPreferences[i].charAt(0) == ';') continue; // Comment 
    
    int equalsIndex = localPreferences[i].indexOf('=');
    if (equalsIndex == -1) {
      println("Couldn't parse line " + str(i) + " of localPreferences (use ; to comment out individual lines).");
      continue;
    }
    String tag = trim(localPreferences[i].substring(0, equalsIndex));
    String argument = trim(localPreferences[i].substring(equalsIndex+1));
    
    settingsDict.set(tag, argument);
  }

  return settingsDict;
}

String[] emptySettingsFile = {
  "; Lines beginning with ; are ignored when parsing this file.",
  "; The keys and their default values are listed in this default file, uncomment (and change) the arguments to your likings.",
  ";appSizeX = " + defaultAppWidth,
  ";appSizeY = " + defaultAppHeight, 
  ";imagePathL = " + defaultImagePathL,
  ";imagePathR = " + defaultImagePathR, 
  ";backgroundPath = " + defaultBackgroundPath,
  "; Only use this if you want to load various images at runtime and would like to use a different fixed resolution (yes, you cannot change the resolution after initialization).",
  "; (Not currently implemented, setting this has no effect)", 
  ";camResolutionX = 640",
  ";camResolutionY = 480" };
