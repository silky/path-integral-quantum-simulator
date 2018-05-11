using System;
// using System.Numerics; // no complex impl in kiwi yet - I should add that
// using System.Collections; // cannot use bitarray.
using KiwiSystem;

class Complex {
  
  public double real, imag;
  
  public Complex(double real_, double imag_) {
    real = real_;
    imag = imag_;
  }
  
  public static Complex operator +(Complex c1, Complex c2)
  {
      return new Complex(c1.real + c2.real, c1.imag + c2.imag);
  }
  
  public static Complex operator *(Complex c1, Complex c2)
  {
      return new Complex(
        c1.real * c2.real - c1.imag * c2.imag,
        c1.real * c2.imag + c1.imag * c2.real);
  }

  public static Complex operator *(Complex c1, Double f2)
  {
      return new Complex(c1.real * f2, c1.imag * f2);
  }
}

enum Op {Idty, H, CNOT};

class CircuitOp {
  
  public Op op;
  public int[] qubits;
  
  public CircuitOp(Op op_, int[] qubits_) {
    op = op_;
    qubits = qubits_;
  }
}


class s {
  public const uint BSIZE = 12;
};

class MINSTD_revised {
  const uint a = 48271;  // revised
  const uint n = 0x7fffffff; // M31
  const uint g = 16807;
  
  static UInt32 state = 100;
  
  static void init(UInt32 seed) { state = seed; }
  
  static public UInt32 lcg_parkmiller() {
    UInt32 nextstate = (UInt32)(((UInt64)state * a) %  n);
    state = nextstate;
    return nextstate;
  }
  
}

class qsim
{
    [Kiwi.InputWordPort(31, 0)]
    static uint finaltarget = 0;

    [Kiwi.OutputWordPort(31, 0)] 
    static float outreal = 0;
    
    [Kiwi.OutputWordPort(31, 0)] 
    static float outimag = 0;

    [Kiwi.OutputBitPort]
    static bool done = false; // Signal indicating when result is ready

    public static int partial_trace(int state, int[] qubits) { // partial trace of a basis state only!
      int result = 0;
      // do the trace
      bool isset;
      for (int i=0; i<qubits.Length; i++) {
        isset = (state & (1 << qubits[i])) != 0;
        result = (result << 1) + (isset ? 1 : 0);
      }
      
      return result;
    }
    
    public static int insert_bit(int state, bool bit, int loc) {
      int mask = ~(1 << loc);
      return (state & mask) ^ ((bit ? 1 : 0) << loc);
    }
    
    public static int insert_bits(int state, int newstate, int[] qubits) {
      for (int i=0; i<qubits.Length; i++) {
        state = insert_bit(state, (newstate & (1 << i)) != 0, qubits[i]);
      } 
      return state;
    }
    
    public static int[] state_ball(int state, int[] qubits) {
      int nstates = (1<<qubits.Length);
      // Console.WriteLine("nstates {0}", nstates);
      int[] states = new int[nstates];
      for (int insertbits=0; insertbits<nstates; insertbits++) {
        states[insertbits] = state;
        for (int i=0; i<qubits.Length; i++) {
          bool bit = (insertbits & (1 << i)) != 0;
          // Console.WriteLine("insering bit {0}", bit); // good.
          states[insertbits] = insert_bit(states[insertbits], bit, qubits[i]);
        }
      } 
      return states;
    }
    
    static Complex sqrt22 = new Complex(0.707106781, 0.0);
    public static Complex H_select(int input_state, Complex input_amp, int targetstate) {
      if (targetstate == 0) { 
        // for either input state it is the same.
        return input_amp * sqrt22;
      } else { // input "down"
        return input_amp * sqrt22 * (input_state == 0 ? 1 : -1);
      }
    }

    static Complex zero = new Complex(0.0, 0.0);
    public static Complex CNOT_select(int input_state, Complex input_amp, int targetstate) {
      switch (targetstate)
      {
          case 0:
              return (input_state == 0) ?  input_amp : zero;
              break; // for style?
          case 1:
              return (input_state == 1) ?  input_amp : zero;
              break; 
          case 2:
              // note the swap of 2/3!
              return (input_state == 3) ?  input_amp : zero;
              break; 
          case 3:
              return (input_state == 2) ?  input_amp : zero;
              break;
          default:
              return new Complex(999999.0, 999999.0); // poison
      }      
    }
    
    //static int debuglevel = 0;
    
    public static Complex CalcAmp(CircuitOp[] remaining_circuit, int circuitpos, int inital_state, int target_state) {
    
      // class-based dynamic dispatch errors out if the return value from this wunction is created with operator new inside a branch that is conditional on remaining_circuit.Length.
      // so 
      double realpart, imagpart;
      if (circuitpos == 0) { 
        //Console.WriteLine("{0}Base case for target {1}", new string (' ', debuglevel), target_state);
        realpart = (target_state == inital_state) ? 1.0 : 0.0;
        imagpart = 0.0;
      } else {
        //Console.WriteLine("{0}evaluating for lvl {1} target {2}", new string (' ', debuglevel), circuitpos, target_state);
        CircuitOp current_gate = remaining_circuit[circuitpos-1];
        int[] predecessors = state_ball(target_state, current_gate.qubits);
        
        Complex[] predecessor_amp = new Complex[predecessors.Length];
        for (int i=0; i<predecessors.Length; i++) {
          Kiwi.Pause();
          //debuglevel += 1;
          predecessor_amp[i] = CalcAmp(remaining_circuit, circuitpos-1, inital_state, predecessors[i]);
          //debuglevel -= 1;
        }
        
        Complex resamp = zero;
        for (int i=0; i<predecessors.Length; i++) {
          switch (current_gate.op)
          {
              case Op.H:
                  resamp = resamp + H_select(
                                        partial_trace(predecessors[i],                           current_gate.qubits),
                                        predecessor_amp[i],
                                        partial_trace(target_state,                              current_gate.qubits)
                                            );
                  break;
              case Op.CNOT:
                  resamp = resamp + CNOT_select(
                                        partial_trace(predecessors[i],                           current_gate.qubits),
                                        predecessor_amp[i],
                                        partial_trace(target_state,                              current_gate.qubits)
                                            );
                  break;
              default:
                Console.WriteLine("UNKNOWN OPERATION!");
                break;
          }
        }
        
        realpart = resamp.real; //(target_state == inital_state) ? 1.0 : 0.0;
        imagpart = resamp.imag;
      }

      return new Complex(realpart, imagpart);
    }

    public unsafe struct WorkUnit  
    {  
      public int target;  
      public int depth;
      
      public bool dep_done_0;
      public bool dep_done_1;
      public bool dep_done_2;
      public bool dep_done_3;
      
      public int dep_target_0;
      public int dep_target_1;
      public int dep_target_2;
      public int dep_target_3;

      public Complex dep_amp_0;
      public Complex dep_amp_1;
      public Complex dep_amp_2;
      public Complex dep_amp_3;
    }
    
    static public void wuDefault(ref WorkUnit ret) {
      ret.target = 0; ret.depth = 0;
      ret.dep_done_0 = false; ret.dep_done_1 = false; ret.dep_done_2 = false; ret.dep_done_3 = false;
      ret.dep_target_0 = 0; ret.dep_target_1 = 0; ret.dep_target_2 = 0; ret.dep_target_3 = 0;
      ret.dep_amp_0 = zero; ret.dep_amp_1 = zero; ret.dep_amp_2 = zero; ret.dep_amp_3 = zero;
    }

    public static WorkUnit add_preds(ref WorkUnit current, CircuitOp gate) {
      
      int[] predecessors = state_ball(current.target, gate.qubits);
      switch (gate.op)
      {
          case Op.H:
              current.dep_done_0 = false; current.dep_done_1 = false;
              current.dep_done_2 = true; current.dep_done_3 = true;
              
              current.dep_target_0 = predecessors[0]; current.dep_target_1 = predecessors[1];
              current.dep_target_2 = 0; current.dep_target_3 = 0;
              break;
          case Op.CNOT:
              current.dep_done_0 = false; current.dep_done_1 = false;
              current.dep_done_2 = false; current.dep_done_3 = false;
              
              current.dep_target_0 = predecessors[0]; current.dep_target_1 = predecessors[1];
              current.dep_target_2 = predecessors[0]; current.dep_target_3 = predecessors[1];
              break;
          default:
            Console.WriteLine("UNKNOWN OPERATION!");
            break;
      }
      return current;
    }
    
    public static bool can_evaluate(WorkUnit current) {
      return current.dep_done_0 & current.dep_done_1 & current.dep_done_2 & current.dep_done_3;
    }
    
    public static Complex evaluate(WorkUnit current, CircuitOp current_gate) {
      Complex resamp = zero;
      
      switch (current_gate.op)
      {
          case Op.H:
            resamp = resamp + H_select(
                                  partial_trace(current.dep_target_0, current_gate.qubits),
                                  current.dep_amp_0,
                                  partial_trace(current.target, current_gate.qubits));
            
            resamp = resamp + H_select(
                                  partial_trace(current.dep_target_1, current_gate.qubits),
                                  current.dep_amp_1,
                                  partial_trace(current.target, current_gate.qubits));
            break;
          
          case Op.CNOT:
            resamp = resamp + CNOT_select(
                                  partial_trace(current.dep_target_0, current_gate.qubits),
                                  current.dep_amp_0,
                                  partial_trace(current.target, current_gate.qubits));
            
            resamp = resamp + CNOT_select(
                                  partial_trace(current.dep_target_1, current_gate.qubits),
                                  current.dep_amp_1,
                                  partial_trace(current.target, current_gate.qubits));
            
            resamp = resamp + CNOT_select(
                                  partial_trace(current.dep_target_2, current_gate.qubits),
                                  current.dep_amp_2,
                                  partial_trace(current.target, current_gate.qubits));
            
            resamp = resamp + CNOT_select(
                                  partial_trace(current.dep_target_3, current_gate.qubits),
                                  current.dep_amp_3,
                                  partial_trace(current.target, current_gate.qubits));

            break;
          default:
            Console.WriteLine("UNKNOWN OPERATION!");
            break;
      }
      return resamp;
    }
    
    public static Complex CalcAmpFlat(CircuitOp[] remaining_circuit, int circuitpos, int inital_state, int target_state) {
      int curridx = -1; // number of active elements in the queue.
      WorkUnit[] worklist = new WorkUnit[16];
      
      CircuitOp current_gate = remaining_circuit[circuitpos-1];
      // wuDefault(ref worklist[0]); // ref types don't work in Kiwi, fine
      // WorkUnit firstelement = wuDefault();
      worklist[0].target = target_state;
      worklist[0].depth = circuitpos;
      // add_preds(ref worklist[0], current_gate);
      
      
      curridx = 0; // if -1, return.
      WorkUnit current;
      Complex lasteval;
      // while (curridx > 0) { // valid indices for the work list
      //   Kiwi.Pause();
      //   current = worklist[curridx-1];
      //   current_gate = remaining_circuit[curridx-1];
      //   if (can_evaluate(current)) {
      //     lasteval = evaluate(current, current_gate);
      //     curridx -= 1; // pop off the stack.
      //   } else {
      //     Console.WriteLine("need to addd to the worklist, cant do that yet!");
      //     curridx -= 1;
      //   }
      // }
      
      Console.WriteLine("RAN OFF THE END OF THE WORKLIST!");
      return new Complex(0.0, 0.0);
    }

    
    [Kiwi.HardwareEntryPoint]
    static void Main()
    {
      CircuitOp[] circuit = new CircuitOp[2];
      circuit[0] = new CircuitOp(Op.H, new int[] { 0 });
      circuit[1] = new CircuitOp(Op.H, new int[] { 1 });
      
      // circuit[2] = new CircuitOp(Op.CNOT, new int[] { 1, 0 });
      // 
      // 
      // circuit[3] = new CircuitOp(Op.H, new int[] { 0 });
      // circuit[4] = new CircuitOp(Op.H, new int[] { 1 });
      
      int tgt=0;
      Complex res = CalcAmpFlat(circuit, circuit.Length, 0, tgt);
      Console.WriteLine("HH|{0}> on |0> is {1}", tgt, res.real);


      
      // Complex res = H_select(0, new Complex(1.0, 0.0), 0);
      // for (int tgt=0; tgt<4; tgt++) {
      //   Complex res = CalcAmp(circuit, circuit.Length, 2, tgt);
      //   Console.WriteLine("H|{0}> on |2> is {1}", tgt, res.real);
      // }
      
      // Console.WriteLine("0 with bit set at idx 1 is {0}", insert_bit(0, true, 1)  ); // true
      // 
      // Console.WriteLine("0 with bit set at idx 1 is {0}", insert_bit(0, false, 1)  ); // false, does not clear the bit.
      // 
      // Console.WriteLine("trace of 1 out of |010> is {0}", partial_trace(2, new int[] {1}));
      // 
      // 
      // Console.WriteLine("stateball for |000> on pos 1 is");
      // int[] stateball = state_ball(0, new int[] {1});
      // for (int i=0; i<stateball.Length; i++) {
      //   Console.WriteLine("|{0}>", stateball[i]);
      // }
      done = true;
    }

}
