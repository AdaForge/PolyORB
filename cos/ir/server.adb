------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--                               S E R V E R                                --
--                                                                          --
--                                 B o d y                                  --
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
--             AdaBroker is maintained by ENST Paris University.            --
--                     (email: broker@inf.enst.fr)                          --
--                                                                          --
------------------------------------------------------------------------------

with CORBA;
with CORBA.Object;
with CORBA.ORB;
with CORBA.Repository_Root.IRObject.Impl;
with CORBA.Repository_Root.Contained.Impl;
with CORBA.Repository_Root.Repository.Impl;
with CORBA.Repository_Root; use CORBA.Repository_Root;

with PortableServer;

with CosNaming.NamingContext;

with PolyORB.CORBA_P.Naming_Tools;
with PolyORB.CORBA_P.Server_Tools; use PolyORB.CORBA_P.Server_Tools;

with PolyORB.Setup.No_Tasking_Server;
pragma Elaborate_All (PolyORB.Setup.No_Tasking_Server);
pragma Warnings (Off, PolyORB.Setup.No_Tasking_Server);

pragma Elaborate (PolyORB.CORBA_P.Server_Tools);

procedure Server is
   Ref : CORBA.Object.Ref;
   Repo : constant Repository.Impl.Object_Ptr := new Repository.Impl.Object;
begin
   --  PolyORB.ORB.Thread_Pool.Initialize (4, 10);
   CORBA.ORB.Initialize ("ORB");
   Repository.Impl.Init (Repo,
                         IRObject.Impl.Object_Ptr (Repo),
                         dk_Repository,
                         Contained.Impl.Contained_Seq.Null_Sequence);
   Initiate_Servant (PortableServer.Servant (Repo), Ref);
--   Ada.Text_IO.Put_Line
--     ("'" & CORBA.To_Standard_String (CORBA.Object.Object_To_String (Ref)) &
--      "'");
   begin
      PolyORB.CORBA_P.Naming_Tools.Register ("Interface_Repository", Ref);
   exception
      when CosNaming.NamingContext.AlreadyBound =>
         PolyORB.CORBA_P.Naming_Tools.Register
           ("Interface_Repository", Ref, Rebind => True);
   end;
   Initiate_Server;
end Server;

