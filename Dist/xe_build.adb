------------------------------------------------------------------------------
--                                                                          --
--                            GLADE COMPONENTS                              --
--                                                                          --
--                             X E _ B U I L D                              --
--                                                                          --
--                                 B o d y                                  --
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

with Make;             use Make;
with Namet;            use Namet;
with Osint;            use Osint;
with Output;           use Output;
with XE;               use XE;
with XE_Back;          use XE_Back;
with XE_Check;         use XE_Check;
with XE_Parse;         use XE_Parse;
with XE_Scan;          use XE_Scan;
with XE_Stubs;         use XE_Stubs;
with XE_Utils;         use XE_Utils;

with Debug;
with Opt;
with XE_Lead;
with XE_Usage;

procedure XE_Build is

   Suffix    : constant String := ".cfg";

begin

   Make.Initialize;
   --  Use Gnatmake already defined switches.
   Verbose_Mode       := Opt.Verbose_Mode;
   Debug_Mode         := Debug.Debug_Flag_Q;
   Quiet_Output       := Opt.Quiet_Output;
   No_Recompilation   := Opt.Dont_Execute;
   Building_Script    := Opt.List_Dependencies;

   --  Use -dq for Gnatdist internal debugging.
   Debug.Debug_Flag_Q := False;

   --  Don't want log messages that would corrupt scripts.
   if Building_Script then
      Verbose_Mode := False;
      Quiet_Output := True;
   end if;

   Opt.Check_Source_Files := False;
   Opt.All_Sources        := False;

   if Osint.Number_Of_Files = 0 then
      XE_Usage;

   else

      --  Initialization of differents modules.

      XE_Utils.Initialize;
      XE_Scan.Initialize;
      XE_Parse.Initialize;
      XE_Check.Initialize;

      --  Look for the configuration file :
      --     Next_Main_Source or Next_Main_Source + ".cfg" if the latter
      --     does not exist.

      declare
         N : Name_Id := Next_Main_Source;
         L : Integer;
         S : Integer := Suffix'Length;
      begin

         Get_Name_String (N);
         L := Name_Len;

         --  Remove suffix if needed.
         if L > S and then Name_Buffer (L - S + 1 .. L) = Suffix then
            L := L - S;
            N := Name_Find;
         else
            Name_Buffer (L + 1 .. L + S) := Suffix;
            Name_Len := L + S;
            N := Name_Find;
         end if;

         --  If the filename is not already correct.
         if not Is_Regular_File (N) then

            Write_Program_Name;
            Write_Str  (": ");
            Write_Name (N);
            Write_Str  (" not found");
            Write_Eol;
            Exit_Program (E_Fatal);
         else
            Configuration_File := N;
         end if;
      end;

      if Building_Script then
         Write_Str (Standout, "#! /bin/sh");
         Write_Eol (Standout);
      end if;

      Parse;
      Back;

      --  The configuration name and the configuration file name don't match.

      Get_Name_String (Configuration_File);
      Name_Len := Name_Len - 4;
      if Configuration /= Name_Find then
         if not Quiet_Output then
            Write_Program_Name;
            Write_Str (": file name does not match configuration name,");
            Write_Str (" should be """);
            Write_Name (Configuration);
            Write_Str (".cfg""");
            Write_Eol;
         end if;
         raise Fatal_Error;
      end if;

      Check;

      if not Quiet_Output then
         Show_Configuration;
      end if;

      --  Look for a partition list on the command line. Only those
      --  partitions are going to be generated. If no partition list is
      --  given, then generate all of them.

      if More_Source_Files then
         for P in Partitions.First .. Partitions.Last loop
            Partitions.Table (P).To_Build := False;
         end loop;
         while More_Source_Files loop

            --  At this level, the key associated to a partition name is
            --  its table index.

            declare
               N : Name_Id  := Next_Main_Source;
               P : PID_Type := Get_PID (N);
            begin
               if P = Null_PID then
                  Write_Program_Name;
                  Write_Name (N);
                  Write_Str (" is not a partition");
                  raise Fatal_Error;
               end if;
               Partitions.Table (P).To_Build := True;
            end;

         end loop;
      end if;

      XE_Stubs.Build;
      XE_Lead;

      Exit_Program (E_Success);

   end if;

exception
   when Scanning_Error =>
      Write_Program_Name;
      Write_Str (": *** scanning failed");
      Write_Eol;
      Exit_Program (E_Fatal);
   when Parsing_Error =>
      Write_Program_Name;
      Write_Str (": *** parsing failed");
      Write_Eol;
      Exit_Program (E_Fatal);
   when Partitioning_Error =>
      Write_Program_Name;
      Write_Str (": *** partitionning failed");
      Write_Eol;
      Exit_Program (E_Fatal);
   when Usage_Error =>
      Write_Program_Name;
      Write_Str (": *** wrong argument(s)");
      Write_Eol;
      Exit_Program (E_Fatal);
   when Not_Yet_Implemented =>
      Write_Program_Name;
      Write_Str (": *** unimplemented feature");
      Write_Eol;
      Exit_Program (E_Fatal);
   when Fatal_Error =>
      Write_Program_Name;
      Write_Str (": *** can't continue");
      Write_Eol;
      Exit_Program (E_Fatal);
   when others =>
      Write_Program_Name;
      Write_Str (": *** unknown error");
      Write_Eol;
      raise;  --  hope GNAT will output its name

end XE_Build;
