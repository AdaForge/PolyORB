------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--            P O L Y O R B . G I O P _ P . E X C E P T I O N S             --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2002-2003 Free Software Foundation, Inc.           --
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

--  $Id$

with PolyORB.Any;
with PolyORB.Exceptions;
with PolyORB.Log;
with PolyORB.Types;
with PolyORB.Utils;

package body PolyORB.GIOP_P.Exceptions is

   use PolyORB.Any;
   use PolyORB.Exceptions;
   use PolyORB.Log;
   use PolyORB.Types;
   use PolyORB.Utils;

   package L is new PolyORB.Log.Facility_Log ("polyorb.giop_p.exceptions");
   procedure O (Message : in Standard.String; Level : Log_Level := Debug)
     renames L.Output;

   CORBA_Exc_Root    : constant String := "IDL:omg.org/CORBA/";
   CORBA_Exc_Version : constant String := ":1.0";
   --  CORBA exceptions root and version.

   function To_CORBA_Exception_TypeCode
     (TC : PolyORB.Any.TypeCode.Object)
     return PolyORB.Any.TypeCode.Object;

   -------------------------
   -- Is_System_Exception --
   -------------------------

   --  IMPLEMENTATION NOTE : Every change to this function should be
   --  duplicated to PolyORB.CORBA_P.Exceptions.Is_System_Exception.

   function Is_System_Exception
     (Name : String)
     return Boolean
   is
      Prefix_Length : constant Natural := PolyORB_Exc_Prefix'Length;
      Version_Length : constant Natural
        := To_Standard_String (PolyORB_Exc_Version)'Length;

      Result : Boolean := False;
   begin
      if Name'Length > Prefix_Length + Version_Length
        and then Name (Name'First .. Name'First + Prefix_Length - 1)
        = PolyORB_Exc_Prefix
      then
         declare
            Error_Id_Name : constant String
              := Name (Name'First + Prefix_Length ..
                       Name'Last - Version_Length) & "_E";

         begin
            pragma Debug (O ("Error_Id_Name : " & Error_Id_Name));

            Result := Error_Id'Value (Error_Id_Name) in ORB_System_Error;
         end;
      end if;

      pragma Debug (O (Name & " is a system exception ? "
                       & Boolean'Image (Result)));
      return Result;
   end Is_System_Exception;

   -----------------------------------
   -- Extract_System_Exception_Name --
   -----------------------------------

   function Extract_System_Exception_Name
     (Name : Standard.String)
     return Standard.String
   is
      CER_Length : constant Natural :=  CORBA_Exc_Root'Length;
      CEV_Length : constant Natural :=  CORBA_Exc_Version'Length;

   begin
      if Name (Name'First .. Name'First + CER_Length - 1) /=
        CORBA_Exc_Root then
         raise Program_Error;
      end if;

      pragma Debug (O ("System exception name :"
                       & Name (Name'First + CER_Length
                               .. Name'Last - CEV_Length)));

      return Name (Name'First + CER_Length .. Name'Last - CEV_Length);
   end Extract_System_Exception_Name;

   ---------------------------------
   -- To_CORBA_Exception_TypeCode --
   ---------------------------------

   function To_CORBA_Exception_TypeCode
     (TC : PolyORB.Any.TypeCode.Object)
     return PolyORB.Any.TypeCode.Object
   is
      CORBA_Root_PTS : constant PolyORB.Types.String
        := To_PolyORB_String (CORBA_Exc_Root);

      CORBA_Exc_Version_PTS : constant PolyORB.Types.String
        := To_PolyORB_String (CORBA_Exc_Version);

      Name : constant String := To_Standard_String (From_Any
        (TypeCode.Get_Parameter (TC, PolyORB.Types.Unsigned_Long (1))));

      Colon1 : constant Integer := Find (Name, Name'First, '/');
      Colon2 : constant Integer := Find (Name, Colon1 + 1, ':');

      Internal_Name : constant String := Name (Colon1 + 1 .. Colon2 - 1);

      New_Name : PolyORB.Types.String;
      Result_TC : TypeCode.Object := TypeCode.TC_Except;
   begin
      pragma Debug (O ("Exception name was : " & Name));

      --  Construct CORBA exception typecode

      --  Name
      TypeCode.Add_Parameter (Result_TC, To_Any
                              (To_PolyORB_String (Internal_Name)));

      New_Name := CORBA_Root_PTS
        & To_PolyORB_String (Internal_Name)
        & CORBA_Exc_Version_PTS;

      pragma Debug (O ("New exception name is : "
                       & To_Standard_String (New_Name)));
      TypeCode.Add_Parameter (Result_TC, To_Any (New_Name));

      --  Component 'minor'
      TypeCode.Add_Parameter
        (Result_TC, To_Any (TC_Unsigned_Long));
      TypeCode.Add_Parameter
        (Result_TC, To_Any (To_PolyORB_String ("minor")));

      --  Component 'completed'
      TypeCode.Add_Parameter
        (Result_TC, To_Any (TC_Completion_Status));
      TypeCode.Add_Parameter
        (Result_TC, To_Any (To_PolyORB_String ("completed")));

      return Result_TC;
   end To_CORBA_Exception_TypeCode;

   ------------------------
   -- To_CORBA_Exception --
   ------------------------

   function To_CORBA_Exception (Exc : PolyORB.Any.Any)
      return PolyORB.Any.Any
   is
      use PolyORB.Any.TypeCode;

      Exc_TC : constant PolyORB.Any.TypeCode.Object := Get_Type (Exc);
      Result_TC : PolyORB.Any.TypeCode.Object;

      Result : Any.Any;

   begin
      pragma Debug (O ("To_CORBA_Exception: enter"));

      --  Construct exception typecode
      Result_TC := To_CORBA_Exception_TypeCode (Exc_TC);

      if Exc_TC /= Result_TC then
         pragma Debug (O ("Must modify Exc TypeCode"));

         Set_Type (Result, Result_TC);

         Result := Get_Empty_Any_Aggregate (Result_TC);
         Add_Aggregate_Element
           (Result,
            Get_Aggregate_Element (Exc,
                                   TypeCode.TC_Unsigned_Long,
                                   Types.Unsigned_Long (0)));

         Add_Aggregate_Element
           (Result,
            Get_Aggregate_Element (Exc,
                                   TC_Completion_Status,
                                   Types.Unsigned_Long (1)));

         pragma Debug (O ("To_CORBA_Exception: leave"));
         return Result;
      else
         pragma Debug (O ("No need to modify Exc TypeCode"));
         pragma Debug (O ("To_CORBA_Exception: leave"));

         return Exc;
      end if;
   end To_CORBA_Exception;

   -------------------------------
   -- System_Exception_TypeCode --
   -------------------------------

   function System_Exception_TypeCode
     (Name : Standard.String)
     return Any.TypeCode.Object
   is
      TC    : TypeCode.Object := TypeCode.TC_Except;
      Shift : Natural := 0;

      Repository_Id : PolyORB.Types.String;
   begin
      --  Name
      TypeCode.Add_Parameter (TC, To_Any (To_PolyORB_String (Name)));

      if Name (Name'First .. Name'First + PolyORB_Exc_Root'Length - 1)
        = PolyORB_Exc_Root then
         Shift := PolyORB_Exc_Root'Length + 1;
      end if;

      --  RepositoryId : 'INTERNAL:<Name>:1.0'
      Repository_Id := To_PolyORB_String (PolyORB_Exc_Prefix)
        & To_PolyORB_String (Name (Name'First + Shift .. Name'Last))
        & PolyORB_Exc_Version;

      TypeCode.Add_Parameter (TC, To_Any (Repository_Id));

      --  Component 'minor'
      TypeCode.Add_Parameter
        (TC, To_Any (TC_Unsigned_Long));
      TypeCode.Add_Parameter
        (TC, To_Any (To_PolyORB_String ("minor")));

      --  Component 'completed'
      TypeCode.Add_Parameter
        (TC, To_Any (TC_Completion_Status));
      TypeCode.Add_Parameter
        (TC, To_Any (To_PolyORB_String ("completed")));

      pragma Debug (O ("Built Exception TypeCode for: "
                       & To_Standard_String (Repository_Id)));

      return TC;
   end System_Exception_TypeCode;

end PolyORB.GIOP_P.Exceptions;
