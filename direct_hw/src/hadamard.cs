

// IDEA: this is a module to implimnet a hadamard gate in hardware. wait for input data to be present and mlutiply with the required size of H matrix.

using System;
using KiwiSystem;

public struct Qbit { 
  public float up; 
  public float down; 
}

class hadamard
{
  [Kiwi.InputWordPort(31, 0)]
  static float up = 0; // should be complex numbers!
  [Kiwi.InputWordPort(31, 0)]
  static float down = 0;
  
  // static float sqrt2 = HprlsMathsPrimsCrude.KiwiFpSqRoot.Sqrt(2);
  static float sqrt2 = 1.41421356237f;
  
  [Kiwi.InputBitPort]
  static bool go = false;


  [Kiwi.OutputWordPort(31, 0)]
  static float upout = 0;
  [Kiwi.OutputWordPort(31, 0)]
  static float downout = 0;
  [Kiwi.OutputBitPort]
  static bool done = false;
  [Kiwi.OutputBitPort]
  static bool running = false;

  
  /*
  Matrix([a, b]).transpose() * Matrix([[1, 1], [1, -1]]) = Matrix([[a + b, a - b]])
  */
  
  static Qbit H(float up, float down) {
    Qbit ret;
    ret.up = ((up + down)/sqrt2);
    ret.down = ((up-down)/sqrt2);
    return ret;
  }
  
          

  [Kiwi.HardwareEntryPoint]
  static void Main_hw()
  {
    while (true) {
      if (go) { 
        running = true;
        done = false;
        Kiwi.Pause();
        
        Qbit output = H(up, down);
        upout = output.up;
        downout = output.down;        
        done = true;
      } else {
        Kiwi.Pause();
      }
    }
  }
  
  static void Main()
  {
    Qbit transfomed = H(1.0f, 0.0f);
    Console.WriteLine("H|1> = {0}|0> + {1}|1>", transfomed.up, transfomed.down);
  }
}
