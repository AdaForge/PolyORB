------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--         P O L Y O R B . C O R B A _ P . I N T E R C E P T O R S          --
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

with CORBA.Object;

with PolyORB.CORBA_P.Exceptions;
with PolyORB.CORBA_P.Interceptors_Hooks;
with PolyORB.CORBA_P.Interceptors_Slots;

with PolyORB.Exceptions;
with PolyORB.Initialization;
with PolyORB.References;
with PolyORB.Requests;
with PolyORB.Smart_Pointers;
with PolyORB.Types;
with PolyORB.Tasking.Threads.Annotations;
with PolyORB.Utils.Chained_Lists;
with PolyORB.Utils.Strings;

with PortableServer;

with PortableInterceptor.ClientRequestInfo;
with PortableInterceptor.ClientRequestInfo.Impl;
with PortableInterceptor.ClientRequestInterceptor;
with PortableInterceptor.ORBInitInfo.Impl;
with PortableInterceptor.ServerRequestInfo;
with PortableInterceptor.ServerRequestInfo.Impl;
with PortableInterceptor.ServerRequestInterceptor;

package body PolyORB.CORBA_P.Interceptors is

   use PolyORB.Annotations;
   use PolyORB.CORBA_P.Interceptors_Slots;
   use PolyORB.Tasking.Threads.Annotations;

   --  Client Interceptors

   function "="
     (Left, Right : in PortableInterceptor.ClientRequestInterceptor.Local_Ref)
      return Boolean;

   package ClientRequestInterceptor_Lists is
      new PolyORB.Utils.Chained_Lists
           (PortableInterceptor.ClientRequestInterceptor.Local_Ref);

   All_Client_Interceptors : ClientRequestInterceptor_Lists.List;

   procedure Client_Invoke
     (Request : in PolyORB.Requests.Request_Access;
      Flags   : in PolyORB.Requests.Flags);

   function Create_Client_Request_Info
     (Request : in PolyORB.Requests.Request_Access;
      Point   : in Client_Interception_Point;
      Target  : in CORBA.Object.Ref)
      return PortableInterceptor.ClientRequestInfo.Local_Ref;

   generic
      with procedure Operation
        (Self : in PortableInterceptor.ClientRequestInterceptor.Local_Ref;
         Info : in PortableInterceptor.ClientRequestInfo.Local_Ref);
   procedure Call_Client_Request_Interceptor_Operation
     (Self     : in     PortableInterceptor.ClientRequestInterceptor.Local_Ref;
      Info     : in     PortableInterceptor.ClientRequestInfo.Local_Ref;
      Forward  : in     Boolean;
      Excp_Inf : in out PolyORB.Any.Any);

   --  Server interceptors

   function "="
     (Left, Right : in PortableInterceptor.ServerRequestInterceptor.Local_Ref)
      return Boolean;

   package ServerRequestInterceptor_Lists is
      new PolyORB.Utils.Chained_Lists
           (PortableInterceptor.ServerRequestInterceptor.Local_Ref);

   All_Server_Interceptors : ServerRequestInterceptor_Lists.List;

   procedure Server_Invoke
     (Servant : access PolyORB.Smart_Pointers.Entity'Class;
      Request : in     PolyORB.Requests.Request_Access;
      Profile : in     PolyORB.Binding_Data.Profile_Access);

   procedure Server_Intermediate
     (Request        : in PolyORB.Requests.Request_Access;
      From_Arguments : in Boolean);

   function Create_Server_Request_Info
     (Request      : in PolyORB.Requests.Request_Access;
      Profile      : in PolyORB.Binding_Data.Profile_Access;
      Point        : in Server_Interception_Point;
      Args_Present : in Boolean)
      return PortableInterceptor.ServerRequestInfo.Local_Ref;

   generic
      with procedure Operation
        (Self : in PortableInterceptor.ServerRequestInterceptor.Local_Ref;
         Info : in PortableInterceptor.ServerRequestInfo.Local_Ref);
   procedure Call_Server_Request_Interceptor_Operation
     (Self     : in     PortableInterceptor.ServerRequestInterceptor.Local_Ref;
      Info     : in     PortableInterceptor.ServerRequestInfo.Local_Ref;
      Forward  : in     Boolean;
      Excp_Inf : in out PolyORB.Any.Any);

   --  ORB_Initializers

   function "=" (Left, Right : in PortableInterceptor.ORBInitializer.Local_Ref)
     return Boolean;

   package Initializer_Ref_Lists is
     new PolyORB.Utils.Chained_Lists
          (PortableInterceptor.ORBInitializer.Local_Ref);

   All_Initializer_Refs : Initializer_Ref_Lists.List;

   --  Internal subprograms

   function To_PolyORB_ForwardRequest_Members_Any
     (Members : in PortableInterceptor.ForwardRequest_Members)
      return PolyORB.Any.Any;
   pragma Inline (To_PolyORB_ForwardRequest_Members_Any);
   --  Converting PortableInterceptor::ForwardRequest_Members into
   --  PolyORB internal representation.

   ---------
   -- "=" --
   ---------

   function "="
     (Left, Right : in PortableInterceptor.ClientRequestInterceptor.Local_Ref)
      return Boolean
   is
   begin
      return CORBA.Object.Is_Equivalent (CORBA.Object.Ref (Left), Right);
   end "=";

   ---------
   -- "=" --
   ---------

   function "="
     (Left, Right : in PortableInterceptor.ORBInitializer.Local_Ref)
      return Boolean
   is
   begin
      return CORBA.Object.Is_Equivalent (CORBA.Object.Ref (Left), Right);
   end "=";

   ---------
   -- "=" --
   ---------

   function "="
     (Left, Right : in PortableInterceptor.ServerRequestInterceptor.Local_Ref)
      return Boolean
   is
   begin
      return CORBA.Object.Is_Equivalent (CORBA.Object.Ref (Left), Right);
   end "=";

   ------------------------------------
   -- Add_Client_Request_Interceptor --
   ------------------------------------

   procedure Add_Client_Request_Interceptor
     (Interceptor : in PortableInterceptor.ClientRequestInterceptor.Local_Ref)
   is
   begin
      ClientRequestInterceptor_Lists.Append
        (All_Client_Interceptors, Interceptor);
   end Add_Client_Request_Interceptor;

   ------------------------------------
   -- Add_Server_Request_Interceptor --
   ------------------------------------

   procedure Add_Server_Request_Interceptor
     (Interceptor : in PortableInterceptor.ServerRequestInterceptor.Local_Ref)
   is
   begin
      ServerRequestInterceptor_Lists.Append
        (All_Server_Interceptors, Interceptor);
   end Add_Server_Request_Interceptor;

   -----------------------------------------------
   -- Call_Client_Request_Interceptor_Operation --
   -----------------------------------------------

   procedure Call_Client_Request_Interceptor_Operation
     (Self     : in     PortableInterceptor.ClientRequestInterceptor.Local_Ref;
      Info     : in     PortableInterceptor.ClientRequestInfo.Local_Ref;
      Forward  : in     Boolean;
      Excp_Inf : in out PolyORB.Any.Any)
   is
   begin
      Operation (Self, Info);

   exception
      when E : CORBA.Unknown |
               CORBA.Bad_Param |
               CORBA.No_Memory |
               CORBA.Imp_Limit |
               CORBA.Comm_Failure |
               CORBA.Inv_Objref |
               CORBA.No_Permission |
               CORBA.Internal |
               CORBA.Marshal |
               CORBA.Initialize |
               CORBA.No_Implement |
               CORBA.Bad_TypeCode |
               CORBA.Bad_Operation |
               CORBA.No_Resources |
               CORBA.No_Response |
               CORBA.Persist_Store |
               CORBA.Bad_Inv_Order |
               CORBA.Transient |
               CORBA.Free_Mem |
               CORBA.Inv_Ident |
               CORBA.Inv_Flag |
               CORBA.Intf_Repos |
               CORBA.Bad_Context |
               CORBA.Obj_Adapter |
               CORBA.Data_Conversion |
               CORBA.Object_Not_Exist |
               CORBA.Transaction_Required |
               CORBA.Transaction_Rolledback |
               CORBA.Invalid_Transaction |
               CORBA.Inv_Policy |
               CORBA.Codeset_Incompatible |
               CORBA.Rebind |
               CORBA.Timeout |
               CORBA.Transaction_Unavailable |
               CORBA.Transaction_Mode |
               CORBA.Bad_Qos =>

         Excp_Inf := PolyORB.CORBA_P.Exceptions.System_Exception_To_Any (E);

      when E : PortableInterceptor.ForwardRequest =>

         --  If forwarding at this interception point is allowed then
         --  convert PortableInterceptor::ForwardRequest to
         --  PolyORB::ForwardRequest.

         if Forward then
            declare
               Members : PortableInterceptor.ForwardRequest_Members;

            begin
               PolyORB.Exceptions.User_Get_Members (E, Members);

               Excp_Inf := To_PolyORB_ForwardRequest_Members_Any (Members);
            end;

         else
            raise;
         end if;
   end Call_Client_Request_Interceptor_Operation;

   ---------------------------
   -- Call_ORB_Initializers --
   ---------------------------

   procedure Call_ORB_Initializers is
      use Initializer_Ref_Lists;

      Info_Ptr : constant PortableInterceptor.ORBInitInfo.Impl.Object_Ptr
        := new PortableInterceptor.ORBInitInfo.Impl.Object;
      Info_Ref : PortableInterceptor.ORBInitInfo.Local_Ref;
   begin
      PortableInterceptor.ORBInitInfo.Impl.Init (Info_Ptr);

      PortableInterceptor.ORBInitInfo.Set
        (Info_Ref, PolyORB.Smart_Pointers.Entity_Ptr (Info_Ptr));

      declare
         Iter : Iterator := First (All_Initializer_Refs);
      begin
         while not Last (Iter) loop
            PortableInterceptor.ORBInitializer.Pre_Init
              (Value (Iter).all, Info_Ref);
            Next (Iter);
         end loop;
      end;

      declare
         Iter : Iterator := First (All_Initializer_Refs);
      begin
         while not Last (Iter) loop
            PortableInterceptor.ORBInitializer.Post_Init
              (Value (Iter).all, Info_Ref);
            Next (Iter);
         end loop;
      end;

      --  Mark in ORBInitInfo the fact of initialization complete. This is
      --  required for raise exceptions on all ORBInitInfo operations if some
      --  of Interceptors cache ORBInitInfo reference.

      PortableInterceptor.ORBInitInfo.Impl.Post_Init_Done (Info_Ptr);
   end Call_ORB_Initializers;

   -----------------------------------------------
   -- Call_Server_Request_Interceptor_Operation --
   -----------------------------------------------

   procedure Call_Server_Request_Interceptor_Operation
     (Self     : in     PortableInterceptor.ServerRequestInterceptor.Local_Ref;
      Info     : in     PortableInterceptor.ServerRequestInfo.Local_Ref;
      Forward  : in     Boolean;
      Excp_Inf : in out PolyORB.Any.Any)
   is
   begin
      Operation (Self, Info);

   exception
      when E : CORBA.Unknown |
               CORBA.Bad_Param |
               CORBA.No_Memory |
               CORBA.Imp_Limit |
               CORBA.Comm_Failure |
               CORBA.Inv_Objref |
               CORBA.No_Permission |
               CORBA.Internal |
               CORBA.Marshal |
               CORBA.Initialize |
               CORBA.No_Implement |
               CORBA.Bad_TypeCode |
               CORBA.Bad_Operation |
               CORBA.No_Resources |
               CORBA.No_Response |
               CORBA.Persist_Store |
               CORBA.Bad_Inv_Order |
               CORBA.Transient |
               CORBA.Free_Mem |
               CORBA.Inv_Ident |
               CORBA.Inv_Flag |
               CORBA.Intf_Repos |
               CORBA.Bad_Context |
               CORBA.Obj_Adapter |
               CORBA.Data_Conversion |
               CORBA.Object_Not_Exist |
               CORBA.Transaction_Required |
               CORBA.Transaction_Rolledback |
               CORBA.Invalid_Transaction |
               CORBA.Inv_Policy |
               CORBA.Codeset_Incompatible |
               CORBA.Rebind |
               CORBA.Timeout |
               CORBA.Transaction_Unavailable |
               CORBA.Transaction_Mode |
               CORBA.Bad_Qos =>

         Excp_Inf := PolyORB.CORBA_P.Exceptions.System_Exception_To_Any (E);

      when E : PortableInterceptor.ForwardRequest =>

         --  If forwarding at this interception point is allowed then
         --  convert PortableInterceptor::ForwardRequest to
         --  PolyORB::ForwardRequest.

         if Forward then
            declare
               Members : PortableInterceptor.ForwardRequest_Members;

            begin
               PolyORB.Exceptions.User_Get_Members (E, Members);

               Excp_Inf := To_PolyORB_ForwardRequest_Members_Any (Members);
            end;

         else
            raise;
         end if;
   end Call_Server_Request_Interceptor_Operation;

   -------------------
   -- Client_Invoke --
   -------------------

   procedure Client_Invoke
     (Request : in PolyORB.Requests.Request_Access;
      Flags   : in PolyORB.Requests.Flags)
   is
      use ClientRequestInterceptor_Lists;
      use type PolyORB.Any.TypeCode.Object;
      use type PolyORB.Requests.Request_Access;

      procedure Call_Send_Request is
         new Call_Client_Request_Interceptor_Operation
              (PortableInterceptor.ClientRequestInterceptor.Send_Request);

      procedure Call_Receive_Reply is
         new Call_Client_Request_Interceptor_Operation
             (PortableInterceptor.ClientRequestInterceptor.Receive_Reply);

      procedure Call_Receive_Exception is
         new Call_Client_Request_Interceptor_Operation
              (PortableInterceptor.ClientRequestInterceptor.Receive_Exception);

      procedure Call_Receive_Other is
         new Call_Client_Request_Interceptor_Operation
              (PortableInterceptor.ClientRequestInterceptor.Receive_Other);

      Target  : CORBA.Object.Ref;
      TSC     : Slots_Note;
      Index   : Natural;
      Cur_Req : PolyORB.Requests.Request_Access := Request;

   begin
      CORBA.Object.Convert_To_CORBA_Ref (Request.Target, Target);

      --  Getting thread scope slots information (allocating thread scope
      --  slots if it is not allocated), and make "logical copy" and place it
      --  in the request.
      Get_Note (Get_Current_Thread_Notepad.all, TSC, Invalid_Slots_Note);

      if not Is_Allocated (TSC) then
         Allocate_Slots (TSC);
      end if;

      loop
         Set_Note (Cur_Req.Notepad, TSC);

         Index := Length (All_Client_Interceptors);

         --  Call Send_Request on all interceptors.

         for J in 0 .. Index - 1 loop
            Call_Send_Request
              (Element (All_Client_Interceptors, J).all,
               Create_Client_Request_Info (Cur_Req, Send_Request, Target),
               True,
               Cur_Req.Exception_Info);

            --  If got system or ForwardRequest exception then avoid call
            --  Send_Request on other Interceptors.

            if not PolyORB.Any.Is_Empty (Cur_Req.Exception_Info) then
               Index := J;
               exit;
            end if;
         end loop;

         --  Avoid operation invocation if interceptor raise system exception.

         if Index = Length (All_Client_Interceptors) then
            PolyORB.Requests.Invoke (Cur_Req, Flags);

            --  Restore request scope slots, because it may be changed during
            --  invokation.
            Set_Note (Cur_Req.Notepad, TSC);
         end if;

         for J in reverse 0 .. Index - 1 loop
            if not PolyORB.Any.Is_Empty (Cur_Req.Exception_Info) then
               if PolyORB.Any.Get_Type (Cur_Req.Exception_Info) =
                 PolyORB.Exceptions.TC_ForwardRequest
               then
                  Call_Receive_Other
                    (Element (All_Client_Interceptors, J).all,
                     Create_Client_Request_Info
                       (Cur_Req, Receive_Other, Target),
                     True,
                     Cur_Req.Exception_Info);
               else
                  Call_Receive_Exception
                    (Element (All_Client_Interceptors, J).all,
                     Create_Client_Request_Info
                       (Cur_Req, Receive_Exception, Target),
                     True,
                     Cur_Req.Exception_Info);
               end if;

            else
               Call_Receive_Reply
                 (Element (All_Client_Interceptors, J).all,
                  Create_Client_Request_Info (Cur_Req, Receive_Reply, Target),
                  False,
                  Cur_Req.Exception_Info);
            end if;
         end loop;

         exit when PolyORB.Any.Is_Empty (Cur_Req.Exception_Info)
           or else PolyORB.Any.Get_Type (Cur_Req.Exception_Info) /=
                     PolyORB.Exceptions.TC_ForwardRequest;

         --  Reinvocation. Extract object reference from ForwardRequest
         --  exception and reinitialize request.

         declare
            Members : constant PolyORB.Exceptions.ForwardRequest_Members
              := PolyORB.Exceptions.From_Any (Cur_Req.Exception_Info);
            Ref     : PolyORB.References.Ref;
            Aux_Req : PolyORB.Requests.Request_Access;
         begin
            PolyORB.References.Set
              (Ref,
               Smart_Pointers.Entity_Of (Members.Forward_Reference));

            PolyORB.Requests.Create_Request
              (Target    => Ref,
               Operation => PolyORB.Types.To_String (Request.Operation),
               Arg_List  => Request.Args,
               Result    => Request.Result,
               Exc_List  => Request.Exc_List,
               Req       => Aux_Req,
               Req_Flags => Request.Req_Flags);

            if Cur_Req /= Request then
               PolyORB.Requests.Destroy_Request (Cur_Req);
            end if;

            Cur_Req := Aux_Req;
         end;
      end loop;

      if Cur_Req /= Request then
         --  Auxiliary request allocated, copy request results from it
         --  to original request and destroy auxiliary request.

         Request.Args           := Cur_Req.Args;
         Request.Out_Args       := Cur_Req.Out_Args;
         Request.Result         := Cur_Req.Result;
         Request.Exception_Info := Cur_Req.Exception_Info;

         PolyORB.Requests.Destroy_Request (Cur_Req);
      end if;

      --  Restoring thread scope slots.
      Set_Note (Get_Current_Thread_Notepad.all, TSC);
   end Client_Invoke;

   --------------------------------
   -- Create_Client_Request_Info --
   --------------------------------

   function Create_Client_Request_Info
     (Request : in PolyORB.Requests.Request_Access;
      Point   : in Client_Interception_Point;
      Target  : in CORBA.Object.Ref)
      return PortableInterceptor.ClientRequestInfo.Local_Ref
   is
      Info_Ptr : constant PortableInterceptor.ClientRequestInfo.Impl.Object_Ptr
         := new PortableInterceptor.ClientRequestInfo.Impl.Object;
      Info_Ref : PortableInterceptor.ClientRequestInfo.Local_Ref;

   begin
      PortableInterceptor.ClientRequestInfo.Impl.Init
       (Info_Ptr, Point, Request, Target);

      PortableInterceptor.ClientRequestInfo.Set
        (Info_Ref, PolyORB.Smart_Pointers.Entity_Ptr (Info_Ptr));

      return Info_Ref;
   end Create_Client_Request_Info;

   --------------------------------
   -- Create_Server_Request_Info --
   --------------------------------

   function Create_Server_Request_Info
     (Request      : in PolyORB.Requests.Request_Access;
      Profile      : in PolyORB.Binding_Data.Profile_Access;
      Point        : in Server_Interception_Point;
      Args_Present : in Boolean)
      return PortableInterceptor.ServerRequestInfo.Local_Ref
   is
      Info_Ptr : constant PortableInterceptor.ServerRequestInfo.Impl.Object_Ptr
         := new PortableInterceptor.ServerRequestInfo.Impl.Object;
      Info_Ref : PortableInterceptor.ServerRequestInfo.Local_Ref;
   begin
      PortableInterceptor.ServerRequestInfo.Impl.Init
       (Info_Ptr, Point, Request, Profile, Args_Present);

      PortableInterceptor.ServerRequestInfo.Set
        (Info_Ref, PolyORB.Smart_Pointers.Entity_Ptr (Info_Ptr));

      return Info_Ref;
   end Create_Server_Request_Info;

   ------------------------------------------
   -- Is_Client_Request_Interceptor_Exists --
   ------------------------------------------

   function Is_Client_Request_Interceptor_Exists
     (Name : in String)
      return Boolean
   is
      Iter : ClientRequestInterceptor_Lists.Iterator
         := ClientRequestInterceptor_Lists.First (All_Client_Interceptors);
   begin
      if Name = "" then
         return False;
      end if;

      while not ClientRequestInterceptor_Lists.Last (Iter) loop
         if CORBA.To_Standard_String
              (PortableInterceptor.ClientRequestInterceptor.Get_Name
                (ClientRequestInterceptor_Lists.Value (Iter).all))
             = Name
         then
            return True;
         end if;

         ClientRequestInterceptor_Lists.Next (Iter);
      end loop;

      return False;
   end Is_Client_Request_Interceptor_Exists;

   ------------------------------------------
   -- Is_Server_Request_Interceptor_Exists --
   ------------------------------------------

   function Is_Server_Request_Interceptor_Exists
     (Name : in String)
      return Boolean
   is
      Iter : ServerRequestInterceptor_Lists.Iterator
         := ServerRequestInterceptor_Lists.First (All_Server_Interceptors);
   begin
      if Name = "" then
         return False;
      end if;

      while not ServerRequestInterceptor_Lists.Last (Iter) loop
         if CORBA.To_Standard_String
              (PortableInterceptor.ServerRequestInterceptor.Get_Name
                (ServerRequestInterceptor_Lists.Value (Iter).all))
             = Name
         then
            return True;
         end if;

         ServerRequestInterceptor_Lists.Next (Iter);
      end loop;

      return False;
   end Is_Server_Request_Interceptor_Exists;

   ------------------------------
   -- Register_ORB_Initializer --
   ------------------------------

   procedure Register_ORB_Initializer
     (Init : in PortableInterceptor.ORBInitializer.Local_Ref)
   is
      use Initializer_Ref_Lists;
   begin
      Append (All_Initializer_Refs, Init);
   end Register_ORB_Initializer;

   -------------------------
   -- Server_Intermediate --
   -------------------------

   procedure Server_Intermediate
     (Request        : in PolyORB.Requests.Request_Access;
      From_Arguments : in Boolean)
   is
      use ServerRequestInterceptor_Lists;

      procedure Call_Receive_Request is
         new Call_Server_Request_Interceptor_Operation
              (PortableInterceptor.ServerRequestInterceptor.Receive_Request);

      Note             : Server_Interceptor_Note;
      Break_Invocation : Boolean := False;

      It : Iterator := First (All_Server_Interceptors);

   begin
      PolyORB.Annotations.Get_Note (Request.Notepad, Note);

      if not Note.Intermediate_Called then
         Note.Intermediate_Called := True;

         while not Last (It) loop
            Call_Receive_Request
              (Value (It).all,
               Create_Server_Request_Info
               (Request, Note.Profile, Receive_Request, From_Arguments),
               True,
               Note.Exception_Info);

            if not PolyORB.Any.Is_Empty (Note.Exception_Info) then
               --  Exception information can't be saved in Request,
               --  because skeleton replace it to CORBA.UNKNOWN
               --  exception.

               Break_Invocation := True;
               exit;
            end if;
            Next (It);
         end loop;
      end if;

      PolyORB.Annotations.Set_Note (Request.Notepad, Note);

      if Break_Invocation then
         --  XXX Is this valid for PolyORB::ForwardRequest?

         PolyORB.CORBA_P.Exceptions.Raise_From_Any (Note.Exception_Info);
      end if;
   end Server_Intermediate;

   -------------------
   -- Server_Invoke --
   -------------------

   procedure Server_Invoke
     (Servant : access PolyORB.Smart_Pointers.Entity'Class;
      Request : in     PolyORB.Requests.Request_Access;
      Profile : in     PolyORB.Binding_Data.Profile_Access)
   is
      use ServerRequestInterceptor_Lists;
      use type PolyORB.Any.TypeCode.Object;

      package PISRI renames PortableInterceptor.ServerRequestInterceptor;

      procedure Call_Receive_Request_Service_Contexts is
         new Call_Server_Request_Interceptor_Operation
              (PISRI.Receive_Request_Service_Contexts);

      procedure Call_Send_Reply is
         new Call_Server_Request_Interceptor_Operation (PISRI.Send_Reply);

      procedure Call_Send_Exception is
         new Call_Server_Request_Interceptor_Operation (PISRI.Send_Exception);

      procedure Call_Send_Other is
         new Call_Server_Request_Interceptor_Operation (PISRI.Send_Other);

      RSC             : Slots_Note;
      Empty_Any       : PolyORB.Any.Any;
      Skip_Invocation : Boolean := False;
      Note            : Server_Interceptor_Note
        := (PolyORB.Annotations.Note with
              Profile             => Profile,
              Last_Interceptor    => Length (All_Server_Interceptors),
              Exception_Info      => Empty_Any,
              Intermediate_Called => False);
   begin
      --  Allocating thread request scope slots. Storing it in the request.
      Allocate_Slots (RSC);
      Set_Note (Request.Notepad, RSC);

      for J in 0 .. Note.Last_Interceptor - 1 loop
         Call_Receive_Request_Service_Contexts
           (Element (All_Server_Interceptors, J).all,
            Create_Server_Request_Info
              (Request, Profile, Receive_Request_Service_Contexts, False),
            True,
            Request.Exception_Info);

         --  If got system or ForwardRequest exception then avoid call
         --  Receive_Request_Service_Contexts on other Interceptors.

         if not PolyORB.Any.Is_Empty (Request.Exception_Info) then
            Note.Last_Interceptor  := J;
            Skip_Invocation        := True;
            exit;
         end if;
      end loop;

      --  Copy ing request scope slots to thread scope slots

      Get_Note (Request.Notepad, RSC);
      Set_Note (Get_Current_Thread_Notepad.all, RSC);

      --  Saving in request information for calling intermediate
      --  interception point.

      Set_Note (Request.Notepad, Note);

      if not Skip_Invocation then
         PortableServer.Invoke
           (PortableServer.DynamicImplementation'Class (Servant.all)'Access,
            Request);
         --  Redispatch
      end if;

      Get_Note (Request.Notepad, Note);

      if not PolyORB.Any.Is_Empty (Note.Exception_Info) then
         --  If a system exception or ForwardRequest exception will be
         --  raised in Receive_Request interception point then replace
         --  Request exception information, because it may be replaced
         --  in skeleton.
         Request.Exception_Info := Note.Exception_Info;
      end if;

      --  Retrieve thread scope slots and copy it back to request
      --  scope slots.

      Get_Note (Get_Current_Thread_Notepad.all, RSC);
      Set_Note (Request.Notepad, RSC);

      for J in reverse 0 .. Note.Last_Interceptor - 1 loop
         if not PolyORB.Any.Is_Empty (Request.Exception_Info) then
            if PolyORB.Any.Get_Type (Request.Exception_Info) =
              PolyORB.Exceptions.TC_ForwardRequest
            then
               Call_Send_Other
                 (Element (All_Server_Interceptors, J).all,
                  Create_Server_Request_Info
                    (Request, Profile, Send_Other, True),
                  True,
                  Request.Exception_Info);
            else
               Call_Send_Exception
                 (Element (All_Server_Interceptors, J).all,
                  Create_Server_Request_Info
                    (Request, Profile, Send_Exception, True),
                  True,
                  Request.Exception_Info);
            end if;

         else
            Call_Send_Reply
              (Element (All_Server_Interceptors, J).all,
               Create_Server_Request_Info (Request, Profile, Send_Reply, True),
               False,
               Request.Exception_Info);
         end if;
      end loop;
   end Server_Invoke;

   -------------------------------------------
   -- To_PolyORB_ForwardRequest_Members_Any --
   -------------------------------------------

   function To_PolyORB_ForwardRequest_Members_Any
     (Members : in PortableInterceptor.ForwardRequest_Members)
      return PolyORB.Any.Any
   is
   begin
      return
        PolyORB.Exceptions.To_Any
        (PolyORB.Exceptions.ForwardRequest_Members'
         (Forward_Reference =>
            PolyORB.Smart_Pointers.Ref
          (CORBA.Object.To_PolyORB_Ref (Members.Forward))));
   end To_PolyORB_ForwardRequest_Members_Any;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize;

   procedure Initialize is
   begin
      PolyORB.CORBA_P.Interceptors_Hooks.Client_Invoke := Client_Invoke'Access;
      PolyORB.CORBA_P.Interceptors_Hooks.Server_Invoke := Server_Invoke'Access;
      PolyORB.CORBA_P.Interceptors_Hooks.Server_Intermediate :=
        Server_Intermediate'Access;
   end Initialize;

   use PolyORB.Initialization;
   use PolyORB.Initialization.String_Lists;
   use PolyORB.Utils.Strings;

begin
   Register_Module
     (Module_Info'
      (Name      => +"polyorb.corba_p.interceptors",
       Conflicts => Empty,
       Depends   => +"corba.request"
       & "portablserver",
       Provides  => Empty,
       Implicit  => False,
       Init      => Initialize'Access));

end PolyORB.CORBA_P.Interceptors;