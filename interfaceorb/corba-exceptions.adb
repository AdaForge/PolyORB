-----------------------------------------------------------------------
-----------------------------------------------------------------------
----                                                               ----
----                         AdaBroker                             ----
----                                                               ----
----                 package Corba.Exceptions                      ----
----                                                               ----
----                                                               ----
----   Copyright (C) 1999 ENST                                     ----
----                                                               ----
----   This file is part of the AdaBroker library                  ----
----                                                               ----
----   The AdaBroker library is free software; you can             ----
----   redistribute it and/or modify it under the terms of the     ----
----   GNU Library General Public License as published by the      ----
----   Free Software Foundation; either version 2 of the License,  ----
----   or (at your option) any later version.                      ----
----                                                               ----
----   This library is distributed in the hope that it will be     ----
----   useful, but WITHOUT ANY WARRANTY; without even the implied  ----
----   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR     ----
----   PURPOSE.  See the GNU Library General Public License for    ----
----   more details.                                               ----
----                                                               ----
----   You should have received a copy of the GNU Library General  ----
----   Public License along with this library; if not, write to    ----
----   the Free Software Foundation, Inc., 59 Temple Place -       ----
----   Suite 330, Boston, MA 02111-1307, USA                       ----
----                                                               ----
----                                                               ----
----                                                               ----
----   Description                                                 ----
----   -----------                                                 ----
----                                                               ----
----     This package is a sub package of package corba dealing    ----
----   with Corba exceptions.                                      ----
----     It provides two main functions : Raise_corba_Exception    ----
----   and Get_Members. These functions allows the programmer to   ----
----   associate to each exception a "memmber" structure with      ----
----   all kinds of datas he needs.                                ----
----                                                               ----
----                                                               ----
----   authors : Sebastien Ponce, Fabien Azavant                   ----
----   date    : 02/28/99                                          ----
----                                                               ----
-----------------------------------------------------------------------
-----------------------------------------------------------------------


with Ada.Unchecked_Conversion ;
with Interfaces.C ;
with System ;
with Text_IO ; use Text_IO ;
with Ada.Tags ;

with Constants ;
use type Constants.Exception_Id ;
with Adabroker_Debug ; use Adabroker_Debug ;

package body Corba.Exceptions is

   type ID_Num is mod 65000 ;
   ID_Number : ID_Num := 0;
   -- Number of exceptions raised until now
   -- used to build an identifier for each exception


   type Cell ;
   type Cell_Ptr is access all Cell ;
   type Cell (N : Positive) is
      record
         Value : Idl_Exception_Members_Ptr ;
         ID : Standard.String (1..N) ;
         Next : Cell_Ptr ;
      end record ;
   -- Definition of type list of Idl_Exception_Members in order to store
   -- the different member object waiting for their associated exception
   -- to be catched.
   -- Actually, this list works as a stack since the last exception raised
   -- may be the first catched.
   -- Each member is associated to a string which references it and allows
   -- the procedure Get_Members to find it again since the corresponding
   -- exception will be raised with the same string as message.
   -- Actually, the string is the image of ID_Number that is incremented
   -- each time an exception is raised.

--   protected Member_List is
--      procedure Put (V : in Idl_Exception_Members'Class ;
--                     ID_V : in Standard.String) ;
--      procedure Get (From : in Ada.Exceptions.Exception_Occurrence ;
--                     Result : out Idl_Exception_Members'Class) ;
--   private
      List : Cell_Ptr := null ;
--   end Member_List;
   -- list of members
   -- The list is declared protected to avoid conflict between several
   -- threads.


   -- Free : free the memory
   -------------------------
   procedure Free is new Ada.Unchecked_Deallocation(Cell, Cell_Ptr) ;


--   protected body Member_List is

      -- Put : add a member to the list
      ---------------------------------
      procedure Put (V : in Idl_Exception_Members'Class ;
                     ID_V : in Standard.String) is
         Temp : Cell_Ptr ;
      begin
         pragma Debug(Output(Corba_Exceptions_Debug,"corba-exception put, member type : " & Ada.Tags.External_Tag(V'Tag)));
         -- makes a new cell ...
         Temp := new Cell'(N => ID_V'Length,
                           Value => new Idl_Exception_Members'Class'(V),
                           ID => ID_V,
                           Next => List) ;
         -- ... and add it in front of the list
         List := Temp ;
      end ;


      -- Get : get a member from the list
      ------------------------------------
      procedure Get (From : in Ada.Exceptions.Exception_Occurrence ;
                     Result : out Idl_Exception_Members'Class) is
         Temp : Cell_Ptr := List ;
         Old_Temp : Cell_Ptr := null ;
         -- pointers on the cell which is beeing process and on the previous cell
         ID : Standard.String := Ada.Exceptions.Exception_Message (From) ;
         -- reference of the searched member
      begin
         if Temp = null
         then
            -- raise an Ada Exception AdaBroker_Fatal_Error
            pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get temp = null ****")) ;
            Ada.Exceptions.Raise_Exception (AdaBroker_Fatal_Error'Identity,
                                            "Corba.exceptions.Get (Standard.String)"
                                            & Corba.CRLF
                                            & "Member associated to exception "
                                            & Ada.Exceptions.Exception_Name (From)
                                            & " not found.") ;
         else
            loop
               pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get another loop")) ;
               if Temp.all.ID = ID
               then
                  declare
                     -- we found the member associated to From
                     Member : Idl_Exception_Members'Class := Temp.all.Value.all ;
                  begin
                     pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get found the right member")) ;
                     -- we can suppress the correponding cell
                     if Old_Temp = null
                     then
                        -- temp was the first cell
                        List := Temp.all.Next ;
                     else
                        -- temp was not the first cell
                        Old_Temp.all.Next := Temp.all.Next ;
                     end if ;
                     -- and free the memory
                     pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get frees temp.all.value")) ;
                     Free (Temp.all.Value) ;
                     pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get frees temp")) ;
                     Free (Temp) ;
                     pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get frees completed")) ;
                     pragma Debug(Output(Corba_Exceptions_Debug,"result type : " & Ada.Tags.External_Tag(Result'Tag))) ;
                     pragma Debug(Output(Corba_Exceptions_Debug,"member type : " & Ada.Tags.External_Tag(Member'Tag))) ;
                     -- at last, return the result
                     Result := Member ;
                     pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get goes out")) ;
                     return ;
                  end ;
               else
                  -- if the end of list is reached
                  if Temp.all.Next = null
                  then
                  -- raise an Ada Exception AdaBroker_Fatal_Error
                  pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get member not found ****")) ;
                  Ada.Exceptions.Raise_Exception (AdaBroker_Fatal_Error'Identity,
                                                  "Corba.exceptions.Get (Standard.String)"
                                                  & Corba.CRLF
                                                  & "Member associated to exception "
                                                  & Ada.Exceptions.Exception_Name (From)
                                                  & " not found.") ;
                  else
                     -- else go to the next element of the list
                     Old_Temp := Temp ;
                     Temp := Temp.all.Next ;
               end if ;
               end if ;
            end loop ;
         end if ;
      end ;

--   end Member_List ;

   -- Get_Members
   --------------
   procedure Get_Members (From : in Ada.Exceptions.Exception_Occurrence;
                          To : out Idl_Exception_Members'Class) is
   begin
      pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get_member calls get")) ;
--      Member_List.
      Get (From, To) ;
      pragma Debug(Output(Corba_Exceptions_Debug,"corba.exceptions.get_member goes out")) ;
   end ;


   -- Raise_Corba_exception
   ------------------------
   procedure Raise_Corba_Exception(Excp : in Ada.Exceptions.Exception_Id ;
                                   Excp_Memb: in Idl_Exception_Members'Class) is
      ID : Standard.String := ID_Num'Image(ID_Number) ;
   begin
      -- stores the member object
      -- Member_List.
      Put (Excp_Memb,ID) ;
      -- raises the Ada exception with the ID String as message
      Ada.Exceptions.Raise_Exception (Excp,ID) ;
   end ;

end Corba.Exceptions ;
