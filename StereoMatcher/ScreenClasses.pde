abstract class ScreenBase
{
  int xRes, yRes;
  float F;
  float ratio; // This ratio is the inverse of the one in the main applet! Keep this in mind!
  float openX, openY;
  
  //Position and orientation of the camera origin
  float px, py, pz;
  float delta;

  PImage input;
  PGraphics canvas;
  PImage output;
  
  boolean canvasPrepared = false;
  
  ScreenBase(int xRes, int yRes, float openY)
  {
    this.xRes = xRes;
    this.yRes = yRes;
    this.openY = openY;
    ratio = float(xRes)/yRes; // Am i the only one who finds the necessity for this conversion... idiotic?
    
    // ->"Camera projection terminology"
    F = yRes / tan(openY / 2.0) / 2.0;
    openX = 2.0 * atan(xRes / F / 2.0);
    
    output = createImage(xRes, yRes, ARGB);
    canvas = createGraphics(xRes, yRes, P3D);
  }
  
  void prepareCanvas()
  {
    canvas.beginDraw();
    canvas.textureMode(NORMAL);
    ((PGraphicsOpenGL)canvas).textureSampling(3);
    canvas.strokeWeight(0);
    canvas.endDraw();
    canvasPrepared = true;
  }
  
  void setProjection(float px, float py, float pz, float delta)
  {
    this.px = px;
    this.py = py;
    this.pz = pz;
    this.delta = delta;
  }
  
  void setImage(PImage img)
  {
    input = img;
  }
  
  abstract void drawTo(PGraphics g, float distance);
}

class ProjectionScreen extends ScreenBase
{
  ProjectionScreen(int xRes, int yRes, float openY)
  {
    super(xRes, yRes, openY);
  }
  
  void drawTo(PGraphics g, float distance)
  {
    output.set(0, 0, input);
    output.updatePixels();
    
    float screenWidth2  =  distance * tan(openX / 2.0); // half width
    float screenHeight2 =  distance * tan(openY / 2.0); // half height
    g.pushMatrix();
    g.translate(px, py, pz); // Only tested for x translation
    g.rotateY(delta);
    g.translate(0.0, 0.0, -distance);
    g.beginShape();
    g.texture(output);
    g.vertex(-screenWidth2, -screenHeight2, 0, 0, 0);
    g.vertex( screenWidth2, -screenHeight2, 0, 1, 0);
    g.vertex( screenWidth2,  screenHeight2, 0, 1, 1);
    g.vertex(-screenWidth2,  screenHeight2, 0, 0, 1);
    g.endShape(CLOSE);
    g.popMatrix();
  }
}

// Always parallel to the x/y plane
class RectedScreen extends ScreenBase
{
  ProjectionScreen source;
  
  float rectNullHeight, rectNullWidth; // Width and height at 0 parallax
  
  RectHelperScreen helper;
  
  RectedScreen(ProjectionScreen source, int xRes, int yRes)
  {
    super(xRes, yRes, source.openY);
    super.setProjection(source.px, source.py, source.pz, source.delta);
    this.source = source;
    
    rectNullHeight = 2.0 * tan(openY / 2.0); // This equals the camera projection height above the screen middle
    rectNullWidth = rectNullHeight * ratio;  // Multiply with distance for useable values
    
    helper = new RectHelperScreen(source, xRes, yRes);
  }
  
  // Cannot be done in the superclass because only here are x and y increments proportional to image coordinates
  float roomX(int a, float distance)
  {
    // If we input camXRes, we should get tan(openX/2) for mX
    return ((a - xRes/2) / F - tan(delta)) * distance + px;
  }
  
  float roomY(int b, float distance)
  {
    return -(b - yRes/2) / F * distance + py;
  }
  
  void rectangulateSourceGL()
  {
    if (!canvasPrepared) prepareCanvas();
    helper.setImage(source.output);
    helper.drawTo(canvas, -1); // The -1 is just an unused parameter.
    /*output.set(0, 0, canvas);
    output.updatePixels();*/
  }
  
  void drawTo(PGraphics g, float distance)
  {
    float rectScreenHeight = distance * rectNullHeight; // Scales proportionally with distance
    float rectScreenWidth  = distance * rectNullWidth;
    g.pushMatrix();
    g.translate(px - distance * tan(delta), py, -pz - distance);
    g.beginShape();
    g.texture(canvas);
    g.vertex(-rectScreenWidth/2.0, -rectScreenHeight/2.0, 0, 0, 0);
    g.vertex( rectScreenWidth/2.0, -rectScreenHeight/2.0, 0, 1, 0);
    g.vertex( rectScreenWidth/2.0,  rectScreenHeight/2.0, 0, 1, 1);
    g.vertex(-rectScreenWidth/2.0,  rectScreenHeight/2.0, 0, 0, 1);
    g.endShape(CLOSE);
    g.popMatrix();
  }
}

// Rected screen
class RectHelperScreen extends ScreenBase
{
   RectHelperScreen(ProjectionScreen from, int xRes, int yRes)
   {
    super(xRes, yRes, from.openY);
    super.setProjection(-from.px, -from.py, -from.pz, -from.delta);
    
    calculateGLCoordinates();
  }
  
  float zF;
  float rectAbsY; // absolute y coordinate of the helper image vertices
  float rectX1, rectZ1;
  float rectX2, rectZ2;
  
  void calculateGLCoordinates()
  {
    assert(delta != 0); // Don't know how to properly handle this yet.
    
    // If you want to understand this, you should have both Rectangulation.txt and the
    // "Rectangulation via Rendering" sketch at your fingertips.
    zF = px / tan(delta);
    float tanEpsilon = tan(openY/2.0) * cos(openX/2.0);
    float intersection_X_L = tan(-openX/2.0 + delta) * zF - px;
    float intersection_X_R = tan( openX/2.0 + delta) * zF - px;
    float intersection_Y_L = tanEpsilon * (zF / cos(-openX/2.0 + delta));
    float intersection_Y_R = tanEpsilon * (zF / cos( openX/2.0 + delta));
    rectAbsY = intersection_Y_L; // Could be the other (_R not _L) as well, just needs to be consistent for the other calculations
    rectX1 = intersection_X_L; // This gets executed only once, so readability over speed!
    rectZ1 = zF;
    float scaleRatio = intersection_Y_L / intersection_Y_R;
    rectX2 = intersection_X_R * scaleRatio;
    rectZ2 = zF               * scaleRatio;
    
    if (false)
    {
      println("Rectangulation helper coordinates:");
      println("x1: " + str(rectX1) + "; x2:" + str(rectX2));
      println("y: " + str(rectAbsY));
      println("z1: " + str(rectZ1) + "; z2:" + str(rectZ2));
    }
  }
  
  void drawTo(PGraphics g, float arbitraryDistance)
  {
    g.beginDraw();
    g.background(128);
    
    g.textureMode(NORMAL); // Um, this probably should only be set once...
    g.camera( 0, 0, 0, 0, 0, -zF, 0, 1.0, 0);
    g.perspective(openY, ratio, 0.1, 1000);
    g.beginShape();
    g.texture(input);
    g.vertex(rectX1, -rectAbsY, -rectZ1, 0, 0);
    g.vertex(rectX2, -rectAbsY, -rectZ2, 1, 0);
    g.vertex(rectX2,  rectAbsY, -rectZ2, 1, 1);
    g.vertex(rectX1,  rectAbsY, -rectZ1, 0, 1);
    g.endShape(CLOSE);
    g.endDraw();
  }
}
