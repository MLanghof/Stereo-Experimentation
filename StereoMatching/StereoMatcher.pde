class StereoMatcher
{
  StereoInput inLeft, inRight;

  // Contains original image data
  ProjectionScreen pScreenL, pScreenR;
  RectedScreen rScreenL, rScreenR;

  public StereoMatcher(StereoInput inLeft, StereoInput inRight)
  {
    this.inLeft  = inLeft;
    this.inRight = inRight;

    // Projection screens
    pScreenL = new ProjectionScreen(inLeft.resX(),  inLeft.resY(),  inLeft.openY);
    pScreenL.setProjection(inLeft.xOffset(),  0, 0, inLeft.delta );
    pScreenR = new ProjectionScreen(inRight.resX(), inRight.resY(), inRight.openY);
    pScreenR.setProjection(inRight.xOffset(), 0, 0, inRight.delta);
    
    // Rected screens
    int scale = 2;
    rScreenL = new RectedScreen(pScreenL, inLeft.resX()/scale, camYRes/scale);
    rScreenR = new RectedScreen(pScreenR, camXRes/scale, camYRes/scale);
    
    // Temporary solution to have the pixel values available without the constant need for loadPixels()
    dataL = new color[camXRes/scale * camYRes/scale];
    dataR = new color[camXRes/scale * camYRes/scale];
    
    
    convolutionPoints = createShape();
    coveredParallaxes = new boolean[rScreenL.xRes];
  }




  PShape convolutionPoints;
  boolean[] coveredParallaxes;

  void fixedDistanceConvolution(int parallax)
  {
    ConvolutionKernel k = ConvolutionKernel.Gauss33;
    RectedScreen r1 = rScreenL;
    RectedScreen r2 = rScreenR;
    int n = k.n;
    int xRes = r1.xRes; // I'll save myself the bunch of assertions.
    int yRes = r1.yRes;

    int now = millis();
    if (abs(parallax) >= xRes - n) return;
    float distance = parallaxToDistance(parallax, r1, r2);

    // Parallax can still be negative
    int limit1 = max(parallax + n, n); // Needs to be > n
    int limit2 = min(xRes - n + parallax, xRes - n); // Do not exceed camXRes - n
    convolutionPoints.beginShape(POINTS);
    convolutionPoints.strokeWeight(2);
    convolutionPoints.stroke(255);
    for (int b = n; b < yRes - n; b += 1) // Rows first for better cache effects
      for (int a = limit1; a < limit2; a += 1)
      {
        float score = 0;
        if (!coveredParallaxes[parallax])
        {
          score = convolute(xRes, a, b, a-parallax, b, k);
          if (score > 5)
          {
            convolutionPoints.stroke(score*10);
            convolutionPoints.vertex(rScreenL.roomX(a, distance), 
            -rScreenL.roomY(b, distance), 
            -distance + 2); // Reducing z fighting a bit
          }
        }

        if ((a == pa) && (b == pb))
        {
          vectors = createShape();
          vectors.beginShape(LINES);
          vectors.strokeWeight(1);
          if (!rightOnly())
          {
            vectors.stroke(0, 0, 255, 128);
            drawVectors(a, b, distance, rScreenL, dataL, n);
          }
          vectors.stroke(255, 0, 0, 128);
          drawVectors(a-parallax, b, distance, rScreenR, dataR, n);
          vectors.endShape();
          println("Matching score at test point: " + str(score));
        }
      }
    convolutionPoints.endShape();
    if (!coveredParallaxes[parallax])
      println("Convolution with parallax " + str(parallax) +
        " took " + str(millis() - now) + " ms");  
    coveredParallaxes[parallax] = true;
  }
}
