
// This method contains an assortment of various ways to fill the background.
void createBackground()
{
   //bg = loadImage("moon-wide.jpg");
  bg = new PImage(200, 150);
  bg.loadPixels();
  boolean white = true;
  for (int i = 0; i < bg.pixels.length; i++)
  {
    white = boolean((i / bg.width) % 2);
    //bg.pixels[i] = (white ? color(255) : color(0));
    white = !white;
  }
  bg.updatePixels();
  bg = loadImage("frankreich.jpg"); 
}



float maxWeight = 5.0;
float maxDist = dist(0, 0, 0, 20, 20, 20);

float weightDiff = 0.5;
float weightCol = 0.05;

int searchDistance = 40;

float maxPointSize = PI;

float sqsum(float d1, float d2, float d3)
{
  return d1*d1 + d2*d2 + d3*d3;
}
