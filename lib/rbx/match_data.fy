class MatchData {
   """
   MatchData instances are created when using the #=== match operator
   (e.g. by using match/case expressions).
   """

   ruby_alias: 'size
   ruby_alias: '[]

   def at: idx {
     """
     @idx Index of value to get.
     @return Value at index @idx.
     """

     self[idx]
   }

   def to_a {
     """
     @return @Array@ representation of @self containing matched values of @self.
     """

     arr = []
     self size times: |i| {
       arr << (at: i)
     }
     arr
   }

   def first {
     at: 0
   }

   def second {
     at: 1
   }

   def third {
     at: 2
   }

   def fourth {
     at: 3
   }
}