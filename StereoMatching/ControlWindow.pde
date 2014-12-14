GWindow windControl;

GCheckbox cbShowScreens;
boolean showScreens() { return cbShowScreens.isSelected(); }
GCheckbox cbShowLines;
boolean showLines() { return cbShowLines.isSelected(); }
GCheckbox cbShowTestPoint;
boolean showTestPoint() { return cbShowTestPoint.isSelected(); }
GCheckbox cbShowBackground;
boolean showBackground() { return cbShowBackground.isSelected(); }
GCheckbox cbCalcPipe;
boolean calcPipe() { return cbCalcPipe.isSelected(); }
GCheckbox cbShowRightOnly;
boolean rightOnly() { return cbShowRightOnly.isSelected(); }
GCheckbox cbShowRected;
boolean showRected() { return cbShowRected.isSelected(); }
GCheckbox cbIsoNoise;
boolean isoNoise() { return cbIsoNoise.isSelected(); }
GCheckbox cbConvPoints;
boolean showConvPoints() { return cbConvPoints.isSelected(); }

GCheckbox cbDiffVert;
boolean showDiffVert() { return cbDiffVert.isSelected(); }
GCheckbox cbDiffHori;
boolean showDiffHori() { return cbDiffHori.isSelected(); }
GCheckbox cbBrightness;
boolean showBrightness() { return cbBrightness.isSelected(); }

GCustomSlider sdScreenDist;
GLabel lbSliderScreenDistNear, lbSliderScreenDist, lbSliderScreenDistFar;
GCustomSlider sdRectDist;
GLabel lbSliderRectDistNear, lbSliderRectDist, lbSliderRectDistFar;


GOption viewNormal, viewLeft, viewRight, viewMiddle;
GToggleGroup tgView;
boolean lookFromLeft() { return viewLeft.isSelected(); }
boolean lookFromRight() { return viewRight.isSelected(); }
boolean lookFromMiddle() { return viewMiddle.isSelected(); }

GSlider2D sdABChooser;
GLabel lbABChooserA, lbABChooserB;

GButton bnResetConvo;


PApplet app;

void createControlWindow()
{
  windControl = new GWindow(this, "Controls", 760, 400, 550, 340, false, JAVA2D);
   app = windControl.papplet;
  
  int x1 = 15;
  int y = 10; // Scroll right. Do it, come on.
  cbShowScreens =    new GCheckbox(app, x1, y, 200, 18, "Show screens [s]"); y += 20; // Well done.
  cbShowLines =      new GCheckbox(app, x1, y, 200, 18, "Show lines [l]"); y += 20;
  cbShowTestPoint =  new GCheckbox(app, x1, y, 200, 18, "Show test point [t]"); y += 20;
  cbShowBackground = new GCheckbox(app, x1, y, 200, 18, "Show background [b]"); y += 20;
  cbCalcPipe =       new GCheckbox(app, x1, y, 200, 18, "Pipeline calculations [p]"); y += 20;
  cbShowRightOnly =  new GCheckbox(app, x1, y, 200, 18, "Show only right screen(s) [a]"); y += 20;
  cbShowRected =     new GCheckbox(app, x1, y, 200, 18, "Show rectangulated images [r]"); y += 20;
  cbIsoNoise =       new GCheckbox(app, x1, y, 200, 18, "Simulate iso noise [n]"); y += 20;
  cbConvPoints =     new GCheckbox(app, x1, y, 200, 18, "Show convolution points [c]"); y += 20;
  // Change the default state of some of these
  toggleControl(cbShowLines);
  toggleControl(cbShowBackground);
  toggleControl(cbConvPoints);
  toggleControl(cbCalcPipe);
  
  y += 10;
  sdABChooser = new GSlider2D(app, x1, y, 160, 120);
  sdABChooser.setLimitsX(0, 0, sm.rScreenL.xRes);
  sdABChooser.setLimitsY(0, 0, sm.rScreenL.yRes);
  y += 120;
  lbABChooserA = new GLabel(app, x1, y, 160, 18, "Test point: a = 0");
  lbABChooserB = new GLabel(app, x1+110, y-70, 120, 18, "b = 0");
  lbABChooserA.setTextAlign(GAlign.CENTER, null);
  lbABChooserB.setTextAlign(GAlign.CENTER, null);
  lbABChooserB.setRotation(-PI/2, GControlMode.CENTER);
  
  y -= 10;
  //bnConvolute = new GButton(app, 250, y, 120, 24, "Convolute");
  
  // Second column
  int x2 = 220;
  y = 10;
  viewNormal = new GOption(app, x2, y, 150, 18, "View default"); y += 20;
  viewLeft =   new GOption(app, x2, y, 150, 18, "View left [hold 1]"); y += 20;
  viewRight =  new GOption(app, x2, y, 150, 18, "View right [hold 2]"); y += 20;
  viewMiddle = new GOption(app, x2, y, 150, 18, "View middle [hold 3]"); y += 20;
  tgView = new GToggleGroup();
  tgView.addControls(viewNormal, viewLeft, viewRight, viewMiddle);
  viewNormal.setSelected(true);
  
  y += 5;
  int sw = 200; // Slider width
  int lw = 80; // Label width
  lbSliderScreenDistNear = new GLabel(app, x2, y, lw, 18, "Near");
  lbSliderScreenDistNear.setTextAlign(GAlign.LEFT, null);
  lbSliderScreenDist = new GLabel(app, x2+(sw-lw)/2, y, lw, 18, "Screen dist.");
  lbSliderScreenDist.setTextAlign(GAlign.CENTER, null);
  lbSliderScreenDistFar = new GLabel(app, x2+(sw-lw), y, lw, 18, "Far");
  lbSliderScreenDistFar.setTextAlign(GAlign.RIGHT, null);
  y += 20;
  sdScreenDist = new GCustomSlider(app, x2, y, sw, 15, null);
  sdScreenDist.setLimits(sDepth, sDepth, lH); // Init, start, end
  
  y += 25;
  lbSliderRectDistNear = new GLabel(app, x2, y, lw, 18, "Near");
  lbSliderRectDistNear.setTextAlign(GAlign.LEFT, null);
  lbSliderRectDist = new GLabel(app, x2+(sw-lw)/2, y, lw, 18, "Rect. dist.");
  lbSliderRectDist.setTextAlign(GAlign.CENTER, null);
  lbSliderRectDistFar = new GLabel(app, x2+(sw-lw), y, lw, 18, "Far");
  lbSliderRectDistFar.setTextAlign(GAlign.RIGHT, null);
  y += 20;
  sdRectDist = new GCustomSlider(app, x2, y, sw, 15, null);
  sdRectDist.setLimits(0.2, 0.2, 1.0); // Init, start, end
  
  y += 20;
  cbDiffVert = new GCheckbox(app, x2, y, 200, 18, "Show vertical gradient"); y += 20;
  cbDiffHori = new GCheckbox(app, x2, y, 200, 18, "Show horizontal gradient"); y += 20;
  cbBrightness = new GCheckbox(app, x2, y, 200, 18, "Show brightness"); y += 20;
  toggleControl(cbDiffVert);
  toggleControl(cbDiffHori);
  toggleControl(cbBrightness);
  
  y += 5;
  bnResetConvo = new GButton(app, x2, y, 200, 30, "Reset convolution points");
  
  
  
  windControl.addDrawHandler(this, "drawController");
  windControl.addKeyHandler(this, "keyController");
  
  
  PApplet.useNativeSelect = true;
}

public void handleToggleControlEvents(GToggleControl option, GEvent event)
{
  
}

public void handleSliderEvents(GValueControl slider, GEvent event)
{
  if (slider == sdRectDist)
  {
    pz = sdRectDist.getValueF() * zF;
    px = sm.rScreenL.roomX(pa, pz);
    py = sm.rScreenL.roomY(pb, pz);
  }
}

public void handleSlider2DEvents(GSlider2D slider2d, GEvent event)
{
  if ((slider2d == sdABChooser) && backgroundSetupDone) // Apparently this can fire before the window creation is completed...
  {
    pa = sdABChooser.getValueXI();
    pb = sdABChooser.getValueYI();
    lbABChooserA.setText("Test Point: a = " + str(pa));
    lbABChooserB.setText("b = " + str(pb));
    pz = sdRectDist.getValueF() * zF;
    px = sm.rScreenL.roomX(pa, pz);
    py = sm.rScreenL.roomY(pb, pz);
  }
}

public void handleButtonEvents(GButton button, GEvent event)
{
  if (button == bnResetConvo)
  {
    sm.convolutionPoints = createShape();
    sm.coveredParallaxes = new boolean[sm.rScreenL.xRes];
  }
}

public void drawController(GWinApplet appc, GWinData data)
{
  appc.background(227, 230, 255);
}
public void keyController(GWinApplet appc, GWinData data, KeyEvent event)
{
  key = event.getKey();
  if (event.getAction() == KeyEvent.PRESS)
    keyPressed();
  else if (event.getAction() == KeyEvent.RELEASE)
    keyReleased();
}

void toggleControl(GToggleControl c)
{
  c.setSelected(!c.isSelected());
}
