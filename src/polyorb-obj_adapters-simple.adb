------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--          P O L Y O R B . O B J _ A D A P T E R S . S I M P L E           --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--             Copyright (C) 1999-2003 Free Software Fundation              --
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

--  Object adapters: entities that manage the association
--  of references with servants.

--  $Id$

with Ada.Streams;
with Ada.Unchecked_Conversion;

with PolyORB.POA_Policies.Thread_Policy.ORB_Ctrl;
with PolyORB.POA_Policies.Thread_Policy;

package body PolyORB.Obj_Adapters.Simple is

   use Ada.Streams;

   use PolyORB.Tasking.Mutexes;

   use PolyORB.POA_Policies.Thread_Policy.ORB_Ctrl;
   use PolyORB.POA_Policies.Thread_Policy;

   use Object_Map_Entry_Seqs;

   subtype Simple_OA_Oid is Stream_Element_Array
     (1 .. Integer'Size / Stream_Element'Size);

   function Index_To_Oid is
      new Ada.Unchecked_Conversion (Integer, Simple_OA_Oid);

   function Oid_To_Index is
      new Ada.Unchecked_Conversion (Simple_OA_Oid, Integer);

   function Find_Entry
     (OA    : Simple_Obj_Adapter;
      Index : Integer)
     return Object_Map_Entry;
   --  Check that Index is a valid object Index (associated
   --  to a non-null Servant) for object adapter OA, and
   --  return the associated entry. If Index is out of range
   --  or associated to a null Servant, Invalid_Object_Id is raised.

   ----------------
   -- Find_Entry --
   ----------------

   function Find_Entry
     (OA    : Simple_Obj_Adapter;
      Index : Integer)
      return Object_Map_Entry
   is
      use type Servants.Servant_Access;

      OME : Object_Map_Entry;
   begin
      Enter (OA.Lock);
      OME := Element_Of (OA.Object_Map, Index);
      Leave (OA.Lock);

      if OME.Servant = null then
         raise Invalid_Object_Id;
      end if;

      return OME;

   exception
      when Sequences.Index_Error =>
         raise Invalid_Object_Id;

      when others =>
         raise;
   end Find_Entry;

   ------------
   -- Create --
   ------------

   procedure Create
     (OA : access Simple_Obj_Adapter) is
   begin
      Create (OA.Lock);
   end Create;

   -------------
   -- Destroy --
   -------------

   procedure Destroy
     (OA : access Simple_Obj_Adapter) is
   begin
      Destroy (OA.Lock);
   end Destroy;

   ------------
   -- Export --
   ------------

   function Export
     (OA  : access Simple_Obj_Adapter;
      Obj :        Servants.Servant_Access;
      Key :        Objects.Object_Id_Access := null)
      return Objects.Object_Id
   is
      use type Servants.Servant_Access;
      use type Objects.Object_Id_Access;
   begin
      if Key /= null then
         raise Invalid_Object_Id;
         --  The Simple Object Adapter does not support
         --  user-defined object identifiers.
      end if;

      Enter (OA.Lock);
      declare
         M : constant Element_Array := To_Element_Array (OA.Object_Map);
         New_Id : Integer := M'Last + 1;
      begin
         Map :
         for I in M'Range loop
            if M (I).Servant = null then
               Replace_Element
                 (OA.Object_Map, 1 + I - M'First,
                  Object_Map_Entry'
                    (Servant => Obj, If_Desc => (null, null)));
               New_Id := I;
               exit Map;
            end if;
         end loop Map;

         if New_Id > M'Last then
            Append (OA.Object_Map, Object_Map_Entry'
                    (Servant => Obj, If_Desc => (null, null)));
         end if;
         Leave (OA.Lock);

         return Objects.Object_Id (Index_To_Oid (New_Id - M'First + 1));
      end;
   end Export;

   --  XXX There is FAR TOO MUCH code duplication in here!

   --------------
   -- Unexport --
   --------------

   procedure Unexport
     (OA : access Simple_Obj_Adapter;
      Id : Objects.Object_Id_Access)
   is
      use type Servants.Servant_Access;

      Index : constant Integer
        := Oid_To_Index (Simple_OA_Oid (Id.all));

      OME : Object_Map_Entry
        := Find_Entry (OA.all, Index);
   begin
      pragma Assert (OME.Servant /= null);

      Enter (OA.Lock);
      OME := (Servant => null, If_Desc => (null, null));
      Replace_Element (OA.Object_Map, Index, OME);
      Leave (OA.Lock);

   exception
      when others =>
         Leave (OA.Lock);
         raise;

   end Unexport;

   ----------------
   -- Object_Key --
   ----------------

   function Object_Key
     (OA : access Simple_Obj_Adapter;
      Id :        Objects.Object_Id_Access)
      return Objects.Object_Id is
   begin
      raise Invalid_Object_Id;

      pragma Warnings (Off);
      return Object_Key (OA, Id);
      pragma Warnings (On);
      --  An SOA object identifier cannot contain a user-defined
      --  object key.
   end Object_Key;

   -------------------------------
   -- Set_Interface_Description --
   -------------------------------

   procedure Set_Interface_Description
     (OA      : in out Simple_Obj_Adapter;
      Id      : access Objects.Object_Id;
      If_Desc : Interface_Description)
   is
      use type Servants.Servant_Access;

      Index : constant Integer
        := Oid_To_Index (Simple_OA_Oid (Id.all));

      OME : Object_Map_Entry
        := Find_Entry (OA, Index);
   begin
      pragma Assert (OME.Servant /= null);
      OME.If_Desc := If_Desc;
      Enter (OA.Lock);
      Replace_Element (OA.Object_Map, Index, OME);
      Leave (OA.Lock);

   exception
      when others =>
         Leave (OA.Lock);
         raise;

   end Set_Interface_Description;

   ------------------------
   -- Get_Empty_Arg_List --
   ------------------------

   function Get_Empty_Arg_List
     (OA     : access Simple_Obj_Adapter;
      Oid    : access Objects.Object_Id;
      Method :        String)
     return Any.NVList.Ref
   is
      Index : constant Integer := Oid_To_Index (Simple_OA_Oid (Oid.all));
      Result : Any.NVList.Ref;

      OME : constant Object_Map_Entry
        := Find_Entry (OA.all, Index);
   begin
      if OME.If_Desc.PP_Desc = null then
         raise Invalid_Method;
      end if;

      Enter (OA.Lock);
      Result := OME.If_Desc.PP_Desc (Method);
      Leave (OA.Lock);

      return Result;

   exception
      when others =>
         Leave (OA.Lock);
         raise;

   end Get_Empty_Arg_List;

   ----------------------
   -- Get_Empty_Result --
   ----------------------

   function Get_Empty_Result
     (OA     : access Simple_Obj_Adapter;
      Oid    : access Objects.Object_Id;
      Method :        String)
     return Any.Any
   is
      Index : constant Integer := Oid_To_Index (Simple_OA_Oid (Oid.all));
      Result : Any.Any;

      OME : constant Object_Map_Entry
        := Find_Entry (OA.all, Index);
   begin
      if OME.If_Desc.PP_Desc = null then
         raise Invalid_Method;
      end if;

      Enter (OA.Lock);
      Result := OME.If_Desc.RP_Desc (Method);
      Leave (OA.Lock);
      return Result;

   exception
      when others =>
         Leave (OA.Lock);
         raise;

   end Get_Empty_Result;

   ------------------
   -- Find_Servant --
   ------------------

   No_Thread_Policy : constant ThreadPolicy_Access := new ORB_Ctrl_Policy;
   --  XXX ????

   function Find_Servant
     (OA : access Simple_Obj_Adapter;
      Id : access Objects.Object_Id)
     return Servants.Servant_Access
   is
      Result : Servants.Servant_Access;
   begin
      Enter (OA.Lock);
      Result := Element_Of (OA.Object_Map, Oid_To_Index
                            (Simple_OA_Oid (Id.all))).Servant;
      Servants.Set_Thread_Policy (Result, No_Thread_Policy);
      Leave (OA.Lock);
      return Result;
   end Find_Servant;

   ---------------------
   -- Release_Servant --
   ---------------------

   procedure Release_Servant
     (OA : access Simple_Obj_Adapter;
      Id : access Objects.Object_Id;
      Servant : in out Servants.Servant_Access)
   is
      pragma Warnings (Off);
      pragma Unreferenced (OA);
      pragma Unreferenced (Id);
      pragma Warnings (On);

   begin
      --  SOA: do nothing.
      Servant := null;
   end Release_Servant;

end PolyORB.Obj_Adapters.Simple;
