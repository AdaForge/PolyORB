------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--                         B R O C A . O B J E C T                          --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision: 1.10 $
--                                                                          --
--            Copyright (C) 1999 ENST Paris University, France.             --
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
with Broca.IOP;
with Broca.Buffers; use Broca.Buffers;

package body Broca.Object is

   ----------------------
   -- Compute_New_Size --
   ----------------------

   procedure Compute_New_Size
     (Buffer : in out Buffer_Descriptor;
      Value  : in Broca.Object.Object_Type) is
      A_Buf : Buffer_Descriptor;
      Old_Size : Buffer_Index_Type := Full_Size (Buffer);
   begin
      Encapsulate_IOR (A_Buf, Old_Size, Value);
      --  XXX should cache A_Buf in object for subsequent call to
      --  Marshall.
      Skip_Bytes (Buffer, Full_Size (A_Buf) - Old_Size);
      Destroy (A_Buf);
   end Compute_New_Size;

   --------------
   -- Marshall --
   --------------

   procedure Marshall
     (Buffer : in out Buffer_Descriptor;
      Value  : in Broca.Object.Object_Type) is
   begin
      --  XXX Check:
      --  Value of "From" parameter (0);
      --  Potential exception (if Get (Value) cannot be
      --  narrowed to Object_Type)
      Encapsulate_IOR (Buffer, Size_Used (Buffer), Value);
   end Marshall;

   ----------------
   -- Unmarshall --
   ----------------

   procedure Unmarshall
     (Buffer : in out Buffer_Descriptor;
      Result : out Broca.Object.Object_Type) is
   begin
      Decapsulate_IOR (Buffer, Result);
   end Unmarshall;

   ------------------
   -- Find_Profile --
   ------------------

   function Find_Profile (Object : Object_Ptr) return IOP.Profile_Ptr is
   begin
      return Object.Profiles (Object.Profiles'First);
   end Find_Profile;

   ---------------------
   -- Encapsulate_IOR --
   ---------------------

   procedure Encapsulate_IOR
     (Buffer : in out Buffers.Buffer_Descriptor;
      From   : in Buffer_Index_Type;
      Object : in Object_Type'Class)
   is
   begin
      IOP.Encapsulate_IOR (Buffer, From, Object.Type_Id, Object.Profiles);
   end Encapsulate_IOR;

   ---------------------
   -- Decapsulate_IOR --
   ---------------------

   procedure Decapsulate_IOR
     (Buffer : in out Buffers.Buffer_Descriptor;
      Object : out Object_Type'Class)
   is
   begin
      IOP.Decapsulate_IOR (Buffer, Object.Type_Id, Object.Profiles);
   end Decapsulate_IOR;

end Broca.Object;
