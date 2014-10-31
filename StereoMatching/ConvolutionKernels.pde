static class ConvolutionKernel
{
  final int n; // kernel will be (2*n+1)x(2*n+1) or s x s
  final int s; // 2 * n + 1
  final float[][] kernel; // It's not technically required for these to be two-dimensional
  final float kernelSum; // None of this needs to be float, but maybe later...
  
  public ConvolutionKernel(int size, float[][] kernel)
  {
    n = size;
    s = 2 * n + 1;
    float kernelTempSum = 0;
    
    this.kernel = new float[s][s];
    for (int i = 0; i < s; i++)
      for (int j = 0; j < s; j++)
      {
        this.kernel[i][j] = kernel[i][j];
        kernelTempSum += abs(kernel[i][j]); 
      }
    kernelSum = kernelTempSum; // How about letting me change it as long as I'm in the constructor, even if it's "final"?
  }
  
  
  static final ConvolutionKernel Gauss33 = new ConvolutionKernel(
    1, new float[][] { { 1, 2, 1 },
                       { 2, 4, 2 },
                       { 1, 2, 1 } });
  static final ConvolutionKernel Gauss55 = new ConvolutionKernel(
    2, new float[][] { { 1,  4,  7,  4,  1 },
                       { 4, 16, 26, 16,  4 },
                       { 7, 26, 41, 26,  7 },
                       { 4, 16, 26, 16,  4 },
                       { 1,  4,  7,  4,  1 } });
                       
  static final ConvolutionKernel Scharr33 = new ConvolutionKernel(
    1, new float[][] { { -1, 0, 1 },
                       { -3, 0, 3 },
                       { -1, 0, 1 } });
  
  static final ConvolutionKernel Scharr55 = new ConvolutionKernel(
    2, new float[][] { { -1, -1, 0, 1, 1 },
                       { -2, -2, 0, 2, 2 },
                       { -3, -6, 0, 6, 3 },
                       { -2, -2, 0, 2, 2 },
                       { -1, -1, 0, 1, 1 } });
}

/*
  public ConvolutionKernel(int size, float[][] kernel, float sum)
  {
    n = size;
    s = 2 * n + 1;
    kernelSum = sum;
    
    this.kernel = new float[s][s];
    for (int i = 0; i < s; i++)
      for (int j = 0; j < s; j++)
      {
        this.kernel[i][j] = kernel[i][j]; 
      }
  }*/
