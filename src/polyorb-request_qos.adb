------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                  P O L Y O R B . R E Q U E S T _ Q O S                   --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--            Copyright (C) 2004 Free Software Foundation, Inc.             --
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

with PolyORB.Annotations;
with PolyORB.Log;
with PolyORB.Types;

package body PolyORB.Request_QoS is

   use PolyORB.Annotations;
   use PolyORB.Log;
   use PolyORB.Types;

   package L is new PolyORB.Log.Facility_Log ("polyorb.request_qos");
   procedure O (Message : in Standard.String; Level : Log_Level := Debug)
     renames L.Output;

   use PolyORB.Request_QoS.QoS_Parameter_Lists;

   Call_Back_Array : array (QoS_Kind'Range) of Fetch_QoS_CB;

   type QoS_Note is new Note with record
      QoS : QoS_Parameters;
   end record;

   procedure Destroy (N : in out QoS_Note);

   Default_Note : constant QoS_Note := QoS_Note'(Note with QoS => Empty);

   -------------
   -- Destroy --
   -------------

   procedure Destroy (N : in out QoS_Note) is
   begin
      Deallocate (N.QoS);
   end Destroy;

   -----------------------
   -- Extract_Parameter --
   -----------------------

   function Extract_Parameter
     (Kind : QoS_Kind;
      Req  : PolyORB.Requests.Request_Access)
     return QoS_Parameter
   is

      Note : QoS_Note;
      It : Iterator;

   begin
      Get_Note (Req.Notepad, Note, Default_Note);

      if Note /= Default_Note then
         It := First (Note.QoS);

         while not Last (It) loop
            if Value (It).all.Kind = Kind then
               return Value (It).all.all;
            end if;

            Next (It);
         end loop;
      end if;

      return QoS_Parameter'(Kind => PolyORB.Request_QoS.None);
   end Extract_Parameter;

   ---------------
   -- Fetch_QoS --
   ---------------

   function Fetch_QoS
     (Ref : PolyORB.References.Ref)
     return QoS_Parameter_Lists.List
   is
      use PolyORB.Request_QoS.QoS_Parameter_Lists;

      Result : QoS_Parameter_Lists.List;

      A_Parameter : QoS_Parameter_Access;
   begin
      pragma Debug (O ("Fetch_Qos: enter"));

      for J in Call_Back_Array'Range loop
         if Call_Back_Array (J) /= null then
            pragma Debug (O ("Fetching QoS parameters for "
                             & QoS_Kind'Image (J)));

            A_Parameter := Call_Back_Array (J) (Ref);
            if A_Parameter /= null then
               Append (Result, A_Parameter);
            end if;
         end if;
      end loop;

      pragma Debug (O ("Fetch_Qos: leave"));
      return Result;
   end Fetch_QoS;

   --------------
   -- Register --
   --------------

   procedure Register (Kind : QoS_Kind; CB : Fetch_QoS_CB) is
   begin
      pragma Debug (O ("Registering call back for "
                       & QoS_Kind'Image (Kind)));

      pragma Assert (Call_Back_Array (Kind) = null);
      Call_Back_Array (Kind) := CB;
   end Register;

   -----------
   -- Image --
   -----------

   function Image (QoS : QoS_Parameter_Lists.List) return String is
      use PolyORB.Request_QoS.QoS_Parameter_Lists;

      Result : PolyORB.Types.String := To_PolyORB_String ("");

      It : Iterator := First (QoS);

   begin
      while not Last (It) loop
         Result := Result
           & To_PolyORB_String (QoS_Kind'Image (Value (It).all.Kind) & ",");
         Next (It);
      end loop;

      return To_Standard_String (Result);
   end Image;

   -------------
   -- Set_QoS --
   -------------

   procedure Set_QoS (Req : PR.Request_Access; QoS : QoS_Parameters) is
      Note : constant QoS_Note := QoS_Note'(Annotations.Note with QoS => QoS);

   begin
      Set_Note (Req.Notepad, Note);
   end Set_QoS;

   -------------
   -- Get_QoS --
   -------------

   function Get_QoS (Req : PR.Request_Access) return QoS_Parameters is
      Note : QoS_Note;

   begin
      Get_Note (Req.Notepad, Note, Default_Note);

      return Note.QoS;
   end Get_QoS;

end PolyORB.Request_QoS;
