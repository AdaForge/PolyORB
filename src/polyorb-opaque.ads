------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                       P O L Y O R B . O P A Q U E                        --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                Copyright (C) 2001 Free Software Fundation                --
--                                                                          --
-- PolyORB is free software; you  can  redistribute  it and/or modify it    --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. PolyORB is distributed  in the hope that it will be  useful,    --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with PolyORB; see file COPYING. If    --
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
--              PolyORB is maintained by ENST Paris University.             --
--                                                                          --
------------------------------------------------------------------------------

--  Storage of opaque data.

--  $Id: //droopi/main/src/polyorb-opaque.ads#4 $

with Ada.Streams; use Ada.Streams;
with Ada.Unchecked_Deallocation;

package PolyORB.Opaque is

   pragma Preelaborate;

   type Zone_Access is access all Stream_Element_Array;
   --  A storage zone: an array of bytes.

   procedure Free is new Ada.Unchecked_Deallocation
     (Stream_Element_Array, Zone_Access);

   type Opaque_Pointer is record
      Zone : Zone_Access;
      --  The storage zone wherein the data resides.

      Offset : Stream_Element_Offset;
      --  The position of the first data element within the zone.

   end record;

   function "+" (P : Opaque_Pointer; Ofs : Stream_Element_Offset)
                return Opaque_Pointer;
   pragma Inline ("+");
   --  Add Ofs to P.Offset.

   subtype Alignment_Type is Stream_Element_Offset range 1 .. 8;

end PolyORB.Opaque;
