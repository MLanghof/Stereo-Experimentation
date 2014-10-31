// A GPU could handle this a lot better... I know nothing about shaders though...
void firstDifferences(PImage input, PImage output, ConvolutionKernel k)//, PImage outputX, PImage outputY)
{
  float[][] kernel = k.kernel;
  int n = k.n;
  float prefactor = 1.0/k.kernelSum;
  
  assert(luminanceOnly); // I know...
  int w = input.width;
  int h = input.height;

  output.loadPixels();
  input.loadPixels();
  
  /*for (int y = n; y < h - n; y++)
    for (int x = n; x < w - n; x++)*/
  for (int y = 0; y < h; y++)
    for (int x = 0; x < w; x++)
    {
      int pos = x + y * w;
      if (y < n || y >= h-n || x < n || x >= w-n)
      {
        output.pixels[pos] = color(128, 128, 0);
        continue;
      }
      float sumH = 0;
      float sumV = 0;
      // Apply kernel
      for (int b = -n; b <= n; b++)
        for (int a = -n; a <= n; a++)
        {
          float brightness = brightness(input.pixels[pos + a + b * w]);
          sumV += brightness * kernel[a+n][b+n];
          sumH += brightness * kernel[b+n][a+n];
        }
      // Pack data into red and green values
      int r = (round(sumH * prefactor / 2.0) + 128) & 0xFF;
      int g = (round(sumV * prefactor / 2.0) + 128) & 0xFF;
      output.pixels[pos] = 255 << 24 | r << 16 | g << 8;
    }
  output.updatePixels();
}

void brightnessToBlue(PImage input, PImage output)
{
  int w = input.width;
  int h = input.height;
  input.loadPixels();
  output.loadPixels();
  for (int j = 0; j < h; j++)
    for (int i = 0; i < w; i++)
    {
      int pos = i + j * w;
      int b = (int)brightness(input.pixels[pos]);
      output.pixels[pos] += b & 0xFF; // Not sure if that's necessary...
    }
  output.updatePixels();
}


void isoNoisify()
{
  // Add some noise to the images (iso or stuff)
  imageLeft.loadPixels();
  imageRight.loadPixels();
  color c;
  for (int x = 0; x < camXRes; x++)
    for (int y = 0; y < camYRes; y++)
    {
      c = rawImageLeft.pixels[x + y * camXRes];
      c = color(
        red(c)   + (noise(x/isoScale, y/isoScale, -1000 + frameCount) - 0.5) * isoNoiseAmount, 
        green(c) + (noise(x/isoScale, y/isoScale, -2000 + frameCount) - 0.5) * isoNoiseAmount, 
        blue(c)  + (noise(x/isoScale, y/isoScale, -3000 + frameCount) - 0.5) * isoNoiseAmount);
      imageLeft.pixels[x + y * camXRes] = c;
      c = rawImageRight.pixels[x + y * camXRes];
      c = color(
        red(c)   + (noise(x/isoScale, y/isoScale, 1000 + frameCount) - 0.5) * isoNoiseAmount, 
        green(c) + (noise(x/isoScale, y/isoScale, 2000 + frameCount) - 0.5) * isoNoiseAmount, 
        blue(c)  + (noise(x/isoScale, y/isoScale, 3000 + frameCount) - 0.5) * isoNoiseAmount);
      imageRight.pixels[x + y * camXRes] = c;
    }
  imageLeft.updatePixels();
  imageRight.updatePixels();
}

// Oh you found it?
color[] dataL;
color[] dataR;

float convolute(int w, int a1, int b1, int a2, int b2, ConvolutionKernel k)
{
  int n = k.n;
  float[][] kernel = k.kernel;
  
  float align = 0;
  // I sincerely hope this gets properly unrolled...
  for (int j = -n; j <= n; j++)
    for (int i = -n; i <= n; i++)
    {
      color cL = dataL[(b1 + j) * w + (a1 + i)];
      color cR = dataR[(b2 + j) * w + (a2 + i)];
      float ker = kernel[i+n][j+n];
      // Dot product gives us how much the two gradient vectors align
      PVector gradL = new PVector(((cL >> 16) & 0xFF) - 128, ((cL >> 8 ) & 0xFF) - 128);
      PVector gradR = new PVector(((cR >> 16) & 0xFF) - 128, ((cR >> 8 ) & 0xFF) - 128);
      gradL.div(sqrt(gradL.mag()+1));
      gradR.div(sqrt(gradR.mag()+1));
      /*gradL.normalize();
      gradR.normalize();*/
      align += gradL.dot(gradR) * ker;
      //align += (((cL      ) & 0xFF) - 128) * (((cR      ) & 0xFF) - 128) * ker;
    }
  return align / k.kernelSum;
}
