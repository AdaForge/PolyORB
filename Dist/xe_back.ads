------------------------------------------------------------------------------
--                                                                          --
--                            GLADE COMPONENTS                              --
--                                                                          --
--                              X E _ B A C K                               --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                            $Revision$                             --
--                                                                          --
--         Copyright (C) 1996,1997 Free Software Foundation, Inc.           --
--                                                                          --
-- GNATDIST is  free software;  you  can redistribute  it and/or  modify it --
-- under terms of the  GNU General Public License  as published by the Free --
-- Software  Foundation;  either version 2,  or  (at your option) any later --
-- version. GNATDIST is distributed in the hope that it will be useful, but --
-- WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHANTABI- --
-- LITY or FITNESS  FOR A PARTICULAR PURPOSE.  See the  GNU General  Public --
-- License  for more details.  You should  have received a copy of the  GNU --
-- General Public License distributed with  GNATDIST; see file COPYING.  If --
-- not, write to the Free Software Foundation, 59 Temple Place - Suite 330, --
-- Boston, MA 02111-1307, USA.                                              --
--                                                                          --
--                 GLADE  is maintained by ACT Europe.                      --
--                 (email: glade-report@act-europe.fr)                      --
--                                                                          --
------------------------------------------------------------------------------

with Table;
with XE_Utils;  use XE_Utils;
with XE;        use XE;
package XE_Back is


   -- CID_Type --

   type CID_Type is new Int range 100_000 .. 199_999;

   Null_CID  : constant CID_Type := 100_000;
   First_CID : constant CID_Type := 100_001;
   Last_CID  : constant CID_Type := 199_999;


   -- CUID_Type --

   type CUID_Type is new Int range 200_000 .. 299_999;
   --  CUID = Configure Unit ID to differentiate from Unit_Id. Such units
   --  from the configuration language are not always real ada units as
   --  configuration file can be erroneous.

   Null_CUID  : constant CUID_Type := 200_000;
   First_CUID : constant CUID_Type := 200_001;
   Last_CUID  : constant CUID_Type := 299_999;


   -- Host_Id --

   type Host_Id is new Int range 300_000 .. 399_999;

   Null_Host  : constant Host_Id := 300_000;
   First_Host : constant Host_Id := 300_001;
   Last_Host  : constant Host_Id := 399_999;


   -- PID_Type --

   type PID_Type is new Int range 400_000 .. 499_999;

   Null_PID  : constant PID_Type := 400_000;
   First_PID : constant PID_Type := 400_001;
   Last_PID  : constant PID_Type := 499_999;


   -- Names --

   subtype Partition_Name_Type is Name_Id;
   No_Partition_Name : constant Partition_Name_Type := No_Name;

   subtype Channel_Name_Type is Name_Id;
   No_Channel_Name : constant Channel_Name_Type := No_Name;

   subtype Filter_Name_Type is Name_Id;
   No_Filter_Name : constant Filter_Name_Type := No_Name;

   subtype CUnit_Name_Type is Name_Id;
   No_CUnit_Name     : constant CUnit_Name_Type := No_Name;

   subtype Host_Name_Type is Name_Id;
   No_Host_Name      : constant Host_Name_Type := No_Name;

   subtype Main_Subprogram_Type is Name_Id;
   No_Main_Subprogram : constant Main_Subprogram_Type := No_Name;

   subtype Command_Line_Type is Name_Id;
   No_Command_Line   : constant Command_Line_Type := No_Name;

   subtype Storage_Dir_Name_Type is Name_Id;
   No_Storage_Dir    : constant Storage_Dir_Name_Type := No_Name;

   -- Defaults --

   Default_Main          : Main_Subprogram_Type  := No_Main_Subprogram;
   Default_Host          : Host_Id               := Null_Host;
   Default_Storage_Dir   : Storage_Dir_Name_Type := No_Storage_Dir;
   Default_Command_Line  : Command_Line_Type     := No_Command_Line;
   Default_Termination   : Termination_Type      := Unknown_Termination;
   Default_Filter        : Filter_Name_Type      := No_Filter_Name;
   Protocol_Name         : Name_Id               := No_Name;
   Protocol_Data         : Name_Id               := No_Name;
   Starter_Method        : Starter_Method_Type   := Ada_Starter;
   Version_Checks        : Boolean               := True;

   -- Table element types --

   type Channel_Type is record
      Name   : Channel_Name_Type;
      Lower  : PID_Type;
      Upper  : PID_Type;
      Filter : Filter_Name_Type;
   end record;

   type Conf_Unit_Type is record
      CUname    : CUnit_Name_Type;
      My_ALI    : ALI_Id;
      My_Unit   : Unit_Id;
      Partition : PID_Type;
      Next      : CUID_Type;
   end record;

   type Host_Type is
      record
         Static   : Boolean            := True;
         Import   : Import_Method_Type := None_Import;
         Name     : Host_Name_Type     := No_Name;
         External : Host_Name_Type     := No_Name;
      end record;

   type Partition_Type is record
      Name            : Partition_Name_Type;
      Host            : Host_Id;
      Storage_Dir     : Storage_Dir_Name_Type;
      Command_Line    : Command_Line_Type;
      Main_Subprogram : Unit_Name_Type;
      Termination     : Termination_Type;
      First_Unit      : CUID_Type;
      Last_Unit       : CUID_Type;
      To_Build        : Boolean;
      Most_Recent     : File_Name_Type;
   end record;

   -- Tables --

   package Partitions  is new Table
     (Table_Component_Type => Partition_Type,
      Table_Index_Type     => PID_Type,
      Table_Low_Bound      => First_PID,
      Table_Initial        => 20,
      Table_Increment      => 100,
      Table_Name           => "Partition");

   package Hosts  is new Table
     (Table_Component_Type => Host_Type,
      Table_Index_Type     => Host_Id,
      Table_Low_Bound      => First_Host,
      Table_Initial        => 20,
      Table_Increment      => 100,
      Table_Name           => "Host");

   package Channels  is new Table
     (Table_Component_Type => Channel_Type,
      Table_Index_Type     => CID_Type,
      Table_Low_Bound      => First_CID,
      Table_Initial        => 20,
      Table_Increment      => 100,
      Table_Name           => "Channel");

   package CUnit is new Table
     (Table_Component_Type => Conf_Unit_Type,
      Table_Index_Type     => CUID_Type,
      Table_Low_Bound      => First_CUID,
      Table_Initial        => 200,
      Table_Increment      => 100,
      Table_Name           => "CUnit");

   Configuration       : Name_Id         := No_Name;
   --  Name of the configuration.

   Main_Partition     : PID_Type  := Null_PID;
   --  Partition where the main procedure has been assigned.

   Main_Subprogram    : Name_Id        := No_Name;
   Main_Source_File   : File_Name_Type := No_Name;
   Main_ALI           : ALI_Id;
   --  Several variables related to the main procedure.

   procedure Add_Channel_Partition
     (Partition : in Partition_Name_Type; To : in CID_Type);
   --  Assign a paritition to a channel. Sort the partition pair.

   procedure Add_Conf_Unit (CU : in CUnit_Name_Type; To : in PID_Type);
   --  Assign a Conf Unit to a partition. This unit is declared in the
   --  configuration file (it is not yet mapped to an ada unit).

   function Already_Loaded (Unit : Name_Id) return Boolean;
   --  Check that this unit has not been previously loaded in order
   --  to avoid multiple entries in GNAT tables.

   procedure Back;

   procedure Copy_Channel
     (Name : in Channel_Name_Type;
      Many : in Int);
   --  Create Many successive copies of channel Name.

   procedure Copy_Partition
     (Name : in Partition_Name_Type;
      Many : in Int);
   --  Create Many successive copies of partition Name.

   procedure Create_Channel
     (Name : in  Channel_Name_Type;
      CID  : out CID_Type);
   --  Create a new channel and store its CID in its name key.

   procedure Create_Partition
     (Name : in  Partition_Name_Type;
      PID  : out PID_Type);
   --  Create a new partition and store its PID in its name key.

   function Get_Absolute_Exec   (P : PID_Type) return File_Name_Type;
   --  Look for storage_dir into partitions and compute absolute executable
   --  name. If null, return default.

   function  Get_ALI_Id (N : Name_Id) return ALI_Id;
   --  Return N name key if its value is in ALI_Id range, otherwise
   --  return No_ALI_Id.

   function Get_CID  (N : Name_Id) return CID_Type;
   function Get_Command_Line (P : PID_Type) return Command_Line_Type;
   --  Look for conammd_line into partitions. If null, return default.

   function  Get_CUID  (N : Name_Id) return CUID_Type;
   function Get_Filter          (C : CID_Type) return Name_Id;
   --  Look for filter in channels. If null, return default.

   function Get_Host            (P : PID_Type) return Name_Id;
   --  Look for host into partitions. If null, return default.

   function Get_Main_Subprogram (P : PID_Type) return Main_Subprogram_Type;
   --  Look for main_subprogram into partitions. If null, return default.

   function Get_Partition_Dir   (P : PID_Type) return File_Name_Type;
   --  Look for partition_dir into partitions. If null, return default.

   function  Get_PID  (N : Name_Id) return PID_Type;
   function Get_Relative_Exec   (P : PID_Type) return File_Name_Type;
   --  Look for storage_dir into partitions and compute relative executable
   --  name into partitions. If null, return default.

   function Get_Storage_Dir     (P : PID_Type) return Storage_Dir_Name_Type;
   --  Look for storage_dir into partitions. If null, return default.

   function Get_Termination     (P : PID_Type) return Termination_Type;
   --  Look for termination into partitions. If null, return default.

   function  Get_Unit_Id (N : Name_Id) return Unit_Id;
   --  Return N name key if its value is in Unit_Id range, otherwise
   --  return No_Unit_Id.

   function Get_Unit_Sfile      (U : Unit_Id)  return File_Name_Type;
   --  Look for sfile into unit.

   function Is_Set (Partition : PID_Type) return Boolean;
   --  Some units have already been assigned to this partition.

   procedure Load_All_Units (From : Unit_Name_Type);
   --  Recursively update GNAT internal tables by downloading all Uname
   --  dependent units if available.

   procedure More_Recent_Stamp (P : in PID_Type; F : in File_Name_Type);
   --  The more recent stamp of files needed to build a partition is
   --  updated.

   procedure Set_ALI_Id (N : Name_Id; A : ALI_Id);
   --  Set A in N key.

   procedure Set_CID  (N : Name_Id; C : CID_Type);

   procedure Set_CUID  (N : Name_Id; U : CUID_Type);

   procedure Set_PID  (N : Name_Id; P : PID_Type);

   procedure Set_Unit_Id (N : Name_Id; U : Unit_Id);
   --  Set U into N key.

   procedure Show_Configuration;
   --  Report the current configuration.

end XE_Back;
