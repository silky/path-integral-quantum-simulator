// CREDIT: StackOverflow user R1tschY
// https://stackoverflow.com/questions/11761703/overloading-macro-on-number-of-arguments
// 

// get number of arguments with __NARG__
#define __NARG__(...)  __NARG_I_(__VA_ARGS__,__RSEQ_N())
#define __NARG_I_(...) __ARG_N(__VA_ARGS__)
#define __ARG_N(       _1, _2, _3, _4, _5, _6, _7, _8, _9,_10,      _11,_12,_13,_14,_15,_16,_17,_18,_19,_20,      _21,_22,_23,_24,_25,_26,_27,_28,_29,_30,      _31,_32,_33,_34,_35,_36,_37,_38,_39,_40,      _41,_42,_43,_44,_45,_46,_47,_48,_49,_50,      _51,_52,_53,_54,_55,_56,_57,_58,_59,_60,      _61,_62,_63,N,...) N
#define __RSEQ_N()      63,62,61,60,                        59,58,57,56,55,54,53,52,51,50,      49,48,47,46,45,44,43,42,41,40,      39,38,37,36,35,34,33,32,31,30,      29,28,27,26,25,24,23,22,21,20,      19,18,17,16,15,14,13,12,11,10,      9,8,7,6,5,4,3,2,1,0

// general definition for any function name
#define _VFUNC_(name, n) name##n
#define _VFUNC(name, n) _VFUNC_(name, n)
#define VFUNC(func, ...) _VFUNC(func, __NARG__(__VA_ARGS__)) (__VA_ARGS__)

// AUTOMATICALLY GENERATED
#define SCD(...) VFUNC(SCD, __VA_ARGS__)
#define SCD1(A) A(#A)
#define SCD2(A, B) A(#A), B(#B)
#define SCD3(A, B, C) A(#A), B(#B), C(#C)
#define SCD4(A, B, C, D) A(#A), B(#B), C(#C), D(#D)
#define SCD5(A, B, C, D, E) A(#A), B(#B), C(#C), D(#D), E(#E)
#define SCD6(A, B, C, D, E, F) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F)
#define SCD7(A, B, C, D, E, F, G) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G)
#define SCD8(A, B, C, D, E, F, G, H) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H)
#define SCD9(A, B, C, D, E, F, G, H, I) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I)
#define SCD10(A, B, C, D, E, F, G, H, I, J) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J)
#define SCD11(A, B, C, D, E, F, G, H, I, J, K) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K)
#define SCD12(A, B, C, D, E, F, G, H, I, J, K, L) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L)
#define SCD13(A, B, C, D, E, F, G, H, I, J, K, L, M) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M)
#define SCD14(A, B, C, D, E, F, G, H, I, J, K, L, M, N) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N)
#define SCD15(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O)
#define SCD16(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P)
#define SCD17(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q)
#define SCD18(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R)
#define SCD19(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S)
#define SCD20(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S), T(#T)
#define SCD21(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S), T(#T), U(#U)
#define SCD22(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S), T(#T), U(#U), V(#V)
#define SCD23(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S), T(#T), U(#U), V(#V), W(#W)
#define SCD24(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S), T(#T), U(#U), V(#V), W(#W), X(#X)
#define SCD25(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y) A(#A), B(#B), C(#C), D(#D), E(#E), F(#F), G(#G), H(#H), I(#I), J(#J), K(#K), L(#L), M(#M), N(#N), O(#O), P(#P), Q(#Q), R(#R), S(#S), T(#T), U(#U), V(#V), W(#W), X(#X), Y(#Y)
