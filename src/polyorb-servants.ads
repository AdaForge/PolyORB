------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                     P O L Y O R B . S E R V A N T S                      --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2002-2011, Free Software Foundation, Inc.          --
--                                                                          --
-- PolyORB is free software; you  can  redistribute  it and/or modify it    --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. PolyORB is distributed  in the hope that it will be  useful,    --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with PolyORB; see file COPYING. If    --
-- not, write to the Free Software Foundation, 51 Franklin Street, Fifth    --
-- Floor, Boston, MA 02111-1301, USA.                                       --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

--  Root type for concrete object implementations (servants)

with PolyORB.Annotations;
with PolyORB.Components;
with PolyORB.Requests;

package PolyORB.Servants is

   -------------
   -- Servant --
   -------------

   --  A Servant is a Component that supports the messages defined in
   --  PolyORB.Servants.Interface. This type may be further derived by
   --  units implementing a specific applicative personality.

   type Servant is abstract new PolyORB.Components.Component with private;
   type Servant_Access is access all Servant'Class;

   function Handle_Message
     (S   : not null access Servant;
      Msg : Components.Message'Class) return Components.Message'Class;

   function Execute_Servant
     (S   : not null access Servant;
      Req : Requests.Request_Access) return Boolean
      is abstract;
   --  This primitive is redispatched to by Handle_Message to process
   --  the Execute_Request message. Note that we explicitly specify
   --  null-exclusion here so that the semantics of this declaration are
   --  consistent when compiled in Ada 95 and in Ada 2005 mode. This is
   --  needed because Servant is derived in the PolyORB version of
   --  System.Partition_Interface, which is always processed in Ada 2005 mode.
   --  Returns True if the request has been executed (and can be destroyed),
   --  False if the request has been queued for later execution.

   function Abortable_Execute_Servant
     (S   : not null access Servant'Class;
      Req : Requests.Request_Access) return Boolean;
   --  Call Execute_Servant within an Abortable object

   function Notepad_Of
     (S : Servant_Access) return PolyORB.Annotations.Notepad_Access;
   pragma Inline (Notepad_Of);
   --  Return Notepad associated to a servant

   overriding procedure Destroy (S : in out Servant);
   --  Deallocate any storage resource associated with S

   --------------
   -- Executor --
   --------------

   --  An Executor is responsible for establishing the proper context to
   --  perform a call to Abortable_Execute_Servant, depending on object adapter
   --  thread policy. By default, Execute_In_Context just makes the call in the
   --  current task. Object adapters may provide derived executor types, e.g.
   --  to grab appropriate locks.

   type Executor is tagged limited private;
   type Executor_Access is access all Executor'Class;

   function Execute_In_Context
     (Self      : access Executor;
      Req       : Requests.Request_Access;
      Requestor : Components.Component_Access) return Boolean;

   procedure Set_Executor (S : access Servant; Exec : Executor_Access);
   pragma Inline (Set_Executor);

private

   type Executor is tagged limited null record;

   type Servant is abstract new PolyORB.Components.Component with record
      Exec    : Executor_Access;
      Notepad : aliased PolyORB.Annotations.Notepad;
   end record;

end PolyORB.Servants;
