------------------------------------------------------------------------------
--                                                                          --
--                          GNATDIST COMPONENTS                             --
--                                                                          --
--                              X E _ L E A D                               --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision$                              --
--                                                                          --
--           Copyright (C) 1996 Free Software Foundation, Inc.              --
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
--              GNATDIST is maintained by ACT Europe.                       --
--            (email:distribution@act-europe.gnat.com).                     --
--                                                                          --
------------------------------------------------------------------------------
with Types;       use Types;
with Namet;       use Namet;
with XE_Utils;    use XE_Utils;
with GNAT.Os_Lib; use GNAT.Os_Lib;
with Output;      use Output;
with Osint;       use Osint;
with XE;          use XE;

procedure XE_Lead is

   FD : File_Descriptor;

   procedure Set_Host           (Partition : in PID_Type);

   procedure Set_Boot_Server (Partition : in PID_Type);

   procedure Set_Launcher       (Partition  : in PID_Type);

   procedure Set_Host           (Partition : in PID_Type) is
      Host : Host_Id := Partitions.Table (Partition).Host;
   begin
      if Host = Null_Host then
         Host := Default_Host;
      end if;
      if Hosts.Table (Host).Name = No_Name then
         Write_Str  (FD, "echo '");
         Write_Name (FD, Partitions.Table (Partition).Name);
         Write_Str  (FD, " host: '");
         Write_Eol  (FD);
         Write_Str  (FD, "read ");
         Write_Name (FD, Partitions.Table (Partition).Name);
         Write_Str  (FD, "_HOST");
         Write_Eol  (FD);

      --  XXXX : These tests should not occur there (xe_check)
      elsif not Hosts.Table (Host).Static then
         if Starter_Method = Ada_Starter and then
            Hosts.Table (Host).Import = Shell_Import then
            Write_Program_Name;
            Write_Str  (": Starter method is Ada when function ");
            Write_Name (Hosts.Table (Host).Name);
            Write_Str  (" is imported from Shell");
            Write_Eol;
            raise Parsing_Error;
         elsif Starter_Method = Shell_Starter and then
            Hosts.Table (Host).Import = Ada_Import then
            Write_Program_Name;
            Write_Str  (": Starter method is Shell when function ");
            Write_Name (Hosts.Table (Host).Name);
            Write_Str  (" is imported from Ada");
            Write_Eol;
            raise Parsing_Error;
         end if;
         Write_Name (FD, Partitions.Table (Partition).Name);
         Write_Str  (FD, "_HOST=`");
         Write_Name (FD, Hosts.Table (Host).External);
         Write_Str  (FD, "`");
         Write_Eol  (FD);
      else
         Write_Name (FD, Partitions.Table (Partition).Name);
         Write_Str  (FD, "_HOST=");
         Write_Name (FD, Hosts.Table (Host).Name);
         Write_Eol  (FD);
      end if;
   end Set_Host;

   procedure Set_Launcher (Partition  : in PID_Type) is
   begin
      if Partition /= Main_Partition then
         Write_Str  (FD, "rsh -n $");
         Write_Name (FD, Partitions.Table (Partition).Name);
         Write_Str  (FD, "_HOST """);
      end if;
      if Partitions.Table (Partition).Storage_Dir /= No_Storage_Dir then
         declare
            Dir : constant Name_Id := Partitions.Table (Partition).Storage_Dir;
            Str : String (1 .. Strlen (Dir));
         begin
            Get_Name_String (Dir);
            Str := Name_Buffer (1 .. Name_Len);
            if Str (1) /= Separator then
               Write_Str  (FD, "`pwd`/");
               Write_Str  (FD, Str);
               Write_Str  (FD, "/");
            else
               Write_Str  (FD, Str);
               Write_Str  (FD, "/");
            end if;
         end;
      elsif Default_Storage_Dir = Null_Name then
         Write_Str  (FD, "`pwd`/");
      else
         Write_Name (FD, Default_Storage_Dir & Dir_Sep_Id);
      end if;

      Write_Name (FD, Partitions.Table (Partition).Name);
      Write_Str  (FD, " --boot_server $BOOT_SERVER");

      declare
         Cmd : Command_Line_Type;
      begin
         if Partitions.Table (Partition).Command_Line = No_Command_Line then
            Cmd := Default_Command_Line;
         else
            Cmd := Partitions.Table (Partition).Command_Line;
         end if;

         if Cmd /= No_Command_Line then
            Write_Str (FD, " ");
            Write_Name (FD, Cmd);
            Write_Str (FD, " ");
         end if;
      end;

      if Partition /= Main_Partition then
         Write_Str (FD, " --detach --slave &""");
      end if;
      Write_Eol (FD);
   end Set_Launcher;

   procedure Set_Boot_Server
     (Partition : in PID_Type) is
   begin
      Write_Name (FD, Partitions.Table (Partition).Name);
      Write_Str  (FD, "_HOST=`hostname`");
      Write_Eol  (FD);
      Write_Str  (FD, "BOOT_SERVER=tcp://$");
      Write_Name (FD, Partitions.Table (Partition).Name);
      Write_Str  (FD, "_HOST:5555");
      Write_Eol  (FD);
   end Set_Boot_Server;

begin

   if Starter_Method /= None_Starter and then not Quiet_Output then
      Write_Program_Name;
      Write_Str  (": generating starter ");
      Write_Name (Main_Subprogram);
      Write_Eol;
   end if;

   case Starter_Method is

      when Shell_Starter =>

         Unlink_File (Main_Subprogram);

         Create (FD, Main_Subprogram, True);

         if Building_Script then
            Write_Str  ("cat >");
            Write_Name (Main_Subprogram);
            Write_Str  (" <<EOF");
            Write_Eol;
         end if;

         Write_Str (FD, "#! /bin/sh");
         Write_Eol (FD);
         Write_Str (FD, "PATH=/usr/ucb:${PATH}");
         Write_Eol (FD);

         for Partition in Partitions.First .. Partitions.Last loop
            if Partition /= Main_Partition then
               Set_Host (Partition => Partition);
            end if;
         end loop;

         Set_Boot_Server (Main_Partition);
         for Partition in Partitions.First .. Partitions.Last loop
            if Partition /= Main_Partition then
               Set_Launcher (Partition  => Partition);
            end if;
         end loop;
         Set_Launcher (Partition  => Main_Partition);

         Close (FD);

         if Building_Script then
            Write_Str ("EOF");
            Write_Eol;
         end if;

      when Ada_Starter =>

         for PID in Partitions.First .. Partitions.Last loop
            if PID = Main_Partition then
               declare
                  PName : constant Partition_Name_Type :=
                    Partitions.Table (PID).Name;
                  Dir   : Storage_Dir_Name_Type;
               begin
                  Dir := Partitions.Table (PID).Storage_Dir;
                  if Dir = No_Storage_Dir then
                     Dir := Default_Storage_Dir;
                  end if;
                  if Dir = No_Storage_Dir then
                     Copy_With_File_Stamp
                       (Source         => PName,
                        Target         => Main_Subprogram,
                        Maybe_Symbolic => True);
                  else
                     Copy_With_File_Stamp
                       (Source         => Dir & Dir_Sep_Id & PName,
                        Target         => Main_Subprogram,
                        Maybe_Symbolic => True);
                  end if;
                  exit;
               end;
            end if;
         end loop;

      when None_Starter => null;

   end case;

end XE_Lead;
