-- |
-- Module: Utils
-- Description: Utility bounded-list functions (e.g., folds, scans, etc.)
-- Copyright: (c) 2011 National Institute of Aerospace / Galois, Inc.
--
-- Utility bounded-list functions (e.g., folds, scans, etc.)

module Copilot.Library.Utils
       ( -- * Functions similar to the Prelude functions on lists
         take, tails, cycle,
         -- ** Folds
         nfoldl, nfoldl1, nfoldr, nfoldr1,
         -- ** Scans
         nscanl, nscanr, nscanl1, nscanr1,
         -- ** Indexing
         case', (!!))
where

import Copilot.Language
import qualified Prelude as P

tails :: ( Typed a )
         => Stream a -> [ Stream a ]
tails s = [ drop x s | x <- [ 0 .. ] ]


take :: ( Integral a, Typed b )
        => a -> Stream b -> [ Stream b ]
take n s = P.take ( fromIntegral n ) $ tails s

nfoldl :: ( Typed a, Typed b )
          => Int -> ( Stream a -> Stream b -> Stream a )
                 ->   Stream a -> Stream b -> Stream a
nfoldl n f e s = foldl f e $ take n s

nfoldl1 :: ( Typed a )
           => Int -> ( Stream a -> Stream a -> Stream a )
                  ->   Stream a -> Stream a
nfoldl1 n f s = foldl1 f $ take n s

nfoldr :: ( Typed a, Typed b )
          => Int -> ( Stream a -> Stream b -> Stream b )
                 ->   Stream b -> Stream a -> Stream b
nfoldr n f e s = foldr f e $ take n s

nfoldr1 :: ( Typed a )
           => Int -> ( Stream a -> Stream a -> Stream a )
                  ->   Stream a -> Stream a
nfoldr1 n f s = foldr1 f $ take n s

nscanl :: ( Typed a, Typed b )
          => Int -> ( Stream a -> Stream b -> Stream a )
          -> Stream a -> Stream b -> [ Stream a ]
nscanl n f e s = scanl f e $ take n s

nscanr :: ( Typed a )
          => Int -> ( Stream a -> Stream b -> Stream b )
          -> Stream b -> Stream a -> [ Stream b ]
nscanr n f e s = scanr f e $ take n s

nscanl1 :: ( Typed a )
           => Int -> ( Stream a -> Stream a -> Stream a )
           -> Stream a -> [ Stream a ]
nscanl1 n f s = scanl1 f $ take n s

nscanr1 :: ( Typed a )
           => Int -> ( Stream a -> Stream a -> Stream a )
           -> Stream a -> [ Stream a ]
nscanr1 n f s = scanr1 f $ take n s


-- | Case-like function: The index of the first predicate that is true
-- in the predicate list selects the stream result. If no predicate
-- is true, the last element is chosen (default element)
case' :: ( Typed a )
         => [ Stream Bool ] -> [ Stream a ] -> Stream a
case' predicates alternatives =
  let case'' []         ( default' : _ ) = default'
      case'' ( p : ps ) ( a : as )       = mux p a ( case'' ps as )
      case'' _          _                =
        badUsage $ "in case' in Utils library: "
                   P.++ "length of alternatives list is not "
                   P.++ "greater by one than the length of predicates list"
  in case'' predicates alternatives

-- | Index.  WARNING: Very expensive!  Consider using this only for very short
-- lists.
(!!) :: (Typed a, Eq b, Num b, Typed b) => [Stream a] -> Stream b -> Stream a
ls !! n = let indices      = map
                             ( constant . fromIntegral )
                             [ 0 .. P.length ls - 1 ]
              select [] _  = last ls
              select
                ( i : is )
                ( x : xs ) = mux ( i == n ) x ( select is xs )
                             -- should not happen
              select _ []  = badUsage ("in (!!) defined in Utils.hs " P.++
                               "in copilot-libraries")
          in if null ls then
               badUsage ("in (!!) defined in Utils.hs " P.++
                            "indexing the empty list with !! is not defined")
             else
               select indices ls

cycle :: ( Typed a ) => [ a ] -> Stream a
cycle ls = cycle'
  where cycle' = ls ++ cycle'
