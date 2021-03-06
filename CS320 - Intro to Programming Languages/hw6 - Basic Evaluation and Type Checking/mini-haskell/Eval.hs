----------------------------------------------------------------
-- Computer Science 320 (Fall, 2009)
-- Concepts of Programming Languages
--
-- Assignments 6, 7, and 8
--   Eval.hs

----------------------------------------------------------------
-- Evaluation for Mini-Haskell

module Eval (evalExp) where

import Env
import Err
import Exp
import Val

----------------------------------------------------------------
-- This function is exported to the Main module.

-- Assignment 6, Problem 2, Part B
evalExp :: Exp -> Error Val
evalExp e = ev emptyEnv e

----------------------------------------------------------------
-- Functions for evaluating operations applied to values.

-- Assignment 6, Problem 1, Part A
appOp :: Oper -> Val -> Error Val
appOp Plus (VN x) = S (Partial Plus (VN x))
appOp Times (VN x) = S (Partial Plus (VN x))
appOp Equal (VN x) = S (Partial Equal (VN x))
appOp And (VB x) = S (Partial And (VB x))
appOp Or (VB x) = S (Partial Or (VB x))
appOp Not (VB x) = S (VB (not x))
appOp Cons x = S (Partial Cons x)
appOp Head (VTuple [VNil]) = S (VTuple [VNil]) 
appOp Head (VTuple (x:xs)) = S x
appOp Head (VList [VNil]) = S (VList [VNil]) 
appOp Head (VList (x:xs)) = S x
appOp Tail (VTuple [VNil]) = S (VTuple [VNil])
appOp Tail (VTuple (x:xs)) = S (VTuple xs)
appOp Tail (VList [VNil]) = S (VList [VNil])
appOp Tail (VList (x:xs)) = S (VList xs)
appOp _ _ = Error "Operator is not defined for that value.a"

-- Assignment 6, Problem 1, Part B
appBinOp :: Oper -> Val -> Val -> Error Val
appBinOp Plus (VN x) (VN y) = S (VN (x + y))
appBinOp Times (VN x) (VN y) = S (VN (x * y))
appBinOp Equal (VN x) (VN y) = S (VN (x * y))
appBinOp And (VB x) (VB y) = S (VB (x&&y))
appBinOp Or (VB x) (VB y) = S (VB (x||y))
appBinOp Cons (VTuple [VNil]) y = S y
appBinOp Cons x (VTuple [VNil]) = S x
appBinOp Cons (VList [VNil]) y = S y
appBinOp Cons x (VList [VNil]) = S x

appBinOp Cons (VTuple x) (VTuple y) = S (VList (concat (x:[y]) ))
appBinOp _ _ _ = Error "Operator is not defined for those values.b"

----------------------------------------------------------------
-- Function for applying one value to another.

-- Assignment 6, Problem 1, Part C
appVals :: Val -> Val -> Error Val
appVals (VOp Plus) (VN x) = appOp Plus (VN x)
appVals (Partial Plus (VN x)) (VN y) = appBinOp Plus (VN x) (VN x)
appVals (VOp Times)(VN x) = appOp Times (VN x)
appVals (Partial Times (VN x)) (VN y) = appBinOp Times (VN x) (VN y)
appVals (VOp Equal)(VN x) = appOp Equal (VN x)
appVals (Partial Equal (VN x)) (VN y) = appBinOp Equal (VN x) (VN y)
appVals (VOp And)(VB x) = appOp And (VB x)
appVals (Partial And (VN x)) (VN y) = appBinOp And (VN x) (VN y)
appVals (VOp Or) (VB x) = appOp Or (VB x)
appVals (Partial Or (VN x)) (VN y) = appBinOp Or (VN x) (VN y)
appVals (VOp Not) (VB x) = appOp Not (VB x)
appVals (VOp Cons) x = appOp Cons x
appVals (Partial Cons x) y = appBinOp Cons x y
appVals (VOp Head) (VTuple x) = appOp Head (VTuple x)
appVals (VOp Head) (VList x) = appOp Head (VList x)
appVals (VOp Tail) (VTuple x) = appOp Tail (VTuple x)
appVals (VOp Tail) (VList x) = appOp Tail (VList x)
appVals _ _ = Error "Operator is not defined for those values.c"

----------------------------------------------------------------
-- Function for evaluating an expression with no bindings or
-- variables to a value.

-- Assignment 6, Problem 1, Part D
ev0 :: Exp -> Error Val
ev0 (N x) = S (VN x)
ev0 (B x) = S (VB x)
ev0 (Op x) = S (VOp x)
ev0 (App (Op x) y) = appOp x (g (ev0 y))
ev0 (App x y) = appVals (g (ev0 x)) (g (ev0 y))
ev0 (Tuple [Nil]) = S (VTuple [VNil])
ev0 (Tuple x) = case (mapError ev0 x) of
        S l -> S (VTuple l)
        Error msg -> Error msg
ev0 (If val y z) = case (ev0 val) of
                S (VB True) -> ev0 y
                S (VB False) -> ev0 z
                _ -> Error "Operator is not defined for that value.d"
ev0 _ = Error "Operator is not defined for that value.e"
	
g :: Error a -> a
g (S z) = z
----------------------------------------------------------------
-- Function for evaluating an expression to a value. Note the
-- need for an environment to keep track of variables.

-- Assignment 6, Problem 2, Part A
ev :: Env Val -> Exp -> Error Val
ev emptyEnv x = ev0 x
ev e (Var x) = if (x == fst (head e)) then S (snd (head e)) else Error "Unable to evaluate in current enviornment."
ev e (N x) = S (VN x)
ev e (B x) = S (VB x)
ev e (Op x) = S (VOp x)
ev e (App (Op x) y) = appOp x (g (ev0 y))
ev e (App (Op x) (Var y)) = appOp x (g (ev e (Var y)))
ev e (App x (Var y)) = appVals (g (ev0 x)) (g (ev e (Var y)))
ev e (App x y) = appVals (g (ev0 x)) (g (ev0 y))
ev e (If val y z) = case (ev e val) of
                S (VB True) -> ev e y
                S (VB False) -> ev e z
                _ -> Error "Operator is not defined for that value."
ev e (Let var e1 e2) = if ((head var) == fst (head e)) then  ev [((head var), (g (ev e e1)))] e2 else Error "Unable to evaluate in current enviornment."
ev _ _ = Error "Unable to evaluate in current enviornment."


--eof
