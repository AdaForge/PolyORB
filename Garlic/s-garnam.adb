------------------------------------------------------------------------------
--                                                                          --
--                            GLADE COMPONENTS                              --
--                                                                          --
--                 S Y S T E M . G A R L I C . N A M I N G                  --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision$
--                                                                          --
--         Copyright (C) 1996-1998 Free Software Foundation, Inc.           --
--                                                                          --
-- GARLIC is free software;  you can redistribute it and/or modify it under --
-- terms of the  GNU General Public License  as published by the Free Soft- --
-- ware Foundation;  either version 2,  or (at your option)  any later ver- --
-- sion.  GARLIC is distributed  in the hope that  it will be  useful,  but --
-- WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHANTABI- --
-- LITY or  FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public  --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License  distributed with GARLIC;  see file COPYING.  If  --
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
--               GLADE  is maintained by ACT Europe.                        --
--               (email: glade-report@act-europe.fr)                        --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Exceptions;
with GNAT.OS_Lib;              use GNAT.OS_Lib;
with Interfaces.C;             use Interfaces.C;
with Interfaces.C.Strings;     use Interfaces.C.Strings;
with System.Garlic.Constants;  use System.Garlic.Constants;
with System.Garlic.Debug;      use System.Garlic.Debug;
with System.Garlic.Soft_Links; use System.Garlic.Soft_Links;
with System.Garlic.Utils;      use System.Garlic.Utils;
with Unchecked_Conversion;
with Unchecked_Deallocation;

package body System.Garlic.Naming is

   use System.Garlic.Thin;

   Private_Debug_Key : constant Debug_Key :=
     Debug_Initialize ("S_GARNAM", "(s-garnam): ");
   procedure D
     (Message : in String;
      Key     : in Debug_Key := Private_Debug_Key)
     renames Print_Debug_Info;

   Default_Buffer_Size : constant := 16384;

   procedure Free is
      new Unchecked_Deallocation (char_array, char_array_access);

   function Parse_Entry (Host : Hostent)
     return Host_Entry;
   --  Parse an entry

   procedure Raise_Naming_Error
     (Errno   : in Integer;
      Message : in String);
   --  Raise the exception Naming_Error with an appropriate error message

   ----------------
   -- Address_Of --
   ----------------

   function Address_Of (Something : String) return Address is
   begin
      if Is_IP_Address (Something) then
         return Value (Something);
      else
         return Info_Of (Something) .Addresses (1);
      end if;
   end Address_Of;

   ------------
   -- Adjust --
   ------------

   procedure Adjust (Object : in out Host_Entry)
   is
      Aliases : String_Array renames Object.Aliases;
   begin
      Object.Name := new String'(Object.Name.all);
      for I in Aliases'Range loop
         Aliases (I) := new String'(Aliases (I) .all);
      end loop;
   end Adjust;

   -----------------
   -- Any_Address --
   -----------------

   function Any_Address return Address is
   begin
      return To_Address (Inaddr_Any);
   end Any_Address;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Object : in out Host_Entry)
   is
      Aliases : String_Array renames Object.Aliases;
   begin
      Free (Object.Name);
      for I in Aliases'Range loop
         Free (Aliases (I));
      end loop;
   end Finalize;

   ---------------
   -- Host_Name --
   ---------------

   function Host_Name return String
   is
      Buffer : aliased char_array (1 .. 64);
      Res    : constant int := C_Gethostname (Buffer'Address, Buffer'Length);
   begin
      if Res = Failure then
         Raise_Naming_Error (Errno, "");
      end if;
      return To_Ada (Buffer);
   end Host_Name;

   -----------
   -- Image --
   -----------

   function Image (Add : Address) return String
   is

      function Image (A : Address_Component) return String;
      --  Return the string corresponding to its argument without
      --  the leading space.

      -----------
      -- Image --
      -----------

      function Image (A : Address_Component)
        return String
      is
         Im : constant String := Address_Component'Image (A);
      begin
         return Im (Im'First + 1 .. Im'Last);
      end Image;

   begin
      return Image (Add.H1) & "." & Image (Add.H2) & "." &
        Image (Add.H3) & "." & Image (Add.H4);
   end Image;

   -------------
   -- Info_Of --
   -------------

   function Info_Of (Name : String)
     return Host_Entry
   is
      Res : Hostent_Access;
   begin
      Enter_Critical_Section;
      Res := C_Gethostbyname (To_C (Name));
      if Res = null then
         Leave_Critical_Section;
         Raise_Naming_Error (Errno, Name);
      end if;
      declare
         Result : constant Host_Entry := Parse_Entry (Res.all);
      begin
         Leave_Critical_Section;
         return Result;
      end;
   end Info_Of;

   -------------
   -- Info_Of --
   -------------

   function Info_Of (Addr : Address)
     return Host_Entry
   is
      Add : aliased In_Addr := To_In_Addr (Addr);
      Res : Hostent_Access;
   begin
      Enter_Critical_Section;
      Res := C_Gethostbyaddr (Add'Address,
                              C.int (Add'Size / CHAR_BIT),
                              Af_Inet);
      if Res = null then
         Leave_Critical_Section;
         Raise_Naming_Error (Errno, Image (Addr));
      end if;
      declare
         Result : constant Host_Entry := Parse_Entry (Res.all);
      begin
         Leave_Critical_Section;
         return Result;
      end;
   end Info_Of;

   ------------------------
   -- Info_Of_Name_Or_IP --
   ------------------------

   function Info_Of_Name_Or_IP (Something : String)
     return Host_Entry
   is
   begin
      if Is_IP_Address (Something) then
         return Info_Of (Value (Something));
      else
         return Info_Of (Something);
      end if;
   end Info_Of_Name_Or_IP;

   -------------------
   -- Is_Ip_Address --
   -------------------

   function Is_IP_Address (Something : String)
     return Boolean
   is
   begin
      for Index in Something'Range loop
         declare
            Current : Character renames Something (Index);
         begin
            if (Current < '0'
                or else Current > '9')
              and then Current /= '.' then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_IP_Address;

   -------------
   -- Name_Of --
   -------------

   function Name_Of (Something : String)
     return String
   is
      Hostent : constant Host_Entry := Info_Of_Name_Or_IP (Something);
   begin
      if Hostent.Name = null then
         Ada.Exceptions.Raise_Exception (Naming_Error'Identity,
                                         "No name for " & Something);
      end if;
      To_Lower (Hostent.Name.all);
      return Hostent.Name.all;
   end Name_Of;

   -----------------
   -- Parse_Entry --
   -----------------

   function Parse_Entry (Host : Hostent)
     return Host_Entry
   is
      C_Aliases : constant Thin.Chars_Ptr_Array    :=
        Chars_Ptr_Pointers.Value (Host.H_Aliases);
      C_Addr    : constant In_Addr_Access_Array :=
                                    In_Addr_Access_Pointers.Value
                                      (Host.H_Addr_List);
      Result    : Host_Entry (N_Aliases     => C_Aliases'Length - 1,
                              N_Addresses => C_Addr'Length - 1);
   begin
      Result.Name := new String'(Value (Host.H_Name));
      for I in 1 .. Result.Aliases'Last loop
         declare
            Index   : Natural := I - 1 + Natural (C_Aliases'First);
            Current : chars_ptr renames C_Aliases (size_t (Index));
         begin
            Result.Aliases (I) := new String'(Value (Current));
         end;
      end loop;
      for I in Result.Addresses'Range loop
         declare
            Index   : Natural := I - 1 + Natural (C_Addr'First);
            Current : In_Addr_Access renames C_Addr (Index);
         begin
            Result.Addresses (I) := To_Address (Current.all);
         end;
      end loop;
      return Result;
   end Parse_Entry;

   ------------------------
   -- Raise_Naming_Error --
   ------------------------

   procedure Raise_Naming_Error
     (Errno   : in Integer;
      Message : in String)
   is

      function Error_Message return String;
      --  Return the message according to Errno.

      -------------------
      -- Error_Message --
      -------------------

      function Error_Message return String is
      begin
         case Errno is
            when Host_Not_Found => return "Host not found";
            when Try_Again      => return "Try again";
            when No_Recovery    => return "No recovery";
            when No_Address     => return "No address";
            when others         => return "Unknown error" &
                                          Integer'Image (Errno);
         end case;
      end Error_Message;

   begin
      Ada.Exceptions.Raise_Exception (Naming_Error'Identity,
                                      Error_Message & ": " & Message);
   end Raise_Naming_Error;

   ----------------
   -- To_Address --
   ----------------

   function To_Address (Addr : In_Addr) return Address is
   begin
      return (H1 => Address_Component (Addr.S_B1),
              H2 => Address_Component (Addr.S_B2),
              H3 => Address_Component (Addr.S_B3),
              H4 => Address_Component (Addr.S_B4));
   end To_Address;

   ----------------
   -- To_In_Addr --
   ----------------

   function To_In_Addr (Addr : Address) return In_Addr is
   begin
      return (S_B1 => unsigned_char (Addr.H1),
              S_B2 => unsigned_char (Addr.H2),
              S_B3 => unsigned_char (Addr.H3),
              S_B4 => unsigned_char (Addr.H4));
   end To_In_Addr;

   -----------
   -- Value --
   -----------

   function Value (Add : String) return Address
   is
      function Convert is
         new Unchecked_Conversion (Source => Interfaces.Unsigned_32,
                                   Target => In_Addr);
      Converted : constant In_Addr := Convert (C_Inet_Addr (To_C (Add)));
   begin
      return (H1 => Address_Component (Converted.S_B1),
              H2 => Address_Component (Converted.S_B2),
              H3 => Address_Component (Converted.S_B3),
              H4 => Address_Component (Converted.S_B4));
   end Value;

end System.Garlic.Naming;
