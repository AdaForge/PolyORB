------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                              T E S T 0 0 2                               --
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

with Ada.Text_IO;

with PolyORB.Initialization;
with PolyORB.Utils.Report;
with PolyORB.Utils.Strings;


procedure Test002 is

   use Ada.Text_IO;

   use PolyORB.Initialization;
   use PolyORB.Initialization.String_Lists;
   use PolyORB.Utils.Report;
   use PolyORB.Utils.Strings;

   generic
      Name : String;
   procedure Init;

   procedure Init is
   begin
      Put_Line ("Initializing module " & Name);
   end Init;

   procedure Init_Bar is new Init ("bar");
   procedure Init_Bazooka is new Init ("bazooka");
   procedure Init_Fred is new Init ("fred");

   Empty_List : String_Lists.List;

begin
   Register_Module
     (Module_Info'
      (Name      => +"bar",
       Depends   => Empty_List & "foo" & "baz",
       Conflicts => Empty_List,
       Provides  => Empty_List,
       Implicit  => False,
       Init      => Init_Bar'Unrestricted_Access));

   Register_Module
     (Module_Info'
      (Name      => +"bazooka",
       Depends   => Empty_List,
       Conflicts => Empty_List,
       Provides  => Empty_List & "baz",
       Implicit  => False,
       Init      => Init_Bazooka'Unrestricted_Access));

   Register_Module
     (Module_Info'
      (Name      => +"fred",
       Depends   => Empty_List & "bar" & "foo",
       Conflicts => Empty_List & "bazaar",
       Provides  => Empty_List,
       Implicit  => False,
       Init      => Init_Fred'Unrestricted_Access));

   Initialize_World;

   Output ("Test initialization #2", False);

exception
   when PolyORB.Initialization.Unresolved_Dependency =>
      Output ("Test initialization #2", True);
      End_Report;

   when others =>
      Output ("Test initialization #2", False);

end Test002;