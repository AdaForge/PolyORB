------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                      P A R A L L E L _ C L I E N T                       --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2002-2012, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
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

--  Parallel echo client

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with CORBA.ORB;

with Echo;

with PolyORB.Setup.Thread_Pool_Client;
pragma Warnings (Off, PolyORB.Setup.Thread_Pool_Client);
with PolyORB.Utils.Report;

procedure Parallel_Client is
   use Ada.Command_Line;
   use Ada.Text_IO;

   use PolyORB.Utils.Report;
   use type CORBA.String;

   Tasks : constant := 100;
   Calls : constant := 1_000;

   task type Caller (Index : Natural) is
   end Caller;

   task body Caller is
      Sent_Msg : constant CORBA.String :=
                   CORBA.To_CORBA_String (Standard.String'("Hello Ada !"));
   begin
      for J in 1 .. Calls loop
         declare
            R : Echo.Ref;
         begin
            CORBA.ORB.String_To_Object
              (CORBA.To_CORBA_String (Ada.Command_Line.Argument (1)), R);
            if R.echoString (Sent_Msg) /= Sent_Msg then
               Output ("echo test", False);
               exit;
            end if;
         exception
            when E : others =>
               Output ("echo test", False);
               Put_Line ("Exception raised in task" & Index'Img
                         & " at call" & J'Img & ": "
                         & Ada.Exceptions.Exception_Information (E));
               exit;
         end;
      end loop;
   end Caller;

begin
   if Argument_Count /= 1 then
      Put_Line ("Usage: parallel_client <ior>");
      return;
   end if;

   New_Test ("Echo client");

   CORBA.ORB.Initialize ("ORB");

   declare
      type Caller_Access is access Caller;
      Callers : array (1 .. Tasks) of Caller_Access;
   begin
      for J in Callers'Range loop
         Callers (J) := new Caller (Index => J);
      end loop;
   end;

   CORBA.ORB.Shutdown (Wait_For_Completion => False);
   End_Report;
end Parallel_Client;
