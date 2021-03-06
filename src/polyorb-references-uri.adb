------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--               P O L Y O R B . R E F E R E N C E S . U R I                --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2003-2017, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

with PolyORB.Initialization;

with PolyORB.Log;
with PolyORB.Utils.Chained_Lists;
with PolyORB.Types;

package body PolyORB.References.URI is

   use PolyORB.Binding_Data;
   use PolyORB.Log;
   use PolyORB.Utils.Strings;

   package L is new PolyORB.Log.Facility_Log ("polyorb.references.uri");
   procedure O (Message : String; Level : Log_Level := Debug)
     renames L.Output;
   function C (Level : Log_Level := Debug) return Boolean
     renames L.Enabled;

   type Profile_Record is record
      Tag                    : PolyORB.Binding_Data.Profile_Tag;
      Proto_Ident            : String_Ptr;
      Profile_To_String_Body : Profile_To_String_Body_Type;
      String_To_Profile_Body : String_To_Profile_Body_Type;
   end record;

   package Profile_Record_List is
      new PolyORB.Utils.Chained_Lists (Profile_Record);
   use Profile_Record_List;

   Callbacks : Profile_Record_List.List;

   Null_String : constant String := "";

   type Tag_Array is array (Natural range <>) of Profile_Tag;

   type String_Array is array (Integer range <>) of String_Ptr;

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Get_URI_List
     (URI      :     URI_Type;
      URI_List : out String_Array;
      Tag_List : out Tag_Array;
      N        : out Natural);
   --  Return the list of all URIs found in URI

   function String_To_Profile
     (Obj_Addr : String) return Binding_Data.Profile_Access;
   --  Returns null if it failed

   function Profile_To_String
     (P : Binding_Data.Profile_Access) return String;

   procedure Free (SA : in out String_Array);
   --  Free a String_Array

   ------------------
   -- Get_URI_List --
   ------------------

   procedure Get_URI_List
     (URI      :     URI_Type;
      URI_List : out String_Array;
      Tag_List : out Tag_Array;
      N        : out Natural)
   is
      Profs : constant Profile_Array := Profiles_Of (URI);
   begin
      N := 0;

      for J in Profs'Range loop
         declare
            Str : constant String := Profile_To_String (Profs (J));
         begin
            if Str'Length /= 0 then
               N := N + 1;
               URI_List (N) := new String'(Str);
               Tag_List (N) := Get_Profile_Tag (Profs (J).all);
            end if;
         end;
      end loop;

      pragma Debug (C, O ("Profile found :" & Natural'Image (N)));
   end Get_URI_List;

   -----------------------
   -- Profile_To_String --
   -----------------------

   function Profile_To_String
     (P : Binding_Data.Profile_Access) return String
   is
      use PolyORB.Types;

      T    : Profile_Tag;
      Iter : Iterator := First (Callbacks);
   begin
      pragma Assert (P /= null);
      pragma Debug (C, O ("Profile to string with tag:"
                       & Profile_Tag'Image (Get_Profile_Tag (P.all))));

      T := Get_Profile_Tag (P.all);

      while not Last (Iter) loop
         declare
            Info : constant Profile_Record := Value (Iter).all;
         begin
            if T = Info.Tag then
               declare
                  Str : constant String :=
                    Info.Profile_To_String_Body (P);
               begin
                  if Str'Length /= 0 then
                     pragma Debug (C, O ("Profile ok"));
                     return Str;
                  else
                     pragma Debug (C, O ("Profile not ok"));
                     return Null_String;
                  end if;
               end;
            end if;
         end;

         Next (Iter);
      end loop;

      pragma Debug (C, O ("Profile not ok"));
      return Null_String;
   end Profile_To_String;

   -----------------------
   -- String_To_Profile --
   -----------------------

   function String_To_Profile
     (Obj_Addr : String) return Binding_Data.Profile_Access
   is
      use PolyORB.Utils;

      Iter : Iterator := First (Callbacks);
   begin
      pragma Debug (C, O ("String_To_Profile: enter with "
                       & Obj_Addr));

      while not Last (Iter) loop
         if Has_Prefix (Obj_Addr, Prefix => Value (Iter).Proto_Ident.all) then
            pragma Debug
              (C, O ("Try to unmarshall profile with profile factory tag "
                  & Profile_Tag'Image (Value (Iter).Tag)));
            return Value (Iter).String_To_Profile_Body (Obj_Addr);
         end if;

         Next (Iter);
      end loop;

      pragma Debug (C, O ("Profile not found for " & Obj_Addr));
      return null;
   end String_To_Profile;

   ----------------------------------------
   -- Object_To_String_With_Best_Profile --
   ----------------------------------------

   function Object_To_String_With_Best_Profile
     (URI : URI_Type)
     return String
   is
   begin
      pragma Debug (C, O ("Create URI with best profile: Enter"));

      if Is_Nil (URI) then
         pragma Debug (C, O ("URI is Empty"));
         return Null_String;
      else
         declare
            use PolyORB.Types;

            N  : Natural;
            TL : Tag_Array (1 .. Length (Callbacks));
            SL : String_Array (1 .. Length (Callbacks));
            Profs : constant Profile_Array := Profiles_Of (URI);
            Best_Preference : Profile_Preference := Profile_Preference'First;
            Best_Profile_Index : Integer := 0;
         begin
            Get_URI_List (URI, SL, TL, N);

            for J in Profs'Range loop
               declare
                  P : constant Profile_Preference
                    := Get_Profile_Preference (Profs (J).all);
               begin
                  if P > Best_Preference then
                     for K in 1 .. N loop
                        if TL (K) = Get_Profile_Tag (Profs (J).all) then
                           Best_Preference := P;
                           Best_Profile_Index := K;
                        end if;
                     end loop;
                  end if;
               end;
            end loop;

            pragma Debug (C, O ("Create URI with best profile: Leave"));

            if Best_Profile_Index > 0 then
               declare
                  Str : constant String := SL (Best_Profile_Index).all;
               begin
                  Free (SL);
                  return Str;
               end;
            else
               Free (SL);
               return Null_String;
            end if;
         end;
      end if;
   end Object_To_String_With_Best_Profile;

   ----------------------
   -- String_To_Object --
   ----------------------

   function String_To_Object (Str : String) return URI_Type is
      Result : URI_Type;
      Pro    : Profile_Access;
   begin
      pragma Debug (C, O ("Try to decode URI: enter "));
      Pro := String_To_Profile (Str);

      if Pro /= null then
         Create_Reference ((1 => Pro), "", References.Ref (Result));
      end if;

      pragma Debug (C, O ("Try to decode URI: leave "));
      return Result;
   end String_To_Object;

   --------------
   -- Register --
   --------------

   procedure Register
     (Tag                    : PolyORB.Binding_Data.Profile_Tag;
      Proto_Ident            : String;
      Profile_To_String_Body : Profile_To_String_Body_Type;
      String_To_Profile_Body : String_To_Profile_Body_Type) is
   begin
      pragma Debug (C, O ("Register URI cb: prefix=" & Proto_Ident
                            & " tag=" & Tag'Img));
      Append (Callbacks,
              Profile_Record'(Tag,
                              new String'(Proto_Ident),
                              Profile_To_String_Body,
                              String_To_Profile_Body));
   end Register;

   ----------
   -- Free --
   ----------

   procedure Free (SA : in out String_Array) is
   begin
      for J in SA'Range loop
         Free (SA (J));
      end loop;
   end Free;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize;

   procedure Initialize is
      Iter : Iterator := First (Callbacks);
   begin
      while not Last (Iter) loop
         Register_String_To_Object
           (Value (Iter).Proto_Ident.all, String_To_Object'Access);
         Next (Iter);
      end loop;
   end Initialize;

   use PolyORB.Initialization;
   use PolyORB.Initialization.String_Lists;

begin
   Register_Module
     (Module_Info'
      (Name      => +"references.uri",
       Conflicts => PolyORB.Initialization.String_Lists.Empty,
       Depends   => +"binding_factories",
       Provides  => +"references",
       Implicit  => False,
       Init      => Initialize'Access,
       Shutdown  => null));
end PolyORB.References.URI;
