------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--                        B R O C A . B U F F E R S                         --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                            $Revision: 1.14 $
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

with Ada.Unchecked_Deallocation;

package Broca.Buffers is

   pragma Elaborate_Body;

   --  True if this machine use little endian byte order.
   Is_Little_Endian : Boolean;

   type Buffer_Descriptor is private;

   --  Buffer to/from network before unmarshalling or after marshalling.
   --  Must start at 0, according to CORBA V2.2 13.3

   type Byte is mod 2 ** 8;
   type Buffer_Index_Type is mod 2 ** 32;
   type Buffer_Type is array (Buffer_Index_Type range <>) of Byte;
   type Buffer_Ptr is access Buffer_Type;

   subtype Alignment_Type is Buffer_Index_Type range 1 .. 8;

   procedure Align_Size
     (Buffer    : in out Buffer_Descriptor;
      Alignment : in Alignment_Type);
   pragma Inline (Align_Size);
   --  Align Buffer size to Alignment

   procedure Allocate_Buffer (Buffer : in out Buffer_Descriptor);
   --  Allocate the buffer using pos and clear pos. Use local endianess.

   procedure Allocate_Buffer_And_Clear_Pos
     (Buffer : in out Buffer_Descriptor;
      Size   : in Buffer_Index_Type);
   --  Be sure Buffer.Buffer is at least of length Size.  Set
   --  Buffer.Pos to 0. Endianess is already set.

   procedure Append_Buffer
     (Target : in out Buffer_Descriptor;
      Source : in Buffer_Descriptor);
   --  Append Source into Target

   procedure Compute_New_Size
     (Target : in out Buffer_Descriptor;
      Source : in Buffer_Descriptor);
   --  Compute new size of Target when Source appended

   procedure Compute_New_Size
     (Buffer : in out Buffer_Descriptor;
      Align  : in Alignment_Type;
      Size   : in Buffer_Index_Type);

   procedure Copy
     (Source : in Buffer_Descriptor;
      Target : out Buffer_Descriptor);

   procedure Destroy (Buffer : in out Buffer_Descriptor);

   procedure Dump (Buffer : in Buffer_Type);
   --  Display Buffer

   procedure Extract_Buffer
     (Target : in out Buffer_Descriptor;
      Source : in out Buffer_Descriptor;
      Length : in Buffer_Index_Type);
   --  Extract Length bytes from Source, update position of Source and
   --  copy it to Target. Pos is reset before copying and not updated,
   --  and Little_Endian flag is copied from Source.

   function Get_Endianess (Buffer : Buffer_Descriptor) return Boolean;

   procedure Read
     (Buffer  : in out Buffer_Descriptor;
      Bytes   : out Buffer_Type);
   pragma Inline (Read);
   --  Read from Buffer an array of bytes

   procedure Rewind (Buffer : in out Buffer_Descriptor);
   --  Rewind buffer from beginning

   procedure Set_Endianess
     (Buffer        : in out Buffer_Descriptor;
      Little_Endian : in Boolean);

   function Size_Left (Buffer : Buffer_Descriptor) return Buffer_Index_Type;
   function Full_Size (Buffer : Buffer_Descriptor) return Buffer_Index_Type;
   function Size_Used (Buffer : Buffer_Descriptor) return Buffer_Index_Type;

   procedure Skip_Bytes
     (Buffer : in out Buffer_Descriptor;
      Size   : in Buffer_Index_Type);

   procedure Show (Buffer : in Buffer_Descriptor);

   procedure Write
     (Buffer  : in out Buffer_Descriptor;
      Bytes   : in Buffer_Type);
   pragma Inline (Write);
   --  Write into Buffer an array of bytes

private

   procedure Free is
      new Ada.Unchecked_Deallocation (Buffer_Type, Buffer_Ptr);

   --  A buffer with the current position, as needed by unmarshall and
   --  endianness.
   type Buffer_Descriptor is
      record
         Pos           : Buffer_Index_Type := 0;
         Little_Endian : Boolean := False;
         Write         : Boolean := True;
         Buffer        : Buffer_Ptr := null;
      end record;

end Broca.Buffers;
