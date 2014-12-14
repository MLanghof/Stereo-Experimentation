import java.nio.charset.Charset;
import java.util.zip.*;
// This GUI library made things a lot easier.
import g4p_controls.*;

// I'd recommend increasing the width of the processing window
// if you plan on reading this code further. Just saying.


StereoMatcher sm;


// ccd Dimensions taken from one of the cameras whose pictures are used for tests.
// Many explanatory sketches in http://1drv.ms/ZmQgnp
// ->"ccdCalculations"
float ccdWidth = 6.16; // mm
float ccdHeight = 4.62; // mm
float ccdF = 6; // mm
float ratio = (float)ccdHeight/ccdWidth;
float openX = 2.0 * atan(ccdWidth / ccdF / 2.0);
float openY = 2.0 * atan(ccdHeight / ccdF / 2.0);

// Resolution of the input images
int camXRes;
int camYRes;
// Assumes cam has same ratio as the ccd. No clue what would happen otherwise... Probably cropping/clipping.
float camF;

/*float zF = 900.0;
float xC = 77.0; // mm
float delta = 0;*/

// This is the information about the camera positions.
// ->"Basic camera setup and terminology"
float zF = 500.0; // mm
float xC = 100.0; // mm
float delta = atan2(xC, zF); // yes, this is the correct order.
// This has only eyecandy purposes
float spacer = 30.0;

// Some calculations to have the pScreens touching each other
float lHelper =  xC / sin(openX / 2.0 + delta);
float sDepth = lHelper * cos(openX / 2.0);
float sWidth = lHelper * sin(openX / 2.0);
float sHeight = sDepth * tan(openY / 2.0);

// Hypothenuse length (between xC and zF)
float lH = mag(xC, zF);

// Test point (was used to confirm rectangulation validity)
float px = -100.0;
float py = 60.0;
float pz = -0.4 * zF;
int pa, pb;

// Scene camera stuff
float rateTrans = 1.0;
float transx = 0.0;
float transy = 0.0;
float rateRot = 0.005;
float rotx = 0.0;
float roty = 0.0;
float rateScal = 0.01;
float scaling = 1.0;

processing.core.PMatrix3D camLMat, camRMat; // Simple homogene transformation matrix

PImage rawImageLeft, rawImageRight;
PImage rawDiffLeft, rawDiffRight;
PImage imageLeft, imageRight;

PImage bg;
float bgW2 = 800;
float bgH2 = 600;
float shift = -00;


// We can use some perlin noise to simulate the iso noise cameras suffer from
float isoNoiseAmount = 20.0;
float isoScale = 1.2;

boolean luminanceOnly = true; // You'd rather want SAD and thus 3 channels, we can get only 1 here 
int[][] diffLeft, diffRight;
PImage diffImage;

// Presampling
int psWidth = 5;
int psHeight = 5;
float psXCount = camXRes / psWidth;
float psYCount = camYRes / psHeight;

// Pipe contains luminance and luminance gradients (vertical/horizontal)
ProjectionScreen pPipeL, pPipeR;
RectedScreen rPipeL, rPipeR;


boolean backgroundSetupDone = false;
boolean closeSplashScreen = false;

int t0;
void setup()
{
  size(400, 300, P3D); // Splash screen size
  frameRate(30);
  
  t0 = millis();
  println(time() + "Starting up...");
  
  thread("BackgroundSetupFunction");
}

void draw()
{
  if (!backgroundSetupDone)
  {
    background(127*(1.0+cos(-frameCount/54.0)));
    frame.setTitle("Starting up...");
    return;
  }
  if (closeSplashScreen)
  {
    if (frame != null) {
      frame.setResizable(true);
    }
    frame.setSize(loadupWidth, loadupHeight);
    closeSplashScreen = false;
  }
   
  calculationPipeline();
  
  // Actual drawing happens now.
  displayThings();
}

void calculationPipeline()
{
  // Determine how the camera images are preprocessed
  if (isoNoise())
    isoNoisify();
  else if (calcPipe())
  {
    imageLeft.set(0, 0, rawDiffLeft);
    imageRight.set(0, 0, rawDiffRight);
    brightnessToBlue(rawImageLeft, imageLeft);
    brightnessToBlue(rawImageRight, imageRight);
  }
  else
  {
    imageLeft.set(0, 0, rawImageLeft);
    imageRight.set(0, 0, rawImageRight);
  }
  
  // This is not the rendering itself: The calculations are skipped if the result won't be rendered this frame.
  if (showScreens())
  {
    sm.pScreenL.setImage(imageLeft);
    sm.pScreenR.setImage(imageRight);
  }
  if (showRected())
  {
    sm.rScreenL.rectangulateSourceGL();
    sm.rScreenR.rectangulateSourceGL();
  }
  
  // Actual processing
  if (frameCount % 5 == 0)
  {
    int parallax = distanceToParallax(zF * sdRectDist.getValueF(),
                                       sm.rScreenL, sm.rScreenR);
    sm.fixedDistanceConvolution(parallax);
  }
}

void displayThings()
{
  background(0);
  frame.setTitle(nf(frameRate, 1, 2)+"fps");
  
  camera();
  perspective();
  translate(width/2.0, height/2.0, 0.0);

  scale(scaling);
  translate(transx, transy, 00);
  rotateX(rotx);
  rotateY(roty);
  
  
  if (lookFromLeft())
    camera(-xC, 0, 0, 0, 0, -zF, 0, 1.0, 0);
  if (lookFromRight())
    camera( xC, 0, 0, 0, 0, -zF, 0, 1.0, 0);
  if (lookFromMiddle())
    camera( 0, 0, 0, 0, 0, -zF, 0, 1.0, 0);
  if (lookFromLeft() || lookFromRight() || lookFromMiddle())
    perspective(openY, 1.0/ratio, 0.1, 1000);

  pushStyle();


  // Drawing stuff begins
  noStroke();
  
  // Background, maybe shifted up a bit
  if (showBackground())
  {
    beginShape();
    texture(bg);
    vertex(-bgW2, -bgH2+shift, -zF, 0, 0);
    vertex( bgW2, -bgH2+shift, -zF, 1, 0);
    vertex( bgW2, bgH2+shift, -zF, 1, 1);
    vertex(-bgW2, bgH2+shift, -zF, 0, 1);
    endShape();
  }
  
  stroke(120);
  strokeWeight(2);

  // x-axis
  line(-spacer - xC, 0, spacer + xC, 0);
  // z-axis
  line(0, 0, spacer, 0, 0, -zF - spacer);


  if (showLines())
  {
    // Point F
    noStroke();
    fill(#0000FF);
    pushMatrix();
    translate(0, 0, -zF);
    //sphere(2); // usually it appears smaller...
    popMatrix();
  
    strokeWeight(2);
    stroke(#0000FF);
    // View lines
    line(-xC, 0, 0, 0, 0, -zF);
    line( xC, 0, 0, 0, 0, -zF);
    
    stroke(240);
    // One view ray per corner per image = 2x2x2 rays
    for (int a = -1; a <= 1; a += 2)
    {
      pushMatrix();
      translate(float(a) * xC, 0, 0);
      rotateY(float(a) * delta);
      for (int b = -1; b <= 1; b += 2)
        for (int c = -1; c <= 1; c += 2)
          line(0.0, 0.0, 0.0,
            1000.0 * tan(float(c) * openX/2.0),
           -1000.0 * tan(float(b) * openY/2.0),
           -1000.0);
      popMatrix();
    }
  }


  if (showTestPoint())
  {
    // Point P itself
    noStroke();
    fill(#FF0000);
    pushMatrix();
    translate(px, -py, -pz);
    //sphere(1);
    shape(createShape(BOX, 0.2));
    popMatrix();
    // Lines from cameras to P
    stroke(#FF0000);
    line(xC, 0, 0, px, -py, -pz);
    line(-xC, 0, 0, px, -py, -pz);
  }

  noStroke();

  if (showScreens())
  {
    if (!rightOnly())
      sm.pScreenL.drawTo(g, sdScreenDist.getValueF());
    sm.pScreenR.drawTo(g, sdScreenDist.getValueF());
  }

  // Show the "rectified" images on screen
  if (showRected())
  {
    // Only show the desired channels
    tint(color(showDiffHori() ? 255 : 0, showDiffVert() ? 255 : 0, showBrightness() ? 255 : 0));
    float rectScreenDist = (sdRectDist.getValueF()) * zF;
    if (!rightOnly())
      sm.rScreenL.drawTo(g, rectScreenDist);
    sm.rScreenR.drawTo(g, rectScreenDist);
    noTint();
    
    // This is how we get the data to the convolution algorithm
    sm.rScreenL.canvas.loadPixels();
    sm.rScreenR.canvas.loadPixels();
    arrayCopy(sm.rScreenL.canvas.pixels, dataL);
    arrayCopy(sm.rScreenR.canvas.pixels, dataR);
  }
  
  if (showConvPoints() && (sm.convolutionPoints != null))
    shape(sm.convolutionPoints);  
  if (showTestPoint() && (vectors != null))
    shape(vectors);
  
  popStyle(); // Just to make sure...
}


PShape vectors;

// Will not check if vectors is ready for input.
void drawVectors(int a, int b, float distance, RectedScreen screen, color[] data, int n)
{
  for (int j = -n; j <= n; j++)
    for (int i = -n; i <= n; i++)
    {
      color date = data[(b + j) * screen.xRes + (a + i)];
      float dx = (((date >> 16) & 0xFF) - 128);
      float dy = (((date >> 8 ) & 0xFF) - 128);
      float x = screen.roomX(a+i, distance);
      float y = screen.roomY(b+j, distance);
      vectors.vertex(x, -y, -distance);
      vectors.vertex(x+dx, -(y-dy), -distance+2);
    }
}

//*
// Takes rScreenL and rScreenR as well as a parallax.
// At zF we have 0 parallax.
// Where do we have width parallax (images touching each other)?
// xC/(xC+rW2) * zF
// Between that, it's NOT linear, because the images also get smaller: At dist=0 the parallax is infinite.
// Parallax is aL - aR
float parallaxToDistance(int parallax, RectedScreen r1, RectedScreen r2)
{
  assert(r1.xRes == r2.xRes);
  assert(r1.F == r2.F);
  return (r2.px - r1.px) / (parallax / r1.F - tan(r1.delta) + tan(r2.delta));
}
int distanceToParallax(float distance, RectedScreen r1, RectedScreen r2)
{
  assert(r1.xRes == r2.xRes);
  assert(r1.F == r2.F);
  return round(((r2.px - r1.px) / distance + tan(r1.delta) - tan(r2.delta)) * r1.F); 
}
//*/

void mouseDragged() {
  if (mouseButton == LEFT)
  {
    rotx += (pmouseY -  mouseY) * rateRot;
    roty += (mouseX  - pmouseX) * rateRot;
  }
  if (mouseButton == RIGHT)
  {
    scaling *= 1 + rateScal * (pmouseY - mouseY);
  }
  if (mouseButton == CENTER)
  {
    transx += (mouseX - pmouseX) * rateTrans;
    transy += (mouseY - pmouseY) * rateTrans;
  }
}

void keyPressed()
{
  switch (key)
  {
  case 'b': 
    toggleControl(cbShowBackground); 
    break;
  case 's': 
    toggleControl(cbShowScreens); 
    break;
  case '1': 
    viewLeft.setSelected(true);  
    break;
  case '2': 
    viewRight.setSelected(true);  
    break;
  case '3': 
    viewMiddle.setSelected(true);  
    break;
  case 't': 
    toggleControl(cbShowTestPoint); 
    break;
  case 'l': 
    toggleControl(cbShowLines); 
    break;
  case 'n': 
    toggleControl(cbIsoNoise); 
    break;
  case 'p':
    toggleControl(cbCalcPipe);
    break;
  case 'a': // Arbitrary key...
    toggleControl(cbShowRightOnly);
    break;
  case 'r':
    toggleControl(cbShowRected);
    break;
  case 'c':
    toggleControl(cbConvPoints);
    break;
  }
}

void keyReleased()
{
  switch (key)
  {
  case '1': 
    viewNormal.setSelected(true); 
    camera();
    break;
  case '2': 
    viewNormal.setSelected(true); 
    camera(); 
    break;
  case '3': 
    viewNormal.setSelected(true); 
    camera(); 
    break;
  }
}

String time()
{
  return nf(millis() - t0, 6) + ": ";
}
