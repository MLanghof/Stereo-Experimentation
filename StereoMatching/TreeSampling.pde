import java.util.TreeMap;

class TreeSampler<Entry>
{
  TreeMap<Float, Entry> entries;
  float totalScore;
  
  public TreeSampler()
  {
    entries = new TreeMap<Float, Entry>();
    totalScore = 0;
  }
  
  public void addEntry(Entry point, float score)
  {
    totalScore += score;
    entries.put(totalScore, point);
  }
  
  public Entry samplePoint()
  {
    float r = random(totalScore);
    
    return entries.higherEntry(r).getValue();
  }
}
