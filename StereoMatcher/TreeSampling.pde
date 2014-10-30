import java.util.TreeMap;

class PointSampler
{
  TreeMap<Float, PVector> entries;
  float totalScore;
  
  public PointSampler()
  {
    entries = new TreeMap<Float, PVector>();
    totalScore = 0;
  }
  
  public void addEntry(PVector point, float score)
  {
    totalScore += score;
    entries.put(totalScore, point);
  }
  
  public PVector samplePoint()
  {
    float r = random(totalScore);
    
    return entries.higherEntry(r).getValue();
  }
}
