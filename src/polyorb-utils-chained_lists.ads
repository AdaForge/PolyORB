------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--          P O L Y O R B . U T I L S . C H A I N E D _ L I S T S           --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2001-2003 Free Software Foundation, Inc.           --
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

--  Generic chained list.

--  $Id$

generic
   type T is private;
   with function "=" (X, Y : T) return Boolean is <>;
package PolyORB.Utils.Chained_Lists is

   pragma Preelaborate;

   type List is private;
   type Iterator is private;
   type Element_Access is access all T;

   function Length (L : List) return Natural;
   --  Return the number of elements in L

   function Element (L : List; Index : Natural) return Element_Access;
   --  Return the element at position Index (0-based) in L.

   procedure Extract_First
     (L      : in out List;
      Result : out T);
   --  Return the first element of L into Result,
   --  and remove it from the list.

   function First (L : List) return Iterator;
   --  Return an iterator on L positioned at L's first element.

   function First (I : Iterator) return Boolean;
   --  True when I is positioned at the first element of the
   --  underlying list.

   function Value (I : Iterator) return Element_Access;
   --  Return an access to the value of the list element currently
   --  designated by I.

   procedure Next (I : in out Iterator);
   --  Move I to the next element in the list.

   function Last (L : List) return Iterator;
   --  Return an iterator position at the end of L (i.e. immediately
   --  after the last element in L; this iterator has no associated
   --  value).

   function Last (I : Iterator) return Boolean;
   --  True when I is positioned at the end of L (i.e. after the
   --  last element).

   procedure Prepend (L : in out List; I : T);
   --  Prepend value I at the beginning of L.

   procedure Append (L : in out List; I : T);
   --  Append value I at the end of L.

   procedure Insert (L : in out List; I : T; Before : in out Iterator);
   --  Insert I into L before the designated position.

   procedure Remove (L : in out List; I : in out Iterator);
   --  Remove the item designated by I from L, and advance I to the next
   --  item in L.

   procedure Remove (L : in out List; I : T);
   --  Remove all occurences of value I from list L.

   Empty : constant List;
   --  A list that contains no elements.

   function "+" (I : T) return List;
   --  Make a list with I as its only element.

   function "&" (I : T; L : List) return List;
   --  Prepend I to L.

   function "&" (L : List; I : T) return List;
   --  Append I to L.

   function "&" (L1, L2 : List) return List;
   --  Concatenate L1 and L2;

   function Duplicate (L : List) return List;
   --  Return a copy of list L.

   procedure Deallocate (L : in out List);
   --  Release the storage associated with L.

private

   pragma Inline (First);
   pragma Inline (Value);
   pragma Inline (Last);
   pragma Inline (Next);
   pragma Inline (Prepend);
   pragma Inline (Append);
   pragma Inline (Insert);
   pragma Inline (Remove);
   pragma Inline ("+");
   pragma Inline ("&");

   type Node;
   type Node_Access is access all Node;
   type Node is record
      Value : aliased T;
      Next  : Node_Access;
   end record;

   type Iterator is record
     Current, Previous : Node_Access;
   end record;

   type List is record
      First, Last : Node_Access;
   end record;

   Empty : constant List := (null, null);

end PolyORB.Utils.Chained_Lists;
