------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--                       A D A B R O K E R . O M N I                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision: 1.4 $
--                                                                          --
--         Copyright (C) 1999-2000 ENST Paris University, France.           --
--                                                                          --
-- AdaBroker is free software; you  can  redistribute  it and/or modify it  --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. AdaBroker  is distributed  in the hope that it will be  useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with AdaBroker; see file COPYING. If  --
-- not, write to the Free Software Foundation, 59 Temple Place - Suite 330, --
-- Boston, MA 02111-1307, USA.                                              --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
--             AdaBroker is maintained by ENST Paris University.            --
--                     (email: broker@inf.enst.fr)                          --
--                                                                          --
------------------------------------------------------------------------------

with CORBA;

package body AdaBroker.Omni is

   use type CORBA.Unsigned_Long;

   --------------
   -- Align_To --
   --------------

   function Align_To
     (Size  : in CORBA.Unsigned_Long;
      Align : in Alignment_T)
      return CORBA.Unsigned_Long
   is
      Temp : CORBA.Unsigned_Long;
   begin
      Temp := Size mod CORBA.Unsigned_Long (Align);
      if Temp = 0 then
         return Size;
      else
         return Size + CORBA.Unsigned_Long (Align) - Temp;
      end if;
   end Align_To;

end AdaBroker.Omni;
