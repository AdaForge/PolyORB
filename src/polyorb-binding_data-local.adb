------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--           P O L Y O R B . B I N D I N G _ D A T A . L O C A L            --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2001-2003 Free Software Foundation, Inc.           --
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
--                PolyORB is maintained by ACT Europe.                      --
--                    (email: sales@act-europe.fr)                          --
--                                                                          --
------------------------------------------------------------------------------

--  Contact information for an object that exists within the local ORB.

--  $Id$

package body PolyORB.Binding_Data.Local is

   use PolyORB.Objects;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (P : in out Local_Profile_Type) is
   begin
      P.Object_Id := null;
   end Initialize;

   ------------
   -- Adjust --
   ------------

   procedure Adjust
     (P : in out Local_Profile_Type) is
   begin
      if P.Object_Id /= null then
         P.Object_Id := new Object_Id'(P.Object_Id.all);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   procedure Finalize
     (P : in out Local_Profile_Type) is
   begin
      Free (P.Object_Id);
   end Finalize;

   --------------------------
   -- Create_Local_Profile --
   --------------------------

   procedure Create_Local_Profile
     (Oid : Objects.Object_Id;
      P   : out Local_Profile_Type) is
   begin
      P.Object_Id := new Object_Id'(Oid);
      pragma Assert (P.Object_Id /= null);
   end Create_Local_Profile;

   ------------------
   -- Bind_Profile --
   -------------------

   function Bind_Profile
     (Profile : Local_Profile_Type;
      The_ORB : Components.Component_Access)
     return Components.Component_Access
   is
      pragma Warnings (Off); -- WAG:3.15
      pragma Unreferenced (Profile);
      pragma Unreferenced (The_ORB);
      pragma Warnings (On); -- WAG:3.15

   begin
      raise Program_Error;
      --  May not happen currently, because the local case
      --  is handled specially in PolyORB.References.Bind,
      --  but could be implemented as (mostly):

      --  return Components.Component_Access
      --    (Find_Servant
      --     (Object_Adapter (Local_ORB), Profile.Object_Id));

      return null;
   end Bind_Profile;

   ---------------------
   -- Get_Profile_Tag --
   ---------------------

   function Get_Profile_Tag
     (Profile : Local_Profile_Type)
     return Profile_Tag
   is
      pragma Warnings (Off);
      pragma Unreferenced (Profile);
      pragma Warnings (On);

   begin
      return Tag_Local;
   end Get_Profile_Tag;

   ----------------------------
   -- Get_Profile_Preference --
   ----------------------------

   function Get_Profile_Preference
     (Profile : Local_Profile_Type)
     return Profile_Preference
   is
      pragma Warnings (Off);
      pragma Unreferenced (Profile);
      pragma Warnings (On);

   begin
      return Profile_Preference'Last;
      --  A local profile is always preferred to any other.

   end Get_Profile_Preference;

   -----------
   -- Image --
   -----------

   function Image
     (Prof : Local_Profile_Type)
     return String is
   begin
      return "Object_Id: " & PolyORB.Objects.Image (Prof.Object_Id.all);
   end Image;

end PolyORB.Binding_Data.Local;
