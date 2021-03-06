------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--             R T C O R B A . T H R E A D P O O L P O L I C Y              --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2003-2012, Free Software Foundation, Inc.          --
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

with PolyORB.CORBA_P.POA_Config;
with PolyORB.CORBA_P.Policy;
with PolyORB.CORBA_P.Policy_Management;

with PolyORB.Initialization;

with PolyORB.Lanes;
with PolyORB.POA_Policies;
with PolyORB.RTCORBA_P.ThreadPoolManager;
with PolyORB.RT_POA_Policies.Thread_Pool_Policy;
with PolyORB.Smart_Pointers;
with PolyORB.Utils.Strings;

with RTCORBA.ThreadpoolPolicy.Helper;

package body RTCORBA.ThreadpoolPolicy is

   use CORBA;
   use CORBA.Policy;
   use CORBA.TypeCode;

   use PolyORB.CORBA_P.Policy;
   use PolyORB.CORBA_P.Policy_Management;

   function Create_ThreadpoolPolicy
     (The_Type : CORBA.PolicyType;
      Value    : CORBA.Any)
     return CORBA.Policy.Ref;

   -----------------------------
   -- Create_ThreadpoolPolicy --
   -----------------------------

   function Create_ThreadpoolPolicy
     (The_Type : CORBA.PolicyType;
      Value    : CORBA.Any) return CORBA.Policy.Ref
   is
   begin
      pragma Assert (The_Type = THREADPOOL_POLICY_TYPE);

      if Get_Type (Value) /= CORBA.TC_Unsigned_Long then
         Raise_PolicyError ((Reason => BAD_POLICY_TYPE));
      end if;

      declare
         Result : CORBA.Policy.Ref;
         Entity : constant PolyORB.Smart_Pointers.Entity_Ptr
           := new Policy_Object_Type;

      begin
         Set_Policy_Type (Policy_Object_Type (Entity.all), The_Type);
         Set_Policy_Value (Policy_Object_Type (Entity.all), Value);

         CORBA.Policy.Set (Result, Entity);

         return Result;
      end;
   end Create_ThreadpoolPolicy;

   --------------------
   -- Get_Threadpool --
   --------------------

   function Get_Threadpool
     (Self : Local_Ref)
     return RTCORBA.ThreadpoolId
   is
   begin
      return From_Any (Get_Policy_Value
                       (Policy_Object_Type
                        (Entity_Of
                         (CORBA.Policy.Ref (Self)).all)));
   end Get_Threadpool;

   ----------------------------------
   -- Thread_Pool_Policy_Allocator --
   ----------------------------------

   function Thread_Pool_Policy_Allocator
     (Self : CORBA.Policy.Ref)
     return PolyORB.POA_Policies.Policy_Access;

   function Thread_Pool_Policy_Allocator
     (Self : CORBA.Policy.Ref)
     return PolyORB.POA_Policies.Policy_Access
   is
      use PolyORB.RT_POA_Policies.Thread_Pool_Policy;
      use PolyORB.RTCORBA_P.ThreadPoolManager;
      use RTCORBA.ThreadpoolPolicy.Helper;

      Lanes : constant PolyORB.Lanes.Lane_Root_Access
        := Lane (Get_Threadpool (To_Local_Ref (Self)));

   begin
      return Create (Lanes);
   end Thread_Pool_Policy_Allocator;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize;

   procedure Initialize is
   begin
      PolyORB.CORBA_P.POA_Config.Register
        (THREADPOOL_POLICY_TYPE,
         Thread_Pool_Policy_Allocator'Access);

      Register
        (The_Type       => THREADPOOL_POLICY_TYPE,
         POA_Level      => True,
         Factory        => Create_ThreadpoolPolicy'Access,
         System_Default =>
           Create_ThreadpoolPolicy (THREADPOOL_POLICY_TYPE,
                                    To_Any (CORBA.Unsigned_Long (0))));
   end Initialize;

   use PolyORB.Initialization;
   use PolyORB.Initialization.String_Lists;
   use PolyORB.Utils.Strings;

begin
   Register_Module
     (Module_Info'
      (Name      => +"rtcorba-threadpoolpolicy",
       Conflicts => Empty,
       Depends   => +"rt_poa",
       Provides  => Empty,
       Implicit  => False,
       Init      => Initialize'Access,
       Shutdown  => null));
end RTCORBA.ThreadpoolPolicy;
