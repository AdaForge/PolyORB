------------------------------------------------------------------------------
--                                                                          --
--                          DROOPI COMPONENTS                               --
--                                                                          --
--                         C O R B A. G I O P                               --
--                                                                          --
--                               S p e c                                    --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Streams;   use Ada.Streams;

with CORBA;

with Droopi.Buffers;
with Droopi.Binding_Data;
with Droopi.Binding_Data.IIOP;
with Droopi.Objects;
with Droopi.Opaque;
with Droopi.ORB;
with Droopi.Protocols;
with Droopi.References;
with Droopi.References.IOR;
with Droopi.Requests;

with Sequences.Unbounded;

package Droopi.Protocols.GIOP is

   use Droopi.Buffers;

   Max_Data_Received     : constant Integer;
   Endianess_Bit         : constant Integer;
   Fragment_Bit          : constant Integer;
   Byte_Order_Offset     : constant Integer;

   type GIOP_Session is new Session with private;

   type GIOP_Protocol is new Protocol with private;

   subtype GIOP_Request is Requests.Request;

   type Sync_Scope is (NONE, WITH_TRANSPORT, WITH_SERVER, WITH_TARGET);

   subtype Bits_8 is CORBA.Octet;

   type IOR_Addressing_Info is record
      Selected_Profile_Index : CORBA.Unsigned_Long;
      IOR                    : References.IOR.IOR_Type;
   end record;

   type Addressing_Disposition is new Natural range 0 .. 2;

   type Target_Address
     (Address_Type : Addressing_Disposition)
   is record
      case Address_Type is
         when 0 =>
            Object_Key : Objects.Object_Id_Access;
         when 1 =>
            Profile : Binding_Data.IIOP.IIOP_Profile_Type;
         when 2 =>
            Ref : IOR_Addressing_Info;
      end case;
   end record;


   --  GIOP:: MsgType
   type Msg_Type is
     (Request,
      Reply,
      Cancel_Request,
      Locate_Request,
      Locate_Reply,
      Close_Connection,
      Message_Error,
      Fragment);


   --  GIOP::ReplyStatusType
   type Reply_Status_Type is
     (No_Exception,
      User_Exception,
      System_Exception,
      Location_Forward,
      Location_Forward_Perm,
      Needs_Addressing_Mode);

   --  GIOP::LocateStatusType
   type Locate_Status_Type is
     (Unknown_Object,
      Object_Here,
      Object_Forward,
      Object_Forward_Perm,
      Loc_System_Exception,
      Loc_Needs_Addressing_Mode);

   type Pending_Request is private;

   --  type Response_Sync(Version :  range 0 .. 1) is
   --  record
   --    case Version is
   --      when 0 =>
   --         Response_Expected : CORBA.Boolean;
   --      when 1 | 2 =>
   --         Sync_Type         : SyncScope;
   --    end case;
   --   end record;

   type Send_Request_Result_Type is
     (Sr_No_Reply,
      Sr_Reply,
      Sr_User_Exception,
      Sr_Forward,
      Sr_Forward_Perm,
      Sr_Needs_Addressing_Mode
      );

   type Locate_Request_Result_Type is
     (Sr_Unknown_Object,
      Sr_Object_Here,
      Sr_Object_Forward,
      Sr_Object_Forward_Perm,
      Sr_Loc_System_Exception,
      Sr_Loc_Needs_Addressing_Mode
      );


   --  type GIOP_Version is private;

   package Octet_Sequences is new Sequences.Unbounded (CORBA.Octet);
   subtype CORBA_Octet_Array is Octet_Sequences.Element_Array;

   --  Define Types of Target Addresses used with Request Message


   type ServiceId is
     (Transaction_Service,
      CodeSets,
      ChainByPassCheck,
      ChainByPassInfo,
      LogicalThreadId,
      Bi_Dir_IIOP,
      SendingContextRunTime,
      Invocation_Policies,
      Forwarded_Identity,
      UnknownExceptionInfo);


   -----------------------------------------------------------
   --  Some common marshalling procedures for GIOP 1.0, 1.1, 1.2
   ------------------------------------------------------------

   procedure Exception_Marshall
     (Buffer           : access Buffer_Type;
      Request_Id       : in CORBA.Unsigned_Long;
      Exception_Type   : in Reply_Status_Type;
      Occurence        : in CORBA.Exception_Occurrence);


   procedure Location_Forward_Marshall
     (Buffer           : access Buffer_Type;
      Request_Id       : in  CORBA.Unsigned_Long;
      Forward_Ref      : in  References.Ref);


   procedure Cancel_Request_Marshall
     (Buffer           : access Buffer_Type;
      Request_Id       : in CORBA.Unsigned_Long);


   procedure Locate_Request_Marshall
     (Buffer           : access Buffer_Type;
      Request_Id       : in CORBA.Unsigned_Long;
      Profile_Ref      : in Binding_Data.Profile_Type);

   procedure Locate_Reply_Marshall
     (Buffer         : access Buffer_Type;
      Request_Id     : in CORBA.Unsigned_Long;
      Locate_Status  : in Locate_Status_Type);

   -----------------------------------
   --  Unmarshall
   ----------------------------------

   procedure Unmarshall_GIOP_Header
     (Ses                   : access GIOP_Session;
      Message_Type          : out Msg_Type;
      Message_Size          : out CORBA.Unsigned_Long;
      Fragment_Next         : out CORBA.Boolean;
      Success               : out Boolean);

   procedure Locate_Reply_Unmarshall
     (Buffer        : access Buffer_Type;
      Request_Id    : out CORBA.Unsigned_Long;
      Locate_Status : out Locate_Status_Type);



   ---------------------------------------
   ---  Marshalling switch  -----------
   --------------------------------------

   procedure Request_Message
     (Ses               : access GIOP_Session;
      Response_Expected : in Boolean;
      Message_Size      : in CORBA.Unsigned_Long;
      Fragment_Next     : out Boolean);

   procedure No_Exception_Reply
     (Ses           : access GIOP_Session;
      Request_Id    : in CORBA.Unsigned_Long;
      Message_Size  : in CORBA.Unsigned_Long;
      Fragment_Next : out Boolean);


   procedure Exception_Reply
     (Ses             : access GIOP_Session;
      Message_Size    : in Stream_Element_Offset;
      Exception_Type  : in Reply_Status_Type;
      Occurence       : in CORBA.Exception_Occurrence);


   procedure Location_Forward_Reply
     (Ses             : access GIOP_Session;
      Message_Size    : in Stream_Element_Offset;
      Exception_Type  : in Reply_Status_Type;
      Forward_Ref     : in References.Ref;
      Fragment_Next   : out Boolean);

   procedure Need_Addressing_Mode_Message
     (Ses             : access GIOP_Session;
      Message_Size    : in Stream_Element_Offset;
      Address_Type    : in Addressing_Disposition);

   procedure Cancel_Request_Message
     (Ses             : access GIOP_Session;
      Message_Size    : in Stream_Element_Offset);

   procedure Locate_Request_Message
     (Ses             : access GIOP_Session;
      Message_Size    : in Stream_Element_Offset;
      Address_Type    : in Addressing_Disposition;
      Target_Ref      : in Target_Address;
      Fragment_Next   : out Boolean);

   procedure Locate_Reply_Message
     (Ses             : access GIOP_Session;
      Message_Size    : in Stream_Element_Offset;
      Locate_Status   : in Locate_Status_Type);


   -------------------------------------------
   --  Session procedures
   ------------------------------------------


   procedure Create
     (Proto   : access GIOP_Protocol;
      Session : out Filter_Access);

   procedure Connect (S : access GIOP_Session);

   procedure Invoke_Request
     (S : access GIOP_Session;
      R : Requests.Request);

   procedure Abort_Request
     (S : access GIOP_Session;
      R : Requests.Request);

   procedure Send_Reply
     (S : access GIOP_Session;
      R : Requests.Request);

   procedure Handle_Connect_Indication (S : access GIOP_Session);

   procedure Handle_Connect_Confirmation (S : access GIOP_Session);

   procedure Handle_Data_Indication (S : access GIOP_Session);

   procedure Handle_Disconnect (S : access GIOP_Session);



   ----------------------------------------
   ---  Pending requests primitives
   ---------------------------------------

   procedure Store_Request
     (Req     : Requests.Request;
      Profile : in Binding_Data.IIOP.IIOP_Profile_Type);

private

   type GIOP_Session is new Session with record
      Major_Version        : CORBA.Octet;
      Minor_Version        : CORBA.Octet;
      Buffer_Out           : Buffers.Buffer_Access;
      Buffer_In            : Buffers.Buffer_Access;
      Role                 : ORB.Endpoint_Role;
      Object_Found         : Boolean := False;
      Nbr_Tries            : Natural := 0;
      Expect_Header        : Boolean := True;
      Mess_Type_Received   : Msg_Type;
   end record;

   type GIOP_Protocol is new Protocol with null record;

   type Pending_Request is record
      Req             : Requests.Request_Access;
      Request_Id      : CORBA.Unsigned_Long := 0;
      Target_Profile  : Binding_Data.Profile_Access;
   end record;

   procedure Expect_Data
     (S             : access GIOP_Session;
      In_Buf        : Buffers.Buffer_Access;
      Expect_Max    : Ada.Streams.Stream_Element_Count);

   Message_Header_Size : constant := 12;

   Message_Body_Size : constant := 1000;

   Max_Data_Received : constant Integer := 1024;

   Endianess_Bit : constant Integer := 1;

   Fragment_Bit : constant Integer := 2;

   Byte_Order_Offset : constant Integer := 6;

   Max_Nb_Tries : constant Integer := 100;

end Droopi.Protocols.GIOP;
