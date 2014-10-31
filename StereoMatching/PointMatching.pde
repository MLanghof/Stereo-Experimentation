class MatchPoint
{
  float a; // Normalized coordinates!
  float b;
  float parallax;
  float score;
  
  MatchPoint(int a, int b, int parallax)
  {
    this.a = a;
    this.b = b;
    this.parallax = parallax;
    score = 0;
  }
}

class WeightField
{
  ArrayList<MatchPoint> scores; // if the number of points is known beforehand, we could just use an array.
  float maxScore;
  
  WeightField()
  {
    scores = new ArrayList<MatchPoint>();
    maxScore = -1.0E+32; // Basically negative infinty
  }
  int getSize()
  {
    return scores.size();
  }
  void addPoint(MatchPoint point) // We'll assert no null gets passed...
  {
    maxScore = max(point.score, maxScore);
    scores.add(point);
  }
  
}


// Could use a separate thread to generate a buffer of values
class MatchSuggestor
{
  WeightField previousScores;
  int maxX, maxY; // Well, not technically "max" but "max+1"
  
  float pixelSpread;
  
  MatchSuggestor(int w, int h, int spread, float scaling)
  {
    maxX = w;
    maxY = h;
    // Parallax scales with the same factor as screen dimensions (look at distanceToParallax -> F).
  }
  
  void setWeights(WeightField newScores)
  {
    previousScores = newScores;
  }
  
  MatchPoint suggestPoint()
  {
    float maxScore = previousScores.maxScore;
    MatchPoint point;
    while (true)
    {
      int index = int(random(previousScores.getSize()));
      point = previousScores.scores.get(index);
      if (random(maxScore) < point.score) break;
    }
    float theta = random(TWO_PI);
    float dist = randomGaussian() * pixelSpread;
    float a = point.a + cos(theta) * dist;
    float b = point.b + sin(theta) * dist;
    float parallax = point.parallax + randomGaussian(); // Might want to adjust this to a wider spread...
    //return new MatchPoint(a, b, parallax);
    return new MatchPoint(0, 0, 0);
  }
  
}


class PyramidDownsamplingEstimation
{
  int stepCount;
  
  ConvolutionKernel colorKernel, diffKernel;
  
  DownsamplingStep[] steps;
  
  PyramidDownsamplingEstimation(int stepCount, int width, int height, float scaling)
  {
    this.stepCount = stepCount;
    float levelWidth = width;
    float levelHeight = height;
    steps = new DownsamplingStep[stepCount];
    for (int level = 0; level < stepCount; level++)
    {
      steps[level] = new DownsamplingStep(int(levelWidth), int(levelHeight), colorKernel, diffKernel);
      levelWidth /= scaling;
      levelHeight /= scaling;
    }
  }
  
  void setConvolutionKernels(ConvolutionKernel colorKernel, ConvolutionKernel diffKernel)
  {
    this.colorKernel = colorKernel;
    this.diffKernel = diffKernel;
  }
  
}
    
class DownsamplingStep
{
  color[] dataL, dataR;
  int width, height;
  
  MatchSuggestor suggestor;
  ConvolutionKernel colorKernel;
  ConvolutionKernel diffKernel;
  
  DownsamplingStep(int width, int height, ConvolutionKernel colorKernel, ConvolutionKernel diffKernel)
  {
    this.width = width;
    this.height = height;
    this.colorKernel = colorKernel;
    this.diffKernel = diffKernel;
    //suggestor = new MatchSuggestor();
  }
  
  void processData(int maxMatchingAttempts)
  {
    for (int i = 0; i < maxMatchingAttempts; i++)
    {
      MatchPoint point = suggestor.suggestPoint();
      convolute(width, int(point.a), int(point.b), int(point.a+point.parallax), int(point.b), diffKernel);
    }
  }
  
}


// Expects diffLeft and diffRight to be available
// Returns the parallax in pixels
// This return is probably insufficient later on
/*int matchPointByGrad(int a1, int b)
{
  assert(luminanceOnly);
  
  float[][] kernel = convKernel33;
  
  int paramax = 0; // Parallax of the best alignment
  float maxAlign = 0; // Value of the best alignment
  
  float tempKernel[][][] = new float[2*ck+1][2*ck+1][2];
  
  // These multiplications only need to happen once
  for (int i = -ck; i <= ck; i++)
    for (int j = -ck ; j <= ck; j++)
    {
      tempKernel[i+ck][j+ck][0] = kernel[i+ck][j+ck] * 
        diffLeft[(b+j) * camXRes + (a1 + i)][0];
      tempKernel[i+ck][j+ck][1] = kernel[i+ck][j+ck] * 
        diffLeft[(b+j) * camXRes + (a1 + i)][1];
    }
  
  for (int a2 = ck; a2 < camXRes - ck; a2++)
  {
    float align = 0;
    for (int j = -ck ; j <= ck; j++)
      for (int i = -ck; i <= ck; i++)
      {
        // Dot product gives us how much the two gradient vectors align
        align += tempKernel[i+ck][j+ck][0] *
                 diffRight[(b + j) * camXRes + (a2 + i)][0];
        align += tempKernel[i+ck][j+ck][1] *
                 diffRight[(b + j) * camXRes + (a2 + i)][1];
      }  
    if (align > maxAlign)
    {
      paramax = a2 - a1;
      maxAlign = align;
    } 
  }
  return paramax;
}*/
